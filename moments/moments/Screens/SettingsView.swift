import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var pushNotifications = true
    @State private var emailDigests = true
    @State private var smsUrgentOnly = true
    @State private var oiPhoneNumber = "Loading"
    @State private var isProvisioningNumber = false
    @State private var showProvisionConfirm = false
    @State private var showProvisionError = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.userName)
                                .font(.headline)
                            Text(session.userEmail ?? "No email on file")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Admin")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("FAMILY") {
                    NavigationLink("Family Members") {}
                    NavigationLink("Invite Someone") {}
                    NavigationLink("Roles & Permissions") {}
                }

                Section("CONNECTED SERVICES") {
                    SettingsRow(title: "Oi phone number", status: oiPhoneNumber)
                    if oiPhoneNumber == "Not provisioned" {
                        Button {
                            showProvisionConfirm = true
                        } label: {
                            HStack {
                                Text("Get Oi phone number")
                                Spacer()
                                if isProvisioningNumber {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isProvisioningNumber)
                    }
                    SettingsRow(title: "Google Calendar", status: "Connected")
                    SettingsRow(title: "Gmail", status: "Connected")
                    SettingsRow(title: "Apple Calendar", status: "Connected")
                    SettingsRow(title: "Apple Health", status: healthStatus)
                    NavigationLink("Telegram") {}
                    NavigationLink("Home Assistant") {}
                }

                Section("PREFERENCES") {
                    SettingsRow(title: "Morning Brief Time", status: "7:00 AM")
                    SettingsRow(title: "Quiet Hours", status: "9 PM - 7 AM")
                    SettingsRow(title: "Auto-Approve Under", status: "$50")
                    NavigationLink("Dietary Restrictions") {}
                }

                Section("NOTIFICATIONS") {
                    Toggle("Push Notifications", isOn: $pushNotifications)
                    Toggle("Email Digests", isOn: $emailDigests)
                    Toggle("SMS for Urgent Only", isOn: $smsUrgentOnly)
                }

                Section("SUPPORT") {
                    NavigationLink("Help Center") {}
                    NavigationLink("Report Issue") {}
                    NavigationLink("Privacy Policy") {}
                    NavigationLink("Terms of Service") {}
                    NavigationLink("About Oi My Day") {}
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        session.signOut()
                    }
                }

                Section {
                    Text("Version 1.0.0 (Build 42)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .navigationTitle("Settings")
        }
        .task {
            await loadPhoneNumber()
        }
        .alert("Activate Oi phone number?", isPresented: $showProvisionConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Activate") {
                Task { await provisionPhoneNumber() }
            }
        } message: {
            Text("Oi will purchase a phone number for calls and SMS. Standard carrier fees may apply.")
        }
        .alert("Unable to provision number", isPresented: $showProvisionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again later.")
        }
    }

    private func loadPhoneNumber() async {
        guard let token = KeychainStore.shared.getString(forKey: "authToken"),
              let workspaceId = UserDefaults.standard.string(forKey: "workspaceId"),
              !token.isEmpty,
              !workspaceId.isEmpty else {
            oiPhoneNumber = "Not provisioned"
            return
        }

        do {
            let numbers = try await ControlPlaneAPI.shared.fetchPhoneNumbers(token: token, workspaceId: workspaceId)
            if let number = numbers.first {
                oiPhoneNumber = number.phoneNumber
                UserDefaults.standard.set(number.phoneNumber, forKey: "oiPhoneNumber")
            } else {
                oiPhoneNumber = "Not provisioned"
            }
        } catch {
            oiPhoneNumber = UserDefaults.standard.string(forKey: "oiPhoneNumber") ?? "Not provisioned"
        }
    }

    private func provisionPhoneNumber() async {
        guard let token = KeychainStore.shared.getString(forKey: "authToken"),
              let workspaceId = UserDefaults.standard.string(forKey: "workspaceId"),
              !token.isEmpty,
              !workspaceId.isEmpty else {
            showProvisionError = true
            return
        }

        isProvisioningNumber = true
        defer { isProvisioningNumber = false }

        do {
            let result = try await ControlPlaneAPI.shared.provisionPhoneNumber(
                token: token,
                workspaceId: workspaceId,
                confirm: true
            )
            oiPhoneNumber = result.phoneNumber
            UserDefaults.standard.set(result.phoneNumber, forKey: "oiPhoneNumber")
        } catch {
            showProvisionError = true
        }
    }

    private var healthStatus: String {
        guard HealthKitManager.shared.isAvailable else {
            return "Unavailable"
        }
        switch HealthKitManager.shared.permissionState() {
        case .authorized:
            return "Connected"
        case .limited:
            return "Limited"
        case .denied, .restricted:
            return "Not enabled"
        case .notDetermined:
            return "Not enabled"
        }
    }
}

private struct SettingsRow: View {
    let title: String
    let status: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(status)
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
    }
}
