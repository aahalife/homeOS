import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var audioManager = AudioManager.shared
    @FocusState private var isInputFocused: Bool
    @State private var showVoiceMode = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Messages
                messagesScrollView

                // Input
                inputBar
            }

            // Voice Mode Overlay
            if showVoiceMode {
                VoiceModeOverlay(
                    isRecording: audioManager.isRecording,
                    audioLevel: audioManager.audioLevel,
                    duration: audioManager.recordingDuration,
                    onCancel: {
                        audioManager.cancelRecording()
                        showVoiceMode = false
                    },
                    onSend: {
                        Task {
                            await handleVoiceMessage()
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showVoiceMode)
    }

    private func handleVoiceMessage() async {
        guard let url = audioManager.stopRecording(),
              let audioData = audioManager.getRecordingData() else {
            showVoiceMode = false
            return
        }

        showVoiceMode = false

        // Send audio for transcription and processing
        await viewModel.sendVoiceMessage(audioData: audioData)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("HomeOS")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isConnected ? .green : .red)
                        .frame(width: 8, height: 8)

                    Text(viewModel.isConnected ? "Connected" : "Offline")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            Button {
                // New conversation
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(GlassSurface(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isTyping {
                        TypingIndicator()
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(viewModel.messages.last?.id)
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            // Microphone button
            Button {
                showVoiceMode = true
                audioManager.startRecording()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(GlassSurface(cornerRadius: 22))
            }

            TextField("Message", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(GlassSurface(cornerRadius: 24))
                .focused($isInputFocused)
                .lineLimit(1...5)

            Button {
                Task {
                    await viewModel.sendMessage()
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        viewModel.inputText.isEmpty
                            ? .white.opacity(0.3)
                            : LinearGradient(
                                colors: [Color(hex: "4361ee"), Color(hex: "3a0ca3")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            }
            .disabled(viewModel.inputText.isEmpty || viewModel.isTyping)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Voice Mode Overlay

struct VoiceModeOverlay: View {
    let isRecording: Bool
    let audioLevel: Float
    let duration: TimeInterval
    let onCancel: () -> Void
    let onSend: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Recording indicator
                ZStack {
                    // Pulse animation
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 120 + CGFloat(audioLevel) * 60, height: 120 + CGFloat(audioLevel) * 60)
                        .animation(.easeInOut(duration: 0.1), value: audioLevel)

                    Circle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: 100, height: 100)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }

                // Duration
                Text(formatDuration(duration))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(.white)

                Text(isRecording ? "Recording..." : "Processing...")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // Buttons
                HStack(spacing: 60) {
                    // Cancel
                    Button(action: onCancel) {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())

                            Text("Cancel")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    // Send
                    Button(action: onSend) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "4361ee"), Color(hex: "3a0ca3")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())

                            Text("Send")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .disabled(!isRecording || duration < 1)
                    .opacity(!isRecording || duration < 1 ? 0.5 : 1)
                }
                .padding(.bottom, 60)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.white.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: animating ? -4 : 4)
                        .animation(
                            .easeInOut(duration: 0.4)
                                .repeatForever()
                                .delay(Double(index) * 0.1),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(GlassSurface(cornerRadius: 18))

            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    ChatView()
}
