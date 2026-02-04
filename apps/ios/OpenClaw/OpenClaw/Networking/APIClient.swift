import Foundation

// MARK: - API Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int, message: String?)
    case decodingFailed(Error)
    case noData
    case networkUnavailable
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case unauthorized
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .requestFailed(let code, let msg): return "Request failed (\(code)): \(msg ?? "Unknown error")"
        case .decodingFailed(let error): return "Failed to decode response: \(error.localizedDescription)"
        case .noData: return "No data received"
        case .networkUnavailable: return "No internet connection. Please check your network."
        case .rateLimitExceeded: return "API rate limit exceeded. Please try again later."
        case .unauthorized: return "Invalid API credentials"
        case .unknown(let error): return error.localizedDescription
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}

// MARK: - Base API Client

class BaseAPIClient {
    let session: URLSession
    let logger = AppLogger.shared

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body
        urlRequest.timeoutInterval = 30

        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingFailed(error)
                }
            case 401:
                throw APIError.unauthorized
            case 402:
                throw APIError.rateLimitExceeded(retryAfter: nil)
            case 429:
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    .flatMap { TimeInterval($0) }
                throw APIError.rateLimitExceeded(retryAfter: retryAfter)
            default:
                let message = String(data: data, encoding: .utf8)
                throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: message)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unknown(error)
        }
    }
}

// MARK: - Rate Limiter

actor APIRateLimiter {
    static let shared = APIRateLimiter()

    private var requestCounts: [String: (count: Int, resetTime: Date)] = [:]

    func checkLimit(api: String, maxRequests: Int, windowSeconds: TimeInterval) throws {
        let now = Date()

        if let existing = requestCounts[api] {
            if now < existing.resetTime {
                if existing.count >= maxRequests {
                    throw APIError.rateLimitExceeded(retryAfter: existing.resetTime.timeIntervalSince(now))
                }
                requestCounts[api] = (existing.count + 1, existing.resetTime)
            } else {
                requestCounts[api] = (1, now.addingTimeInterval(windowSeconds))
            }
        } else {
            requestCounts[api] = (1, now.addingTimeInterval(windowSeconds))
        }
    }
}
