import Foundation
import HomeOSCore

public struct EducationSkill: SkillProtocol {
    public let name = "education"
    public let description = "Homework help, grade tracking, and personalized study plans"
    public let triggerKeywords = [
        "homework", "grade", "grades", "study", "test", "exam", "quiz",
        "school", "assignment", "report card", "tutor", "learn", "math",
        "science", "reading", "essay", "project", "GPA"
    ]

    // MARK: - Grade Thresholds
    private static let urgentThreshold: Double = 75.0
    private static let warningThreshold: Double = 80.0

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let message = intent.rawMessage.lowercased()
        let matches = triggerKeywords.filter { message.contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("grade") || message.contains("report card") || message.contains("gpa") {
            return try await gradeTracker(context: context)
        } else if message.contains("study") || message.contains("study plan") || message.contains("prepare") {
            return try await createStudyPlan(context: context)
        } else if message.contains("homework") || message.contains("assignment") {
            return try await homeworkHelper(context: context)
        } else if message.contains("test") || message.contains("exam") || message.contains("quiz") {
            return try await testPrep(context: context)
        } else {
            return try await homeworkHelper(context: context)
        }
    }

    // MARK: - Grade Tracker

    private func gradeTracker(context: SkillContext) async throws -> SkillResult {
        let children = context.family.children
        guard !children.isEmpty else {
            return .response("No children registered in the family for grade tracking.")
        }

        var response = "📊 GRADE REPORT\n\n"
        var hasAlerts = false

        for child in children {
            let grades = try? await context.storage.read(
                path: "data/education/\(child.id)/grades.json",
                type: [GradeRecord].self
            )

            response += "👤 \(child.name)"
            if let age = child.age { response += " (age \(age))" }
            response += "\n"

            guard let grades = grades, !grades.isEmpty else {
                response += "   No grades recorded yet.\n\n"
                continue
            }

            // Group by subject and show latest
            let bySubject = Dictionary(grouping: grades, by: { $0.subject })
            for (subject, subjectGrades) in bySubject.sorted(by: { $0.key < $1.key }) {
                let latest = subjectGrades.sorted { $0.date > $1.date }.first!
                let avg = subjectGrades.map { $0.score }.reduce(0, +) / Double(subjectGrades.count)

                let status: String
                if avg < Self.urgentThreshold {
                    status = "🔴 URGENT"
                    hasAlerts = true
                } else if avg < Self.warningThreshold {
                    status = "🟡 WARNING"
                    hasAlerts = true
                } else if avg >= 90 {
                    status = "🌟 Excellent"
                } else {
                    status = "🟢 OK"
                }

                response += "   📘 \(subject): \(String(format: "%.0f", avg))% \(status)\n"
                response += "      Latest: \(latest.title) — \(String(format: "%.0f", latest.score))%"
                response += " (\(latest.date))\n"

                // Trend indicator
                if subjectGrades.count >= 3 {
                    let recent3 = subjectGrades.sorted { $0.date > $1.date }.prefix(3)
                    let scores = recent3.map { $0.score }
                    if let first = scores.last, let last = scores.first {
                        let trend = last - first
                        if trend > 5 {
                            response += "      📈 Trending up (+\(String(format: "%.0f", trend)))\n"
                        } else if trend < -5 {
                            response += "      📉 Trending down (\(String(format: "%.0f", trend)))\n"
                        } else {
                            response += "      ➡️ Stable\n"
                        }
                    }
                }
            }

            // Calculate overall average
            let overallAvg = grades.map { $0.score }.reduce(0, +) / Double(grades.count)
            response += "   ────────────\n"
            response += "   Overall Average: \(String(format: "%.1f", overallAvg))%\n\n"
        }

        if hasAlerts {
            response += "⚠️ ACTION NEEDED: Some subjects are below target.\n"
            response += "Would you like me to create a study plan for struggling areas?\n"
        }

        return .response(response)
    }

    // MARK: - Study Plan (LLM-Generated)

    private func createStudyPlan(context: SkillContext) async throws -> SkillResult {
        let children = context.family.children
        let child = children.first

        guard let child = child else {
            return .response("No children registered for study planning.")
        }

        // Load grades to identify weak areas
        let grades = (try? await context.storage.read(
            path: "data/education/\(child.id)/grades.json",
            type: [GradeRecord].self
        )) ?? []

        let weakSubjects = identifyWeakSubjects(grades: grades)

        // Check upcoming tests
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: context.currentDate)
        let twoWeeks = formatter.string(
            from: Calendar.current.date(byAdding: .day, value: 14, to: context.currentDate)!
        )

        let upcomingTests = context.calendar.filter {
            $0.type == .school && $0.date >= today && $0.date <= twoWeeks
        }

        let prompt = """
        Create a personalized study plan for \(child.name) (age \(child.age ?? 12)).
        
        Weak subjects needing attention: \(weakSubjects.isEmpty ? "none identified" : weakSubjects.joined(separator: ", "))
        
        Upcoming tests/assignments:
        \(upcomingTests.isEmpty ? "None scheduled" : upcomingTests.map { "• \($0.title) on \($0.date)" }.joined(separator: "\n"))
        
        Original request: "\(context.intent.rawMessage)"
        
        Create a 7-day study plan that:
        1. Prioritizes weak areas and upcoming tests
        2. Includes specific study techniques (flashcards, practice problems, etc.)
        3. Breaks sessions into age-appropriate durations (25-45 min blocks)
        4. Includes breaks and rewards
        5. Is encouraging and motivating
        
        Format as a daily schedule. Be specific and actionable.
        """

        let plan: String
        do {
            plan = try await context.llm.generate(prompt: prompt)
        } catch {
            return .response(buildFallbackStudyPlan(child: child, weakSubjects: weakSubjects))
        }

        var response = "📚 STUDY PLAN: \(child.name)\n\n"
        response += plan + "\n\n"

        if !weakSubjects.isEmpty {
            response += "🎯 Focus areas: \(weakSubjects.joined(separator: ", "))\n"
        }
        response += "💡 Tip: Consistency beats cramming! Short daily sessions are more effective."

        // Save the plan
        let savedPlan = StudyPlan(
            memberId: child.id,
            createdDate: today,
            focusAreas: weakSubjects,
            plan: plan
        )
        try? await context.storage.write(
            path: "data/education/\(child.id)/current_plan.json", value: savedPlan
        )

        return .response(response)
    }

    // MARK: - Homework Helper

    private func homeworkHelper(context: SkillContext) async throws -> SkillResult {
        let children = context.family.children

        // Load pending homework tasks
        let tasks = (try? await context.storage.read(
            path: "data/tasks.json",
            type: [HomeTask].self
        )) ?? []

        let homeworkTasks = tasks.filter {
            $0.type == .homework && $0.status != .completed && $0.status != .cancelled
        }

        // Check if user is asking for help with specific homework
        let message = context.intent.rawMessage.lowercased()
        let isAskingHelp = message.contains("help") || message.contains("how to")
            || message.contains("explain") || message.contains("understand")

        if isAskingHelp {
            return try await provideHomeworkGuidance(context: context)
        }

        var response = "📝 HOMEWORK TRACKER\n\n"

        if homeworkTasks.isEmpty {
            response += "No pending homework assignments!\n"

            if !children.isEmpty {
                response += "\nTo add homework, tell me:\n"
                response += "  • Subject and assignment title\n"
                response += "  • Due date\n"
                response += "  • Which child it's for\n"
            }
            return .response(response)
        }

        // Group by child
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: context.currentDate)

        for child in children {
            let childTasks = homeworkTasks.filter { $0.assignee == child.id }
            if childTasks.isEmpty { continue }

            response += "👤 \(child.name)\n"
            for task in childTasks.sorted(by: { ($0.dueDate ?? "") < ($1.dueDate ?? "") }) {
                let isOverdue = (task.dueDate ?? "") < today
                let isDueSoon = task.dueDate == today

                let icon: String
                if isOverdue {
                    icon = "🔴"
                } else if isDueSoon {
                    icon = "🟡"
                } else {
                    icon = "⬜"
                }

                response += "  \(icon) \(task.title)\n"
                if let due = task.dueDate {
                    response += "     Due: \(due)\(isOverdue ? " — OVERDUE" : "")\n"
                }
                if let desc = task.description {
                    response += "     \(desc)\n"
                }
            }
            response += "\n"
        }

        // Count overdue
        let overdueCount = homeworkTasks.filter { ($0.dueDate ?? "") < today }.count
        if overdueCount > 0 {
            response += "⚠️ \(overdueCount) overdue assignment(s)! Let's prioritize those first.\n"
        }

        return .response(response)
    }

    // MARK: - Homework Guidance (LLM assists, doesn't give answers)

    private func provideHomeworkGuidance(context: SkillContext) async throws -> SkillResult {
        let prompt = """
        A student needs help understanding their homework.
        
        Their question: "\(context.intent.rawMessage)"
        
        IMPORTANT RULES:
        - Guide them through the THINKING PROCESS, don't give direct answers
        - Ask leading questions to help them discover the answer
        - Explain the underlying concept simply
        - Give a similar example problem they can try
        - Be encouraging and patient
        - Keep explanation age-appropriate
        
        Think of yourself as a tutor, not an answer key.
        """

        let guidance: String
        do {
            guidance = try await context.llm.generate(prompt: prompt)
        } catch {
            return .response(
                "📚 HOMEWORK HELP\n\n"
                + "I'd love to help! Can you tell me:\n"
                + "  • What subject is this for?\n"
                + "  • What specific concept are you stuck on?\n"
                + "  • What have you tried so far?\n\n"
                + "Remember: understanding HOW to solve it is more valuable than just the answer! 💪"
            )
        }

        var response = "📚 HOMEWORK HELP\n\n"
        response += guidance + "\n\n"
        response += "💡 Remember: The goal is to understand, not just finish. You've got this! 💪"

        return .response(response)
    }

    // MARK: - Test Preparation

    private func testPrep(context: SkillContext) async throws -> SkillResult {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: context.currentDate)
        let nextWeek = formatter.string(
            from: Calendar.current.date(byAdding: .day, value: 7, to: context.currentDate)!
        )

        let upcomingTests = context.calendar.filter {
            $0.type == .school && $0.date >= today && $0.date <= nextWeek
        }.sorted { $0.date < $1.date }

        var response = "📝 TEST PREPARATION\n\n"

        if upcomingTests.isEmpty {
            response += "No tests or exams scheduled in the next 7 days.\n\n"
            response += "When you have an upcoming test, tell me:\n"
            response += "  • Subject and topic\n"
            response += "  • Test date\n"
            response += "  • What you need to study\n\n"
            response += "I'll create a prep plan!"
            return .response(response)
        }

        for test in upcomingTests {
            let daysUntil = Calendar.current.dateComponents(
                [.day],
                from: context.currentDate,
                to: formatter.date(from: test.date)!
            ).day ?? 0

            let urgencyIcon: String
            if daysUntil <= 1 {
                urgencyIcon = "🔴"
            } else if daysUntil <= 3 {
                urgencyIcon = "🟡"
            } else {
                urgencyIcon = "🟢"
            }

            response += "\(urgencyIcon) \(test.title)\n"
            response += "   📅 \(test.date) (\(daysUntil) day(s) away)\n"
            if let notes = test.notes { response += "   📝 \(notes)\n" }
            response += "\n"
        }

        // Generate study tips via LLM
        let testList = upcomingTests.map { $0.title }.joined(separator: ", ")
        let prompt = """
        A student has these upcoming tests: \(testList)
        
        Give 3-4 specific, actionable study tips. Keep it brief and encouraging.
        Focus on study techniques (spaced repetition, practice tests, etc.)
        """

        if let tips = try? await context.llm.generate(prompt: prompt) {
            response += "📖 STUDY TIPS:\n\(tips)\n"
        }

        response += "\n🎯 Want a detailed study plan for any of these tests?"
        return .response(response)
    }

    // MARK: - Helpers

    private func identifyWeakSubjects(grades: [GradeRecord]) -> [String] {
        let bySubject = Dictionary(grouping: grades, by: { $0.subject })
        var weak: [String] = []

        for (subject, subjectGrades) in bySubject {
            let avg = subjectGrades.map { $0.score }.reduce(0, +) / Double(subjectGrades.count)
            if avg < Self.warningThreshold {
                weak.append("\(subject) (\(String(format: "%.0f", avg))%)")
            }
        }

        return weak.sorted()
    }

    private func buildFallbackStudyPlan(child: FamilyMember, weakSubjects: [String]) -> String {
        var plan = "📚 STUDY PLAN: \(child.name)\n\n"
        plan += "Daily Schedule (7 days):\n\n"
        plan += "📌 Each day:\n"
        plan += "  • 25 min focused study block\n"
        plan += "  • 5 min break\n"
        plan += "  • 25 min second block\n"
        plan += "  • Review yesterday's material (10 min)\n\n"

        if !weakSubjects.isEmpty {
            plan += "🎯 Priority subjects: \(weakSubjects.joined(separator: ", "))\n"
            plan += "Spend 60% of study time on these areas.\n\n"
        }

        plan += "💡 Techniques:\n"
        plan += "  • Flashcards for vocabulary and facts\n"
        plan += "  • Practice problems for math/science\n"
        plan += "  • Summarize chapters in own words\n"
        plan += "  • Teach the concept to someone else\n"

        return plan
    }
}

// MARK: - DTOs

private struct GradeRecord: Codable {
    let subject: String
    let title: String
    let score: Double
    let maxScore: Double
    let date: String
    let type: String // "test", "quiz", "homework", "project"
}

private struct StudyPlan: Codable {
    let memberId: String
    let createdDate: String
    let focusAreas: [String]
    let plan: String
}
