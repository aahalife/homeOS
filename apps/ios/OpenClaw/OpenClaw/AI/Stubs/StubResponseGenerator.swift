import Foundation

/// Template-based response generator (stub for on-device AI)
final class StubResponseGenerator: ResponseGenerator {

    func generate(intent: IntentResult, context: ConversationContext) -> String {
        switch intent.action {
        case .greeting:
            return generateGreeting(context: context)
        case .help:
            return generateHelpResponse(context: context)
        case .unknown:
            return "I'm not sure I understood that. I can help with meal planning, healthcare, education, elder care, home maintenance, family coordination, and daily planning. What would you like help with?"
        default:
            return generateSkillResponse(intent: intent, context: context)
        }
    }

    func fillTemplate(template: String, data: [String: Any]) -> String {
        var result = template
        for (key, value) in data {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: "\(value)")
        }
        return result
    }

    // MARK: - Response Generators

    private func generateGreeting(context: ConversationContext) -> String {
        let hour = Calendar.current.component(.hour, from: context.currentTime)
        let timeOfDay: String
        switch hour {
        case 5...11: timeOfDay = "Good morning"
        case 12...16: timeOfDay = "Good afternoon"
        case 17...21: timeOfDay = "Good evening"
        default: timeOfDay = "Hello"
        }

        return "\(timeOfDay)! I'm here to help the \(context.familyName) family. What can I assist you with today?"
    }

    private func generateHelpResponse(context: ConversationContext) -> String {
        var response = "Here's what I can help with:\n\n"
        for skill in context.activeSkills.sorted(by: { $0.rawValue < $1.rawValue }) {
            response += "- **\(skill.rawValue)**: \(skill.description)\n"
        }
        response += "\nJust ask me anything, and I'll figure out how to help!"
        return response
    }

    private func generateSkillResponse(intent: IntentResult, context: ConversationContext) -> String {
        switch intent.skill {
        case .mealPlanning:
            return generateMealResponse(action: intent.action, entities: intent.entities)
        case .healthcare:
            return generateHealthcareResponse(action: intent.action, entities: intent.entities)
        case .education:
            return generateEducationResponse(action: intent.action, entities: intent.entities)
        case .elderCare:
            return generateElderCareResponse(action: intent.action, entities: intent.entities)
        case .homeMaintenance:
            return generateHomeMaintenanceResponse(action: intent.action, entities: intent.entities)
        case .familyCoordination:
            return generateFamilyCoordinationResponse(action: intent.action, entities: intent.entities)
        case .mentalLoad:
            return generateMentalLoadResponse(action: intent.action, context: context)
        }
    }

    // MARK: - Skill-Specific Responses

    private func generateMealResponse(action: SkillAction, entities: [String: String]) -> String {
        switch action {
        case .planWeek:
            return "I've put together a weekly meal plan for your family. Each dinner is ready in 30 minutes or less on weeknights, with more involved meals on weekends. The plan respects all dietary restrictions and keeps things varied."
        case .planTonight:
            return "Based on what you typically have available, here's a quick dinner suggestion that can be ready in under 30 minutes."
        case .searchRecipe:
            return "Here are some recipe options that match your criteria. I've filtered them based on your family's dietary needs."
        case .generateGroceryList:
            return "I've generated your grocery list organized by store section. Estimated total is shown below."
        case .pantryCheck:
            return "Based on your pantry inventory, here are some meals you can make with what you have on hand."
        default:
            return "I can help with meal planning. Would you like to plan the week or get a quick dinner idea?"
        }
    }

    private func generateHealthcareResponse(action: SkillAction, entities: [String: String]) -> String {
        switch action {
        case .checkSymptom:
            return "I understand you're concerned about these symptoms. Please note that I cannot provide a medical diagnosis. Based on what you've described, here's my assessment of the urgency level and recommended next steps."
        case .trackMedication:
            return "I've updated the medication tracking log. Remember, consistent medication adherence is important for your health."
        case .bookAppointment:
            return "I can help you find an in-network provider and schedule an appointment. Let me search for available providers."
        case .checkMedication:
            return "Here's the information I found about that medication from the FDA database."
        case .findProvider:
            return "I found several healthcare providers in your area that accept your insurance."
        default:
            return "I can help with medication tracking, symptom assessment, or finding healthcare providers. What do you need?"
        }
    }

    private func generateEducationResponse(action: SkillAction, entities: [String: String]) -> String {
        switch action {
        case .checkHomework:
            let person = entities["person"] ?? "your children"
            return "Here's the homework summary for \(person). Assignments are sorted by due date."
        case .checkGrades:
            let person = entities["person"] ?? "your children"
            return "Here's the latest grade update for \(person). I'll flag any significant changes."
        case .createStudyPlan:
            return "I've created a study plan with Pomodoro sessions spaced out for optimal retention."
        case .contactTeacher:
            return "I've drafted an email for the teacher. Would you like to review it before sending?"
        default:
            return "I can check homework, review grades, create study plans, or help communicate with teachers."
        }
    }

    private func generateElderCareResponse(action: SkillAction, entities: [String: String]) -> String {
        switch action {
        case .performCheckIn, .checkStatus:
            let person = entities["person"] ?? "your family member"
            return "Here's the latest update on \(person). The most recent check-in showed their wellness status."
        case .reviewAlerts:
            return "Here are the recent elder care alerts. Any red flags are highlighted for your attention."
        case .weeklyReport:
            return "Here's the weekly elder care summary including wellness trends, medication adherence, and any concerns."
        default:
            return "I can help with elder care check-ins, medication tracking, and health monitoring."
        }
    }

    private func generateHomeMaintenanceResponse(action: SkillAction, entities: [String: String]) -> String {
        switch action {
        case .reportEmergency:
            return "This sounds urgent. Let me guide you through the safety steps immediately."
        case .findContractor:
            return "I found several highly-rated contractors in your area. Here are the top options."
        case .scheduleMaintenance:
            return "I can help schedule that repair. Let me check available contractors and times."
        case .maintenanceCalendar:
            return "Here's your home maintenance schedule. I've highlighted any overdue items."
        default:
            return "I can help with emergency triage, contractor search, and maintenance scheduling."
        }
    }

    private func generateFamilyCoordinationResponse(action: SkillAction, entities: [String: String]) -> String {
        switch action {
        case .checkCalendar:
            return "Here's what's coming up on the family calendar."
        case .createEvent:
            return "I've added the event to the family calendar. I'll check for conflicts."
        case .assignChore:
            return "Chore assigned. I'll send a notification and track completion."
        case .broadcastMessage:
            return "Message sent to all family members. I'll let you know when they read it."
        case .whereIsEveryone:
            return "Here's where everyone is right now (for those with location sharing enabled)."
        default:
            return "I can manage the family calendar, assign chores, send messages, or check locations."
        }
    }

    private func generateMentalLoadResponse(action: SkillAction, context: ConversationContext) -> String {
        switch action {
        case .morningBriefing:
            return "Good morning, \(context.familyName) family! Here's your daily briefing."
        case .eveningWindDown:
            return "Here's your evening summary for the \(context.familyName) family. Great job today!"
        case .weeklyPlanning:
            return "Here's your week-ahead plan. I've identified a few things to watch out for."
        case .setReminder:
            return "Reminder set! I'll notify you at the right time."
        default:
            return "I can provide morning briefings, evening summaries, weekly planning, and proactive reminders."
        }
    }
}
