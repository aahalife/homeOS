import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager

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

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
