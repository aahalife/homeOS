import Foundation

@MainActor
final class RuntimeStreamClient: ObservableObject {
    static let shared = RuntimeStreamClient()

    private var socket: URLSessionWebSocketTask?
    private var isConnecting = false

    private init() {}

    func connectIfNeeded() async {
        guard socket == nil, !isConnecting else { return }
        guard let authToken = KeychainStore.shared.getString(forKey: "authToken"),
              let workspaceId = UserDefaults.standard.string(forKey: "workspaceId"),
              !authToken.isEmpty,
              !workspaceId.isEmpty else {
            return
        }
        isConnecting = true
        defer { isConnecting = false }

        do {
            let info = try await ControlPlaneAPI.shared.fetchRuntimeConnectionInfo(
                token: authToken,
                workspaceId: workspaceId
            )

            guard var components = URLComponents(string: info.wsUrl) else { return }
            components.queryItems = [
                URLQueryItem(name: "token", value: info.token),
                URLQueryItem(name: "workspaceId", value: workspaceId)
            ]
            guard let url = components.url else { return }

            let task = URLSession.shared.webSocketTask(with: url)
            socket = task
            task.resume()
            listen()
        } catch {
            print("Runtime stream connect failed: \(error)")
        }
    }

    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
    }

    private func listen() {
        socket?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                self.handle(message)
            case .failure(let error):
                print("Runtime stream error: \(error)")
                self.disconnect()
                Task { await self.connectIfNeeded() }
            }
            self.listen()
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .string(let text):
            data = Data(text.utf8)
        case .data(let raw):
            data = raw
        @unknown default:
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        if type == "connected" || type == "pong" || type == "subscribed" {
            return
        }

        NotificationCenter.default.post(
            name: .runtimeEventReceived,
            object: nil,
            userInfo: ["type": type, "payload": json["payload"] ?? [:]]
        )
    }
}

extension Notification.Name {
    static let runtimeEventReceived = Notification.Name("runtimeEventReceived")
}
