import Foundation
import Combine

/// Central orchestrator that routes requests to appropriate skills
final class SkillOrchestrator: ObservableObject {
    private var modelManager: ModelManager?
    private var networkMonitor: NetworkMonitor?
    private let logger = AppLogger.shared

    // MARK: - Skill Handlers
    private(set) lazy var mealPlanning = MealPlanningSkill()
    private(set) lazy var healthcare = HealthcareSkill()
    private(set) lazy var education = EducationSkill()
    private(set) lazy var elderCare = ElderCareSkill()
    private(set) lazy var homeMaintenance = HomeMaintenanceSkill()
    private(set) lazy var familyCoordination = FamilyCoordinationSkill()
    private(set) lazy var mentalLoad = MentalLoadSkill()

    func configure(modelManager: ModelManager, networkMonitor: NetworkMonitor) {
        self.modelManager = modelManager
        self.networkMonitor = networkMonitor
    }

    // MARK: - Request Processing

    struct SkillResponse {
        let text: String
        let skill: SkillType
        let action: SkillAction
        let attachments: [ChatAttachment]
        let confidence: Double
    }

    func processRequest(
        text: String,
        family: Family,
        chatHistory: [ChatMessage]
    ) async -> SkillResponse {
        guard let modelManager = modelManager else {
            return SkillResponse(
                text: "System is not ready yet. Please wait a moment.",
                skill: .mentalLoad, action: .unknown,
                attachments: [], confidence: 0.0
            )
        }

        // 1. Classify intent
        let intent = await modelManager.classifyIntent(text: text)
        logger.info("Intent classified: \(intent.skill.rawValue) -> \(intent.action.rawValue) (confidence: \(intent.confidence))")

        // 2. Generate context
        let context = ConversationContext(
            familyName: family.name,
            memberCount: family.members.count,
            recentMessages: Array(chatHistory.suffix(5)),
            activeSkills: Set(SkillType.allCases),
            currentTime: Date()
        )

        // 3. Route to skill and get attachments
        let (attachments, supplementaryText) = await routeToSkill(
            intent: intent,
            family: family,
            context: context
        )

        // 4. Generate response text
        let responseText = await modelManager.generateResponse(intent: intent, context: context)
        let finalText = supplementaryText.isEmpty ? responseText : "\(responseText)\n\n\(supplementaryText)"

        return SkillResponse(
            text: finalText,
            skill: intent.skill,
            action: intent.action,
            attachments: attachments,
            confidence: intent.confidence
        )
    }

    // MARK: - Skill Routing

    private func routeToSkill(
        intent: IntentResult,
        family: Family,
        context: ConversationContext
    ) async -> ([ChatAttachment], String) {
        do {
            switch intent.skill {
            case .mealPlanning:
                return try await handleMealPlanning(action: intent.action, family: family, entities: intent.entities)
            case .healthcare:
                return try await handleHealthcare(action: intent.action, family: family, entities: intent.entities)
            case .education:
                return try await handleEducation(action: intent.action, family: family, entities: intent.entities)
            case .elderCare:
                return try await handleElderCare(action: intent.action, family: family, entities: intent.entities)
            case .homeMaintenance:
                return try await handleHomeMaintenance(action: intent.action, family: family, entities: intent.entities)
            case .familyCoordination:
                return try await handleFamilyCoordination(action: intent.action, family: family, entities: intent.entities)
            case .mentalLoad:
                return try await handleMentalLoad(action: intent.action, family: family, context: context)
            }
        } catch {
            logger.error("Skill handler error: \(error.localizedDescription)")
            return ([], "")
        }
    }

    // MARK: - Meal Planning

    private func handleMealPlanning(action: SkillAction, family: Family, entities: [String: String]) async throws -> ([ChatAttachment], String) {
        switch action {
        case .planWeek:
            let plan = try await mealPlanning.generateWeeklyPlan(family: family)
            let data = try JSONEncoder().encode(plan)
            let attachment = ChatAttachment(type: .mealPlan, title: "Weekly Meal Plan", data: String(data: data, encoding: .utf8) ?? "{}")
            let summary = plan.meals.enumerated().map { "\($0.offset + 1). \($0.element.recipe.title) (\($0.element.recipe.totalTime) min)" }.joined(separator: "\n")
            return ([attachment], "**This Week's Dinners:**\n\(summary)\n\nEstimated cost: \(plan.estimatedCost.currencyString)")

        case .planTonight:
            let meal = try await mealPlanning.suggestTonightDinner(family: family)
            let data = try JSONEncoder().encode(meal)
            let attachment = ChatAttachment(type: .recipe, title: meal.recipe.title, data: String(data: data, encoding: .utf8) ?? "{}")
            return ([attachment], "**Tonight's Suggestion:** \(meal.recipe.title)\nReady in \(meal.recipe.totalTime) minutes | Serves \(meal.recipe.servings)")

        case .generateGroceryList:
            let list = try await mealPlanning.generateGroceryList(family: family)
            let data = try JSONEncoder().encode(list)
            let attachment = ChatAttachment(type: .groceryList, title: "Grocery List", data: String(data: data, encoding: .utf8) ?? "{}")
            return ([attachment], "**Grocery List** (\(list.items.count) items)\nEstimated total: \(list.estimatedTotal.currencyString)")

        default:
            return ([], "")
        }
    }

    // MARK: - Healthcare

    private func handleHealthcare(action: SkillAction, family: Family, entities: [String: String]) async throws -> ([ChatAttachment], String) {
        switch action {
        case .checkSymptom:
            let assessment = await healthcare.assessSymptoms(description: entities["symptom"] ?? "general concern", family: family)
            return ([], assessment)

        case .trackMedication:
            let memberName = entities["person"] ?? family.members.first?.name ?? "Unknown"
            let status = healthcare.logMedicationTaken(memberName: memberName)
            return ([], status)

        case .findProvider:
            let providers = try await healthcare.searchProviders(family: family, specialty: entities["specialty"])
            let summary = providers.prefix(3).enumerated().map { "\($0.offset + 1). \($0.element.name) - Rating: \($0.element.rating ?? 0)/5" }.joined(separator: "\n")
            return ([], "**Providers Found:**\n\(summary)")

        case .checkMedication:
            let info = try await healthcare.getMedicationInfo(name: entities["medication"] ?? "aspirin")
            return ([], "**\(info.name)**\nGeneric: \(info.genericName ?? "N/A")\nActive: \(info.activeIngredient ?? "N/A")")

        default:
            return ([], "")
        }
    }

    // MARK: - Education

    private func handleEducation(action: SkillAction, family: Family, entities: [String: String]) async throws -> ([ChatAttachment], String) {
        switch action {
        case .checkHomework:
            let assignments = await education.getUpcomingAssignments(family: family, personName: entities["person"])
            let summary = assignments.prefix(5).map { "- \($0.title) (\($0.subject)) - Due: \($0.dueDate.shortDateString)" }.joined(separator: "\n")
            return ([], "**Upcoming Assignments:**\n\(summary)")

        case .checkGrades:
            let grades = await education.getLatestGrades(family: family, personName: entities["person"])
            let summary = grades.map { "\($0.subject): \(Int($0.grade))%" }.joined(separator: "\n")
            return ([], "**Latest Grades:**\n\(summary)")

        case .createStudyPlan:
            let plan = await education.createStudyPlan(family: family, subject: entities["subject"] ?? "General")
            return ([], "**Study Plan Created:**\n\(plan.sessions.count) sessions over \(plan.totalTime / 60) hours")

        default:
            return ([], "")
        }
    }

    // MARK: - Elder Care

    private func handleElderCare(action: SkillAction, family: Family, entities: [String: String]) async throws -> ([ChatAttachment], String) {
        switch action {
        case .performCheckIn, .checkStatus:
            let summary = await elderCare.performCheckIn(family: family)
            return ([], summary)

        case .reviewAlerts:
            let alerts = await elderCare.getRecentAlerts(family: family)
            if alerts.isEmpty {
                return ([], "No new elder care alerts. Everything looks good!")
            }
            let summary = alerts.map { "- [\($0.severity.rawValue.uppercased())] \($0.message)" }.joined(separator: "\n")
            return ([], "**Elder Care Alerts:**\n\(summary)")

        case .weeklyReport:
            let report = await elderCare.generateWeeklyReport(family: family)
            return ([], "**Weekly Elder Care Report:**\n\(report)")

        default:
            return ([], "")
        }
    }

    // MARK: - Home Maintenance

    private func handleHomeMaintenance(action: SkillAction, family: Family, entities: [String: String]) async throws -> ([ChatAttachment], String) {
        switch action {
        case .reportEmergency:
            let response = homeMaintenance.handleEmergency(description: entities["issue"] ?? "unknown issue", family: family)
            return ([], response)

        case .findContractor:
            let providers = try await homeMaintenance.searchContractors(query: entities["service"] ?? "general contractor", family: family)
            let summary = providers.prefix(3).enumerated().map { "\($0.offset + 1). \($0.element.name) - \($0.element.phone) - Rating: \($0.element.rating ?? 0)/5" }.joined(separator: "\n")
            return ([], "**Contractors Found:**\n\(summary)")

        case .maintenanceCalendar:
            let tasks = homeMaintenance.getMaintenanceSchedule(family: family)
            let summary = tasks.prefix(5).map { "- \($0.title) - Due: \($0.nextDue.shortDateString)" }.joined(separator: "\n")
            return ([], "**Upcoming Maintenance:**\n\(summary)")

        default:
            return ([], "")
        }
    }

    // MARK: - Family Coordination

    private func handleFamilyCoordination(action: SkillAction, family: Family, entities: [String: String]) async throws -> ([ChatAttachment], String) {
        switch action {
        case .checkCalendar:
            let events = await familyCoordination.getUpcomingEvents(family: family)
            let summary = events.prefix(5).map { "- \($0.title) - \($0.startTime.shortDateString) \($0.startTime.timeString)" }.joined(separator: "\n")
            return ([], "**Upcoming Events:**\n\(summary)")

        case .assignChore:
            let chore = familyCoordination.assignChore(family: family, task: entities["task"] ?? "Tidy up", to: entities["person"] ?? "")
            return ([], "Chore assigned: \"\(chore.title)\" to \(chore.assignedToName)")

        case .broadcastMessage:
            let message = entities["message"] ?? "Message from family coordinator"
            familyCoordination.broadcastMessage(family: family, message: message)
            return ([], "Broadcast sent to \(family.members.count) family members.")

        default:
            return ([], "")
        }
    }

    // MARK: - Mental Load

    private func handleMentalLoad(action: SkillAction, family: Family, context: ConversationContext) async throws -> ([ChatAttachment], String) {
        switch action {
        case .morningBriefing:
            let briefing = await mentalLoad.generateMorningBriefing(family: family)
            let data = try JSONEncoder().encode(briefing)
            let attachment = ChatAttachment(type: .briefing, title: "Morning Briefing", data: String(data: data, encoding: .utf8) ?? "{}")
            return ([attachment], mentalLoad.formatBriefing(briefing))

        case .eveningWindDown:
            let windDown = await mentalLoad.generateEveningWindDown(family: family)
            return ([], mentalLoad.formatWindDown(windDown))

        case .weeklyPlanning:
            let plan = await mentalLoad.generateWeeklyPlan(family: family)
            return ([], "**Weekly Plan:**\n\(plan.calendarEvents.count) events, \(plan.chores.count) chores, \(plan.reminders.count) reminders for the week ahead.")

        case .setReminder:
            return ([], "Reminder has been set. I'll notify you at the appropriate time.")

        default:
            return ([], "")
        }
    }
}
