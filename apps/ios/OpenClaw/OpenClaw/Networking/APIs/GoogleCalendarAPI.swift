import Foundation

/// Google Calendar API client (OAuth 2.0)
/// Documentation: https://developers.google.com/calendar
final class GoogleCalendarAPI: BaseAPIClient {
    private let baseURL = "https://www.googleapis.com/calendar/v3"
    private var accessToken: String?

    var isAuthenticated: Bool { accessToken != nil }

    func setAccessToken(_ token: String) {
        self.accessToken = token
    }

    // MARK: - Events

    func listEvents(
        calendarId: String = "primary",
        timeMin: Date,
        timeMax: Date
    ) async throws -> [CalendarEvent] {
        guard let token = accessToken else {
            logger.warning("Google Calendar not authenticated, using stub data")
            return StubCalendarData.sampleEvents
        }

        let formatter = ISO8601DateFormatter()
        var components = URLComponents(string: "\(baseURL)/calendars/\(calendarId)/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: formatter.string(from: timeMin)),
            URLQueryItem(name: "timeMax", value: formatter.string(from: timeMax)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: GoogleEventListResponse = try await request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"]
        )

        return (response.items ?? []).map { item in
            CalendarEvent(
                title: item.summary ?? "Untitled",
                description: item.description,
                startTime: parseGoogleDate(item.start) ?? Date(),
                endTime: parseGoogleDate(item.end) ?? Date().addingHours(1),
                externalId: item.id,
                source: .google
            )
        }
    }

    func createEvent(
        title: String,
        startTime: Date,
        endTime: Date,
        description: String? = nil,
        calendarId: String = "primary"
    ) async throws -> CalendarEvent {
        guard let token = accessToken else {
            logger.warning("Google Calendar not authenticated, creating local event only")
            return CalendarEvent(title: title, description: description, startTime: startTime, endTime: endTime, source: .local)
        }

        let url = URL(string: "\(baseURL)/calendars/\(calendarId)/events")!
        let formatter = ISO8601DateFormatter()

        let eventBody = GoogleCalendarEventBody(
            summary: title,
            description: description,
            start: GoogleCalendarTime(dateTime: formatter.string(from: startTime)),
            end: GoogleCalendarTime(dateTime: formatter.string(from: endTime))
        )

        let bodyData = try JSONEncoder().encode(eventBody)

        let response: GoogleCalendarEventResponse = try await request(
            url: url,
            method: .POST,
            headers: [
                "Authorization": "Bearer \(token)",
                "Content-Type": "application/json"
            ],
            body: bodyData
        )

        return CalendarEvent(
            title: response.summary ?? title,
            description: response.description,
            startTime: startTime,
            endTime: endTime,
            externalId: response.id,
            source: .google
        )
    }

    private func parseGoogleDate(_ time: GoogleCalendarTimeResponse?) -> Date? {
        guard let time = time else { return nil }
        if let dateTime = time.dateTime {
            return ISO8601DateFormatter().date(from: dateTime)
        }
        if let dateStr = time.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: dateStr)
        }
        return nil
    }
}

// MARK: - Google Calendar Types

struct GoogleEventListResponse: Codable {
    let items: [GoogleCalendarEventResponse]?
}

struct GoogleCalendarEventResponse: Codable {
    let id: String?
    let summary: String?
    let description: String?
    let start: GoogleCalendarTimeResponse?
    let end: GoogleCalendarTimeResponse?
}

struct GoogleCalendarTimeResponse: Codable {
    let dateTime: String?
    let date: String?
}

struct GoogleCalendarEventBody: Codable {
    let summary: String
    let description: String?
    let start: GoogleCalendarTime
    let end: GoogleCalendarTime
}

struct GoogleCalendarTime: Codable {
    let dateTime: String
}
