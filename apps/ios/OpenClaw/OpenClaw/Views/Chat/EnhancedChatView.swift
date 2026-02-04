import SwiftUI

/// Enhanced modern chat interface with all message types
struct EnhancedChatView: View {
    @StateObject private var viewModel = EnhancedChatViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showTaskMode = false
    @State private var showTransparency = false
    @State private var showSearch = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Main chat content
                VStack(spacing: 0) {
                    // Search bar (when active)
                    if showSearch {
                        searchBar
                    }

                    // Messages
                    messagesView

                    // Quick replies if available
                    if let suggestions = viewModel.currentQuickReplies {
                        QuickReplySuggestionsBar(
                            suggestions: suggestions,
                            onSelect: { suggestion in
                                viewModel.sendQuickReply(suggestion)
                            }
                        )
                    }

                    // Input bar
                    enhancedInputBar
                }

                // Greeting overlay (for new users)
                if viewModel.shouldShowGreeting {
                    GreetingOverlay(
                        greeting: viewModel.personalizedGreeting,
                        onDismiss: { viewModel.dismissGreeting() }
                    )
                }
            }
            .navigationTitle(viewModel.chatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showTaskMode) {
                TaskModeView()
            }
            .sheet(isPresented: $showTransparency) {
                TransparencyView()
            }
            .refreshable {
                await viewModel.loadHistory()
            }
        }
    }

    // MARK: - Messages View

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredMessages) { message in
                        messageView(for: message)
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Typing indicator
                    if viewModel.isProcessing {
                        EnhancedTypingIndicator()
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isProcessing) { _, isProcessing in
                if isProcessing {
                    withAnimation {
                        proxy.scrollTo("typing-indicator", anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func messageView(for message: EnhancedChatMessage) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Avatar for assistant messages
                if message.role == .assistant {
                    assistantAvatar
                }

                // Message content based on type
                Group {
                    switch message.messageType {
                    case .text:
                        TextMessageView(message: message, isUser: message.role == .user)

                    case .skillCard(let data):
                        SkillCardView(data: data)

                    case .action(let data):
                        ActionMessageView(data: data)

                    case .progress(let data):
                        ProgressMessageView(data: data)

                    case .update(let data):
                        UpdateMessageView(data: data)

                    case .achievement(let data):
                        AchievementMessageView(data: data)

                    case .richMedia(let data):
                        RichMediaMessageView(data: data)
                    }
                }
                .contextMenu {
                    messageContextMenu(for: message)
                }
            }

            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }

    private var assistantAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
    }

    // MARK: - Input Bar

    private var enhancedInputBar: some View {
        HStack(spacing: 12) {
            // Voice input button
            Button(action: { viewModel.startVoiceInput() }) {
                Image(systemName: "mic.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Voice input")

            // Text field
            TextField("Ask OpenClaw anything...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .focused($isInputFocused)
                .onSubmit {
                    Task { await viewModel.sendMessage() }
                }
                .disabled(viewModel.isProcessing)

            // Send button
            Button(action: {
                Task { await viewModel.sendMessage() }
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.canSend ? Color.blue : Color(.systemGray4))
                        .frame(width: 36, height: 36)

                    Image(systemName: viewModel.isProcessing ? "hourglass" : "arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(viewModel.isProcessing ? .degrees(180) : .degrees(0))
                }
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSend || viewModel.isProcessing)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color(.separator)),
            alignment: .top
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search messages...", text: $searchText)
                .textFieldStyle(.plain)
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchMessages(query: newValue)
                }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button("Cancel") {
                withAnimation {
                    showSearch = false
                    searchText = ""
                    viewModel.clearSearch()
                }
            }
            .font(.body)
        }
        .padding()
        .background(Color(.systemGray6))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button(action: { viewModel.updateDensity(.conversational) }) {
                    Label("Conversational", systemImage: "bubble.left")
                }
                Button(action: { viewModel.updateDensity(.detailed) }) {
                    Label("Detailed", systemImage: "list.bullet")
                }
                Button(action: { viewModel.updateDensity(.summary) }) {
                    Label("Summary Only", systemImage: "text.alignleft")
                }
            } label: {
                Image(systemName: "textformat.size")
            }
        }

        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text(viewModel.chatTitle)
                    .font(.headline)
                if viewModel.isProcessing {
                    Text("Thinking...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(action: { showTaskMode = true }) {
                    Label("Task Mode", systemImage: "checklist")
                }

                Button(action: { showTransparency = true }) {
                    Label("Transparency Dashboard", systemImage: "chart.bar.doc.horizontal")
                }

                Divider()

                Button(action: { withAnimation { showSearch = true } }) {
                    Label("Search", systemImage: "magnifyingglass")
                }

                Button(action: { viewModel.exportChat() }) {
                    Label("Export Chat", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button(role: .destructive, action: { viewModel.clearChat() }) {
                    Label("Clear Chat", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func messageContextMenu(for message: EnhancedChatMessage) -> some View {
        Button(action: { viewModel.copyMessage(message) }) {
            Label("Copy", systemImage: "doc.on.doc")
        }

        if message.role == .assistant {
            Button(action: { viewModel.regenerateResponse(for: message) }) {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
        }

        if message.metadata?.canUndo == true {
            Button(action: { viewModel.undoAction(for: message) }) {
                Label("Undo Action", systemImage: "arrow.uturn.backward")
            }
        }

        Button(role: .destructive, action: { viewModel.deleteMessage(message) }) {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Quick Reply Suggestions Bar

struct QuickReplySuggestionsBar: View {
    let suggestions: [QuickReplySuggestion]
    let onSelect: (QuickReplySuggestion) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions) { suggestion in
                    Button(action: { onSelect(suggestion) }) {
                        HStack(spacing: 6) {
                            if let icon = suggestion.icon {
                                Image(systemName: icon)
                                    .font(.caption)
                            }
                            Text(suggestion.text)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color(.separator)),
            alignment: .top
        )
    }
}

// MARK: - Enhanced Typing Indicator

struct EnhancedTypingIndicator: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.white)
                }

            // Animated dots
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 8, height: 8)
                        .scaleEffect(scale(for: index))
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer()
        }
        .id("typing-indicator")
        .onAppear {
            phase = 1
        }
    }

    private func scale(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.2
        let animationPhase = (phase + delay).truncatingRemainder(dividingBy: 1.0)
        return 1.0 + sin(animationPhase * .pi) * 0.5
    }
}

// MARK: - Greeting Overlay

struct GreetingOverlay: View {
    let greeting: String
    let onDismiss: () -> Void
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.9

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(greeting)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Button(action: { dismiss() }) {
                    Text("Let's Go!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 40)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                opacity = 1
                scale = 1
            }
        }
    }

    private func dismiss() {
        withAnimation {
            opacity = 0
            scale = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - View Model (Placeholder)

class EnhancedChatViewModel: ObservableObject {
    @Published var messages: [EnhancedChatMessage] = []
    @Published var inputText = ""
    @Published var isProcessing = false
    @Published var currentQuickReplies: [QuickReplySuggestion]?
    @Published var shouldShowGreeting = false
    @Published var personalizedGreeting = ""
    @Published var chatTitle = "OpenClaw"
    @Published var filteredMessages: [EnhancedChatMessage] = []

    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init() {
        loadInitialState()
    }

    func loadInitialState() {
        // Load saved messages and check if greeting should be shown
        filteredMessages = messages
    }

    func sendMessage() async {
        // Send message implementation
    }

    func sendQuickReply(_ suggestion: QuickReplySuggestion) {
        // Quick reply implementation
    }

    func loadHistory() async {
        // Load chat history
    }

    func searchMessages(query: String) {
        // Search implementation
    }

    func clearSearch() {
        filteredMessages = messages
    }

    func startVoiceInput() {
        // Voice input implementation
    }

    func updateDensity(_ density: InformationDensity) {
        // Update density preference
    }

    func exportChat() {
        // Export implementation
    }

    func clearChat() {
        messages.removeAll()
        filteredMessages.removeAll()
    }

    func copyMessage(_ message: EnhancedChatMessage) {
        UIPasteboard.general.string = message.content
    }

    func regenerateResponse(for message: EnhancedChatMessage) {
        // Regenerate implementation
    }

    func undoAction(for message: EnhancedChatMessage) {
        // Undo implementation
    }

    func deleteMessage(_ message: EnhancedChatMessage) {
        messages.removeAll { $0.id == message.id }
        filteredMessages.removeAll { $0.id == message.id }
    }

    func dismissGreeting() {
        shouldShowGreeting = false
    }
}

enum InformationDensity {
    case conversational
    case detailed
    case summary
}

#Preview {
    EnhancedChatView()
}
