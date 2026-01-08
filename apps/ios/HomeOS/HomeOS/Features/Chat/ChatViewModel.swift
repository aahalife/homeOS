import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var isConnected = false

    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Add sample messages for preview
        messages = [
            ChatMessage(
                id: "1",
                role: .assistant,
                content: "Hi! I'm your HomeOS assistant. How can I help you today?",
                timestamp: Date().addingTimeInterval(-60)
            )
        ]

        // Connect to WebSocket
        Task {
            await connect()
        }
    }

    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: inputText,
            timestamp: Date()
        )

        messages.append(userMessage)
        let messageText = inputText
        inputText = ""
        isTyping = true

        // Send to API
        do {
            try await sendToAPI(message: messageText)
        } catch {
            print("Error sending message: \(error)")
            isTyping = false
        }
    }

    private func sendToAPI(message: String) async throws {
        guard let url = URL(string: "\(Configuration.runtimeURL)/v1/chat/turn") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AuthManager.shared.token ?? "")", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "workspaceId": AuthManager.shared.workspaceId ?? "",
            "message": message
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ChatTurnResponse.self, from: data)

        // Response will come via WebSocket stream
        print("Started chat turn: \(response.taskId)")
    }

    func sendVoiceMessage(audioData: Data) async {
        isTyping = true

        do {
            // First, transcribe the audio
            let transcription = try await transcribeAudio(audioData: audioData)

            // Add user message with transcription
            let userMessage = ChatMessage(
                id: UUID().uuidString,
                role: .user,
                content: transcription,
                timestamp: Date(),
                isVoiceMessage: true
            )
            messages.append(userMessage)

            // Send to API
            try await sendToAPI(message: transcription)
        } catch {
            print("Voice message error: \(error)")
            isTyping = false
        }
    }

    private func transcribeAudio(audioData: Data) async throws -> String {
        guard let url = URL(string: "\(Configuration.runtimeURL)/v1/voice/transcribe") else {
            throw NSError(domain: "ChatViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AuthManager.shared.token ?? "")", forHTTPHeaderField: "Authorization")

        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)

        return response.text
    }

    func playVoiceResponse(text: String) async {
        do {
            guard let url = URL(string: "\(Configuration.runtimeURL)/v1/voice/synthesize") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(AuthManager.shared.token ?? "")", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "text": text,
                "useDefault": true  // Use default voice, can be customized
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await URLSession.shared.data(for: request)

            // Play the audio response
            await MainActor.run {
                AudioManager.shared.playAudio(data: data)
            }
        } catch {
            print("Voice synthesis error: \(error)")
        }
    }

    private func connect() async {
        guard let token = AuthManager.shared.token,
              let workspaceId = AuthManager.shared.workspaceId,
              let url = URL(string: "\(Configuration.runtimeWSURL)/v1/stream?token=\(token)") else {
            return
        }

        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true

        // Listen for messages
        await receiveMessages()
    }

    private func receiveMessages() async {
        guard let webSocketTask = webSocketTask else { return }

        do {
            while true {
                let message = try await webSocketTask.receive()

                switch message {
                case .string(let text):
                    handleWebSocketMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleWebSocketMessage(text)
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

    private func handleWebSocketMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        switch type {
        case "chat.message.delta":
            // Handle streaming delta
            if let payload = json["payload"] as? [String: Any],
               let delta = payload["delta"] as? String {
                handleChatDelta(delta)
            }

        case "chat.message.final":
            // Handle final message
            if let payload = json["payload"] as? [String: Any],
               let content = payload["content"] as? String {
                handleChatFinal(content)
            }

        case "task.created", "task.updated":
            // Handle task updates
            break

        case "approval.requested":
            // Handle approval request
            break

        default:
            break
        }
    }

    private func handleChatDelta(_ delta: String) {
        // For streaming, we'd update the last message incrementally
        // For now, we'll wait for the final message
    }

    private func handleChatFinal(_ content: String) {
        isTyping = false

        let assistantMessage = ChatMessage(
            id: UUID().uuidString,
            role: .assistant,
            content: content,
            timestamp: Date(),
            isNew: true
        )

        messages.append(assistantMessage)
    }
}

struct ChatTurnResponse: Codable {
    let sessionId: String
    let taskId: String
    let workflowId: String
}

struct TranscriptionResponse: Codable {
    let text: String
    let duration: Double?
}
