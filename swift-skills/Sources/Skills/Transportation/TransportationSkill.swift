import Foundation
import HomeOSCore

public struct TransportationSkill: SkillProtocol {
    public let name = "transportation"
    public let description = "Manage rides, commutes, carpools, and parking"
    public let triggerKeywords = ["uber", "lyft", "ride", "commute", "traffic", "carpool", "parking", "drive", "airport"]
    
    public init() {}
    
    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }
    
    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()
        
        if message.contains("uber") || message.contains("lyft") || message.contains("ride") {
            return try await rideEstimate(context: context)
        } else if message.contains("commute") || message.contains("traffic") || message.contains("how long") {
            return commuteCheck(context: context)
        } else if message.contains("carpool") {
            return carpoolHelp(context: context)
        } else {
            return commuteCheck(context: context)
        }
    }
    
    private func rideEstimate(context: SkillContext) async throws -> SkillResult {
        // Ride booking is HIGH risk — always needs approval
        let response = """
        🚗 RIDE OPTIONS
        
        To get an estimate, I need:
        1. 📍 Where are you now?
        2. 🎯 Where are you going?
        3. 👥 How many passengers?
        
        Once you choose a ride, I'll need your explicit approval before booking.
        
        ⚠️ Booking a ride will charge your account.
        """
        return .response(response)
    }
    
    private func commuteCheck(context: SkillContext) -> SkillResult {
        // LOW risk — just information
        return .response("""
        🚗 COMMUTE CHECK
        
        To check travel time:
        1. Where are you going?
        2. When do you need to arrive?
        
        I'll calculate when you should leave, accounting for traffic.
        
        💡 Tip: Check Google Maps or Waze for real-time traffic.
        """)
    }
    
    private func carpoolHelp(context: SkillContext) -> SkillResult {
        let children = context.family.children
        return .response("""
        🚗 CARPOOL SETUP
        
        \(children.isEmpty ? "No children in profile." : "Kids: \(children.map { $0.name }.joined(separator: ", "))")
        
        To set up a carpool:
        1. What event/activity?
        2. Who else is in the carpool?
        3. What days/times?
        4. Who drives which days?
        
        I'll create a schedule and send reminders!
        """)
    }
}
