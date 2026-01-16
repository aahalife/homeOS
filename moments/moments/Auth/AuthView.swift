import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var passcode = ""
    @State private var passcodeAvailable = false
    @State private var showMissingBaseURL = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Oi My Day")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.primary)
                Text("Sign in to get started")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }

            if passcodeAvailable {
                VStack(spacing: 12) {
                    SecureField("Dev passcode", text: $passcode)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(AppTheme.surfaceSecondary)
                        .cornerRadius(10)

                    Button(action: signIn) {
                        if session.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                        } else {
                            Text("Sign in")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                        }
                    }
                    .background(AppTheme.primary)
                    .cornerRadius(14)
                    .disabled(passcode.isEmpty || session.isAuthenticating)
                }
            } else {
                VStack(spacing: 12) {
                    Button(action: {}) {
                        Text("Sign in with Apple")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.black)
                            .cornerRadius(14)
                    }
                    Text("Apple Sign-In is coming next. Dev passcode is not enabled.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            if showMissingBaseURL {
                Text("Set ControlPlaneBaseURL in build settings to enable sign-in.")
                    .font(.caption)
                    .foregroundColor(Color(hex: "FF3B30"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            showMissingBaseURL = !ControlPlaneAPI.shared.hasBaseURL
            passcodeAvailable = await ControlPlaneAPI.shared.passcodeAvailable()
        }
    }

    private func signIn() {
        if !ControlPlaneAPI.shared.hasBaseURL {
            showMissingBaseURL = true
            return
        }
        Task {
            await session.signInWithPasscode(passcode: passcode)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(SessionManager.shared)
}
