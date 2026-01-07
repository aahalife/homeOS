import SwiftUI
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var token: String?
    @Published var workspaceId: String?
    @Published var userName: String?
    @Published var userEmail: String?

    private let keychain = KeychainHelper.shared

    init() {
        loadStoredCredentials()
    }

    func loadStoredCredentials() {
        if let storedToken = keychain.read(key: "authToken") {
            self.token = storedToken
            self.isAuthenticated = true
            self.workspaceId = keychain.read(key: "workspaceId")
            self.userName = keychain.read(key: "userName")
            self.userEmail = keychain.read(key: "userEmail")
        }
    }

    func handleSignInWithApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                return
            }

            do {
                let response = try await authenticateWithBackend(
                    identityToken: tokenString,
                    authorizationCode: credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) } ?? "",
                    user: AppleUser(
                        email: credential.email,
                        firstName: credential.fullName?.givenName,
                        lastName: credential.fullName?.familyName
                    )
                )

                // Store credentials
                keychain.save(key: "authToken", value: response.token)
                keychain.save(key: "userId", value: response.user.id)

                if let name = response.user.name {
                    keychain.save(key: "userName", value: name)
                    self.userName = name
                }
                if let email = response.user.email {
                    keychain.save(key: "userEmail", value: email)
                    self.userEmail = email
                }

                self.token = response.token
                self.isAuthenticated = true

                // Create or get workspace
                await setupWorkspace()

            } catch {
                print("Authentication failed: \(error)")
            }

        case .failure(let error):
            print("Sign in with Apple failed: \(error)")
        }
    }

    private func authenticateWithBackend(
        identityToken: String,
        authorizationCode: String,
        user: AppleUser
    ) async throws -> AuthResponse {
        guard let url = URL(string: "\(Configuration.controlPlaneURL)/v1/auth/apple") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AppleAuthRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            user: user
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.authenticationFailed
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    private func setupWorkspace() async {
        guard let token = self.token else { return }

        do {
            // Check for existing workspaces
            guard let url = URL(string: "\(Configuration.controlPlaneURL)/v1/workspaces") else { return }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let workspaces = try JSONDecoder().decode([WorkspaceInfo].self, from: data)

            if let workspace = workspaces.first {
                self.workspaceId = workspace.id
                keychain.save(key: "workspaceId", value: workspace.id)
            } else {
                // Create default workspace
                let workspace = try await createWorkspace(name: "My Home")
                self.workspaceId = workspace.id
                keychain.save(key: "workspaceId", value: workspace.id)
            }
        } catch {
            print("Failed to setup workspace: \(error)")
        }
    }

    private func createWorkspace(name: String) async throws -> WorkspaceInfo {
        guard let url = URL(string: "\(Configuration.controlPlaneURL)/v1/workspaces"),
              let token = self.token else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["name": name])

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(WorkspaceInfo.self, from: data)
    }

    func signOut() {
        keychain.delete(key: "authToken")
        keychain.delete(key: "userId")
        keychain.delete(key: "workspaceId")
        keychain.delete(key: "userName")
        keychain.delete(key: "userEmail")

        token = nil
        workspaceId = nil
        userName = nil
        userEmail = nil
        isAuthenticated = false
    }
}

// Models
struct AppleAuthRequest: Codable {
    let identityToken: String
    let authorizationCode: String
    let user: AppleUser?
}

struct AppleUser: Codable {
    let email: String?
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case email
        case name
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(email, forKey: .email)
        if firstName != nil || lastName != nil {
            var nameContainer = container.nestedContainer(keyedBy: NameKeys.self, forKey: .name)
            try nameContainer.encodeIfPresent(firstName, forKey: .firstName)
            try nameContainer.encodeIfPresent(lastName, forKey: .lastName)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        if let nameContainer = try? container.nestedContainer(keyedBy: NameKeys.self, forKey: .name) {
            firstName = try nameContainer.decodeIfPresent(String.self, forKey: .firstName)
            lastName = try nameContainer.decodeIfPresent(String.self, forKey: .lastName)
        } else {
            firstName = nil
            lastName = nil
        }
    }

    init(email: String?, firstName: String?, lastName: String?) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }

    enum NameKeys: String, CodingKey {
        case firstName, lastName
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: UserInfo
}

struct UserInfo: Codable {
    let id: String
    let email: String?
    let name: String?
}

struct WorkspaceInfo: Codable {
    let id: String
    let name: String
    let role: String?
    let createdAt: String?
}

enum AuthError: Error {
    case invalidURL
    case authenticationFailed
}
