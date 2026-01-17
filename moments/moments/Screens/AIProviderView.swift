import SwiftUI

struct AIProviderView: View {
    @State private var provider: LlmProvider = .modal
    @State private var apiKey = ""
    @State private var endpoint = ""
    @State private var isSaving = false
    @State private var statusMessage: String?
    @State private var showError = false

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Provider", selection: $provider) {
                    ForEach(LlmProvider.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            if provider == .modal {
                Section("Modal Endpoint") {
                    TextField("https://...", text: $endpoint)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    Text("Use an OpenAI-compatible chat completions endpoint.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            Section("API Key (optional)") {
                SecureField("Leave blank to use managed key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                Text("Keys are stored securely. Leave blank to use the platform-managed key.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }

            Section {
                Button(action: save) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(isSaving)

                Button("Test Connection", action: testKey)
                    .disabled(isSaving)
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .navigationTitle("AI Provider")
        .alert("Unable to update settings", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again.")
        }
    }

    private func save() {
        guard let token = KeychainStore.shared.getString(forKey: "authToken"),
              let workspaceId = UserDefaults.standard.string(forKey: "workspaceId"),
              !token.isEmpty,
              !workspaceId.isEmpty else {
            showError = true
            return
        }

        isSaving = true
        statusMessage = nil

        Task {
            do {
                try await ControlPlaneAPI.shared.updateAIPreferences(
                    token: token,
                    workspaceId: workspaceId,
                    provider: provider.rawValue,
                    endpoint: provider == .modal ? endpoint : nil
                )

                if !apiKey.isEmpty {
                    try await ControlPlaneAPI.shared.setSecret(
                        token: token,
                        workspaceId: workspaceId,
                        provider: provider.rawValue,
                        apiKey: apiKey
                    )
                }

                statusMessage = "Saved."
                isSaving = false
            } catch {
                showError = true
                isSaving = false
            }
        }
    }

    private func testKey() {
        guard let token = KeychainStore.shared.getString(forKey: "authToken"),
              let workspaceId = UserDefaults.standard.string(forKey: "workspaceId"),
              !token.isEmpty,
              !workspaceId.isEmpty else {
            showError = true
            return
        }

        isSaving = true
        statusMessage = nil

        Task {
            do {
                let result = try await ControlPlaneAPI.shared.testSecret(
                    token: token,
                    workspaceId: workspaceId,
                    provider: provider.rawValue
                )
                statusMessage = result.success ? "Connection OK." : "Connection failed."
                isSaving = false
            } catch {
                showError = true
                isSaving = false
            }
        }
    }
}

enum LlmProvider: String, CaseIterable {
    case modal
    case anthropic
    case openai

    var displayName: String {
        switch self {
        case .modal: return "Modal"
        case .anthropic: return "Anthropic"
        case .openai: return "OpenAI"
        }
    }
}
