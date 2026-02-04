import Foundation
import HomeOSCore

public struct SchoolSkill: SkillProtocol {
    public let name = "school"
    public let description = "Orchestrate school management across multiple children with automated monitoring"
    public let triggerKeywords = ["school monitoring", "school setup", "weekly school", "all school", "school report", "both kids school"]
    
    public init() {}
    
    public func canHandle(intent: UserIntent) -> Double {
        let msg = intent.rawMessage.lowercased()
        // Higher match for multi-child orchestration keywords
        if msg.contains("all") && msg.contains("school") { return 0.9 }
        if msg.contains("monitoring") || msg.contains("setup") { return 0.8 }
        let matches = triggerKeywords.filter { msg.contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }
    
    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()
        let children = context.family.children
        
        guard !children.isEmpty else {
            return .response("📚 No children in your family profile. Add them first so I can track their school life.")
        }
        
        if message.contains("setup") || message.contains("monitoring") {
            return setupMonitoring(children: children)
        } else if message.contains("weekly") || message.contains("week ahead") {
            return try await weeklySummary(context: context, children: children)
        } else {
            return try await dailyCheck(context: context, children: children)
        }
    }
    
    private func setupMonitoring(children: [FamilyMember]) -> SkillResult {
        var response = "📚 SCHOOL MONITORING SETUP\n\n"
        response += "Setting up for \(children.count) student\(children.count > 1 ? "s" : ""):\n"
        for child in children {
            response += "  • \(child.name) (age \(child.age ?? 0))\n"
        }
        response += """
        
        ✅ ENABLING:
        
        1. 📝 Daily Homework Check — 4:00 PM
           • Flag missing/overdue items
           • Notify you of urgent issues
        
        2. 📊 Weekly Grade Report — Sunday 6:00 PM
           • Grade changes and trends
           • Alert for drops below 80%
        
        3. 📅 School Event Sync — Daily
           • Tests, projects, deadlines
           • Family calendar updates
        
        4. ⏰ Smart Reminders
           • Study reminders before tests
           • Permission slip due dates
        
        Activate all of these?
        """
        return .response(response)
    }
    
    private func dailyCheck(context: SkillContext, children: [FamilyMember]) async throws -> SkillResult {
        // Hand off individual student checks to Education skill, compile results
        var response = "📚 DAILY SCHOOL CHECK\n\n"
        
        for child in children {
            response += "━━━ \(child.name.uppercased()) ━━━\n"
            
            // Try to load student-specific data
            struct StudentData: Codable {
                var assignments: [SimpleAssignment]?
                var gradeAlerts: [String]?
            }
            struct SimpleAssignment: Codable {
                var title: String
                var course: String
                var dueDate: String
                var status: String
            }
            
            if let data = try? await context.storage.read(path: "data/education/\(child.id)_status.json", type: StudentData.self) {
                let pending = data.assignments?.filter { $0.status != "completed" } ?? []
                if pending.isEmpty {
                    response += "  ✅ All caught up!\n"
                } else {
                    for a in pending.prefix(3) {
                        response += "  • \(a.title) (\(a.course)) — due \(a.dueDate)\n"
                    }
                }
                if let alerts = data.gradeAlerts, !alerts.isEmpty {
                    response += "  ⚠️ \(alerts.joined(separator: ", "))\n"
                }
            } else {
                response += "  📊 No data tracked yet\n"
            }
            response += "\n"
        }
        
        // Check for scheduling conflicts
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: context.currentDate)
        let todayEvents = context.calendar.filter { $0.date == today }
        
        let childEvents = todayEvents.filter { event in
            children.contains { child in event.participants?.contains(child.id) ?? false }
        }
        
        if childEvents.count > 1 {
            response += "⚠️ COORDINATION: Multiple child events today — check timing!\n"
        }
        
        return .response(response)
    }
    
    private func weeklySummary(context: SkillContext, children: [FamilyMember]) async throws -> SkillResult {
        let prompt = """
        Create a brief week-ahead school summary for \(children.count) children: \(children.map { "\($0.name) age \($0.age ?? 0)" }.joined(separator: ", ")).
        Include typical sections: deadlines, tests, activities, parent tasks.
        Keep it actionable and concise.
        """
        
        let summary = try await context.llm.generate(prompt: prompt)
        return .response("📚 WEEK AHEAD: School Preview\n\n" + summary)
    }
}
