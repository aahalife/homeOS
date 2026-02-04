import Foundation
import Combine

/// ViewModel for the main chat interface
@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?

    private let appState: AppState
    private let persistence = PersistenceController.shared
    private let logger = AppLogger.shared

    init(appState: AppState) {
        self.appState = appState
        loadHistory()
    }

    // MARK: - Message Handling

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        isProcessing = true
        errorMessage = nil

        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        persistence.saveChatMessage(userMessage)

        guard let family = appState.currentFamily else {
            addSystemMessage("Please complete onboarding first to set up your family profile.")
            isProcessing = false
            return
        }

        // Process through orchestrator
        let response = await appState.skillOrchestrator.processRequest(
            text: text,
            family: family,
            chatHistory: messages
        )

        let assistantMessage = ChatMessage(
            role: .assistant,
            content: response.text,
            skill: response.skill,
            attachments: response.attachments.isEmpty ? nil : response.attachments
        )
        messages.append(assistantMessage)
        persistence.saveChatMessage(assistantMessage)

        isProcessing = false
    }

    func clearChat() {
        messages = []
    }

    // MARK: - Quick Actions

    func sendQuickAction(_ action: String) async {
        inputText = action
        await sendMessage()
    }

    // MARK: - Helpers

    private func loadHistory() {
        let history = persistence.loadChatHistory(limit: 50)
        if !history.isEmpty {
            messages = history
        } else {
            // Add welcome message
            addSystemMessage("""
            Welcome to OpenClaw! I'm your family assistant. I can help with:

            - Meal Planning - "Plan dinners for this week"
            - Healthcare - "Check symptoms" or "Track medication"
            - Education - "What homework is due?"
            - Elder Care - "How is Mom doing?"
            - Home Maintenance - "Find a plumber"
            - Family Calendar - "What's on this week?"
            - Daily Planning - "Give me my morning briefing"

            How can I help you today?
            """)
        }
    }

    private func addSystemMessage(_ text: String) {
        let message = ChatMessage(role: .assistant, content: text)
        messages.append(message)
        persistence.saveChatMessage(message)
    }
}
