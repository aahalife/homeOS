import SwiftUI

/// Main chat interface
struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isProcessing {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Quick actions
                QuickActionsBar(onAction: { action in
                    Task { await viewModel.sendQuickAction(action) }
                })

                // Input bar
                ChatInputBar(
                    text: $viewModel.inputText,
                    isProcessing: viewModel.isProcessing,
                    isFocused: $isInputFocused,
                    onSend: {
                        Task { await viewModel.sendMessage() }
                    }
                )
            }
            .navigationTitle("OpenClaw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Clear Chat", systemImage: "trash") {
                            viewModel.clearChat()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: 48) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if let skill = message.skill {
                    Text(skill.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }

                Text(.init(message.content)) // Supports markdown
                    .font(.body)
                    .foregroundStyle(isUser ? .white : .primary)
                    .padding(12)
                    .background(isUser ? Color.blue : Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Attachments
                if let attachments = message.attachments {
                    ForEach(attachments, id: \.title) { attachment in
                        AttachmentCard(attachment: attachment)
                    }
                }

                Text(message.timestamp.timeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !isUser { Spacer(minLength: 48) }
        }
    }
}

// MARK: - Attachment Card

struct AttachmentCard: View {
    let attachment: ChatAttachment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForType(attachment.type))
                    .foregroundStyle(.blue)
                Text(attachment.title)
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3)))
    }

    private func iconForType(_ type: ChatAttachment.AttachmentType) -> String {
        switch type {
        case .mealPlan: return "fork.knife"
        case .recipe: return "book"
        case .groceryList: return "cart"
        case .appointment: return "calendar"
        case .assignment: return "pencil"
        case .checkInSummary: return "heart.text.square"
        case .contractor: return "wrench"
        case .calendar: return "calendar"
        case .briefing: return "sun.max"
        }
    }
}

// MARK: - Quick Actions Bar

struct QuickActionsBar: View {
    let onAction: (String) -> Void

    private let actions = [
        ("Morning Briefing", "sun.max"),
        ("Plan Dinner", "fork.knife"),
        ("Homework Check", "book"),
        ("Check Calendar", "calendar")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(actions, id: \.0) { action in
                    Button {
                        onAction(action.0)
                    } label: {
                        Label(action.0, systemImage: action.1)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    let isProcessing: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask anything...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused(isFocused)
                .onSubmit { onSend() }

            Button(action: onSend) {
                Image(systemName: isProcessing ? "hourglass" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(text.isEmpty || isProcessing ? .gray : .blue)
            }
            .disabled(text.isEmpty || isProcessing)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color(.separator)), alignment: .top)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotIndex = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(.gray)
                        .opacity(dotIndex == index ? 1.0 : 0.3)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
        .onReceive(timer) { _ in
            dotIndex = (dotIndex + 1) % 3
        }
    }
}

#Preview {
    ChatView(viewModel: ChatViewModel(appState: AppState()))
}
