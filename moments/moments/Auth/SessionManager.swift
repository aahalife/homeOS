import Foundation
import SwiftUI
import UIKit

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var userName: String = "You"
    @Published private(set) var userEmail: String?
    @Published private(set) var workspaceId: String?
    @Published private(set) var deviceId: String?
    @Published var isAuthenticating: Bool = false

    private init() {
        loadFromStorage()
    }

    func loadFromStorage() {
        if let token = KeychainStore.shared.getString(forKey: "authToken"), !token.isEmpty {
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
        userName = UserDefaults.standard.string(forKey: "userName") ?? "You"
        userEmail = UserDefaults.standard.string(forKey: "userEmail")
        workspaceId = UserDefaults.standard.string(forKey: "workspaceId")
        deviceId = UserDefaults.standard.string(forKey: "deviceId")

        if isAuthenticated {
            Task { await RuntimeStreamClient.shared.connectIfNeeded() }
        } else {
            RuntimeStreamClient.shared.disconnect()
        }
    }

    func signInWithPasscode(passcode: String) async {
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let deviceId = DeviceIdentity.currentId
            let auth = try await ControlPlaneAPI.shared.signInWithPasscode(passcode: passcode, deviceId: deviceId)

            KeychainStore.shared.setString(auth.token, forKey: "authToken")
            UserDefaults.standard.set(auth.user.name, forKey: "userName")
            UserDefaults.standard.set(auth.user.email, forKey: "userEmail")
            UserDefaults.standard.set(deviceId, forKey: "deviceId")

            let workspaceId = try await ensureWorkspace(token: auth.token, fallbackName: auth.user.name ?? "Family")
            UserDefaults.standard.set(workspaceId, forKey: "workspaceId")

            let registered = try await ControlPlaneAPI.shared.registerDevice(
                token: auth.token,
                workspaceId: workspaceId,
                deviceName: DeviceIdentity.deviceName,
                apnsToken: nil
            )
            UserDefaults.standard.set(registered.id, forKey: "deviceId")

            if let apnsToken = UserDefaults.standard.string(forKey: "apnsToken"), !apnsToken.isEmpty {
                _ = try await ControlPlaneAPI.shared.updateDeviceToken(
                    token: auth.token,
                    deviceId: registered.id,
                    apnsToken: apnsToken
                )
            }

            loadFromStorage()
        } catch {
            print("Sign in failed: \(error)")
        }
    }

    func signOut() {
        KeychainStore.shared.delete(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "workspaceId")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "deviceId")
        RuntimeStreamClient.shared.disconnect()
        loadFromStorage()
    }

    private func ensureWorkspace(token: String, fallbackName: String) async throws -> String {
        let workspaces = try await ControlPlaneAPI.shared.fetchWorkspaces(token: token)
        if let first = workspaces.first {
            return first.id
        }
        let workspace = try await ControlPlaneAPI.shared.createWorkspace(
            token: token,
            name: "\(fallbackName)'s Family"
        )
        return workspace.id
    }
}

enum DeviceIdentity {
    static var currentId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    static var deviceName: String {
        UIDevice.current.name
    }
}
