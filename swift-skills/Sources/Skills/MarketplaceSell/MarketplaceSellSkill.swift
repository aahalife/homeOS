import Foundation
import HomeOSCore

public struct MarketplaceSellSkill: SkillProtocol {
    public let name = "marketplace-sell"
    public let description = "Help list items for sale, pricing guidance, scam detection, and safety"
    public let triggerKeywords = ["sell", "marketplace", "listing", "Facebook Marketplace", "Craigslist",
                                  "OfferUp", "price", "how much", "get rid of", "declutter", "scam"]

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("scam") || message.contains("suspicious") || message.contains("safe") {
            return scamDetection(message: context.intent.rawMessage)
        } else if message.contains("price") || message.contains("how much") || message.contains("worth") {
            return try await pricingGuidance(context: context)
        } else {
            return try await createListing(context: context)
        }
    }

    // MARK: - Create Listing

    private func createListing(context: SkillContext) async throws -> SkillResult {
        let prompt = """
        Write a marketplace listing based on: "\(context.intent.rawMessage)"
        Include: title (concise, searchable), description (honest, highlights condition),
        suggested category, and 3 photo tips specific to this item.
        Format as sections. Be honest about flaws — builds trust and reduces returns.
        """

        let listing = try await context.llm.generate(prompt: prompt)

        var response = "📦 MARKETPLACE LISTING DRAFT\n\n"
        response += listing
        response += "\n\n"
        response += "📸 PHOTO CHECKLIST\n"
        response += "  ☐ Clean, well-lit main photo (natural light best)\n"
        response += "  ☐ Close-ups of any wear/damage (honesty sells)\n"
        response += "  ☐ Size reference (next to common object)\n"
        response += "  ☐ Brand/model label if applicable\n"
        response += "  ☐ All included accessories laid out\n\n"
        response += "🛡 SAFETY REMINDERS\n"
        for tip in Self.safetyGuidelines.prefix(4) {
            response += "  • \(tip)\n"
        }
        response += "\nWant me to adjust the listing or help with pricing?"
        return .response(response)
    }

    // MARK: - Pricing Guidance

    private func pricingGuidance(context: SkillContext) async throws -> SkillResult {
        let prompt = """
        Provide pricing guidance for: "\(context.intent.rawMessage)"
        Include:
        1. Estimated price range (low/mid/high)
        2. Factors that affect price (condition, demand, season)
        3. Pricing strategy (start high or price to sell?)
        4. Where this item sells best (FB Marketplace, OfferUp, specialty sites)
        Be practical and concise.
        """

        let guidance = try await context.llm.generate(prompt: prompt)

        var response = "💰 PRICING GUIDE\n\n"
        response += guidance
        response += "\n\n"
        response += "💡 PRICING TIPS\n"
        response += "  • Price 10-15% above your minimum — leaves room for offers\n"
        response += "  • \"OBO\" (or best offer) gets more messages\n"
        response += "  • Relist after 7 days with a 10% drop if no interest\n"
        response += "  • Bundle related items for faster sale\n"
        response += "\nWant me to draft the listing at this price?"
        return .response(response)
    }

    // MARK: - Scam Detection (Hardcoded Rules)

    private static let scamPatterns: [(pattern: String, flag: String, severity: String)] = [
        ("pay more than asking", "🔴 OVERPAYMENT SCAM — Nobody pays more than listed price", "HIGH"),
        ("cashier's check", "🔴 FAKE CHECK SCAM — Cashier's checks can be forged", "HIGH"),
        ("shipping label", "🔴 SHIPPING SCAM — They send fake labels to get your address", "HIGH"),
        ("venmo me first", "🔴 PREPAYMENT SCAM — Never send money to a buyer", "HIGH"),
        ("zelle", "🟡 ZELLE RISK — Zelle payments are non-reversible; use for trusted only", "MEDIUM"),
        ("gift card", "🔴 GIFT CARD SCAM — Legitimate buyers never pay with gift cards", "HIGH"),
        ("my assistant", "🟡 PROXY SCAM — \"My assistant will pick up\" is often fake", "MEDIUM"),
        ("still available", "🟢 COMMON — This alone is normal, but watch for follow-up scam patterns", "LOW"),
        ("send to this address", "🟡 ADDRESS HARVEST — Don't share home address until verified meetup", "MEDIUM"),
        ("paypal friends", "🟡 NO PROTECTION — PayPal Friends & Family has zero buyer/seller protection", "MEDIUM"),
        ("deposit", "🔴 DEPOSIT SCAM — Don't accept or send deposits for marketplace items", "HIGH"),
        ("qr code", "🔴 QR SCAM — Scanning unknown QR codes can steal payment info", "HIGH"),
    ]

    private func scamDetection(message: String) -> SkillResult {
        let lower = message.lowercased()
        var flags: [(String, String)] = []

        for pattern in Self.scamPatterns {
            if lower.contains(pattern.pattern) {
                flags.append((pattern.flag, pattern.severity))
            }
        }

        var response = "🛡 SCAM CHECK\n\n"

        if flags.isEmpty {
            response += "No obvious red flags detected, but stay cautious.\n\n"
            response += "📋 GENERAL SCAM SIGNALS\n"
            response += "  • Buyer is overly eager / doesn't negotiate\n"
            response += "  • Asks to move off-platform immediately\n"
            response += "  • Won't meet in person\n"
            response += "  • Profile is brand new or has no history\n"
            response += "  • Sob story or urgency pressure\n"
        } else {
            let highCount = flags.filter { $0.1 == "HIGH" }.count
            if highCount > 0 {
                response += "⛔️ \(highCount) HIGH-RISK warning(s) detected!\n\n"
            }
            for (flag, _) in flags {
                response += "  \(flag)\n\n"
            }
        }

        response += "\n🔒 GOLDEN RULES\n"
        for rule in Self.safetyGuidelines {
            response += "  • \(rule)\n"
        }
        response += "\nWhen in doubt, walk away. No sale is worth your safety."
        return .response(response)
    }

    // MARK: - Safety Guidelines (Hardcoded)

    private static let safetyGuidelines = [
        "Meet at a police station or public place (many have designated spots)",
        "Bring someone with you — never meet alone",
        "Cash or verified payment only — count it in person",
        "Never share your home address until you know the buyer",
        "Daytime meetings only",
        "Trust your gut — if something feels off, cancel",
        "Screenshot the buyer's profile before meeting",
        "Tell someone where you're going and when to expect you back",
    ]
}
