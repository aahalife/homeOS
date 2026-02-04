import Foundation

/// Google Classroom API client (OAuth 2.0)
/// Documentation: https://developers.google.com/classroom
final class GoogleClassroomAPI: BaseAPIClient {
    private let baseURL = "https://classroom.googleapis.com/v1"
    private var accessToken: String?

    var isAuthenticated: Bool { accessToken != nil }

    func setAccessToken(_ token: String) {
        self.accessToken = token
    }

    // MARK: - Courses

    func listCourses() async throws -> [ClassroomCourse] {
        guard let token = accessToken else {
            logger.warning("Google Classroom not authenticated, using stub data")
            return StubEducationData.sampleCourses
        }

        let url = URL(string: "\(baseURL)/courses?courseStates=ACTIVE")!
        let response: ClassroomCourseListResponse = try await request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"]
        )
        return response.courses ?? []
    }

    // MARK: - Course Work

    func listCourseWork(courseId: String) async throws -> [ClassroomCourseWork] {
        guard let token = accessToken else {
            return StubEducationData.sampleCourseWork
        }

        let url = URL(string: "\(baseURL)/courses/\(courseId)/courseWork?orderBy=dueDate")!
        let response: ClassroomCourseWorkListResponse = try await request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"]
        )
        return response.courseWork ?? []
    }

    // MARK: - Student Submissions

    func listSubmissions(courseId: String, courseWorkId: String) async throws -> [ClassroomSubmission] {
        guard let token = accessToken else { return [] }

        let url = URL(string: "\(baseURL)/courses/\(courseId)/courseWork/\(courseWorkId)/studentSubmissions")!
        let response: ClassroomSubmissionListResponse = try await request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"]
        )
        return response.studentSubmissions ?? []
    }

    // MARK: - Conversion

    func toAssignments(courseWork: [ClassroomCourseWork], studentId: UUID) -> [Assignment] {
        courseWork.compactMap { work in
            guard let dueDate = parseDueDate(work.dueDate, work.dueTime) else { return nil }
            return Assignment(
                studentId: studentId,
                title: work.title ?? "Untitled",
                subject: work.description ?? "General",
                dueDate: dueDate,
                status: dueDate < Date() ? .overdue : .pending,
                points: work.maxPoints,
                maxPoints: work.maxPoints,
                courseId: work.courseId,
                externalId: work.id
            )
        }
    }

    private func parseDueDate(_ dueDate: ClassroomDate?, _ dueTime: ClassroomTimeOfDay?) -> Date? {
        guard let dueDate = dueDate, let year = dueDate.year, let month = dueDate.month, let day = dueDate.day else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = dueTime?.hours ?? 23
        components.minute = dueTime?.minutes ?? 59
        return Calendar.current.date(from: components)
    }
}

// MARK: - Google Classroom Types

struct ClassroomCourseListResponse: Codable {
    let courses: [ClassroomCourse]?
}

struct ClassroomCourse: Codable, Identifiable {
    let id: String?
    let name: String?
    let section: String?
    let room: String?
    let ownerId: String?
    let courseState: String?
}

struct ClassroomCourseWorkListResponse: Codable {
    let courseWork: [ClassroomCourseWork]?
}

struct ClassroomCourseWork: Codable {
    let id: String?
    let courseId: String?
    let title: String?
    let description: String?
    let maxPoints: Double?
    let dueDate: ClassroomDate?
    let dueTime: ClassroomTimeOfDay?
    let workType: String?
}

struct ClassroomDate: Codable {
    let year: Int?
    let month: Int?
    let day: Int?
}

struct ClassroomTimeOfDay: Codable {
    let hours: Int?
    let minutes: Int?
}

struct ClassroomSubmissionListResponse: Codable {
    let studentSubmissions: [ClassroomSubmission]?
}

struct ClassroomSubmission: Codable {
    let id: String?
    let courseWorkId: String?
    let state: String?
    let assignedGrade: Double?
    let draftGrade: Double?
}
