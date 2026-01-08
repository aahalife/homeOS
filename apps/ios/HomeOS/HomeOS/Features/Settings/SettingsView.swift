import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var audioManager = AudioManager.shared
    @State private var ttsEnabled = true
    @State private var useCustomVoice = false
    @State private var showVoiceRecording = false
    @State private var hasCustomVoice = false

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
                HStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile section
                        profileSection

                        // Voice settings
                        voiceSettingsSection

                        // Preferences
                        preferencesSection

                        // About
                        aboutSection

                        // Sign out
                        signOutSection
                    }
                    .padding()
                }
            }

            // Voice Recording Overlay
            if showVoiceRecording {
                VoiceRecordingSheet(
                    isPresented: $showVoiceRecording,
                    onComplete: { _ in
                        hasCustomVoice = true
                        useCustomVoice = true
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showVoiceRecording)
    }

    private var voiceSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            VStack(spacing: 0) {
                // TTS Toggle
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 28)

                    Text("Text-to-Speech")
                        .font(.body)
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("", isOn: $ttsEnabled)
                        .labelsHidden()
                        .tint(Color(hex: "4361ee"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                GlowDivider(opacity: 0.1).padding(.leading, 52)

                // Custom Voice Toggle
                HStack {
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use Custom Voice")
                            .font(.body)
                            .foregroundColor(.white)

                        if hasCustomVoice {
                            Text("Your cloned voice is ready")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: $useCustomVoice)
                        .labelsHidden()
                        .tint(Color(hex: "4361ee"))
                        .disabled(!hasCustomVoice)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                GlowDivider(opacity: 0.1).padding(.leading, 52)

                // Record Custom Voice
                Button {
                    showVoiceRecording = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(hasCustomVoice ? "Re-record Voice" : "Record Your Voice")
                                .font(.body)
                                .foregroundColor(.white)

                            Text("5-30 seconds sample")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .background(GlassSurface(cornerRadius: 16))
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            GlassCard(cornerRadius: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.5))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authManager.userName ?? "User")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text(authManager.userEmail ?? "No email")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()
                }
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            VStack(spacing: 0) {
                SettingsRow(icon: "bell.fill", title: "Notifications", hasChevron: true)
                GlowDivider(opacity: 0.1).padding(.leading, 52)

                SettingsRow(icon: "lock.fill", title: "Privacy", hasChevron: true)
                GlowDivider(opacity: 0.1).padding(.leading, 52)

                SettingsRow(icon: "brain", title: "AI Preferences", hasChevron: true)
                GlowDivider(opacity: 0.1).padding(.leading, 52)

                SettingsRow(icon: "shield.fill", title: "Approval Settings", hasChevron: true)
            }
            .background(GlassSurface(cornerRadius: 16))
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            VStack(spacing: 0) {
                SettingsRow(icon: "info.circle.fill", title: "About HomeOS", hasChevron: true)
                GlowDivider(opacity: 0.1).padding(.leading, 52)

                SettingsRow(icon: "doc.text.fill", title: "Privacy Policy", hasChevron: true)
                GlowDivider(opacity: 0.1).padding(.leading, 52)

                SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", hasChevron: true)
            }
            .background(GlassSurface(cornerRadius: 16))
        }
    }

    private var signOutSection: some View {
        Button {
            authManager.signOut()
        } label: {
            HStack {
                Spacer()
                Text("Sign Out")
                    .font(.headline)
                    .foregroundColor(.red)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(GlassSurface(cornerRadius: 16))
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let hasChevron: Bool

    var body: some View {
        Button {
            // Navigate
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 28)

                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Spacer()

                if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Voice Recording Sheet

struct VoiceRecordingSheet: View {
    @Binding var isPresented: Bool
    var onComplete: (Data) -> Void

    @StateObject private var audioManager = AudioManager.shared
    @State private var recordingState: RecordingState = .ready
    @State private var isUploading = false

    enum RecordingState {
        case ready, recording, review
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                HStack {
                    Button("Cancel") {
                        audioManager.cancelRecording()
                        isPresented = false
                    }
                    .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("Record Voice Sample")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Spacer for alignment
                    Text("Cancel")
                        .foregroundColor(.clear)
                }
                .padding()

                Spacer()

                // Instructions
                VStack(spacing: 16) {
                    Image(systemName: recordingState == .recording ? "waveform" : "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(recordingState == .recording ? .red : .white.opacity(0.5))
                        .scaleEffect(recordingState == .recording ? 1.0 + CGFloat(audioManager.audioLevel) * 0.3 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: audioManager.audioLevel)

                    if recordingState == .ready {
                        Text("Record a 5-30 second voice sample")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Speak naturally in your normal voice.\nThis will be used to clone your voice for TTS responses.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    } else if recordingState == .recording {
                        Text(formatDuration(audioManager.recordingDuration))
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                            .foregroundColor(.white)

                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.red)
                    } else {
                        Text("Review your recording")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("\(formatDuration(audioManager.recordingDuration)) recorded")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    if recordingState == .ready {
                        Button {
                            audioManager.startRecording()
                            recordingState = .recording
                        } label: {
                            Text("Start Recording")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "4361ee"), Color(hex: "3a0ca3")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                    } else if recordingState == .recording {
                        Button {
                            _ = audioManager.stopRecording()
                            recordingState = .review
                        } label: {
                            Text("Stop Recording")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .disabled(audioManager.recordingDuration < 5)
                        .opacity(audioManager.recordingDuration < 5 ? 0.5 : 1)
                    } else {
                        HStack(spacing: 16) {
                            Button {
                                recordingState = .ready
                            } label: {
                                Text("Re-record")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                            }

                            Button {
                                uploadVoiceSample()
                            } label: {
                                if isUploading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                } else {
                                    Text("Use This Voice")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                }
                            }
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "4361ee"), Color(hex: "3a0ca3")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .disabled(isUploading)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func uploadVoiceSample() {
        guard let audioData = audioManager.getRecordingData() else { return }

        isUploading = true

        Task {
            // Upload to backend for voice cloning
            do {
                try await cloneVoice(audioData: audioData)

                await MainActor.run {
                    isUploading = false
                    onComplete(audioData)
                    isPresented = false
                }
            } catch {
                print("Voice cloning error: \(error)")
                await MainActor.run {
                    isUploading = false
                }
            }
        }
    }

    private func cloneVoice(audioData: Data) async throws {
        guard let url = URL(string: "\(Configuration.runtimeURL)/v1/voice/clone") else {
            throw NSError(domain: "VoiceRecording", code: 1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AuthManager.shared.token ?? "")", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"voice_sample.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add workspace ID
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"workspaceId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(AuthManager.shared.workspaceId ?? "")".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add name
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        body.append("My Voice".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "VoiceRecording", code: 2, userInfo: nil)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
