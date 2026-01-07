import SwiftUI
import Combine

@MainActor
class NetworkManager: ObservableObject {
    @Published var isConnected = false

    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?

    init() {
        // Connection will be established when authenticated
    }

    func connect(token: String, workspaceId: String) async {
        guard let url = URL(string: "\(Configuration.runtimeWSURL)/v1/stream?token=\(token)&workspaceId=\(workspaceId)") else {
            return
        }

        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()

        isConnected = true

        // Start ping timer
        startPingTimer()

        // Listen for messages
        await receiveMessages()
    }

    func disconnect() {
        pingTimer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }

    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func sendPing() {
        let message = URLSessionWebSocketTask.Message.string("{\"type\":\"ping\"}")
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Ping failed: \(error)")
            }
        }
    }

    private func receiveMessages() async {
        guard let webSocketTask = webSocketTask else { return }

        do {
            while true {
                let message = try await webSocketTask.receive()

                switch message {
                case .string(let text):
                    handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            print("WebSocket receive error: \(error)")
            isConnected = false
        }
    }

    private func handleMessage(_ text: String) {
        // Parse and route message to appropriate handler
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        // Post notification for specific message types
        NotificationCenter.default.post(
            name: .websocketMessage,
            object: nil,
            userInfo: ["type": type, "data": json]
        )
    }
}

extension Notification.Name {
    static let websocketMessage = Notification.Name("websocketMessage")
}
