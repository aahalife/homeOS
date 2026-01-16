import Foundation
import UIKit

@MainActor
final class PushNotificationManager: ObservableObject {
    static let shared = PushNotificationManager()

    private init() {}

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func updateDeviceToken(_ token: String) async {
        UserDefaults.standard.set(token, forKey: "apnsToken")

        guard let authToken = KeychainStore.shared.getString(forKey: "authToken"),
              let deviceId = UserDefaults.standard.string(forKey: "deviceId"),
              !authToken.isEmpty,
              !deviceId.isEmpty else {
            return
        }

        do {
            _ = try await ControlPlaneAPI.shared.updateDeviceToken(
                token: authToken,
                deviceId: deviceId,
                apnsToken: token
            )
        } catch {
            print("APNs token update failed: \(error)")
        }
    }
}
