import SwiftUI

/// Multi-step onboarding flow shown to new users after login
struct SetupFlowView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var audioManager = AudioManager.shared
    @State private var currentStep = 0
    @State private var familyMembers: [FamilyMember] = []
    @State private var selectedServices: Set<String> = []
    @State private var hasRecordedVoice = false
    @State private var showVoiceRecording = false
    @State private var isCompleting = false

    let onComplete: () -> Void

    private let steps = ["Welcome", "Voice", "Family", "Services", "Ready"]

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
                // Progress indicator
                progressIndicator
                    .padding(.top, 16)

                // Content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    voiceStep.tag(1)
                    familyStep.tag(2)
                    servicesStep.tag(3)
                    readyStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }

            // Voice recording overlay
            if showVoiceRecording {
                VoiceRecordingSheet(
                    isPresented: $showVoiceRecording,
                    onComplete: { _ in
                        hasRecordedVoice = true
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showVoiceRecording)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color(hex: "4361ee") : Color.white.opacity(0.2))
                    .frame(height: 4)
                    .animation(.easeInOut, value: currentStep)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated emoji
            Text("👋")
                .font(.system(size: 80))

            VStack(spacing: 16) {
                Text("Welcome to HomeOS!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Let's set up your personal AI assistant\nin just a few quick steps")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Fun facts
            VStack(spacing: 20) {
                FactCard(emoji: "📞", title: "Make calls for you", description: "Book reservations, schedule appointments")
                FactCard(emoji: "🛒", title: "Order groceries", description: "Shop from Instacart hands-free")
                FactCard(emoji: "🗣️", title: "Your voice, your AI", description: "Clone your voice for personalized responses")
            }
            .padding(.horizontal, 32)

            Spacer()

            nextButton(title: "Let's Go!")
        }
        .padding(.bottom, 40)
    }

    // MARK: - Step 2: Voice Setup

    private var voiceStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: hasRecordedVoice ? "checkmark.circle.fill" : "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(hasRecordedVoice ? .green : Color(hex: "4361ee"))

            VStack(spacing: 16) {
                Text(hasRecordedVoice ? "Voice Ready!" : "Personalize Your Voice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(hasRecordedVoice
                    ? "Your voice has been cloned for personalized responses"
                    : "Record a short sample so HomeOS can respond in your voice")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            if !hasRecordedVoice {
                VStack(spacing: 16) {
                    Button {
                        showVoiceRecording = true
                        audioManager.startRecording()
                    } label: {
                        HStack {
                            Image(systemName: "mic.fill")
                            Text("Record My Voice")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "4361ee"), Color(hex: "3a0ca3")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .padding(.horizontal, 32)

                    Button {
                        currentStep = 2
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            } else {
                nextButton(title: "Continue")
            }

            Spacer()
                .frame(height: 40)
        }
    }

    // MARK: - Step 3: Family Setup

    private var familyStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("👨‍👩‍👧‍👦")
                    .font(.system(size: 60))

                Text("Your Family")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Add family members so HomeOS can help everyone")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(familyMembers) { member in
                        FamilyMemberRow(member: member) {
                            familyMembers.removeAll { $0.id == member.id }
                        }
                    }

                    AddFamilyMemberButton {
                        familyMembers.append(FamilyMember(name: "", relationship: ""))
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                nextButton(title: familyMembers.isEmpty ? "Skip" : "Continue")

                if !familyMembers.isEmpty {
                    Button {
                        currentStep = 3
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }

            Spacer()
                .frame(height: 40)
        }
    }

    // MARK: - Step 4: Services

    private var servicesStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("🔗")
                    .font(.system(size: 60))

                Text("Connect Services")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Choose which services to connect")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 40)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ServiceTile(
                        name: "Calendar",
                        icon: "calendar",
                        isSelected: selectedServices.contains("calendar")
                    ) {
                        toggleService("calendar")
                    }

                    ServiceTile(
                        name: "Instacart",
                        icon: "cart.fill",
                        isSelected: selectedServices.contains("instacart")
                    ) {
                        toggleService("instacart")
                    }

                    ServiceTile(
                        name: "Uber",
                        icon: "car.fill",
                        isSelected: selectedServices.contains("uber")
                    ) {
                        toggleService("uber")
                    }

                    ServiceTile(
                        name: "Spotify",
                        icon: "music.note",
                        isSelected: selectedServices.contains("spotify")
                    ) {
                        toggleService("spotify")
                    }

                    ServiceTile(
                        name: "Smart Home",
                        icon: "house.fill",
                        isSelected: selectedServices.contains("smarthome")
                    ) {
                        toggleService("smarthome")
                    }

                    ServiceTile(
                        name: "Email",
                        icon: "envelope.fill",
                        isSelected: selectedServices.contains("email")
                    ) {
                        toggleService("email")
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            nextButton(title: selectedServices.isEmpty ? "Skip" : "Continue")

            Spacer()
                .frame(height: 40)
        }
    }

    // MARK: - Step 5: Ready

    private var readyStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 80))

                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("HomeOS is ready to help you and your family")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Summary
            VStack(alignment: .leading, spacing: 16) {
                if hasRecordedVoice {
                    SummaryRow(icon: "checkmark.circle.fill", text: "Voice cloned", color: .green)
                }

                if !familyMembers.isEmpty {
                    SummaryRow(icon: "checkmark.circle.fill", text: "\(familyMembers.count) family member(s) added", color: .green)
                }

                if !selectedServices.isEmpty {
                    SummaryRow(icon: "checkmark.circle.fill", text: "\(selectedServices.count) service(s) to connect", color: .green)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                completeSetup()
            } label: {
                HStack {
                    if isCompleting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Start Using HomeOS")
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.headline)
                .foregroundColor(Color(hex: "1a1a2e"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.white)
                .cornerRadius(28)
            }
            .disabled(isCompleting)
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 40)
        }
    }

    // MARK: - Helpers

    private func nextButton(title: String) -> some View {
        Button {
            withAnimation {
                currentStep += 1
            }
        } label: {
            HStack {
                Text(title)
                Image(systemName: "arrow.right")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(hex: "4361ee"), Color(hex: "3a0ca3")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(28)
        }
        .padding(.horizontal, 32)
    }

    private func toggleService(_ service: String) {
        if selectedServices.contains(service) {
            selectedServices.remove(service)
        } else {
            selectedServices.insert(service)
        }
    }

    private func completeSetup() {
        isCompleting = true

        Task {
            // Save setup preferences to backend
            do {
                try await saveSetupPreferences()
            } catch {
                print("Error saving setup: \(error)")
            }

            await MainActor.run {
                isCompleting = false
                onComplete()
            }
        }
    }

    private func saveSetupPreferences() async throws {
        guard let url = URL(string: "\(Configuration.controlPlaneURL)/v1/preferences/general?workspaceId=\(authManager.workspaceId ?? "")") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authManager.token ?? "")", forHTTPHeaderField: "Authorization")

        let preferences: [String: Any] = [
            "preferences": [
                "onboardingCompleted": true,
                "voiceEnabled": hasRecordedVoice,
                "familyMembers": familyMembers.map { ["name": $0.name, "relationship": $0.relationship] },
                "selectedServices": Array(selectedServices)
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: preferences)

        let (_, _) = try await URLSession.shared.data(for: request)
    }
}

// MARK: - Supporting Views

struct FactCard: View {
    let emoji: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(16)
        .background(GlassSurface(cornerRadius: 16))
    }
}

struct FamilyMember: Identifiable {
    let id = UUID()
    var name: String
    var relationship: String
}

struct FamilyMemberRow: View {
    let member: FamilyMember
    let onDelete: () -> Void

    @State private var name: String = ""
    @State private var relationship: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundColor(.white.opacity(0.5))

            VStack(spacing: 8) {
                TextField("Name", text: $name)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)

                TextField("Relationship (e.g., Spouse, Child)", text: $relationship)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(GlassSurface(cornerRadius: 12))
        .onAppear {
            name = member.name
            relationship = member.relationship
        }
    }
}

struct AddFamilyMemberButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)

                Text("Add Family Member")
                    .font(.headline)

                Spacer()
            }
            .foregroundColor(Color(hex: "4361ee"))
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "4361ee").opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }
}

struct ServiceTile: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "4361ee") : Color.white.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "4361ee").opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color(hex: "4361ee") : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(text)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

#Preview {
    SetupFlowView(onComplete: {})
        .environmentObject(AuthManager())
}
