import Foundation

final class ControlPlaneAPI {
    static let shared = ControlPlaneAPI()

    private init() {}

    func passcodeAvailable() async -> Bool {
        guard let url = baseURL?.appendingPathComponent("/v1/auth/passcode/available") else { return false }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return false
            }
            let payload = try JSONDecoder().decode(PasscodeAvailability.self, from: data)
            return payload.available
        } catch {
            return false
        }
    }

    func signInWithPasscode(passcode: String, deviceId: String) async throws -> AuthResponse {
        guard let url = baseURL?.appendingPathComponent("/v1/auth/passcode") else {
            throw ControlPlaneError.missingBaseURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(PasscodeRequest(passcode: passcode, deviceId: deviceId))

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func fetchWorkspaces(token: String) async throws -> [WorkspaceSummary] {
        guard let url = baseURL?.appendingPathComponent("/v1/workspaces") else {
            throw ControlPlaneError.missingBaseURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode([WorkspaceSummary].self, from: data)
    }

    func createWorkspace(token: String, name: String) async throws -> WorkspaceSummary {
        guard let url = baseURL?.appendingPathComponent("/v1/workspaces") else {
            throw ControlPlaneError.missingBaseURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(CreateWorkspaceRequest(name: name))

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode(WorkspaceSummary.self, from: data)
    }

    func registerDevice(
        token: String,
        workspaceId: String,
        deviceName: String,
        apnsToken: String?
    ) async throws -> DeviceRegistration {
        guard let url = baseURL?.appendingPathComponent("/v1/devices/register") else {
            throw ControlPlaneError.missingBaseURL
        }

        let payload = DeviceRegistrationRequest(
            workspaceId: workspaceId,
            name: deviceName,
            platform: "ios",
            apnsToken: apnsToken
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode(DeviceRegistration.self, from: data)
    }

    func updateDeviceToken(token: String, deviceId: String, apnsToken: String) async throws -> Bool {
        guard let url = baseURL?.appendingPathComponent("/v1/devices/\(deviceId)/token") else {
            throw ControlPlaneError.missingBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(DeviceTokenUpdate(apnsToken: apnsToken))

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        let payload = try JSONDecoder().decode(DeviceTokenUpdateResponse.self, from: data)
        return payload.success
    }

    func fetchNotifications(token: String, workspaceId: String) async throws -> [NotificationRecord] {
        guard let baseURL else {
            throw ControlPlaneError.missingBaseURL
        }
        guard var components = URLComponents(url: baseURL.appendingPathComponent("/v1/notifications"), resolvingAgainstBaseURL: false) else {
            throw ControlPlaneError.missingBaseURL
        }
        components.queryItems = [URLQueryItem(name: "workspaceId", value: workspaceId)]
        guard let url = components.url else {
            throw ControlPlaneError.missingBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode([NotificationRecord].self, from: data)
    }

    func markNotificationRead(token: String, workspaceId: String, notificationId: String) async throws {
        guard let baseURL else {
            throw ControlPlaneError.missingBaseURL
        }
        guard var components = URLComponents(url: baseURL.appendingPathComponent("/v1/notifications/\(notificationId)/read"), resolvingAgainstBaseURL: false) else {
            throw ControlPlaneError.missingBaseURL
        }
        components.queryItems = [URLQueryItem(name: "workspaceId", value: workspaceId)]
        guard let url = components.url else {
            throw ControlPlaneError.missingBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)
    }

    func fetchRuntimeConnectionInfo(token: String, workspaceId: String) async throws -> RuntimeConnectionInfo {
        guard let baseURL else {
            throw ControlPlaneError.missingBaseURL
        }
        guard var components = URLComponents(url: baseURL.appendingPathComponent("/v1/runtime/connection-info"), resolvingAgainstBaseURL: false) else {
            throw ControlPlaneError.missingBaseURL
        }
        components.queryItems = [URLQueryItem(name: "workspaceId", value: workspaceId)]
        guard let url = components.url else {
            throw ControlPlaneError.missingBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode(RuntimeConnectionInfo.self, from: data)
    }

    private var baseURL: URL? {
        guard let baseURLString = Bundle.main.infoDictionary?["ControlPlaneBaseURL"] as? String,
              !baseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return URL(string: baseURLString)
    }

    var hasBaseURL: Bool {
        baseURL != nil
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ControlPlaneError.badResponse
        }
    }
}

enum ControlPlaneError: Error {
    case missingBaseURL
    case badResponse
}

struct PasscodeAvailability: Codable {
    let available: Bool
}

struct PasscodeRequest: Codable {
    let passcode: String
    let deviceId: String
}

struct AuthResponse: Codable {
    let token: String
    let user: AuthUser
}

struct AuthUser: Codable {
    let id: String
    let email: String?
    let name: String?
}

struct CreateWorkspaceRequest: Codable {
    let name: String
}

struct WorkspaceSummary: Codable {
    let id: String
    let name: String
    let role: String?
    let createdAt: String?
}

struct DeviceRegistrationRequest: Codable {
    let workspaceId: String
    let name: String
    let platform: String
    let apnsToken: String?
}

struct DeviceRegistration: Codable {
    let id: String
    let name: String
    let platform: String
    let createdAt: String?
}

struct DeviceTokenUpdate: Codable {
    let apnsToken: String
}

struct DeviceTokenUpdateResponse: Codable {
    let success: Bool
}

struct NotificationRecord: Codable {
    let id: String
    let type: String
    let title: String
    let body: String
    let status: String
    let createdAt: String
    let deliverAt: String?
}

struct RuntimeConnectionInfo: Codable {
    let baseUrl: String
    let wsUrl: String
    let token: String
}
