import Foundation
import HomeOSCore

public struct TelephonySkill: SkillProtocol {
    public let name = "telephony"
    public let description = "AI-powered voice calls for reservations and appointments"
    public let triggerKeywords = ["call", "phone", "dial", "phone call", "call the", "ring"]
    
    public init() {}
    
    public func canHandle(intent: UserIntent) -> Double {
        let msg = intent.rawMessage.lowercased()
        // Must contain "call" in context of making a phone call
        if (msg.contains("call") && (msg.contains("restaurant") || msg.contains("doctor") || msg.contains("book"))) { return 0.8 }
        let matches = triggerKeywords.filter { msg.contains($0) }
        return min(Double(matches.count) * 0.2, 0.7) // Lower confidence — "call" is ambiguous
    }
    
    public func execute(context: SkillContext) async throws -> SkillResult {
        // ALL phone calls are HIGH risk — always require explicit approval
        return .needsApproval(ApprovalRequest(
            description: "Make a phone call on your behalf",
            details: [
                "I can make AI voice calls to businesses for reservations, appointments, etc.",
                "You'll see the full script before I call.",
                "I will NOT provide credit card or sensitive info.",
                "I need: business name, phone number, and what to say."
            ],
            riskLevel: .high,
            onDecision: { approved in
                if approved {
                    return .response("""
                    📞 PHONE CALL SETUP
                    
                    To make this call, I need:
                    1. 📞 Business name and phone number
                    2. 📝 What should I say? (reservation details, appointment request, etc.)
                    3. 🗒️ Name for the booking
                    4. ⏰ Time flexibility?
                    
                    I'll prepare a script for your review before calling.
                    """)
                } else {
                    return .response("No worries! I can help you prepare what to say if you'd rather call yourself.")
                }
            }
        ))
    }
}
