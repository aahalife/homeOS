import Foundation

/// Education Skill - Homework tracking, grades, study plans
final class EducationSkill {
    private let classroomAPI = GoogleClassroomAPI()
    private let persistence = PersistenceController.shared
    private let logger = AppLogger.shared

    // MARK: - Assignments

    func getUpcomingAssignments(family: Family, personName: String? = nil) async -> [Assignment] {
        let children = family.children
        guard !children.isEmpty else { return [] }

        var allAssignments: [Assignment] = []

        for child in children {
            if let name = personName, !child.name.lowercased().contains(name.lowercased()) {
                continue
            }

            // Try Google Classroom first
            if classroomAPI.isAuthenticated {
                do {
                    let courses = try await classroomAPI.listCourses()
                    for course in courses {
                        guard let courseId = course.id else { continue }
                        let courseWork = try await classroomAPI.listCourseWork(courseId: courseId)
                        let assignments = classroomAPI.toAssignments(courseWork: courseWork, studentId: child.id)
                        allAssignments.append(contentsOf: assignments)
                    }
                } catch {
                    logger.warning("Google Classroom fetch failed: \(error.localizedDescription)")
                }
            }

            // Fallback to stub data
            if allAssignments.isEmpty {
                allAssignments.append(contentsOf: StubEducationData.sampleAssignments(for: child.id))
            }
        }

        // Sort by due date
        return allAssignments.sorted { $0.dueDate < $1.dueDate }
    }

    // MARK: - Grades

    func getLatestGrades(family: Family, personName: String? = nil) async -> [GradeEntry] {
        let children = family.children
        var allGrades: [GradeEntry] = []

        for child in children {
            if let name = personName, !child.name.lowercased().contains(name.lowercased()) {
                continue
            }

            // Try loading from persistence
            let stored: [GradeEntry] = persistence.loadData(type: "grades_\(child.id.uuidString)")
            if !stored.isEmpty {
                allGrades.append(contentsOf: stored)
            } else {
                // Use stub data
                allGrades.append(contentsOf: StubEducationData.sampleGrades(for: child.id))
            }
        }

        return allGrades.sorted { $0.date > $1.date }
    }

    // MARK: - Grade Change Detection

    func detectGradeChanges(family: Family) async -> [GradeChange] {
        var changes: [GradeChange] = []
        let children = family.children

        for child in children {
            let grades = await getLatestGrades(family: family, personName: child.name)
            let subjects = Set(grades.map { $0.subject })

            for subject in subjects {
                let subjectGrades = grades.filter { $0.subject == subject }.sorted { $0.date < $1.date }
                guard subjectGrades.count >= 2 else { continue }

                let previous = subjectGrades[subjectGrades.count - 2]
                let current = subjectGrades[subjectGrades.count - 1]
                let delta = current.grade - previous.grade

                if abs(delta) >= EducationAlertThreshold.gradeDrop {
                    changes.append(GradeChange(
                        studentId: child.id,
                        studentName: child.name,
                        subject: subject,
                        previousGrade: previous.grade,
                        currentGrade: current.grade,
                        delta: delta
                    ))
                }
            }
        }

        return changes
    }

    // MARK: - Study Plans

    func createStudyPlan(family: Family, subject: String) async -> StudyPlan {
        let child = family.children.first ?? FamilyMember(name: "Student", role: .child)
        let examDate = Date().addingDays(7)
        let totalStudyMinutes = 180 // 3 hours total

        var sessions: [StudySession] = []
        let sessionsCount = totalStudyMinutes / 30 // 30 min sessions
        let techniques: [StudyTechnique] = [.pomodoro, .practiceProblems, .flashcards, .readingReview]

        for i in 0..<sessionsCount {
            let sessionDate = Date().addingDays(i + 1)
            sessions.append(StudySession(
                date: sessionDate,
                duration: 30,
                topic: "\(subject) - Session \(i + 1)",
                technique: techniques[i % techniques.count]
            ))
        }

        let plan = StudyPlan(
            studentId: child.id,
            subject: subject,
            examDate: examDate,
            sessions: sessions,
            totalTime: totalStudyMinutes
        )

        persistence.saveData(plan, type: "study_plan")
        return plan
    }

    // MARK: - Daily Summary

    func getDailySummary(family: Family) async -> String {
        let assignments = await getUpcomingAssignments(family: family)
        let dueToday = assignments.filter { $0.dueDate.isToday }
        let dueTomorrow = assignments.filter { $0.dueDate.isTomorrow }
        let overdue = assignments.filter { $0.dueDate < Date() && $0.status != .completed }

        var summary = "**Education Summary:**\n"

        if !overdue.isEmpty {
            summary += "\nOverdue (\(overdue.count)):\n"
            for a in overdue { summary += "  - \(a.title) (\(a.subject))\n" }
        }

        if !dueToday.isEmpty {
            summary += "\nDue Today (\(dueToday.count)):\n"
            for a in dueToday { summary += "  - \(a.title) (\(a.subject))\n" }
        }

        if !dueTomorrow.isEmpty {
            summary += "\nDue Tomorrow (\(dueTomorrow.count)):\n"
            for a in dueTomorrow { summary += "  - \(a.title) (\(a.subject))\n" }
        }

        if overdue.isEmpty && dueToday.isEmpty && dueTomorrow.isEmpty {
            summary += "No urgent assignments. Everything is on track!"
        }

        return summary
    }
}
