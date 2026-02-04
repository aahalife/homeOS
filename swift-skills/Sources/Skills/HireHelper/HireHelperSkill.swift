import Foundation
import HomeOSCore

public struct HireHelperSkill: SkillProtocol {
    public let name = "hire-helper"
    public let description = "Search, screen, interview, and onboard household help; background check required for childcare"
    public let triggerKeywords = ["hire", "babysitter", "nanny", "cleaner", "tutor", "handyman",
                                  "helper", "caregiver", "dog walker", "house sitter", "interview",
                                  "background check", "onboard"]

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("interview") || message.contains("question") {
            return try await interviewQuestions(context: context)
        } else if message.contains("onboard") || message.contains("first day") {
            return try await onboardingChecklist(context: context)
        } else if message.contains("screen") || message.contains("background") || message.contains("check") {
            return try await screeningGuidance(context: context)
        } else {
            return try await searchHelp(context: context)
        }
    }

    // MARK: - Helper Categories

    private enum HelperCategory: String, CaseIterable {
        case childcare = "childcare"   // nanny, babysitter, au pair
        case cleaning = "cleaning"     // house cleaner, organizer
        case tutoring = "tutoring"     // tutor, homework help
        case maintenance = "maintenance" // handyman, plumber, electrician
        case petCare = "pet-care"      // dog walker, pet sitter
        case elderCare = "elder-care"  // caregiver, companion
        case other = "other"

        var requiresBackgroundCheck: Bool {
            switch self {
            case .childcare, .elderCare: return true
            default: return false
            }
        }

        var searchPlatforms: [String] {
            switch self {
            case .childcare: return ["Care.com", "Sittercity", "UrbanSitter", "local parent groups"]
            case .cleaning: return ["Thumbtack", "Handy", "TaskRabbit", "Nextdoor recommendations"]
            case .tutoring: return ["Wyzant", "Varsity Tutors", "local school recommendations"]
            case .maintenance: return ["Thumbtack", "Angi", "HomeAdvisor", "Nextdoor"]
            case .petCare: return ["Rover", "Wag", "neighborhood referrals"]
            case .elderCare: return ["Care.com", "A Place for Mom", "local agency referrals"]
            case .other: return ["TaskRabbit", "Thumbtack", "Nextdoor"]
            }
        }
    }

    private func detectCategory(from message: String) -> HelperCategory {
        let lower = message.lowercased()
        if lower.contains("nanny") || lower.contains("babysit") || lower.contains("childcare") || lower.contains("au pair") {
            return .childcare
        } else if lower.contains("clean") || lower.contains("organiz") {
            return .cleaning
        } else if lower.contains("tutor") || lower.contains("homework") {
            return .tutoring
        } else if lower.contains("handyman") || lower.contains("plumb") || lower.contains("electric") || lower.contains("fix") {
            return .maintenance
        } else if lower.contains("dog") || lower.contains("pet") || lower.contains("walk") {
            return .petCare
        } else if lower.contains("elder") || lower.contains("caregiv") || lower.contains("senior") {
            return .elderCare
        }
        return .other
    }

    // MARK: - Search Help

    private func searchHelp(context: SkillContext) async throws -> SkillResult {
        let category = detectCategory(from: context.intent.rawMessage)
        let hasKids = !context.family.children.isEmpty

        var response = "🔍 FINDING A \(category.rawValue.uppercased()) HELPER\n\n"

        response += "📱 WHERE TO SEARCH\n"
        for platform in category.searchPlatforms {
            response += "  • \(platform)\n"
        }
        response += "\n"

        response += "📋 WHAT TO LOOK FOR\n"
        response += "  • Reviews/ratings from families similar to yours\n"
        response += "  • Verified identity and references\n"
        response += "  • Experience: 2+ years for regular roles\n"
        response += "  • Availability matching your schedule\n"
        response += "  • Clear communication style\n\n"

        if category.requiresBackgroundCheck {
            response += "⚠️ BACKGROUND CHECK REQUIRED\n"
            response += "  This role involves \(category == .childcare ? "children" : "vulnerable family members").\n"
            response += "  A background check is NON-NEGOTIABLE before hiring.\n"
            response += "  Services: Checkr, GoodHire, Sterling — typical cost $25-75\n\n"
        }

        // Rate guidance
        let rates = typicalRates(for: category, location: context.intent.entities.locations.first)
        response += "💰 TYPICAL RATES\n"
        response += "  \(rates)\n\n"

        response += "📝 NEXT STEPS\n"
        response += "  1. Post on 2-3 platforms with clear requirements\n"
        response += "  2. Screen responses (I can help)\n"
        response += "  3. Interview top candidates (I'll generate questions)\n"
        response += "  4. Check references + background\n"
        response += "  5. Trial period before committing\n"

        return .response(response)
    }

    // MARK: - Screening Guidance

    private func screeningGuidance(context: SkillContext) async throws -> SkillResult {
        let category = detectCategory(from: context.intent.rawMessage)

        var response = "🔎 SCREENING CHECKLIST\n\n"

        response += "📞 PHONE SCREEN (15 min)\n"
        response += "  ☐ Confirm availability and schedule\n"
        response += "  ☐ Discuss rate expectations\n"
        response += "  ☐ Ask about relevant experience\n"
        response += "  ☐ Describe your needs — gauge their reaction\n"
        response += "  ☐ Red flags: evasive answers, can't provide references\n\n"

        response += "📋 REFERENCE CHECK\n"
        response += "  ☐ Contact 2-3 previous employers\n"
        response += "  ☐ Ask: Would you hire them again? Why/why not?\n"
        response += "  ☐ Ask: Any concerns about reliability or trust?\n"
        response += "  ☐ Ask: How did they handle difficult situations?\n\n"

        if category.requiresBackgroundCheck {
            response += "🔒 BACKGROUND CHECK (MANDATORY for \(category.rawValue))\n"
            response += "  ☐ Criminal history check (national + county)\n"
            response += "  ☐ Sex offender registry\n"
            response += "  ☐ Identity verification\n"
            if category == .childcare {
                response += "  ☐ CPR/First Aid certification\n"
                response += "  ☐ Driving record (if transporting children)\n"
            }
            response += "  📌 Services: Checkr ($30), GoodHire ($50), Sterling ($40)\n"
            response += "  ⏱ Turnaround: 2-5 business days\n\n"
        }

        response += "🚩 RED FLAGS\n"
        response += "  • Refuses background check\n"
        response += "  • No verifiable references\n"
        response += "  • Inconsistent story between interviews\n"
        response += "  • Pressures you to decide quickly\n"
        response += "  • Cash-only, no written agreement\n"

        return .response(response)
    }

    // MARK: - Interview Questions

    private func interviewQuestions(context: SkillContext) async throws -> SkillResult {
        let category = detectCategory(from: context.intent.rawMessage)

        let prompt = """
        Generate 8 interview questions for hiring a \(category.rawValue) helper.
        Family context: \(context.family.members.count) members, \(context.family.children.count) children.
        Include: experience questions, scenario-based questions, and practical questions.
        Number them 1-8. Keep each question to 1-2 sentences.
        """

        let questions = try await context.llm.generate(prompt: prompt)

        var response = "🎤 INTERVIEW QUESTIONS — \(category.rawValue.uppercased())\n\n"
        response += questions
        response += "\n\n"

        response += "💡 INTERVIEW TIPS\n"
        response += "  • Meet in a neutral, comfortable place\n"
        response += "  • Let them do 70% of the talking\n"
        response += "  • Watch for enthusiasm and specific examples\n"
        response += "  • Take notes immediately after\n"

        if category == .childcare && !context.family.children.isEmpty {
            response += "\n👶 CHILDCARE SPECIFIC\n"
            response += "  • Have your child present for part of the interview\n"
            response += "  • Watch how the candidate interacts naturally\n"
            response += "  • Ask about discipline philosophy\n"
            response += "  • Confirm CPR certification\n"
        }

        return .response(response)
    }

    // MARK: - Onboarding Checklist

    private func onboardingChecklist(context: SkillContext) async throws -> SkillResult {
        let category = detectCategory(from: context.intent.rawMessage)

        var response = "📋 ONBOARDING CHECKLIST — \(category.rawValue.uppercased())\n\n"

        response += "📝 BEFORE FIRST DAY\n"
        response += "  ☐ Written agreement (schedule, rate, duties, termination)\n"
        response += "  ☐ Emergency contacts shared\n"
        response += "  ☐ House keys / alarm codes (if needed)\n"
        response += "  ☐ Payment method agreed (Venmo, check, payroll service)\n\n"

        response += "🏠 FIRST DAY WALKTHROUGH\n"
        response += "  ☐ Tour of home — especially relevant rooms\n"
        response += "  ☐ Where supplies / equipment are kept\n"
        response += "  ☐ WiFi password\n"
        response += "  ☐ Parking instructions\n"
        response += "  ☐ Introduce to family members and pets\n\n"

        if category == .childcare {
            response += "👶 CHILDCARE SPECIFICS\n"
            response += "  ☐ Each child's routine (nap, meals, activities)\n"
            response += "  ☐ Allergies and medications\n"
            response += "  ☐ Approved snacks and screen time limits\n"
            response += "  ☐ Authorized pickup people (with photos)\n"
            response += "  ☐ Nearest hospital and pediatrician info\n"
            response += "  ☐ Car seat setup (if driving)\n\n"
        }

        response += "📅 FIRST WEEK\n"
        response += "  ☐ Check in daily — brief and supportive\n"
        response += "  ☐ Clarify any questions they have\n"
        response += "  ☐ Set a 2-week review meeting\n"
        response += "  ☐ Adjust duties if needed — flexibility builds loyalty\n"

        return .response(response)
    }

    // MARK: - Helpers

    private func typicalRates(for category: HelperCategory, location: String?) -> String {
        switch category {
        case .childcare: return "$18-30/hr (varies by location, # of kids, experience)"
        case .cleaning: return "$25-50/hr or $100-250 per session"
        case .tutoring: return "$30-80/hr depending on subject and level"
        case .maintenance: return "$50-150/hr depending on trade and complexity"
        case .petCare: return "$15-25 per walk; $40-75/night for sitting"
        case .elderCare: return "$18-35/hr; live-in $200-350/day"
        case .other: return "$20-50/hr depending on task complexity"
        }
    }
}
