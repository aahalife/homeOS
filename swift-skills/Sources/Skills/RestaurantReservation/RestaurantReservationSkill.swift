import Foundation
import HomeOSCore

public struct RestaurantReservationSkill: SkillProtocol {
    public let name = "restaurant-reservation"
    public let description = "Search restaurants, help with booking (MEDIUM risk), phone booking assistance (HIGH risk)"
    public let triggerKeywords = ["restaurant", "reservation", "book a table", "dinner out", "brunch",
                                  "eating out", "where to eat", "OpenTable", "Resy", "table for"]

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("book") || message.contains("reserve") || message.contains("reservation") {
            return try await handleBooking(context: context)
        } else if message.contains("call") || message.contains("phone") {
            return try await phoneBookingAssist(context: context)
        } else {
            return try await searchGuidance(context: context)
        }
    }

    // MARK: - Search Guidance

    private func searchGuidance(context: SkillContext) async throws -> SkillResult {
        let dietary = collectDietary(family: context.family)
        let allergies = collectAllergies(family: context.family)
        let hasKids = !context.family.children.isEmpty
        let partySize = context.family.members.count
        let location = context.intent.entities.locations.first ?? "your area"
        let budget = context.intent.entities.amounts.first

        let prompt = """
        Suggest 3 types of restaurants for this family dinner out.
        Party size: \(partySize)
        Location: \(location)
        Has children: \(hasKids) (ages: \(context.family.children.compactMap { $0.age }.map(String.init).joined(separator: ", ")))
        Dietary needs: \(dietary.isEmpty ? "none" : dietary.joined(separator: ", "))
        Allergies: \(allergies.isEmpty ? "none" : allergies.joined(separator: ", "))
        Budget: \(budget.map { "$\(Int($0)) per person" } ?? "not specified")
        Provide cuisine type, why it works, and what to look for.
        Be concise — 2 sentences each.
        """

        let suggestions = try await context.llm.generate(prompt: prompt)

        var response = "🍽 RESTAURANT SEARCH GUIDE\n\n"
        response += "👥 Party of \(partySize) • 📍 \(location)\n"
        if !dietary.isEmpty { response += "🥗 Dietary: \(dietary.joined(separator: ", "))\n" }
        if !allergies.isEmpty { response += "⚠️ Allergies: \(allergies.joined(separator: ", "))\n" }
        response += "\n"
        response += suggestions
        response += "\n\n"

        // Practical search tips
        response += "🔍 HOW TO SEARCH\n"
        response += "  • OpenTable / Resy — filter by date, party size, cuisine\n"
        response += "  • Google Maps — check reviews + photos of actual dishes\n"
        response += "  • Yelp — filter \"good for kids\" if needed\n"
        if hasKids {
            response += "  • 💡 Look for: high chairs, kids' menu, outdoor seating, noise-friendly\n"
        }
        response += "\nFound a place? I can help you prepare for the booking!"
        return .response(response)
    }

    // MARK: - Booking Help (MEDIUM risk)

    private func handleBooking(context: SkillContext) async throws -> SkillResult {
        let partySize = context.family.members.count
        let date = context.intent.entities.dates.first ?? "not specified"
        let time = context.intent.entities.times.first ?? "not specified"
        let location = context.intent.entities.locations.first

        // Validate we have enough info
        var missing: [String] = []
        if context.intent.entities.dates.isEmpty { missing.append("date") }
        if context.intent.entities.times.isEmpty { missing.append("time") }
        if location == nil { missing.append("restaurant name") }

        if !missing.isEmpty {
            return .response("🍽 I can help book! I just need a few details:\n\n" +
                missing.map { "  • \($0)" }.joined(separator: "\n") +
                "\n\nParty size: \(partySize) (your family). Correct?")
        }

        // Build reservation details for approval
        let details = [
            "Restaurant: \(location ?? "unknown")",
            "Date: \(date)",
            "Time: \(time)",
            "Party size: \(partySize)",
        ]

        let allergies = collectAllergies(family: context.family)
        var notes = ""
        if !allergies.isEmpty { notes += "⚠️ Allergy note for restaurant: \(allergies.joined(separator: ", "))\n" }
        if !context.family.children.isEmpty {
            notes += "👶 Request: high chair / kids' menu\n"
        }

        return .needsApproval(ApprovalRequest(
            description: "Make a reservation at \(location ?? "restaurant")",
            details: details + (notes.isEmpty ? [] : ["Notes: \(notes)"]),
            riskLevel: .medium,
            onDecision: { approved in
                if approved {
                    var confirmation = "✅ RESERVATION PREPARED\n\n"
                    confirmation += details.joined(separator: "\n") + "\n"
                    if !notes.isEmpty { confirmation += "\n\(notes)" }
                    confirmation += "\n📱 Next steps:\n"
                    confirmation += "  1. Open OpenTable/Resy and search for \(location ?? "the restaurant")\n"
                    confirmation += "  2. Select \(date) at \(time) for \(partySize)\n"
                    confirmation += "  3. Add these special requests in the notes field\n"
                    confirmation += "\nWant me to help draft special request notes?"
                    return .response(confirmation)
                } else {
                    return .response("No problem! Let me know if you want to look at other options.")
                }
            }
        ))
    }

    // MARK: - Phone Booking Assist (HIGH risk)

    private func phoneBookingAssist(context: SkillContext) async throws -> SkillResult {
        let location = context.intent.entities.locations.first ?? "the restaurant"
        let partySize = context.family.members.count
        let date = context.intent.entities.dates.first ?? "[DATE]"
        let time = context.intent.entities.times.first ?? "[TIME]"
        let allergies = collectAllergies(family: context.family)

        let script = buildPhoneScript(
            restaurant: location, partySize: partySize,
            date: date, time: time, allergies: allergies,
            hasKids: !context.family.children.isEmpty
        )

        return .needsApproval(ApprovalRequest(
            description: "Prepare phone booking script for \(location) (you'll make the call)",
            details: ["This generates a call script — no call is made automatically"],
            riskLevel: .high,
            onDecision: { approved in
                if approved {
                    return .response(script)
                } else {
                    return .response("Got it. Want to try online booking instead?")
                }
            }
        ))
    }

    private func buildPhoneScript(restaurant: String, partySize: Int, date: String,
                                   time: String, allergies: [String], hasKids: Bool) -> String {
        var script = "📞 PHONE BOOKING SCRIPT\n\n"
        script += "\"Hi, I'd like to make a reservation please.\"\n\n"
        script += "📋 DETAILS TO GIVE:\n"
        script += "  • Party size: \(partySize)\n"
        script += "  • Date: \(date)\n"
        script += "  • Preferred time: \(time)\n"
        script += "  • Name: [your name]\n"
        script += "  • Phone: [your number]\n\n"

        script += "📝 SPECIAL REQUESTS:\n"
        if !allergies.isEmpty {
            script += "  • \"We have allergies to: \(allergies.joined(separator: ", ")). Can you accommodate?\"\n"
        }
        if hasKids {
            script += "  • \"We'll have children — do you have high chairs / a kids' menu?\"\n"
        }
        script += "  • \"Could we get a [booth / quiet corner / outdoor table]?\"\n\n"

        script += "❓ ASK BEFORE HANGING UP:\n"
        script += "  • Cancellation policy?\n"
        script += "  • Parking situation?\n"
        script += "  • Confirmation number?\n"
        return script
    }

    // MARK: - Helpers

    private func collectDietary(family: Family) -> [String] {
        Array(Set(family.members.compactMap { $0.preferences?.dietary }.flatMap { $0 })).sorted()
    }

    private func collectAllergies(family: Family) -> [String] {
        Array(Set(family.members.compactMap { $0.allergies }.flatMap { $0 })).sorted()
    }
}
