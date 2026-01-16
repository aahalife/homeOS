import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var messageText = ""

    private let messages: [ChatMessage] = [
        ChatMessage(text: "Good morning! Here is your family's day at a glance:\n- Emma has Physics lab\n- Jack has soccer at 4 PM\n- Permission slip due today\n\nHow can Oi help?", isUser: false),
        ChatMessage(text: "What should we have for dinner?", isUser: true),
        ChatMessage(text: "Based on what you have:\n\nPasta primavera\n25 min - Uses veggies\n\nSee recipe or other ideas?", isUser: false)
    ]

    private let quickActions = [
        "Meal Plan",
        "School Update",
        "What's next?",
        "Add reminder"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                Divider()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(quickActions, id: \.self) { action in
                            Button(action: {}) {
                                Text(action)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(AppTheme.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(AppTheme.surfaceSecondary)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Divider()

                HStack(spacing: 12) {
                    TextField("Message Oi...", text: $messageText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(AppTheme.surfaceSecondary)
                        .cornerRadius(12)

                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(AppTheme.primary)
                    }

                    Button(action: {}) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty ? AppTheme.textTertiary : AppTheme.primary)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(16)
            }
            .navigationTitle("Chat with Oi")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle")
                        Text(session.userName)
                            .font(.subheadline)
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}

private struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            Text(message.text)
                .font(.body)
                .foregroundColor(message.isUser ? .white : .primary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(message.isUser ? AppTheme.primary : AppTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(message.isUser ? Color.clear : AppTheme.border, lineWidth: 1)
                )
                .frame(maxWidth: 260, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser { Spacer() }
        }
    }
}
