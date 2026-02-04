import Foundation

// MARK: - Education Models

struct StudentProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var memberId: UUID
    var gradeLevel: Int
    var schoolName: String
    var lmsType: LMSType?
    var lmsConnected: Bool = false
    var assignments: [Assignment] = []
    var grades: [GradeEntry] = []
    var teachers: [Teacher] = []
}

struct Assignment: Identifiable, Codable {
    var id: UUID = UUID()
    var studentId: UUID
    var title: String
    var subject: String
    var dueDate: Date
    var status: AssignmentStatus = .pending
    var estimatedTime: Int? // minutes
    var priority: Priority = .medium
    var description: String?
    var points: Double?
    var maxPoints: Double?
    var courseId: String?
    var externalId: String?
}

enum AssignmentStatus: String, Codable {
    case pending, inProgress, completed, overdue, graded
}

struct GradeEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var studentId: UUID
    var subject: String
    var grade: Double
    var maxGrade: Double = 100.0
    var date: Date = Date()
    var assignmentTitle: String?
    var type: GradeType = .assignment

    var percentage: Double {
        (grade / maxGrade) * 100.0
    }
}

enum GradeType: String, Codable {
    case assignment, quiz, test, project, participation, final
}

struct Teacher: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var subject: String
    var email: String?
    var phone: String?
}

struct StudyPlan: Identifiable, Codable {
    var id: UUID = UUID()
    var studentId: UUID
    var subject: String
    var examDate: Date
    var sessions: [StudySession]
    var totalTime: Int // minutes
}

struct StudySession: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var duration: Int // minutes
    var topic: String
    var technique: StudyTechnique
    var completed: Bool = false
}

enum StudyTechnique: String, Codable {
    case pomodoro = "Pomodoro (25 min focus + 5 min break)"
    case spacedRepetition = "Spaced Repetition"
    case practiceProblems = "Practice Problems"
    case essayOutline = "Essay Outlining"
    case flashcards = "Flashcards"
    case readingReview = "Reading Review"
}

struct GradeChange: Codable {
    var studentId: UUID
    var studentName: String
    var subject: String
    var previousGrade: Double
    var currentGrade: Double
    var delta: Double

    var isSignificantDrop: Bool {
        delta < -5.0
    }

    var isCritical: Bool {
        currentGrade < 70.0
    }
}

// MARK: - Alert Thresholds

struct EducationAlertThreshold {
    static let urgentGrade: Double = 70.0
    static let warningGrade: Double = 80.0
    static let gradeDrop: Double = 5.0
    static let overdueAssignments: Int = 2
    static let upcomingTestDays: Int = 3
}
