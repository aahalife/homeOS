import Foundation

/// Twilio Voice & SMS API client
/// Documentation: https://www.twilio.com/docs
final class TwilioAPI: BaseAPIClient {
    private let baseURL = "https://api.twilio.com/2010-04-01"
    private let accountSid: String
    private let authToken: String
    private let phoneNumber: String

    var isConfigured: Bool {
        !accountSid.isEmpty && !authToken.isEmpty && !phoneNumber.isEmpty
    }

    init(accountSid: String = "", authToken: String = "", phoneNumber: String = "") {
        self.accountSid = KeychainManager.shared.getAPIKey(for: KeychainManager.APIKeys.twilioAccountSid) ?? accountSid
        self.authToken = KeychainManager.shared.getAPIKey(for: KeychainManager.APIKeys.twilioAuthToken) ?? authToken
        self.phoneNumber = KeychainManager.shared.getAPIKey(for: KeychainManager.APIKeys.twilioPhoneNumber) ?? phoneNumber
        super.init()
    }

    // MARK: - Send SMS

    func sendSMS(to: String, body: String) async throws -> TwilioMessageResponse {
        guard isConfigured else {
            logger.warning("Twilio not configured, simulating SMS send")
            return TwilioMessageResponse(sid: "SIMULATED_\(UUID().uuidString)", status: "simulated")
        }

        let url = URL(string: "\(baseURL)/Accounts/\(accountSid)/Messages.json")!
        let params = "To=\(to)&From=\(phoneNumber)&Body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body)"

        let credentials = "\(accountSid):\(authToken)".data(using: .utf8)!.base64EncodedString()

        let response: TwilioMessageResponse = try await request(
            url: url,
            method: .POST,
            headers: [
                "Authorization": "Basic \(credentials)",
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            body: params.data(using: .utf8)
        )

        return response
    }

    // MARK: - Make Voice Call

    func makeCall(to: String, twiml: String) async throws -> TwilioCallResponse {
        guard isConfigured else {
            logger.warning("Twilio not configured, simulating voice call")
            return TwilioCallResponse(sid: "SIMULATED_\(UUID().uuidString)", status: "simulated")
        }

        let url = URL(string: "\(baseURL)/Accounts/\(accountSid)/Calls.json")!
        let twimlEncoded = twiml.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let params = "To=\(to)&From=\(phoneNumber)&Twiml=\(twimlEncoded)"

        let credentials = "\(accountSid):\(authToken)".data(using: .utf8)!.base64EncodedString()

        let response: TwilioCallResponse = try await request(
            url: url,
            method: .POST,
            headers: [
                "Authorization": "Basic \(credentials)",
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            body: params.data(using: .utf8)
        )

        return response
    }

    // MARK: - Elder Care Check-In Call

    func initiateElderCheckIn(elder: ElderCareProfile, greeting: String) async throws -> TwilioCallResponse {
        guard let phone = elder.phoneNumber else {
            throw TwilioError.noPhoneNumber
        }

        let twiml = """
        <Response>
            <Say voice="alice">\(greeting)</Say>
            <Pause length="3"/>
            <Say voice="alice">Press 1 if you are doing well. Press 2 if you need assistance.</Say>
            <Gather numDigits="1" action="/check-in-response" method="POST">
                <Say voice="alice">I did not catch that. Please press 1 or 2.</Say>
            </Gather>
        </Response>
        """

        return try await makeCall(to: phone, twiml: twiml)
    }
}

enum TwilioError: LocalizedError {
    case noPhoneNumber
    case callFailed(String)
    case smsFailed(String)

    var errorDescription: String? {
        switch self {
        case .noPhoneNumber: return "No phone number available"
        case .callFailed(let msg): return "Voice call failed: \(msg)"
        case .smsFailed(let msg): return "SMS failed: \(msg)"
        }
    }
}

// MARK: - Twilio Response Types

struct TwilioMessageResponse: Codable {
    let sid: String
    let status: String
}

struct TwilioCallResponse: Codable {
    let sid: String
    let status: String
}
