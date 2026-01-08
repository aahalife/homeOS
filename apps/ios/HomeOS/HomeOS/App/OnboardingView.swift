import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isAnimating = false
    @State private var showPasscodeEntry = false
    @State private var passcode = ""

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e"),
                    Color(hex: "0f3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .white.opacity(0.3), radius: 20)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    Text("HomeOS")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Your family's AI assistant")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Features
                VStack(spacing: 20) {
                    FeatureRow(icon: "bubble.left.and.text.bubble.right", title: "Natural Chat", description: "Talk naturally with your AI assistant")
                    FeatureRow(icon: "phone.arrow.up.right", title: "Make Calls", description: "Book reservations, schedule appointments")
                    FeatureRow(icon: "lock.shield", title: "Privacy First", description: "Your data stays with you")
                }
                .padding(.horizontal, 32)

                Spacer()

                // Auth buttons
                VStack(spacing: 16) {
                    if showPasscodeEntry {
                        // Passcode entry view
                        VStack(spacing: 16) {
                            SecureField("Enter passcode", text: $passcode)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.white.opacity(0.1))
                                )
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)

                            if let error = authManager.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            Button {
                                Task {
                                    await authManager.signInWithPasscode(passcode)
                                }
                            } label: {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1a1a2e")))
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.white)
                                .foregroundColor(Color(hex: "1a1a2e"))
                                .cornerRadius(28)
                            }
                            .disabled(passcode.isEmpty || authManager.isLoading)
                            .padding(.horizontal, 32)

                            Button("Back to Sign in with Apple") {
                                showPasscodeEntry = false
                                passcode = ""
                                authManager.errorMessage = nil
                            }
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        // Sign in with Apple button
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            Task {
                                await authManager.handleSignInWithApple(result: result)
                            }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .cornerRadius(28)
                        .padding(.horizontal, 32)
                        .shadow(color: .white.opacity(0.2), radius: 10)

                        // Dev passcode option (only shown when available)
                        if authManager.isPasscodeAuthAvailable {
                            Button("Use dev passcode instead") {
                                showPasscodeEntry = true
                            }
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    GlassSurface(cornerRadius: 12)
                )

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
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthManager())
}
