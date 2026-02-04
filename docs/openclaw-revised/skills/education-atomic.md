# Education Skill: Atomic Function Breakdown
## OpenClaw Family Assistant - Production Implementation Guide

**Version:** 1.0
**Date:** February 2, 2026
**Status:** Implementation Ready
**Target Platform:** iOS 17.0+, Swift 5.10+

---

## Table of Contents

1. [Skill Overview](#1-skill-overview)
2. [User Stories](#2-user-stories)
3. [Atomic Functions](#3-atomic-functions)
4. [Data Structures](#4-data-structures)
5. [LMS Integration Workflows](#5-lms-integration-workflows)
6. [Grade Monitoring & Alerts](#6-grade-monitoring--alerts)
7. [Study Plan Generation](#7-study-plan-generation)
8. [Multi-Child Coordination](#8-multi-child-coordination)
9. [Example Scenarios](#9-example-scenarios)
10. [API Integrations](#10-api-integrations)
11. [Test Cases](#11-test-cases)
12. [Error Handling](#12-error-handling)

---

## 1. Skill Overview

### Purpose
The Education skill transforms OpenClaw into a proactive academic assistant that:
- Monitors assignments and grades across multiple children
- Syncs with Google Classroom and Canvas LMS platforms
- Detects academic issues before they become problems
- Generates personalized study plans
- Drafts teacher communications
- Provides daily homework summaries

### Core Capabilities
- **Real-time LMS Sync**: Automatic polling of assignment and grade data
- **Intelligent Alerts**: Grade drops, overdue work, upcoming tests
- **Study Planning**: Pomodoro-based schedules with spaced repetition
- **Multi-Child Management**: Aggregate family academic status
- **Teacher Communication**: Draft emails with appropriate tone

### Design Philosophy
- **Proactive, Not Reactive**: Daily 4pm automatic homework check
- **Pragmatic Thresholds**: Alert on grades < 70%, drops > 5 points
- **Student Privacy**: Age-appropriate data sharing with parents
- **Encouragement-First**: Positive framing of academic challenges

---

## 2. User Stories

### K-5 Elementary (Ages 5-10)

**US-E1: Homework Reminder**
```
As a parent of a 2nd grader,
I want daily homework reminders at 4pm,
So I can help my child complete assignments before dinner.

Acceptance Criteria:
- System checks Google Classroom daily at 4pm
- Sends notification: "Emma has 2 assignments due tomorrow"
- Lists: Reading log (10 min), Math worksheet (pg 45)
- No grade monitoring (elementary uses standards-based grading)
```

**US-E2: Reading Tracker**
```
As a parent of a 3rd grader,
I want to log daily reading minutes,
So we meet the 20-minute daily requirement.

Acceptance Criteria:
- Daily prompt: "Did Jake complete 20 minutes of reading?"
- Tracks streak (5 days in a row = achievement badge)
- Weekly summary for parent-teacher conferences
```

### 6-8 Middle School (Ages 11-13)

**US-M1: Grade Drop Alert**
```
As a parent of a 7th grader,
I want alerts when grades drop below 80%,
So I can intervene early with tutoring or study plans.

Acceptance Criteria:
- System syncs grades weekly from Canvas
- Alert triggered: "Anika's Math grade dropped from 85% to 78%"
- Suggested actions: "Schedule study time" or "Email teacher"
- Tracks trend: "3-week downward trend detected"
```

**US-M2: Assignment Prioritization**
```
As a 6th grader,
I want to see my homework sorted by urgency,
So I know what to do first.

Acceptance Criteria:
- Overdue assignments marked RED
- Due tomorrow marked ORANGE
- Due this week marked YELLOW
- Estimated time shown (Math: 30 min)
```

### 9-12 High School (Ages 14-18)

**US-H1: Test Preparation Plan**
```
As a high school sophomore,
I want a study schedule for my Biology exam in 5 days,
So I can prepare systematically instead of cramming.

Acceptance Criteria:
- System generates 5-day plan (45 min/day)
- Day 1-2: Review notes (chapters 5-7)
- Day 3: Practice problems (40 questions)
- Day 4: Flashcards (20 key terms)
- Day 5: Light review + early sleep
- Pomodoro format: 25 min study, 5 min break
```

**US-H2: College Prep Dashboard**
```
As a parent of a junior,
I want to track GPA, test scores, and deadlines,
So we stay on top of college applications.

Acceptance Criteria:
- Current GPA: 3.7 (with trend graph)
- SAT scores: 1350 (Math 680, Verbal 670)
- Upcoming: SAT retake on March 15, College essay due April 1
- Suggested: "15 hours community service needed for top schools"
```

---

## 3. Atomic Functions

### 3.1 LMS Synchronization

#### `syncGoogleClassroom(studentId:)`
```swift
/// Fetches assignments, grades, and announcements from Google Classroom
/// - Parameter studentId: UUID of the student profile
/// - Returns: SyncResult with updated assignments and grades
/// - Throws: LMSError if authentication fails or API rate limited
func syncGoogleClassroom(studentId: UUID) async throws -> SyncResult {
    guard let student = try await fetchStudentProfile(studentId) else {
        throw LMSError.studentNotFound
    }

    guard let lmsConnection = student.lmsConnection,
          lmsConnection.platform == .googleClassroom else {
        throw LMSError.notConnected
    }

    // Refresh OAuth token if expired
    let accessToken = try await refreshAccessTokenIfNeeded(lmsConnection.refreshToken)

    // Fetch courses
    let courses = try await GoogleClassroomAPI.listCourses(accessToken: accessToken)

    var allAssignments: [Assignment] = []
    var allGrades: [GradeEntry] = []

    for course in courses {
        // Fetch course work (assignments)
        let courseWork = try await GoogleClassroomAPI.listCourseWork(
            courseId: course.id,
            accessToken: accessToken
        )

        // Map to internal Assignment model
        let assignments = courseWork.map { work in
            Assignment(
                id: UUID(),
                externalId: work.id,
                title: work.title,
                subject: course.name,
                description: work.description,
                dueDate: work.dueDate,
                status: determineStatus(work),
                estimatedTime: estimateTimeRequired(work),
                priority: calculatePriority(work),
                attachments: work.materials.map { mapAttachment($0) }
            )
        }
        allAssignments.append(contentsOf: assignments)

        // Fetch student submissions for grading
        let submissions = try await GoogleClassroomAPI.listSubmissions(
            courseId: course.id,
            courseWorkId: courseWork.map { $0.id },
            accessToken: accessToken
        )

        let grades = submissions.compactMap { submission -> GradeEntry? in
            guard let grade = submission.assignedGrade else { return nil }
            return GradeEntry(
                id: UUID(),
                studentId: studentId,
                subject: course.name,
                assignmentTitle: submission.courseWorkTitle,
                grade: grade,
                maxPoints: submission.maxPoints,
                percentage: (grade / submission.maxPoints) * 100,
                gradedDate: submission.gradedDate,
                feedback: submission.feedback
            )
        }
        allGrades.append(contentsOf: grades)
    }

    // Persist to Core Data
    try await saveAssignments(allAssignments, studentId: studentId)
    try await saveGrades(allGrades, studentId: studentId)

    return SyncResult(
        studentId: studentId,
        platform: .googleClassroom,
        assignmentsUpdated: allAssignments.count,
        gradesUpdated: allGrades.count,
        syncDate: Date(),
        errors: []
    )
}
```

#### `syncCanvas(studentId:)`
```swift
/// Fetches assignments, grades, and announcements from Canvas LMS
/// - Parameter studentId: UUID of the student profile
/// - Returns: SyncResult with updated assignments and grades
/// - Throws: LMSError if authentication fails or API error
func syncCanvas(studentId: UUID) async throws -> SyncResult {
    guard let student = try await fetchStudentProfile(studentId) else {
        throw LMSError.studentNotFound
    }

    guard let lmsConnection = student.lmsConnection,
          lmsConnection.platform == .canvas else {
        throw LMSError.notConnected
    }

    let apiToken = try KeychainManager.shared.getAPIKey(for: "canvas_\(studentId)")
    let canvasAPI = CanvasAPI(baseURL: lmsConnection.institutionURL, apiToken: apiToken)

    // Fetch active courses
    let courses = try await canvasAPI.listCourses(enrollmentState: .active)

    var allAssignments: [Assignment] = []
    var allGrades: [GradeEntry] = []

    for course in courses {
        // Fetch assignments
        let assignments = try await canvasAPI.listAssignments(courseId: course.id)

        let mappedAssignments = assignments.map { assignment in
            Assignment(
                id: UUID(),
                externalId: assignment.id,
                title: assignment.name,
                subject: course.name,
                description: assignment.description,
                dueDate: assignment.dueAt,
                status: assignment.hasSubmitted ? .completed :
                        (assignment.dueAt < Date() ? .overdue : .pending),
                estimatedTime: estimateTimeRequired(assignment),
                priority: calculatePriority(assignment),
                attachments: []
            )
        }
        allAssignments.append(contentsOf: mappedAssignments)

        // Fetch submissions with grades
        let submissions = try await canvasAPI.listSubmissions(
            courseId: course.id,
            assignmentIds: assignments.map { $0.id }
        )

        let grades = submissions.compactMap { submission -> GradeEntry? in
            guard let score = submission.score else { return nil }
            return GradeEntry(
                id: UUID(),
                studentId: studentId,
                subject: course.name,
                assignmentTitle: submission.assignmentName,
                grade: score,
                maxPoints: submission.pointsPossible,
                percentage: (score / submission.pointsPossible) * 100,
                gradedDate: submission.gradedAt,
                feedback: submission.comments.first?.comment
            )
        }
        allGrades.append(contentsOf: grades)
    }

    try await saveAssignments(allAssignments, studentId: studentId)
    try await saveGrades(allGrades, studentId: studentId)

    return SyncResult(
        studentId: studentId,
        platform: .canvas,
        assignmentsUpdated: allAssignments.count,
        gradesUpdated: allGrades.count,
        syncDate: Date(),
        errors: []
    )
}
```

### 3.2 Assignment Management

#### `getUpcomingAssignments(studentId:daysAhead:)`
```swift
/// Retrieves assignments due within specified number of days
/// - Parameters:
///   - studentId: UUID of the student
///   - daysAhead: Number of days to look ahead (default: 7)
/// - Returns: Array of assignments sorted by due date
func getUpcomingAssignments(
    studentId: UUID,
    daysAhead: Int = 7
) async throws -> [Assignment] {
    let endDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date())!

    let fetchRequest = Assignment.fetchRequest()
    fetchRequest.predicate = NSPredicate(
        format: "studentId == %@ AND dueDate >= %@ AND dueDate <= %@ AND status != %@",
        studentId as CVarArg,
        Date() as NSDate,
        endDate as NSDate,
        AssignmentStatus.completed.rawValue
    )
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]

    let context = CoreDataManager.shared.viewContext
    return try context.fetch(fetchRequest)
}
```

#### `prioritizeAssignments(assignments:)`
```swift
/// Sorts assignments by urgency and importance
/// - Parameter assignments: Array of assignments to prioritize
/// - Returns: Sorted array with priority field updated
func prioritizeAssignments(_ assignments: [Assignment]) -> [Assignment] {
    var prioritized = assignments

    for (index, assignment) in prioritized.enumerated() {
        let priority = calculatePriority(assignment)
        prioritized[index].priority = priority
    }

    // Sort by priority (urgent > high > medium > low), then by due date
    return prioritized.sorted { lhs, rhs in
        if lhs.priority == rhs.priority {
            return lhs.dueDate < rhs.dueDate
        }
        return lhs.priority.rawValue > rhs.priority.rawValue
    }
}

private func calculatePriority(_ assignment: Assignment) -> Priority {
    let now = Date()
    let timeUntilDue = assignment.dueDate.timeIntervalSince(now)
    let hoursUntilDue = timeUntilDue / 3600

    // Overdue = URGENT
    if assignment.status == .overdue {
        return .urgent
    }

    // Due within 24 hours = HIGH
    if hoursUntilDue <= 24 {
        return .high
    }

    // Due within 48 hours = MEDIUM
    if hoursUntilDue <= 48 {
        return .medium
    }

    // Otherwise LOW
    return .low
}
```

#### `estimateTimeRequired(assignment:)`
```swift
/// Estimates time needed to complete assignment based on type and grade level
/// - Parameter assignment: The assignment to estimate
/// - Returns: Estimated minutes required
func estimateTimeRequired(_ assignment: Assignment) -> Int {
    // Get student's grade level
    guard let student = try? fetchStudentProfile(assignment.studentId),
          let gradeLevel = student.gradeLevel else {
        return 30 // Default estimate
    }

    // Base estimates by assignment type and grade level
    let typeMultiplier: Double

    if assignment.title.lowercased().contains("essay") ||
       assignment.title.lowercased().contains("report") {
        typeMultiplier = gradeLevel <= 5 ? 2.0 : 3.0 // Elementary vs. older
    } else if assignment.title.lowercased().contains("math") ||
              assignment.title.lowercased().contains("worksheet") {
        typeMultiplier = 1.5
    } else if assignment.title.lowercased().contains("reading") {
        typeMultiplier = 1.0
    } else {
        typeMultiplier = 1.2 // Default
    }

    // Base time by grade level
    let baseTime: Int
    switch gradeLevel {
    case 1...5:   baseTime = 15  // K-5: 15-30 min per assignment
    case 6...8:   baseTime = 30  // Middle: 30-60 min
    case 9...12:  baseTime = 45  // High school: 45-90 min
    default:      baseTime = 30
    }

    return Int(Double(baseTime) * typeMultiplier)
}
```

#### `markAssignmentComplete(assignmentId:)`
```swift
/// Marks an assignment as completed
/// - Parameter assignmentId: UUID of the assignment
/// - Returns: Updated assignment
func markAssignmentComplete(assignmentId: UUID) async throws -> Assignment {
    let context = CoreDataManager.shared.viewContext

    guard let assignment = try context.fetch(
        Assignment.fetchRequest().filtered(by: "id", equals: assignmentId)
    ).first else {
        throw EducationError.assignmentNotFound
    }

    assignment.status = .completed
    assignment.completedDate = Date()

    try context.save()

    // Log completion for analytics
    AnalyticsManager.shared.trackEvent(
        "assignment_completed",
        properties: [
            "student_id": assignment.studentId.uuidString,
            "subject": assignment.subject,
            "on_time": assignment.completedDate! <= assignment.dueDate
        ]
    )

    return assignment
}
```

### 3.3 Grade Monitoring

#### `getRecentGrades(studentId:subject:limit:)`
```swift
/// Retrieves recent grades for trend analysis
/// - Parameters:
///   - studentId: UUID of the student
///   - subject: Optional subject filter (nil = all subjects)
///   - limit: Max number of grades to return (default: 20)
/// - Returns: Array of grade entries sorted by date (newest first)
func getRecentGrades(
    studentId: UUID,
    subject: String? = nil,
    limit: Int = 20
) async throws -> [GradeEntry] {
    let fetchRequest = GradeEntry.fetchRequest()

    var predicateFormat = "studentId == %@"
    var predicateArgs: [Any] = [studentId as CVarArg]

    if let subject = subject {
        predicateFormat += " AND subject == %@"
        predicateArgs.append(subject)
    }

    fetchRequest.predicate = NSPredicate(format: predicateFormat, argumentArray: predicateArgs)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "gradedDate", ascending: false)]
    fetchRequest.fetchLimit = limit

    let context = CoreDataManager.shared.viewContext
    return try context.fetch(fetchRequest)
}
```

#### `detectGradeTrends(studentId:subject:)`
```swift
/// Analyzes grade history to detect trends (improving, declining, stable)
/// - Parameters:
///   - studentId: UUID of the student
///   - subject: Subject to analyze
/// - Returns: TrendAnalysis with direction and severity
func detectGradeTrends(
    studentId: UUID,
    subject: String
) async throws -> TrendAnalysis {
    let grades = try await getRecentGrades(
        studentId: studentId,
        subject: subject,
        limit: 10
    )

    guard grades.count >= 3 else {
        return TrendAnalysis(
            subject: subject,
            direction: .insufficient_data,
            averageChange: 0,
            currentAverage: grades.first?.percentage ?? 0,
            previousAverage: 0
        )
    }

    // Calculate recent average (last 3 grades)
    let recentGrades = Array(grades.prefix(3))
    let recentAverage = recentGrades.map { $0.percentage }.reduce(0, +) / Double(recentGrades.count)

    // Calculate previous average (next 3 grades)
    let previousGrades = Array(grades.dropFirst(3).prefix(3))
    guard previousGrades.count >= 3 else {
        return TrendAnalysis(
            subject: subject,
            direction: .insufficient_data,
            averageChange: 0,
            currentAverage: recentAverage,
            previousAverage: 0
        )
    }

    let previousAverage = previousGrades.map { $0.percentage }.reduce(0, +) / Double(previousGrades.count)
    let change = recentAverage - previousAverage

    // Determine trend direction
    let direction: TrendDirection
    if abs(change) < 3.0 {
        direction = .stable
    } else if change > 0 {
        direction = change > 5.0 ? .improving_significant : .improving_slight
    } else {
        direction = change < -5.0 ? .declining_significant : .declining_slight
    }

    return TrendAnalysis(
        subject: subject,
        direction: direction,
        averageChange: change,
        currentAverage: recentAverage,
        previousAverage: previousAverage,
        grades: grades
    )
}
```

#### `calculateGPA(studentId:semester:)`
```swift
/// Calculates GPA for a student (high school only)
/// - Parameters:
///   - studentId: UUID of the student
///   - semester: Optional semester filter (nil = cumulative)
/// - Returns: GPA on 4.0 scale with letter grade breakdown
func calculateGPA(
    studentId: UUID,
    semester: Semester? = nil
) async throws -> GPAResult {
    guard let student = try await fetchStudentProfile(studentId),
          let gradeLevel = student.gradeLevel,
          gradeLevel >= 9 else {
        throw EducationError.gpaNotApplicable(reason: "GPA only calculated for high school")
    }

    var fetchRequest = GradeEntry.fetchRequest()

    if let semester = semester {
        fetchRequest.predicate = NSPredicate(
            format: "studentId == %@ AND gradedDate >= %@ AND gradedDate <= %@",
            studentId as CVarArg,
            semester.startDate as NSDate,
            semester.endDate as NSDate
        )
    } else {
        fetchRequest.predicate = NSPredicate(format: "studentId == %@", studentId as CVarArg)
    }

    let context = CoreDataManager.shared.viewContext
    let grades = try context.fetch(fetchRequest)

    guard !grades.isEmpty else {
        return GPAResult(gpa: 0, letterGrade: "N/A", breakdown: [:])
    }

    // Group by subject to get course grades
    let gradesBySubject = Dictionary(grouping: grades, by: { $0.subject })

    var totalPoints: Double = 0
    var courseCount = 0
    var breakdown: [String: Double] = [:]

    for (subject, subjectGrades) in gradesBySubject {
        let average = subjectGrades.map { $0.percentage }.reduce(0, +) / Double(subjectGrades.count)
        let gradePoints = percentageToGPA(average)

        totalPoints += gradePoints
        courseCount += 1
        breakdown[subject] = gradePoints
    }

    let gpa = totalPoints / Double(courseCount)
    let letterGrade = gpaToLetterGrade(gpa)

    return GPAResult(
        gpa: gpa,
        letterGrade: letterGrade,
        breakdown: breakdown,
        totalCourses: courseCount
    )
}

private func percentageToGPA(_ percentage: Double) -> Double {
    switch percentage {
    case 93...100:  return 4.0  // A
    case 90..<93:   return 3.7  // A-
    case 87..<90:   return 3.3  // B+
    case 83..<87:   return 3.0  // B
    case 80..<83:   return 2.7  // B-
    case 77..<80:   return 2.3  // C+
    case 73..<77:   return 2.0  // C
    case 70..<73:   return 1.7  // C-
    case 67..<70:   return 1.3  // D+
    case 63..<67:   return 1.0  // D
    default:        return 0.0  // F
    }
}

private func gpaToLetterGrade(_ gpa: Double) -> String {
    switch gpa {
    case 3.7...4.0:  return "A"
    case 3.3..<3.7:  return "B+"
    case 2.7..<3.3:  return "B"
    case 2.3..<2.7:  return "C+"
    case 1.7..<2.3:  return "C"
    case 1.0..<1.7:  return "D"
    default:         return "F"
    }
}
```

### 3.4 Alert Generation

#### `checkGradeAlerts(studentId:)`
```swift
/// Checks for grade-related alerts (drops, low grades, trends)
/// - Parameter studentId: UUID of the student
/// - Returns: Array of alerts to notify parent
func checkGradeAlerts(studentId: UUID) async throws -> [EducationAlert] {
    var alerts: [EducationAlert] = []

    guard let student = try await fetchStudentProfile(studentId) else {
        return alerts
    }

    // Get all subjects for the student
    let subjects = try await getActiveSubjects(studentId: studentId)

    for subject in subjects {
        // Get recent grades
        let grades = try await getRecentGrades(
            studentId: studentId,
            subject: subject,
            limit: 10
        )

        guard !grades.isEmpty else { continue }

        let mostRecent = grades[0]

        // ALERT 1: Grade below threshold (70%)
        if mostRecent.percentage < AlertThreshold.urgentGrade {
            alerts.append(EducationAlert(
                type: .lowGrade,
                severity: .urgent,
                studentId: studentId,
                studentName: student.name,
                subject: subject,
                title: "\(student.name)'s \(subject) grade is below 70%",
                message: "Current grade: \(Int(mostRecent.percentage))% on '\(mostRecent.assignmentTitle)'",
                actionSuggestions: [
                    "Schedule tutoring session",
                    "Email teacher to discuss concerns",
                    "Create focused study plan"
                ],
                createdDate: Date()
            ))
        }

        // ALERT 2: Grade drop > 5 points
        if grades.count >= 2 {
            let previous = grades[1]
            let drop = previous.percentage - mostRecent.percentage

            if drop >= AlertThreshold.gradeDrop {
                alerts.append(EducationAlert(
                    type: .gradeDrop,
                    severity: .warning,
                    studentId: studentId,
                    studentName: student.name,
                    subject: subject,
                    title: "\(student.name)'s \(subject) grade dropped \(Int(drop)) points",
                    message: "From \(Int(previous.percentage))% to \(Int(mostRecent.percentage))%",
                    actionSuggestions: [
                        "Review recent assignment feedback",
                        "Increase study time for \(subject)",
                        "Check for missing concepts"
                    ],
                    createdDate: Date()
                ))
            }
        }

        // ALERT 3: Declining trend
        let trend = try await detectGradeTrends(studentId: studentId, subject: subject)
        if trend.direction == .declining_significant {
            alerts.append(EducationAlert(
                type: .decliningTrend,
                severity: .warning,
                studentId: studentId,
                studentName: student.name,
                subject: subject,
                title: "\(subject) grades declining over last 3 assignments",
                message: "Average dropped from \(Int(trend.previousAverage))% to \(Int(trend.currentAverage))%",
                actionSuggestions: [
                    "Meet with teacher",
                    "Assess study habits",
                    "Consider tutoring"
                ],
                createdDate: Date()
            ))
        }
    }

    return alerts
}
```

#### `checkAssignmentAlerts(studentId:)`
```swift
/// Checks for assignment-related alerts (overdue, upcoming, heavy load)
/// - Parameter studentId: UUID of the student
/// - Returns: Array of alerts to notify parent/student
func checkAssignmentAlerts(studentId: UUID) async throws -> [EducationAlert] {
    var alerts: [EducationAlert] = []

    guard let student = try await fetchStudentProfile(studentId) else {
        return alerts
    }

    // Get all pending assignments
    let fetchRequest = Assignment.fetchRequest()
    fetchRequest.predicate = NSPredicate(
        format: "studentId == %@ AND status != %@",
        studentId as CVarArg,
        AssignmentStatus.completed.rawValue
    )

    let context = CoreDataManager.shared.viewContext
    let assignments = try context.fetch(fetchRequest)

    // ALERT 1: Overdue assignments
    let overdueAssignments = assignments.filter { $0.status == .overdue }

    if overdueAssignments.count >= AlertThreshold.overdueAssignments {
        alerts.append(EducationAlert(
            type: .overdueWork,
            severity: .urgent,
            studentId: studentId,
            studentName: student.name,
            subject: "Multiple Subjects",
            title: "\(student.name) has \(overdueAssignments.count) overdue assignments",
            message: overdueAssignments.prefix(3).map { "• \($0.subject): \($0.title)" }.joined(separator: "\n"),
            actionSuggestions: [
                "Create catch-up schedule",
                "Email teachers to explain",
                "Focus on highest-priority work first"
            ],
            createdDate: Date(),
            relatedAssignments: overdueAssignments.map { $0.id }
        ))
    }

    // ALERT 2: Heavy load week (5+ assignments due)
    let upcomingWeek = try await getUpcomingAssignments(studentId: studentId, daysAhead: 7)

    if upcomingWeek.count >= 5 {
        let totalEstimatedTime = upcomingWeek.map { $0.estimatedTime }.reduce(0, +)

        alerts.append(EducationAlert(
            type: .heavyWorkload,
            severity: .info,
            studentId: studentId,
            studentName: student.name,
            subject: "Multiple Subjects",
            title: "Busy week ahead: \(upcomingWeek.count) assignments due",
            message: "Estimated total time: \(totalEstimatedTime / 60) hours. Plan ahead!",
            actionSuggestions: [
                "Create daily schedule",
                "Start long-term projects early",
                "Block out study time on calendar"
            ],
            createdDate: Date(),
            relatedAssignments: upcomingWeek.map { $0.id }
        ))
    }

    // ALERT 3: Upcoming test/exam
    let upcomingTests = assignments.filter { assignment in
        (assignment.title.lowercased().contains("test") ||
         assignment.title.lowercased().contains("exam") ||
         assignment.title.lowercased().contains("quiz")) &&
        assignment.dueDate.timeIntervalSince(Date()) <= Double(AlertThreshold.upcomingTestDays * 24 * 3600)
    }

    for test in upcomingTests {
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: test.dueDate).day ?? 0

        alerts.append(EducationAlert(
            type: .upcomingTest,
            severity: .info,
            studentId: studentId,
            studentName: student.name,
            subject: test.subject,
            title: "\(test.subject) \(test.title) in \(daysUntil) days",
            message: "Due: \(formatDate(test.dueDate))",
            actionSuggestions: [
                "Generate study plan",
                "Review recent homework",
                "Create practice quiz"
            ],
            createdDate: Date(),
            relatedAssignments: [test.id]
        ))
    }

    return alerts
}
```

### 3.5 Study Plan Generation

#### `generateStudyPlan(assignmentId:availableDays:dailyTimeMinutes:)`
```swift
/// Creates a day-by-day study plan for an upcoming test/exam
/// - Parameters:
///   - assignmentId: UUID of the test/exam assignment
///   - availableDays: Number of days until test
///   - dailyTimeMinutes: Minutes available per day for studying
/// - Returns: StudyPlan with daily tasks
func generateStudyPlan(
    assignmentId: UUID,
    availableDays: Int? = nil,
    dailyTimeMinutes: Int = 45
) async throws -> StudyPlan {
    guard let assignment = try await fetchAssignment(assignmentId) else {
        throw EducationError.assignmentNotFound
    }

    // Calculate days until test
    let daysUntil = availableDays ?? Calendar.current.dateComponents(
        [.day],
        from: Date(),
        to: assignment.dueDate
    ).day ?? 3

    guard daysUntil > 0 else {
        throw EducationError.insufficientPrepTime
    }

    let totalMinutes = daysUntil * dailyTimeMinutes

    // Generate study tasks based on subject and test type
    let tasks = generateStudyTasks(
        assignment: assignment,
        totalMinutes: totalMinutes,
        daysAvailable: daysUntil
    )

    // Distribute tasks across days using spaced repetition
    let dailySchedule = distributeTasksAcrossDays(
        tasks: tasks,
        days: daysUntil,
        dailyMinutes: dailyTimeMinutes
    )

    let plan = StudyPlan(
        id: UUID(),
        assignmentId: assignmentId,
        studentId: assignment.studentId,
        subject: assignment.subject,
        testDate: assignment.dueDate,
        totalDays: daysUntil,
        dailyTimeMinutes: dailyTimeMinutes,
        dailySchedule: dailySchedule,
        createdDate: Date(),
        status: .active
    )

    // Save to Core Data
    try await saveStudyPlan(plan)

    return plan
}

private func generateStudyTasks(
    assignment: Assignment,
    totalMinutes: Int,
    daysAvailable: Int
) -> [StudyTask] {
    var tasks: [StudyTask] = []
    let subject = assignment.subject.lowercased()

    if subject.contains("math") || subject.contains("algebra") ||
       subject.contains("geometry") || subject.contains("calculus") {
        // Math/STEM study plan
        tasks.append(StudyTask(
            title: "Review class notes and formulas",
            description: "Go through all notes from chapters covered on the test",
            estimatedMinutes: Int(Double(totalMinutes) * 0.25),
            taskType: .review,
            dayNumber: 1
        ))

        tasks.append(StudyTask(
            title: "Practice problems (easy)",
            description: "Complete 10-15 basic problems from textbook",
            estimatedMinutes: Int(Double(totalMinutes) * 0.20),
            taskType: .practice,
            dayNumber: 2
        ))

        tasks.append(StudyTask(
            title: "Practice problems (medium)",
            description: "Complete 10-15 medium difficulty problems",
            estimatedMinutes: Int(Double(totalMinutes) * 0.25),
            taskType: .practice,
            dayNumber: daysAvailable > 3 ? 3 : 2
        ))

        tasks.append(StudyTask(
            title: "Practice problems (challenging)",
            description: "Attempt 5-10 challenging problems, focus on weak areas",
            estimatedMinutes: Int(Double(totalMinutes) * 0.20),
            taskType: .practice,
            dayNumber: max(daysAvailable - 1, 2)
        ))

        tasks.append(StudyTask(
            title: "Final review and light practice",
            description: "Quick review of formulas, attempt 2-3 problems",
            estimatedMinutes: Int(Double(totalMinutes) * 0.10),
            taskType: .review,
            dayNumber: daysAvailable
        ))

    } else if subject.contains("history") || subject.contains("social") {
        // History/Social Studies plan
        tasks.append(StudyTask(
            title: "Read and summarize key chapters",
            description: "Create one-page summary for each chapter",
            estimatedMinutes: Int(Double(totalMinutes) * 0.30),
            taskType: .review,
            dayNumber: 1
        ))

        tasks.append(StudyTask(
            title: "Create timeline of events",
            description: "Visual timeline with dates, people, significance",
            estimatedMinutes: Int(Double(totalMinutes) * 0.20),
            taskType: .practice,
            dayNumber: 2
        ))

        tasks.append(StudyTask(
            title: "Flashcards for key terms and people",
            description: "Create and study 20-30 flashcards",
            estimatedMinutes: Int(Double(totalMinutes) * 0.25),
            taskType: .memorization,
            dayNumber: daysAvailable > 3 ? 3 : 2
        ))

        tasks.append(StudyTask(
            title: "Practice essay questions",
            description: "Write 2-3 practice essays or outlines",
            estimatedMinutes: Int(Double(totalMinutes) * 0.15),
            taskType: .practice,
            dayNumber: max(daysAvailable - 1, 2)
        ))

        tasks.append(StudyTask(
            title: "Review flashcards and notes",
            description: "Quick review of all materials",
            estimatedMinutes: Int(Double(totalMinutes) * 0.10),
            taskType: .review,
            dayNumber: daysAvailable
        ))

    } else if subject.contains("science") || subject.contains("biology") ||
              subject.contains("chemistry") || subject.contains("physics") {
        // Science study plan
        tasks.append(StudyTask(
            title: "Review notes and diagrams",
            description: "Go through class notes, redraw key diagrams",
            estimatedMinutes: Int(Double(totalMinutes) * 0.25),
            taskType: .review,
            dayNumber: 1
        ))

        tasks.append(StudyTask(
            title: "Vocabulary and concepts flashcards",
            description: "25-30 flashcards for key terms and definitions",
            estimatedMinutes: Int(Double(totalMinutes) * 0.20),
            taskType: .memorization,
            dayNumber: 2
        ))

        tasks.append(StudyTask(
            title: "Practice problems and calculations",
            description: "Work through 15-20 practice problems",
            estimatedMinutes: Int(Double(totalMinutes) * 0.25),
            taskType: .practice,
            dayNumber: daysAvailable > 3 ? 3 : 2
        ))

        tasks.append(StudyTask(
            title: "Review lab procedures and findings",
            description: "Go over recent lab work, understand conclusions",
            estimatedMinutes: Int(Double(totalMinutes) * 0.20),
            taskType: .review,
            dayNumber: max(daysAvailable - 1, 2)
        ))

        tasks.append(StudyTask(
            title: "Final review",
            description: "Quick review of flashcards and problem-solving strategies",
            estimatedMinutes: Int(Double(totalMinutes) * 0.10),
            taskType: .review,
            dayNumber: daysAvailable
        ))

    } else {
        // Generic study plan for other subjects
        tasks.append(StudyTask(
            title: "Review all class materials",
            description: "Notes, handouts, textbook chapters",
            estimatedMinutes: Int(Double(totalMinutes) * 0.40),
            taskType: .review,
            dayNumber: 1
        ))

        tasks.append(StudyTask(
            title: "Create study guide",
            description: "Summarize key concepts, terms, formulas",
            estimatedMinutes: Int(Double(totalMinutes) * 0.30),
            taskType: .practice,
            dayNumber: max(2, daysAvailable - 1)
        ))

        tasks.append(StudyTask(
            title: "Self-quiz and review",
            description: "Test yourself on material, review weak areas",
            estimatedMinutes: Int(Double(totalMinutes) * 0.30),
            taskType: .practice,
            dayNumber: daysAvailable
        ))
    }

    return tasks
}

private func distributeTasksAcrossDays(
    tasks: [StudyTask],
    days: Int,
    dailyMinutes: Int
) -> [DailyStudySchedule] {
    var dailySchedules: [DailyStudySchedule] = []

    for day in 1...days {
        let dayTasks = tasks.filter { $0.dayNumber == day }
        let totalMinutesForDay = dayTasks.map { $0.estimatedMinutes }.reduce(0, +)

        // Convert to Pomodoro sessions (25 min work, 5 min break)
        let pomodoroSessions = convertToPomodoroSessions(tasks: dayTasks)

        let schedule = DailyStudySchedule(
            dayNumber: day,
            date: Calendar.current.date(byAdding: .day, value: day - 1, to: Date())!,
            tasks: dayTasks,
            pomodoroSessions: pomodoroSessions,
            totalMinutes: totalMinutesForDay,
            isCompleted: false
        )

        dailySchedules.append(schedule)
    }

    return dailySchedules
}

private func convertToPomodoroSessions(tasks: [StudyTask]) -> [PomodoroSession] {
    var sessions: [PomodoroSession] = []
    var sessionNumber = 1

    for task in tasks {
        let numPomodoros = Int(ceil(Double(task.estimatedMinutes) / 25.0))

        for _ in 0..<numPomodoros {
            sessions.append(PomodoroSession(
                sessionNumber: sessionNumber,
                taskTitle: task.title,
                workMinutes: 25,
                breakMinutes: 5,
                isCompleted: false
            ))
            sessionNumber += 1
        }
    }

    // Last session has longer break (15 min)
    if !sessions.isEmpty {
        sessions[sessions.count - 1].breakMinutes = 15
    }

    return sessions
}
```

### 3.6 Teacher Communication

#### `draftTeacherEmail(context:)`
```swift
/// Generates a draft email to a teacher based on context
/// - Parameter context: EmailContext with student, subject, reason
/// - Returns: EmailDraft with subject line and body text
func draftTeacherEmail(context: EmailContext) async throws -> EmailDraft {
    guard let student = try await fetchStudentProfile(context.studentId) else {
        throw EducationError.studentNotFound
    }

    guard let teacher = try await fetchTeacher(
        studentId: context.studentId,
        subject: context.subject
    ) else {
        throw EducationError.teacherNotFound
    }

    let subjectLine: String
    let bodyText: String

    switch context.reason {
    case .concernAboutGrades:
        subjectLine = "Question about \(student.name)'s recent \(context.subject) grades"
        bodyText = """
        Dear \(teacher.title) \(teacher.lastName),

        I'm reaching out regarding \(student.name)'s recent grades in \(context.subject). I've noticed a decline from \(context.previousGrade?.formatted() ?? "previous assignments") to \(context.currentGrade?.formatted() ?? "recent work"), and I'd like to understand what we can do to support improvement.

        Would you be available for a brief call or meeting to discuss:
        • Areas where \(student.name) might need extra help
        • Study strategies that would be most effective
        • Whether tutoring or additional resources would be beneficial

        I appreciate your time and partnership in \(student.name)'s education.

        Best regards,
        \(context.parentName)
        """

    case .missedAssignments:
        subjectLine = "Following up on \(student.name)'s missing \(context.subject) assignments"
        bodyText = """
        Dear \(teacher.title) \(teacher.lastName),

        I wanted to reach out about \(student.name)'s missing assignments in \(context.subject). I recently became aware that there are \(context.numMissedAssignments ?? 0) incomplete assignments, and I want to ensure we get back on track.

        Could you please let me know:
        • Which assignments are still able to be submitted for credit
        • Any deadlines for make-up work
        • How we can prevent this from happening going forward

        We're committed to staying on top of assignments and would appreciate your guidance.

        Thank you,
        \(context.parentName)
        """

    case .requestForHelp:
        subjectLine = "Request for additional support in \(context.subject)"
        bodyText = """
        Dear \(teacher.title) \(teacher.lastName),

        \(student.name) has been working hard in \(context.subject), but is struggling with \(context.specificTopic ?? "recent material"). I'd like to arrange additional support to help them succeed.

        Could you recommend:
        • Specific concepts or skills to focus on
        • Tutoring resources or peer study groups
        • Additional practice materials

        Please let me know your availability for a brief conversation. I appreciate your support!

        Sincerely,
        \(context.parentName)
        """

    case .positiveUpdate:
        subjectLine = "Thank you - \(student.name) is doing great in \(context.subject)!"
        bodyText = """
        Dear \(teacher.title) \(teacher.lastName),

        I just wanted to send a quick note of appreciation for your excellent teaching this semester. \(student.name) has really enjoyed \(context.subject) and has shown wonderful improvement.

        Your engaging lessons and supportive approach have made a real difference. Thank you for all you do!

        Gratefully,
        \(context.parentName)
        """

    case .scheduleConference:
        subjectLine = "Request for parent-teacher conference - \(student.name)"
        bodyText = """
        Dear \(teacher.title) \(teacher.lastName),

        I'd like to schedule a parent-teacher conference to discuss \(student.name)'s progress in \(context.subject).

        I'm available:
        \(context.availabilitySlots?.map { "• \(formatDate($0))" }.joined(separator: "\n") ?? "• Please let me know times that work for you")

        Please let me know what works best for your schedule. I look forward to our conversation.

        Best regards,
        \(context.parentName)
        """
    }

    return EmailDraft(
        to: teacher.email,
        subject: subjectLine,
        body: bodyText,
        createdDate: Date(),
        isDraft: true
    )
}
```

### 3.7 Multi-Child Coordination

#### `generateFamilyEducationSummary(familyId:)`
```swift
/// Creates an aggregate summary of all children's academic status
/// - Parameter familyId: UUID of the family
/// - Returns: FamilyEducationSummary with per-child breakdown
func generateFamilyEducationSummary(
    familyId: UUID
) async throws -> FamilyEducationSummary {
    guard let family = try await fetchFamily(familyId) else {
        throw EducationError.familyNotFound
    }

    let students = family.members.compactMap { member -> UUID? in
        guard member.role == .child, member.schoolInfo != nil else {
 return nil }
        return member.id
    }

    var childSummaries: [ChildEducationSummary] = []
    var totalAlerts = 0
    var totalOverdueAssignments = 0

    for studentId in students {
        guard let student = family.members.first(where: { $0.id == studentId }) else {
            continue
        }

        // Get upcoming assignments
        let assignments = try await getUpcomingAssignments(
            studentId: studentId,
            daysAhead: 7
        )

        // Get alerts
        let gradeAlerts = try await checkGradeAlerts(studentId: studentId)
        let assignmentAlerts = try await checkAssignmentAlerts(studentId: studentId)
        let allAlerts = gradeAlerts + assignmentAlerts

        // Calculate subject averages
        let subjects = try await getActiveSubjects(studentId: studentId)
        var subjectAverages: [String: Double] = [:]

        for subject in subjects {
            let grades = try await getRecentGrades(
                studentId: studentId,
                subject: subject,
                limit: 5
            )

            if !grades.isEmpty {
                let average = grades.map { $0.percentage }.reduce(0, +) / Double(grades.count)
                subjectAverages[subject] = average
            }
        }

        let overdueCount = assignments.filter { $0.status == .overdue }.count

        let childSummary = ChildEducationSummary(
            studentId: studentId,
            studentName: student.name,
            gradeLevel: student.schoolInfo?.gradeLevel ?? 0,
            upcomingAssignments: assignments.count,
            overdueAssignments: overdueCount,
            alerts: allAlerts,
            subjectAverages: subjectAverages,
            overallStatus: determineOverallStatus(
                overdueCount: overdueCount,
                alertCount: allAlerts.count,
                averages: subjectAverages
            )
        )

        childSummaries.append(childSummary)
        totalAlerts += allAlerts.count
        totalOverdueAssignments += overdueCount
    }

    return FamilyEducationSummary(
        familyId: familyId,
        generatedDate: Date(),
        childSummaries: childSummaries,
        totalAlerts: totalAlerts,
        totalOverdueAssignments: totalOverdueAssignments,
        requiresAttention: totalAlerts > 0 || totalOverdueAssignments > 0
    )
}

private func determineOverallStatus(
    overdueCount: Int,
    alertCount: Int,
    averages: [String: Double]
) -> EducationStatus {
    // Critical: Multiple overdue or urgent alerts
    if overdueCount >= 3 || alertCount >= 2 {
        return .critical
    }

    // Warning: Some issues present
    if overdueCount > 0 || alertCount > 0 {
        return .needsAttention
    }

    // Check if any subject is below 75%
    let hasLowGrades = averages.values.contains { $0 < 75.0 }
    if hasLowGrades {
        return .needsAttention
    }

    // All good
    return .onTrack
}
```

---

## 4. Data Structures

### 4.1 Core Models

```swift
/// Student academic profile
@Model
class StudentProfile {
    var id: UUID
    var memberId: UUID  // Link to FamilyMember
    var gradeLevel: Int  // 1-12 (K = 0)
    var schoolName: String
    var schoolDistrict: String?
    var lmsConnection: LMSConnection?
    var assignments: [Assignment]
    var grades: [GradeEntry]
    var teachers: [Teacher]
    var studyPlans: [StudyPlan]
    var alerts: [EducationAlert]
    var createdDate: Date
    var updatedDate: Date

    init(id: UUID = UUID(), memberId: UUID, gradeLevel: Int, schoolName: String) {
        self.id = id
        self.memberId = memberId
        self.gradeLevel = gradeLevel
        self.schoolName = schoolName
        self.assignments = []
        self.grades = []
        self.teachers = []
        self.studyPlans = []
        self.alerts = []
        self.createdDate = Date()
        self.updatedDate = Date()
    }
}

/// LMS platform connection details
struct LMSConnection: Codable {
    var platform: LMSPlatform
    var institutionURL: String?  // For Canvas
    var refreshToken: String  // Stored in Keychain
    var tokenExpiration: Date
    var lastSyncDate: Date?
    var isActive: Bool
}

enum LMSPlatform: String, Codable {
    case googleClassroom = "Google Classroom"
    case canvas = "Canvas"
    case schoology = "Schoology"
    case blackboard = "Blackboard"
}

/// Individual assignment
@Model
class Assignment {
    var id: UUID
    var externalId: String?  // ID from LMS
    var studentId: UUID
    var title: String
    var subject: String
    var description: String?
    var dueDate: Date
    var status: AssignmentStatus
    var estimatedTime: Int  // Minutes
    var priority: Priority
    var attachments: [AssignmentAttachment]
    var completedDate: Date?
    var createdDate: Date

    init(
        id: UUID = UUID(),
        externalId: String? = nil,
        studentId: UUID,
        title: String,
        subject: String,
        description: String? = nil,
        dueDate: Date,
        status: AssignmentStatus,
        estimatedTime: Int,
        priority: Priority,
        attachments: [AssignmentAttachment] = []
    ) {
        self.id = id
        self.externalId = externalId
        self.studentId = studentId
        self.title = title
        self.subject = subject
        self.description = description
        self.dueDate = dueDate
        self.status = status
        self.estimatedTime = estimatedTime
        self.priority = priority
        self.attachments = attachments
        self.createdDate = Date()
    }
}

enum AssignmentStatus: String, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case overdue = "Overdue"
}

struct AssignmentAttachment: Codable {
    var id: UUID
    var title: String
    var url: URL
    var type: AttachmentType
}

enum AttachmentType: String, Codable {
    case pdf, document, link, video, image
}

/// Grade entry for an assignment or overall course
@Model
class GradeEntry {
    var id: UUID
    var studentId: UUID
    var subject: String
    var assignmentTitle: String
    var grade: Double  // Numeric score
    var maxPoints: Double
    var percentage: Double
    var letterGrade: String?
    var gradedDate: Date
    var feedback: String?
    var weight: Double?  // For weighted grading
    var createdDate: Date

    init(
        id: UUID = UUID(),
        studentId: UUID,
        subject: String,
        assignmentTitle: String,
        grade: Double,
        maxPoints: Double,
        percentage: Double,
        gradedDate: Date,
        feedback: String? = nil
    ) {
        self.id = id
        self.studentId = studentId
        self.subject = subject
        self.assignmentTitle = assignmentTitle
        self.grade = grade
        self.maxPoints = maxPoints
        self.percentage = percentage
        self.gradedDate = gradedDate
        self.feedback = feedback
        self.createdDate = Date()
    }
}

/// Teacher contact information
struct Teacher: Codable {
    var id: UUID
    var name: String
    var title: String  // Mr., Mrs., Ms., Dr.
    var lastName: String
    var email: String
    var phone: String?
    var subject: String
    var roomNumber: String?
    var officeHours: String?
}

/// Education alert for parents
@Model
class EducationAlert {
    var id: UUID
    var type: AlertType
    var severity: AlertSeverity
    var studentId: UUID
    var studentName: String
    var subject: String
    var title: String
    var message: String
    var actionSuggestions: [String]
    var createdDate: Date
    var readDate: Date?
    var dismissedDate: Date?
    var relatedAssignments: [UUID]

    init(
        id: UUID = UUID(),
        type: AlertType,
        severity: AlertSeverity,
        studentId: UUID,
        studentName: String,
        subject: String,
        title: String,
        message: String,
        actionSuggestions: [String],
        createdDate: Date,
        relatedAssignments: [UUID] = []
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.studentId = studentId
        self.studentName = studentName
        self.subject = subject
        self.title = title
        self.message = message
        self.actionSuggestions = actionSuggestions
        self.createdDate = createdDate
        self.relatedAssignments = relatedAssignments
    }
}

enum AlertType: String, Codable {
    case lowGrade = "Low Grade"
    case gradeDrop = "Grade Drop"
    case decliningTrend = "Declining Trend"
    case overdueWork = "Overdue Work"
    case heavyWorkload = "Heavy Workload"
    case upcomingTest = "Upcoming Test"
    case missedClass = "Missed Class"
}

enum AlertSeverity: String, Codable {
    case urgent = "Urgent"
    case warning = "Warning"
    case info = "Info"
}
```

### 4.2 Study Plan Models

```swift
/// Complete study plan for a test/exam
@Model
class StudyPlan {
    var id: UUID
    var assignmentId: UUID
    var studentId: UUID
    var subject: String
    var testDate: Date
    var totalDays: Int
    var dailyTimeMinutes: Int
    var dailySchedule: [DailyStudySchedule]
    var createdDate: Date
    var status: StudyPlanStatus

    init(
        id: UUID = UUID(),
        assignmentId: UUID,
        studentId: UUID,
        subject: String,
        testDate: Date,
        totalDays: Int,
        dailyTimeMinutes: Int,
        dailySchedule: [DailyStudySchedule],
        createdDate: Date,
        status: StudyPlanStatus
    ) {
        self.id = id
        self.assignmentId = assignmentId
        self.studentId = studentId
        self.subject = subject
        self.testDate = testDate
        self.totalDays = totalDays
        self.dailyTimeMinutes = dailyTimeMinutes
        self.dailySchedule = dailySchedule
        self.createdDate = createdDate
        self.status = status
    }
}

enum StudyPlanStatus: String, Codable {
    case active = "Active"
    case completed = "Completed"
    case abandoned = "Abandoned"
}

/// Daily study schedule within a plan
struct DailyStudySchedule: Codable {
    var dayNumber: Int
    var date: Date
    var tasks: [StudyTask]
    var pomodoroSessions: [PomodoroSession]
    var totalMinutes: Int
    var isCompleted: Bool
    var completedDate: Date?
}

/// Individual study task
struct StudyTask: Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var estimatedMinutes: Int
    var taskType: TaskType
    var dayNumber: Int
    var isCompleted: Bool = false
    var completedDate: Date?
}

enum TaskType: String, Codable {
    case review = "Review"
    case practice = "Practice"
    case memorization = "Memorization"
    case creation = "Creation"  // Creating study guides, flashcards, etc.
}

/// Pomodoro study session (25 min work, 5 min break)
struct PomodoroSession: Codable {
    var sessionNumber: Int
    var taskTitle: String
    var workMinutes: Int
    var breakMinutes: Int
    var isCompleted: Bool
    var completedDate: Date?
}
```

### 4.3 Summary & Result Models

```swift
/// Result from LMS sync operation
struct SyncResult {
    var studentId: UUID
    var platform: LMSPlatform
    var assignmentsUpdated: Int
    var gradesUpdated: Int
    var syncDate: Date
    var errors: [SyncError]

    var isSuccess: Bool {
        errors.isEmpty
    }
}

struct SyncError {
    var code: String
    var message: String
    var recoverable: Bool
}

/// Trend analysis for grades
struct TrendAnalysis {
    var subject: String
    var direction: TrendDirection
    var averageChange: Double
    var currentAverage: Double
    var previousAverage: Double
    var grades: [GradeEntry] = []
}

enum TrendDirection: String, Codable {
    case improving_significant = "Improving Significantly"
    case improving_slight = "Improving Slightly"
    case stable = "Stable"
    case declining_slight = "Declining Slightly"
    case declining_significant = "Declining Significantly"
    case insufficient_data = "Insufficient Data"
}

/// GPA calculation result (high school only)
struct GPAResult {
    var gpa: Double
    var letterGrade: String
    var breakdown: [String: Double]  // Subject -> GPA
    var totalCourses: Int
}

/// Family-wide education summary
struct FamilyEducationSummary {
    var familyId: UUID
    var generatedDate: Date
    var childSummaries: [ChildEducationSummary]
    var totalAlerts: Int
    var totalOverdueAssignments: Int
    var requiresAttention: Bool
}

/// Per-child summary
struct ChildEducationSummary {
    var studentId: UUID
    var studentName: String
    var gradeLevel: Int
    var upcomingAssignments: Int
    var overdueAssignments: Int
    var alerts: [EducationAlert]
    var subjectAverages: [String: Double]
    var overallStatus: EducationStatus
}

enum EducationStatus: String, Codable {
    case onTrack = "On Track"
    case needsAttention = "Needs Attention"
    case critical = "Critical"
}

/// Teacher email draft
struct EmailDraft {
    var to: String
    var subject: String
    var body: String
    var createdDate: Date
    var isDraft: Bool
}

/// Context for generating teacher emails
struct EmailContext {
    var studentId: UUID
    var subject: String
    var reason: EmailReason
    var parentName: String
    var previousGrade: Double?
    var currentGrade: Double?
    var numMissedAssignments: Int?
    var specificTopic: String?
    var availabilitySlots: [Date]?
}

enum EmailReason {
    case concernAboutGrades
    case missedAssignments
    case requestForHelp
    case positiveUpdate
    case scheduleConference
}
```

### 4.4 Alert Thresholds

```swift
/// Configurable alert thresholds
struct AlertThreshold {
    /// Grade below this percentage triggers urgent alert
    static let urgentGrade: Double = 70.0

    /// Grade below this percentage triggers warning
    static let warningGrade: Double = 80.0

    /// Grade drop by this many points triggers alert
    static let gradeDrop: Double = 5.0

    /// Number of overdue assignments before urgent alert
    static let overdueAssignments: Int = 2

    /// Days before test to suggest study plan
    static let upcomingTestDays: Int = 3

    /// Number of assignments in one week to trigger heavy workload alert
    static let heavyWorkloadThreshold: Int = 5
}
```

---

## 5. LMS Integration Workflows

### 5.1 Google Classroom Integration

#### Initial OAuth Flow
```
1. User taps "Connect Google Classroom" in app
2. Present Google OAuth consent screen
   - Scopes: classroom.courses.readonly, classroom.coursework.me.readonly,
             classroom.student-submissions.me.readonly
3. Receive authorization code
4. Exchange for access token + refresh token
5. Store refresh token in Keychain (encrypted)
6. Perform initial sync
7. Schedule daily sync at 4pm
```

#### Daily Sync Workflow
```
[4pm Daily Trigger]
    → For each student with Google Classroom connected:
        → Refresh OAuth token if expired
        → Call listCourses() to get all active courses
        → For each course:
            → Call listCourseWork() to get assignments
            → Call listSubmissions() to get grades
        → Map to internal Assignment/GradeEntry models
        → Save to Core Data
        → Run alert checks
        → Send notifications if issues detected
```

#### API Calls

```swift
class GoogleClassroomAPI {
    private let baseURL = "https://classroom.googleapis.com/v1"

    func listCourses(accessToken: String) async throws -> [Course] {
        let url = URL(string: "\(baseURL)/courses")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CoursesResponse.self, from: data)
        return response.courses
    }

    func listCourseWork(courseId: String, accessToken: String) async throws -> [CourseWork] {
        let url = URL(string: "\(baseURL)/courses/\(courseId)/courseWork")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CourseWorkResponse.self, from: data)
        return response.courseWork
    }

    func listSubmissions(
        courseId: String,
        courseWorkId: String,
        accessToken: String
    ) async throws -> [StudentSubmission] {
        let url = URL(string: "\(baseURL)/courses/\(courseId)/courseWork/\(courseWorkId)/studentSubmissions")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SubmissionsResponse.self, from: data)
        return response.studentSubmissions
    }
}
```

### 5.2 Canvas LMS Integration

#### Initial API Token Setup
```
1. User provides Canvas institution URL (e.g., "https://canvas.school.edu")
2. User generates API token from Canvas account settings
3. User pastes token into OpenClaw
4. Store token in Keychain (encrypted)
5. Validate token by calling /api/v1/users/self
6. Perform initial sync
7. Schedule daily sync at 4pm
```

#### Daily Sync Workflow
```
[4pm Daily Trigger]
    → For each student with Canvas connected:
        → Validate API token (no expiration, but check if revoked)
        → Call /api/v1/courses to get enrolled courses
        → For each course:
            → Call /api/v1/courses/{id}/assignments
            → Call /api/v1/courses/{id}/students/submissions
        → Map to internal models
        → Save to Core Data
        → Run alert checks
```

#### API Calls

```swift
class CanvasAPI {
    private let baseURL: String
    private let apiToken: String

    init(baseURL: String, apiToken: String) {
        self.baseURL = baseURL
        self.apiToken = apiToken
    }

    func listCourses(enrollmentState: EnrollmentState = .active) async throws -> [CanvasCourse] {
        let url = URL(string: "\(baseURL)/api/v1/courses?enrollment_state=\(enrollmentState.rawValue)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([CanvasCourse].self, from: data)
    }

    func listAssignments(courseId: String) async throws -> [CanvasAssignment] {
        let url = URL(string: "\(baseURL)/api/v1/courses/\(courseId)/assignments")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([CanvasAssignment].self, from: data)
    }

    func listSubmissions(
        courseId: String,
        assignmentIds: [String]
    ) async throws -> [CanvasSubmission] {
        var allSubmissions: [CanvasSubmission] = []

        for assignmentId in assignmentIds {
            let url = URL(string: "\(baseURL)/api/v1/courses/\(courseId)/assignments/\(assignmentId)/submissions/self")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let submission = try JSONDecoder().decode(CanvasSubmission.self, from: data)
            allSubmissions.append(submission)
        }

        return allSubmissions
    }
}

enum EnrollmentState: String {
    case active, completed, invited
}
```

---

## 6. Grade Monitoring & Alerts

### 6.1 Alert Trigger Logic

```swift
class GradeMonitoringService {
    /// Main entry point: checks all students for grade alerts
    func monitorAllStudents(familyId: UUID) async throws -> [EducationAlert] {
        let family = try await fetchFamily(familyId)
        let students = family.members.filter { $0.role == .child && $0.schoolInfo != nil }

        var allAlerts: [EducationAlert] = []

        for student in students {
            let alerts = try await checkGradeAlerts(studentId: student.id)
            allAlerts.append(contentsOf: alerts)
        }

        // Send notifications
        for alert in allAlerts where alert.severity == .urgent {
            await NotificationManager.shared.sendNotification(
                title: alert.title,
                body: alert.message,
                category: "education_alert"
            )
        }

        return allAlerts
    }
}
```

### 6.2 Alert Types & Thresholds

#### Low Grade Alert
- **Trigger**: Grade < 70%
- **Severity**: Urgent
- **Actions**: Tutoring, teacher meeting, study plan

#### Grade Drop Alert
- **Trigger**: Drop > 5 points from previous assignment
- **Severity**: Warning
- **Actions**: Review feedback, increase study time

#### Declining Trend Alert
- **Trigger**: Average of last 3 assignments < average of previous 3 by >5 points
- **Severity**: Warning
- **Actions**: Teacher meeting, assess study habits

#### Overdue Work Alert
- **Trigger**: 2+ overdue assignments
- **Severity**: Urgent
- **Actions**: Create catch-up schedule, email teachers

#### Heavy Workload Alert
- **Trigger**: 5+ assignments due in next 7 days
- **Severity**: Info
- **Actions**: Create daily schedule, start early

#### Upcoming Test Alert
- **Trigger**: Test/exam due in ≤3 days
- **Severity**: Info
- **Actions**: Generate study plan

### 6.3 Notification Delivery

```swift
class NotificationManager {
    func sendNotification(title: String, body: String, category: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Notification error: \(error)")
        }
    }
}
```

---

## 7. Study Plan Generation

### 7.1 Algorithm Overview

The study plan generator uses:
1. **Subject-Specific Templates**: Different approaches for Math, Science, History, English
2. **Spaced Repetition**: Review concepts multiple times across days
3. **Pomodoro Technique**: 25-min focused sessions with 5-min breaks
4. **Progressive Difficulty**: Start with review, move to practice, end with light review

### 7.2 Time Allocation by Subject

| Subject | Review % | Practice % | Memorization % | Final Review % |
|---------|----------|------------|----------------|----------------|
| Math/STEM | 25% | 55% | 10% | 10% |
| Science | 25% | 25% | 30% | 20% |
| History | 30% | 15% | 35% | 20% |
| English | 35% | 30% | 20% | 15% |
| Other | 40% | 30% | 15% | 15% |

### 7.3 Sample Study Plans

#### 5-Day Math Test Plan (45 min/day = 225 min total)

**Day 1 (45 min)**: Review
- 25 min: Read through class notes chapters 5-7
- 5 min: Break
- 15 min: Create formula sheet

**Day 2 (45 min)**: Practice - Easy
- 25 min: Complete 10 basic problems
- 5 min: Break
- 15 min: Check answers, understand mistakes

**Day 3 (45 min)**: Practice - Medium
- 25 min: Complete 10 medium problems
- 5 min: Break
- 15 min: Focus on problem types you struggled with

**Day 4 (45 min)**: Practice - Hard
- 25 min: Attempt 5-8 challenging problems
- 5 min: Break
- 15 min: Review solutions thoroughly

**Day 5 (30 min)**: Final Review
- 15 min: Quick review of formula sheet
- 10 min: Attempt 2-3 mixed problems
- 5 min: Confidence-building positive self-talk

#### 3-Day History Test Plan (60 min/day = 180 min total)

**Day 1 (60 min)**: Reading & Summarizing
- 25 min: Chapter 8 summary
- 5 min: Break
- 25 min: Chapter 9 summary
- 5 min: Break

**Day 2 (60 min)**: Flashcards & Timeline
- 25 min: Create 25 flashcards (key terms, people, dates)
- 5 min: Break
- 25 min: Create visual timeline of events
- 5 min: Review

**Day 3 (60 min)**: Practice & Review
- 25 min: Study flashcards
- 5 min: Break
- 25 min: Practice essay outline
- 5 min: Final review of timeline

---

## 8. Multi-Child Coordination

### 8.1 Family Dashboard

```
Daily 4pm Homework Check Summary

Emma (Grade 3)
✓ On Track
- 2 assignments due tomorrow
- Reading: 20 minutes
- Math: Worksheet pg 45
- No alerts

Jake (Grade 7)
⚠️ Needs Attention
- 1 overdue assignment
- Math: Chapter 6 review (due yesterday)
- Science grade dropped from 85% to 78%
- Suggested: Email Math teacher, create Science study plan

Anika (Grade 10)
⚠️ Heavy Week
- 6 assignments due this week
- Biology test Friday (study plan generated)
- English essay due Thursday
- Total est. time: 8 hours

Family Action Items:
1. Help Jake catch up on Math homework tonight
2. Email Jake's Science teacher
3. Review Anika's study plan for Biology test
```

### 8.2 Conflict Detection

```swift
func detectSchedulingConflicts(familyId: UUID) async throws -> [ScheduleConflict] {
    let summary = try await generateFamilyEducationSummary(familyId: familyId)
    var conflicts: [ScheduleConflict] = []

    // Check for same-day major events across children
    var eventsByDate: [Date: [StudentEvent]] = [:]

    for child in summary.childSummaries {
        let assignments = try await getUpcomingAssignments(
            studentId: child.studentId,
            daysAhead: 7
        )

        for assignment in assignments {
            let dateKey = Calendar.current.startOfDay(for: assignment.dueDate)
            let event = StudentEvent(
                studentId: child.studentId,
                studentName: child.studentName,
                title: assignment.title,
                subject: assignment.subject,
                type: assignment.title.lowercased().contains("test") ? .test : .assignment,
                date: assignment.dueDate,
                estimatedTime: assignment.estimatedTime
            )

            eventsByDate[dateKey, default: []].append(event)
        }
    }

    // Find days with multiple major events
    for (date, events) in eventsByDate where events.count >= 2 {
        let totalTime = events.map { $0.estimatedTime }.reduce(0, +)

        if totalTime > 180 { // More than 3 hours
            conflicts.append(ScheduleConflict(
                date: date,
                events: events,
                totalEstimatedTime: totalTime,
                severity: totalTime > 240 ? .high : .medium,
                suggestion: "Consider starting work early or requesting deadline extension"
            ))
        }
    }

    return conflicts
}

struct StudentEvent {
    var studentId: UUID
    var studentName: String
    var title: String
    var subject: String
    var type: EventType
    var date: Date
    var estimatedTime: Int
}

enum EventType {
    case test, assignment, project
}

struct ScheduleConflict {
    var date: Date
    var events: [StudentEvent]
    var totalEstimatedTime: Int
    var severity: ConflictSeverity
    var suggestion: String
}

enum ConflictSeverity {
    case low, medium, high
}
```

---

## 9. Example Scenarios

### Scenario 1: 3rd Grader - Daily Homework Check

**Context**: Emma, grade 3, has Google Classroom connected

**4pm Trigger**:
```swift
// System runs syncGoogleClassroom(studentId: emma.id)
let syncResult = try await syncGoogleClassroom(studentId: emma.id)
// → 2 assignments found

let assignments = try await getUpcomingAssignments(studentId: emma.id, daysAhead: 1)
// → Reading: 20 min + Math worksheet

let prioritized = prioritizeAssignments(assignments)
// → Both marked as HIGH priority (due tomorrow)
```

**Parent Notification**:
```
Emma's Homework for Tonight

📚 Reading (20 minutes)
⏱️ Est. time: 20 min
📅 Due: Tomorrow

✏️ Math Worksheet - Page 45
⏱️ Est. time: 15 min
📅 Due: Tomorrow

Total time needed: 35 minutes
Suggested start: 5:00 PM
```

### Scenario 2: 7th Grader - Grade Drop Alert

**Context**: Jake, grade 7, recent Science grade dropped from 85% to 78%

**Weekly Grade Sync**:
```swift
let syncResult = try await syncCanvas(studentId: jake.id)
// → New grade: Science Lab Report = 78%

let alerts = try await checkGradeAlerts(studentId: jake.id)
// → Grade drop detected: 85% → 78% (7 point drop)

// Alert generated
EducationAlert(
    type: .gradeDrop,
    severity: .warning,
    studentName: "Jake",
    subject: "Science",
    title: "Jake's Science grade dropped 7 points",
    message: "From 85% to 78% on Lab Report",
    actionSuggestions: [
        "Review lab report feedback",
        "Email teacher to discuss",
        "Increase study time for Science"
    ]
)
```

**Parent Notification**:
```
⚠️ Grade Alert: Jake - Science

Jake's Science grade dropped from 85% to 78% on the recent Lab Report.

Suggested Actions:
• Review the teacher's feedback on the lab report
• Email Ms. Johnson to discuss areas for improvement
• Increase study time for upcoming Science assignments

[Draft Email to Teacher] [View Feedback] [Dismiss]
```

### Scenario 3: 10th Grader - Biology Test Study Plan

**Context**: Anika, grade 10, has Biology test in 5 days

**Test Detected**:
```swift
let assignments = try await getUpcomingAssignments(studentId: anika.id, daysAhead: 7)
// → "Biology Chapter 5-7 Test" found, due in 5 days

let alerts = try await checkAssignmentAlerts(studentId: anika.id)
// → Upcoming test alert generated

// User requests: "Create study plan for Biology test"
let studyPlan = try await generateStudyPlan(
    assignmentId: biologyTest.id,
    availableDays: 5,
    dailyTimeMinutes: 45
)
```

**Generated Plan**:
```
Biology Test Study Plan (5 days)
Test Date: Friday, Feb 7

Day 1 (Tuesday) - 45 min
├─ Review class notes chapters 5-7 (25 min)
├─ Break (5 min)
└─ Redraw key cell diagrams (15 min)

Day 2 (Wednesday) - 45 min
├─ Create vocabulary flashcards (25 min)
│  • 25-30 terms from chapters
├─ Break (5 min)
└─ Begin memorizing flashcards (15 min)

Day 3 (Thursday) - 45 min
├─ Practice problems from textbook (25 min)
│  • 15-20 end-of-chapter questions
├─ Break (5 min)
└─ Review flashcards (15 min)

Day 4 (Friday) - 45 min
├─ Review lab procedures (25 min)
│  • Recent lab findings and conclusions
├─ Break (5 min)
└─ Practice flashcards with parent (15 min)

Day 5 (Saturday morning) - 30 min
├─ Quick review of flashcards (15 min)
└─ Review problem-solving strategies (15 min)

Total study time: 3 hours 45 minutes
[Start Plan] [Modify Schedule] [Share with Parent]
```

### Scenario 4: Multi-Child Family - Busy Week

**Context**: Family with 3 kids, all have heavy workloads this week

**Family Summary Generation**:
```swift
let summary = try await generateFamilyEducationSummary(familyId: family.id)

// Conflict detection
let conflicts = try await detectSchedulingConflicts(familyId: family.id)
// → Thursday has 3 major events across kids
```

**Parent Dashboard**:
```
Family Education Summary
Week of Feb 2-8

Emma (Grade 3) - ✓ On Track
• 4 assignments this week (manageable)
• No alerts

Jake (Grade 7) - ⚠️ Needs Attention
• 1 overdue Math assignment
• Science grade dropped to 78%
• 5 assignments due this week

Anika (Grade 10) - ⚠️ Heavy Week
• Biology test Friday
• English essay Thursday
• 6 total assignments
• Est. 8 hours of work

⚠️ Schedule Conflict Detected:
Thursday, Feb 6
• Jake: Social Studies project due
• Anika: English essay due
• Total time needed: 4+ hours

Suggestion: Have Anika start essay over weekend,
            Help Jake with project Tuesday/Wednesday

[View Detailed Schedule] [Email Teachers] [Adjust Plans]
```

---

## 10. API Integrations

### 10.1 Google Classroom API

**Base URL**: `https://classroom.googleapis.com/v1`

**Authentication**: OAuth 2.0

**Required Scopes**:
- `https://www.googleapis.com/auth/classroom.courses.readonly`
- `https://www.googleapis.com/auth/classroom.coursework.me.readonly`
- `https://www.googleapis.com/auth/classroom.student-submissions.me.readonly`

**Key Endpoints**:
```
GET /courses
GET /courses/{courseId}/courseWork
GET /courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions
```

**Rate Limits**: 60 requests/min per user

**Error Handling**: See Section 12

### 10.2 Canvas LMS API

**Base URL**: Institution-specific (e.g., `https://canvas.school.edu/api/v1`)

**Authentication**: API Token (Bearer)

**Key Endpoints**:
```
GET /courses?enrollment_state=active
GET /courses/{id}/assignments
GET /courses/{id}/assignments/{assignment_id}/submissions/self
GET /users/self/courses
```

**Rate Limits**: Varies by institution (typically 3000 requests/hour)

**Error Handling**: See Section 12

### 10.3 Khan Academy API (Optional - Supplemental Learning)

**Base URL**: `https://www.khanacademy.org/api/v1`

**Authentication**: OAuth 1.0

**Use Cases**:
- Recommend practice exercises for weak areas
- Track supplemental learning progress

**Key Endpoints**:
```
GET /user/exercises
GET /topic/{topic_slug}
POST /user/exercises/{exercise_name}/problems/{problem_number}/attempt
```

---

## 11. Test Cases

### 11.1 LMS Synchronization Tests

#### TC-E001: Google Classroom - Successful Sync
**Given**: Student has Google Classroom connected with valid OAuth token
**When**: Daily 4pm sync triggers
**Then**:
- All active courses are fetched
- Assignments from last 30 days are imported
- Grades are updated in Core Data
- SyncResult.isSuccess == true

#### TC-E002: Google Classroom - Expired Token
**Given**: OAuth refresh token is expired
**When**: Sync attempts to run
**Then**:
- Token refresh is attempted
- If refresh fails, user is notified to re-authenticate
- Sync is paused until re-authentication
- Error logged: LMSError.authenticationExpired

#### TC-E003: Canvas - Invalid API Token
**Given**: User's Canvas API token has been revoked
**When**: Sync attempts to run
**Then**:
- API returns 401 Unauthorized
- User notified: "Please update your Canvas token"
- Sync status marked as failed
- Previous data remains unchanged

#### TC-E004: Canvas - Network Timeout
**Given**: Network is slow/unavailable
**When**: Sync attempts to fetch assignments
**Then**:
- Retry 3 times with exponential backoff (1s, 2s, 4s)
- If all retries fail, log error and schedule retry in 1 hour
- User not notified (silent failure, will retry)

#### TC-E005: Duplicate Assignment Prevention
**Given**: Same assignment exists in Core Data with externalId
**When**: Sync fetches updated assignment from LMS
**Then**:
- Existing assignment is updated (not duplicated)
- Only changed fields are modified
- updatedDate timestamp is refreshed

### 11.2 Grade Monitoring Tests

#### TC-E006: Low Grade Alert - Below 70%
**Given**: Student receives grade of 68% on Math quiz
**When**: Grade sync completes
**Then**:
- EducationAlert created with severity: .urgent
- Parent receives push notification
- Alert appears in app with action suggestions

#### TC-E007: Grade Drop Alert - 7 Point Drop
**Given**: Student's Science grade drops from 85% to 78%
**When**: New grade is synced
**Then**:
- Alert generated with type: .gradeDrop, severity: .warning
- Previous grade and current grade shown in alert message
- Action suggestions include "Review feedback" and "Email teacher"

#### TC-E008: Declining Trend Detection
**Given**: Student has grades: [88, 85, 82] then [78, 75, 73]
**When**: detectGradeTrends() is called
**Then**:
- Trend direction: .declining_significant
- Average change: ~10 points
- Alert generated with severity: .warning

#### TC-E009: False Positive - Single Low Grade
**Given**: Student has consistent 85-90% grades, then one 72% grade
**When**: Trend analysis runs
**Then**:
- Low grade alert IS generated (72% < 75%)
- Declining trend alert NOT generated (need 3+ consecutive declines)
- System suggests: "Review this assignment, monitor next grade"

#### TC-E010: No Alert - Grade Improving
**Given**: Student's grades improve from [70, 75, 80] to [82, 85, 88]
**When**: Trend analysis and alert checks run
**Then**:
- No alerts generated
- Trend direction: .improving_significant
- Optional positive notification: "Great progress in Math!"

### 11.3 Assignment Management Tests

#### TC-E011: Prioritization - Overdue Marked Urgent
**Given**: Assignment due date was yesterday
**When**: prioritizeAssignments() is called
**Then**:
- Assignment.status == .overdue
- Assignment.priority == .urgent
- Assignment appears first in sorted list

#### TC-E012: Prioritization - Due Tomorrow vs. Due Next Week
**Given**: Two assignments: A (due tomorrow), B (due in 5 days)
**When**: prioritizeAssignments() is called
**Then**:
- A.priority == .high
- B.priority == .medium
- Sorted order: [A, B]

#### TC-E013: Time Estimation - Elementary Essay
**Given**: Assignment title contains "essay", student is grade 3
**When**: estimateTimeRequired() is called
**Then**:
- Base time: 15 min (elementary)
- Type multiplier: 2.0 (essay)
- Estimated time: 30 min

#### TC-E014: Time Estimation - High School Math
**Given**: Assignment title contains "math", student is grade 11
**When**: estimateTimeRequired() is called
**Then**:
- Base time: 45 min (high school)
- Type multiplier: 1.5 (math)
- Estimated time: 67 min

#### TC-E015: Mark Complete - On Time
**Given**: Assignment due Feb 5, completed Feb 4
**When**: markAssignmentComplete() is called
**Then**:
- status changed to .completed
- completedDate set to current time
- Analytics event logged with on_time: true

### 11.4 Study Plan Generation Tests

#### TC-E016: Math Test - 5 Day Plan
**Given**: Biology test in 5 days, student has 45 min/day
**When**: generateStudyPlan() is called
**Then**:
- 5 daily schedules created
- Total time: ~225 min distributed across days
- Tasks include: Review notes, Practice (easy/medium/hard), Final review
- Pomodoro sessions generated (25 min work, 5 min break)

#### TC-E017: Insufficient Prep Time
**Given**: Test is tomorrow (1 day)
**When**: generateStudyPlan() with availableDays: 1
**Then**:
- Plan still generated but marked as "Cramming"
- Condensed tasks: Quick review + practice problems
- Warning shown: "Limited time available, focus on key concepts"

#### TC-E018: Study Plan - History Essay
**Given**: History essay due in 3 days
**When**: generateStudyPlan() is called
**Then**:
- Day 1: Read chapters, create outline
- Day 2: Write first draft
- Day 3: Revise and proofread
- Tasks emphasize writing over memorization

#### TC-E019: Pomodoro Session Calculation
**Given**: Task estimated at 60 minutes
**When**: convertToPomodoroSessions() is called
**Then**:
- 3 Pomodoro sessions created (60 / 25 = 2.4, rounded up to 3)
- Session 1: 25 min work, 5 min break
- Session 2: 25 min work, 5 min break
- Session 3: 25 min work, 15 min break (longer final break)

#### TC-E020: Study Plan Completion Tracking
**Given**: Student completes Day 1 tasks
**When**: User marks day as complete
**Then**:
- DailyStudySchedule.isCompleted = true
- completedDate set
- Progress shown: "1/5 days completed"
- Next day's tasks highlighted

### 11.5 Multi-Child Coordination Tests

#### TC-E021: Family Summary - Mixed Status
**Given**: Emma (on track), Jake (1 overdue), Anika (heavy week)
**When**: generateFamilyEducationSummary() is called
**Then**:
- 3 child summaries generated
- Emma.overallStatus == .onTrack
- Jake.overallStatus == .needsAttention
- Anika.overallStatus == .needsAttention
- totalOverdueAssignments == 1

#### TC-E022: Schedule Conflict Detection
**Given**: Jake has test Thursday, Anika has essay due Thursday (total 5+ hours)
**When**: detectSchedulingConflicts() is called
**Then**:
- Conflict detected for Thursday
- severity == .high
- Suggestion: "Start work early or request extension"

#### TC-E023: No Children with School Info
**Given**: Family has 2 children but neither has schoolInfo set
**When**: generateFamilyEducationSummary() is called
**Then**:
- childSummaries array is empty
- totalAlerts == 0
- requiresAttention == false
- No errors thrown

#### TC-E024: Single Child Family
**Given**: Family has 1 child with active LMS
**When**: Family summary generated
**Then**:
- 1 child summary
- Conflict detection skipped (need 2+ children)
- Summary still shows alerts and assignments

### 11.6 Alert Generation Tests

#### TC-E025: Overdue Work Alert Threshold
**Given**: Student has 2 overdue assignments
**When**: checkAssignmentAlerts() is called
**Then**:
- Alert generated: "2 overdue assignments"
- Severity: .urgent
- Action: "Create catch-up schedule"

#### TC-E026: Heavy Workload Alert
**Given**: Student has 6 assignments due in next 7 days
**When**: checkAssignmentAlerts() is called
**Then**:
- Alert generated: "Busy week ahead: 6 assignments"
- Total estimated time calculated and shown
- Severity: .info
- Suggestion: "Create daily schedule"

#### TC-E027: Upcoming Test Alert
**Given**: Math test due in 3 days
**When**: checkAssignmentAlerts() is called
**Then**:
- Alert generated: "Math Test in 3 days"
- Severity: .info
- Action suggestion: "Generate study plan"

#### TC-E028: Alert De-duplication
**Given**: Same grade drop alert exists from yesterday
**When**: New sync runs and tries to create duplicate alert
**Then**:
- Duplicate not created
- Existing alert's updatedDate refreshed
- Alert count remains accurate

#### TC-E029: Alert Dismissal
**Given**: User dismisses a low grade alert
**When**: Alert is marked dismissed
**Then**:
- dismissedDate set to current time
- Alert no longer appears in active alerts list
- Alert remains in history for analytics

#### TC-E030: Alert Expiration
**Given**: Alert was created 30 days ago
**When**: Alert list is fetched
**Then**:
- Expired alerts auto-archived
- Only recent (<30 days) alerts shown
- Historical data retained for trend analysis

---

## 12. Error Handling

### 12.1 Network Errors

#### Google Classroom API Errors

```swift
enum GoogleClassroomError: Error {
    case authenticationFailed
    case tokenExpired
    case networkTimeout
    case rateLimitExceeded
    case courseNotFound
    case permissionDenied
    case unknownError(String)
}

extension GoogleClassroomAPI {
    func handleAPIError(_ error: Error) -> LMSError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .networkTimeout(retryAfter: 60)
            case .notConnectedToInternet:
                return .noConnection
            case .cannotFindHost:
                return .serverUnreachable
            default:
                return .networkError(urlError.localizedDescription)
            }
        }

        // HTTP status code errors
        if let httpResponse = (error as NSError).userInfo["response"] as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401:
                return .authenticationExpired
            case 403:
                return .permissionDenied
            case 429:
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                return .rateLimitExceeded(retryAfter: Int(retryAfter ?? "60") ?? 60)
            case 500...599:
                return .serverError(code: httpResponse.statusCode)
            default:
                return .unknownError(error.localizedDescription)
            }
        }

        return .unknownError(error.localizedDescription)
    }
}
```

#### Canvas API Errors

```swift
enum CanvasError: Error {
    case invalidToken
    case institutionNotFound
    case courseAccessDenied
    case assignmentNotFound
    case serverError(Int)
    case unknownError(String)
}

extension CanvasAPI {
    func handleAPIError(_ error: Error) -> LMSError {
        if let httpResponse = (error as NSError).userInfo["response"] as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401:
                return .invalidAPIToken
            case 404:
                return .resourceNotFound
            case 500...599:
                return .serverError(code: httpResponse.statusCode)
            default:
                return .unknownError(error.localizedDescription)
            }
        }

        return .unknownError(error.localizedDescription)
    }
}
```

### 12.2 Error Recovery Strategies

```swift
class LMSSyncManager {
    private let maxRetries = 3
    private let retryDelays = [1.0, 2.0, 4.0] // Exponential backoff (seconds)

    func syncWithRetry(studentId: UUID) async throws -> SyncResult {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                let result = try await performSync(studentId: studentId)
                return result
            } catch let error as LMSError {
                lastError = error

                switch error {
                case .networkTimeout, .noConnection, .serverError:
                    // Retryable errors
                    if attempt < maxRetries - 1 {
                        let delay = retryDelays[attempt]
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }

                case .authenticationExpired, .invalidAPIToken:
                    // Non-retryable - user action required
                    await notifyUserToReauthenticate(studentId: studentId)
                    throw error

                case .permissionDenied:
                    // Non-retryable - missing scopes
                    await notifyUserOfPermissionIssue(studentId: studentId)
                    throw error

                case .rateLimitExceeded(let retryAfter):
                    // Wait and retry
                    try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                    continue

                default:
                    throw error
                }
            }
        }

        // All retries failed
        throw lastError ?? LMSError.unknownError("Sync failed after \(maxRetries) attempts")
    }

    private func notifyUserToReauthenticate(studentId: UUID) async {
        await NotificationManager.shared.sendNotification(
            title: "Re-authentication Required",
            body: "Please reconnect your student's LMS account in Settings",
            category: "lms_error"
        )
    }

    private func notifyUserOfPermissionIssue(studentId: UUID) async {
        await NotificationManager.shared.sendNotification(
            title: "Permission Issue",
            body: "OpenClaw needs additional permissions to access grades. Please reconnect the account.",
            category: "lms_error"
        )
    }
}
```

### 12.3 Data Consistency Errors

```swift
enum DataConsistencyError: Error {
    case duplicateAssignment
    case orphanedGrade(gradeId: UUID)
    case invalidStudentId
    case missingRequiredField(String)
}

class DataValidator {
    func validateAssignment(_ assignment: Assignment) throws {
        guard !assignment.title.isEmpty else {
            throw DataConsistencyError.missingRequiredField("title")
        }

        guard !assignment.subject.isEmpty else {
            throw DataConsistencyError.missingRequiredField("subject")
        }

        guard assignment.dueDate > Date(timeIntervalSince1970: 0) else {
            throw DataConsistencyError.missingRequiredField("valid dueDate")
        }
    }

    func validateGradeEntry(_ grade: GradeEntry) throws {
        guard grade.maxPoints > 0 else {
            throw DataConsistencyError.missingRequiredField("maxPoints must be > 0")
        }

        guard grade.grade <= grade.maxPoints else {
            throw DataConsistencyError.missingRequiredField("grade cannot exceed maxPoints")
        }

        guard (0...100).contains(grade.percentage) else {
            throw DataConsistencyError.missingRequiredField("percentage must be 0-100")
        }
    }

    func cleanupOrphanedData() async throws {
        let context = CoreDataManager.shared.viewContext

        // Find grades without corresponding student
        let allGrades = try context.fetch(GradeEntry.fetchRequest())

        for grade in allGrades {
            let studentExists = try await fetchStudentProfile(grade.studentId) != nil

            if !studentExists {
                context.delete(grade)
                print("Deleted orphaned grade: \(grade.id)")
            }
        }

        try context.save()
    }
}
```

### 12.4 User-Facing Error Messages

```swift
struct UserFriendlyErrorMessage {
    static func message(for error: LMSError) -> (title: String, body: String, action: String?) {
        switch error {
        case .authenticationExpired:
            return (
                title: "Sign In Required",
                body: "Your LMS connection has expired. Please sign in again to continue syncing assignments and grades.",
                action: "Reconnect Account"
            )

        case .networkTimeout, .noConnection:
            return (
                title: "Connection Issue",
                body: "We couldn't connect to your school's system. Check your internet connection and try again.",
                action: "Retry"
            )

        case .rateLimitExceeded(let retryAfter):
            return (
                title: "Too Many Requests",
                body: "We're syncing too frequently. Automatic retry in \(retryAfter) seconds.",
                action: nil
            )

        case .permissionDenied:
            return (
                title: "Permission Needed",
                body: "OpenClaw needs permission to access grades and assignments. Please reconnect and grant access.",
                action: "Grant Permissions"
            )

        case .serverError(let code):
            return (
                title: "School System Error",
                body: "Your school's system is temporarily unavailable (Error \(code)). We'll retry automatically.",
                action: nil
            )

        case .invalidAPIToken:
            return (
                title: "Invalid Credentials",
                body: "Your LMS credentials are no longer valid. Please update your API token in Settings.",
                action: "Update Token"
            )

        default:
            return (
                title: "Sync Error",
                body: "Something went wrong. We'll try again soon.",
                action: "Contact Support"
            )
        }
    }
}
```

### 12.5 Fallback Behavior

```swift
class EducationSkillFallbackHandler {
    /// If sync fails, use cached data with staleness indicator
    func getAssignmentsWithFallback(studentId: UUID) async throws -> (assignments: [Assignment], isCached: Bool) {
        do {
            // Try to sync first
            _ = try await syncGoogleClassroom(studentId: studentId)
            let assignments = try await getUpcomingAssignments(studentId: studentId)
            return (assignments, false)
        } catch {
            // Fallback to cached data
            let cachedAssignments = try await getUpcomingAssignments(studentId: studentId)

            if cachedAssignments.isEmpty {
                throw EducationError.noDataAvailable
            }

            return (cachedAssignments, true)
        }
    }

    /// If grade trend analysis fails, return simple average
    func getGradeTrendWithFallback(studentId: UUID, subject: String) async -> String {
        do {
            let trend = try await detectGradeTrends(studentId: studentId, subject: subject)
            return trend.direction.rawValue
        } catch {
            // Fallback: just show current average
            let grades = try? await getRecentGrades(studentId: studentId, subject: subject, limit: 3)

            guard let grades = grades, !grades.isEmpty else {
                return "No data available"
            }

            let average = grades.map { $0.percentage }.reduce(0, +) / Double(grades.count)
            return "Current average: \(Int(average))%"
        }
    }
}
```

---

## 13. Implementation Checklist

### Phase 1: Foundation (Week 1-2)
- [ ] Define all data models (StudentProfile, Assignment, GradeEntry, etc.)
- [ ] Set up Core Data schema with migrations
- [ ] Implement Keychain storage for API tokens
- [ ] Create base LMS API client classes

### Phase 2: Google Classroom Integration (Week 3-4)
- [ ] Implement OAuth 2.0 flow
- [ ] Build GoogleClassroomAPI wrapper
- [ ] Create syncGoogleClassroom() function
- [ ] Test with real Google Classroom accounts
- [ ] Handle token refresh logic

### Phase 3: Canvas Integration (Week 5)
- [ ] Implement Canvas API token setup
- [ ] Build CanvasAPI wrapper
- [ ] Create syncCanvas() function
- [ ] Test with real Canvas accounts

### Phase 4: Assignment Management (Week 6)
- [ ] Implement getUpcomingAssignments()
- [ ] Implement prioritizeAssignments()
- [ ] Implement estimateTimeRequired()
- [ ] Implement markAssignmentComplete()
- [ ] Build assignment list UI

### Phase 5: Grade Monitoring (Week 7)
- [ ] Implement getRecentGrades()
- [ ] Implement detectGradeTrends()
- [ ] Implement calculateGPA() for high school
- [ ] Build grade history UI with charts

### Phase 6: Alert System (Week 8)
- [ ] Implement checkGradeAlerts()
- [ ] Implement checkAssignmentAlerts()
- [ ] Create notification delivery system
- [ ] Build alert management UI

### Phase 7: Study Plans (Week 9)
- [ ] Implement generateStudyPlan()
- [ ] Create subject-specific templates
- [ ] Implement Pomodoro session generation
- [ ] Build study plan UI with progress tracking

### Phase 8: Multi-Child Coordination (Week 10)
- [ ] Implement generateFamilyEducationSummary()
- [ ] Implement detectSchedulingConflicts()
- [ ] Build family dashboard UI
- [ ] Test with multi-child scenarios

### Phase 9: Teacher Communication (Week 11)
- [ ] Implement draftTeacherEmail()
- [ ] Create email templates for different scenarios
- [ ] Build email preview and editing UI
- [ ] Integrate with Mail app

### Phase 10: Testing & Polish (Week 12)
- [ ] Write 30+ unit tests (all test cases from Section 11)
- [ ] Perform error handling testing
- [ ] Test with simulated families
- [ ] Performance optimization

---

## 14. Future Enhancements

1. **AI-Powered Insights**
   - Predict grade trends 2-3 weeks ahead
   - Suggest optimal study times based on past performance
   - Identify learning style from assignment patterns

2. **Gamification**
   - Achievement badges for completing assignments on time
   - Study streaks (e.g., "5 days of focused Pomodoro sessions")
   - Leaderboard for siblings (opt-in, positive framing)

3. **Teacher Portal**
   - Allow teachers to see parent engagement
   - Direct messaging within app
   - Shared progress reports

4. **Tutoring Integration**
   - Connect with local tutors
   - Schedule tutoring sessions from app
   - Track tutoring effectiveness on grades

5. **College Prep Module (High School)**
   - SAT/ACT prep tracking
   - College application deadlines
   - Scholarship opportunity alerts

---

## Conclusion

This atomic function breakdown provides a complete, production-ready specification for implementing the Education skill in OpenClaw. Swift developers can use this document to:

- Understand exact function signatures and return types
- Implement LMS integrations with proper error handling
- Build deterministic alert systems with clear thresholds
- Generate intelligent study plans for K-12 students
- Coordinate academic management across multiple children

All functions are designed to work with the on-device AI models (Gemma 3n for chat, FunctionGemma for tool calls) as specified in the main PRD. The skill prioritizes privacy (OAuth tokens in Keychain), reliability (retry logic with exponential backoff), and user experience (proactive 4pm homework checks, actionable alerts).

**Next Steps**: Begin Phase 1 implementation, starting with Core Data schema and basic LMS API clients.

---

**Document Version**: 1.0
**Last Updated**: February 2, 2026
**Maintainer**: OpenClaw Engineering Team
