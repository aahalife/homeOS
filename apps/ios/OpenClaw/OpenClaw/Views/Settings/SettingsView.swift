import SwiftUI

/// App settings and API key configuration
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // Family Info
                Section("Family") {
                    if let family = appState.currentFamily {
                        LabeledContent("Family Name", value: family.name)
                        LabeledContent("Members", value: "\(family.members.count)")
                        LabeledContent("Active Skills", value: "\(appState.activeSkills.count)")
                    }
                }

                // API Keys
                Section("API Keys") {
                    SecureField("Spoonacular API Key", text: $viewModel.spoonacularKey)
                    SecureField("USDA FoodData Key", text: $viewModel.usdaKey)
                    SecureField("Google Places API Key", text: $viewModel.googlePlacesKey)

                    Button("Save API Keys") {
                        viewModel.saveKeys()
                    }
                    .buttonStyle(.borderedProminent)

                    if let message = viewModel.saveMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                // Twilio (Elder Care)
                Section("Twilio (Voice/SMS)") {
                    SecureField("Account SID", text: $viewModel.twilioSid)
                    SecureField("Auth Token", text: $viewModel.twilioToken)
                    TextField("Phone Number", text: $viewModel.twilioPhone)
                }

                // Network Status
                Section("System Status") {
                    LabeledContent("Network") {
                        HStack {
                            Circle()
                                .fill(appState.networkMonitor.isConnected ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text(appState.networkMonitor.isConnected ? "Connected" : "Offline")
                        }
                    }
                    LabeledContent("AI Model") {
                        Text(appState.isModelLoaded ? "Loaded (Stub)" : "Not Loaded")
                    }
                }

                // About
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "2026.02.02")
                    LabeledContent("Platform", value: "iOS 17.0+")
                    Link("Documentation", destination: URL(string: "https://github.com/aahalife/openclaw")!)
                }

                // Danger Zone
                Section("Advanced") {
                    Button("Reset Onboarding", role: .destructive) {
                        showResetAlert = true
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset App?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetOnboarding()
                }
            } message: {
                Text("This will delete all data and restart onboarding. This cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
