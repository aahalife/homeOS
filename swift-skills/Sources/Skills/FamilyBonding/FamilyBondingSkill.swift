import Foundation
import HomeOSCore

public struct FamilyBondingSkill: SkillProtocol {
    public let name = "family-bonding"
    public let description = "Suggest family activities by age, weather, budget, and season; date night ideas"
    public let triggerKeywords = ["family activity", "date night", "weekend plans", "bonding", "things to do",
                                  "fun with kids", "family time", "outing", "adventure", "bored"]

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("date night") || message.contains("couple") {
            return try await suggestDateNight(context: context)
        } else {
            return try await suggestFamilyActivity(context: context)
        }
    }

    // MARK: - Activity Library (hardcoded for reliability)

    private struct Activity {
        let name: String
        let description: String
        let ageGroups: Set<AgeGroup>
        let indoor: Bool
        let budgetRange: ClosedRange<Int> // dollars
        let seasons: Set<Season>
        let durationMinutes: Int
    }

    private enum Season: String { case spring, summer, fall, winter }

    private static let activityLibrary: [Activity] = [
        Activity(name: "Nature Scavenger Hunt", description: "Create a list of items to find outdoors — leaves, bugs, rocks, feathers",
                 ageGroups: [.toddler, .preschool, .schoolAge], indoor: false, budgetRange: 0...0, seasons: [.spring, .summer, .fall], durationMinutes: 60),
        Activity(name: "Family Movie Marathon", description: "Pick a theme (Pixar, superheroes, 80s classics) and make popcorn",
                 ageGroups: [.toddler, .preschool, .schoolAge, .tween, .teen, .adult], indoor: true, budgetRange: 0...10, seasons: [.spring, .summer, .fall, .winter], durationMinutes: 180),
        Activity(name: "Backyard Camping", description: "Set up a tent, tell stories, roast marshmallows — no driving required",
                 ageGroups: [.preschool, .schoolAge, .tween, .teen], indoor: false, budgetRange: 0...20, seasons: [.spring, .summer, .fall], durationMinutes: 240),
        Activity(name: "Cooking Competition", description: "Each person picks a secret ingredient; vote on best dish",
                 ageGroups: [.schoolAge, .tween, .teen, .adult], indoor: true, budgetRange: 10...30, seasons: [.spring, .summer, .fall, .winter], durationMinutes: 90),
        Activity(name: "Board Game Tournament", description: "Bracket-style tournament with different games per round",
                 ageGroups: [.schoolAge, .tween, .teen, .adult], indoor: true, budgetRange: 0...0, seasons: [.spring, .summer, .fall, .winter], durationMinutes: 120),
        Activity(name: "Bike Ride / Trail Walk", description: "Explore a local trail; pack snacks and a camera",
                 ageGroups: [.schoolAge, .tween, .teen, .adult], indoor: false, budgetRange: 0...5, seasons: [.spring, .summer, .fall], durationMinutes: 90),
        Activity(name: "Art / Craft Session", description: "Finger painting for little ones, tie-dye or pottery for older kids",
                 ageGroups: [.toddler, .preschool, .schoolAge, .tween], indoor: true, budgetRange: 5...20, seasons: [.spring, .summer, .fall, .winter], durationMinutes: 60),
        Activity(name: "Volunteer Together", description: "Food bank, park cleanup, or animal shelter — builds empathy",
                 ageGroups: [.schoolAge, .tween, .teen, .adult], indoor: false, budgetRange: 0...0, seasons: [.spring, .summer, .fall, .winter], durationMinutes: 120),
        Activity(name: "Stargazing Night", description: "Blankets, hot cocoa, a sky map app — find constellations",
                 ageGroups: [.schoolAge, .tween, .teen, .adult], indoor: false, budgetRange: 0...5, seasons: [.summer, .fall, .winter], durationMinutes: 60),
        Activity(name: "Indoor Fort Building", description: "Blankets, pillows, fairy lights — then read stories inside",
                 ageGroups: [.toddler, .preschool, .schoolAge], indoor: true, budgetRange: 0...0, seasons: [.spring, .summer, .fall, .winter], durationMinutes: 90),
        Activity(name: "Water Balloon / Sprinkler Day", description: "Backyard water fun — perfect for hot days",
                 ageGroups: [.toddler, .preschool, .schoolAge, .tween], indoor: false, budgetRange: 5...10, seasons: [.summer], durationMinutes: 60),
        Activity(name: "Snow Day Activities", description: "Snowman building, snow angels, sledding, hot cocoa after",
                 ageGroups: [.toddler, .preschool, .schoolAge, .tween, .teen], indoor: false, budgetRange: 0...10, seasons: [.winter], durationMinutes: 120),
    ]

    private static let dateNightIdeas: [(name: String, description: String, budget: ClosedRange<Int>)] = [
        ("Cooking Date", "Pick a cuisine neither of you has tried; cook together with wine", 15...30),
        ("Picnic Under Stars", "Pack a blanket, cheese board, and a playlist", 10...25),
        ("Game Night for Two", "Card games, trivia, or co-op board games with snacks", 0...10),
        ("Neighborhood Explore", "Walk a neighborhood you've never explored; find a new café", 5...20),
        ("Movie Night In", "Projector or big screen, popcorn, and a double feature", 0...15),
        ("DIY Spa Night", "Face masks, candles, massages, relaxing playlist", 10...25),
        ("Sunset Drive", "Find a scenic overlook; bring takeout and watch the sunset", 15...30),
        ("Workshop/Class", "Pottery, painting, cocktail making — learn something new together", 30...80),
    ]

    // MARK: - Family Activity Suggestion

    private func suggestFamilyActivity(context: SkillContext) async throws -> SkillResult {
        let childAgeGroups = Set(context.family.children.compactMap { $0.ageGroup })
        let season = currentSeason(date: context.currentDate)
        let budget = extractBudget(from: context.intent)

        // Filter deterministically from library
        var candidates = Self.activityLibrary.filter { activity in
            // Age match: at least one child age group must overlap (or no kids = all OK)
            let ageOk = childAgeGroups.isEmpty || !activity.ageGroups.isDisjoint(with: childAgeGroups)
            let seasonOk = activity.seasons.contains(season)
            let budgetOk = budget == nil || activity.budgetRange.lowerBound <= (budget ?? 0)
            return ageOk && seasonOk && budgetOk
        }

        if candidates.isEmpty { candidates = Array(Self.activityLibrary.prefix(5)) }

        // Pick top 3 deterministically, then use LLM for personalization
        let top3 = Array(candidates.shuffled().prefix(3))
        let familyInfo = context.family.children.map { "\($0.name) (age \($0.age ?? 0))" }.joined(separator: ", ")
        let interests = context.family.members.compactMap { $0.preferences?.interests }.flatMap { $0 }

        let prompt = """
        Personalize these activity suggestions for this family.
        Children: \(familyInfo.isEmpty ? "none specified" : familyInfo)
        Family interests: \(interests.isEmpty ? "not specified" : interests.joined(separator: ", "))
        Season: \(season.rawValue)

        Activities:
        \(top3.enumerated().map { "\($0.offset + 1). \($0.element.name): \($0.element.description)" }.joined(separator: "\n"))

        For each activity, add a 1-sentence personalized tip. Keep it brief.
        """

        let personalTips = (try? await context.llm.generate(prompt: prompt)) ?? ""

        var response = "🎯 FAMILY ACTIVITY IDEAS\n"
        response += "👨‍👩‍👧‍👦 \(context.family.members.count) family members • \(season.rawValue.capitalized)\n\n"

        for (i, activity) in top3.enumerated() {
            let budgetStr = activity.budgetRange.lowerBound == 0 && activity.budgetRange.upperBound == 0
                ? "Free" : "$\(activity.budgetRange.lowerBound)-\(activity.budgetRange.upperBound)"
            response += "\(i + 1). \(activity.name)\n"
            response += "   \(activity.description)\n"
            response += "   🕐 ~\(activity.durationMinutes) min • 💰 \(budgetStr) • \(activity.indoor ? "🏠 Indoor" : "🌳 Outdoor")\n\n"
        }

        if !personalTips.isEmpty {
            response += "💡 PERSONALIZED TIPS\n\(personalTips)\n\n"
        }

        response += "Want more ideas, or details on any of these?"
        return .response(response)
    }

    // MARK: - Date Night

    private func suggestDateNight(context: SkillContext) async throws -> SkillResult {
        let budget = extractBudget(from: context.intent)
        let candidates = budget != nil
            ? Self.dateNightIdeas.filter { $0.budget.lowerBound <= (budget ?? 0) }
            : Self.dateNightIdeas

        let picks = Array((candidates.isEmpty ? Self.dateNightIdeas : candidates).shuffled().prefix(3))

        var response = "💑 DATE NIGHT IDEAS\n\n"
        for (i, idea) in picks.enumerated() {
            let budgetStr = "$\(idea.budget.lowerBound)-\(idea.budget.upperBound)"
            response += "\(i + 1). \(idea.name) — \(budgetStr)\n"
            response += "   \(idea.description)\n\n"
        }

        if !context.family.children.isEmpty {
            response += "👶 You have \(context.family.children.count) kid(s) — need babysitter suggestions too?\n"
        }
        response += "Pick one and I'll help you plan the details!"
        return .response(response)
    }

    // MARK: - Helpers

    private func currentSeason(date: Date) -> Season {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }

    private func extractBudget(from intent: UserIntent) -> Int? {
        if let amount = intent.entities.amounts.first { return Int(amount) }
        let msg = intent.rawMessage.lowercased()
        if msg.contains("free") || msg.contains("no cost") { return 0 }
        if msg.contains("cheap") || msg.contains("budget") { return 15 }
        return nil
    }
}
