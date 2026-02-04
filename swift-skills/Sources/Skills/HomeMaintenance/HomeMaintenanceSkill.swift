import Foundation
import HomeOSCore

public struct HomeMaintenanceSkill: SkillProtocol {
    public let name = "home-maintenance"
    public let description = "Handle home repairs, maintenance, and emergencies with safety-first approach"
    public let triggerKeywords = ["repair", "fix", "broken", "plumber", "electrician", "hvac", "maintenance", "leak", "gas smell", "flood", "no heat", "no ac", "emergency"]
    
    public init() {}
    
    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }
    
    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()
        let severity = classifySeverity(message)
        
        switch severity {
        case .emergency:
            return handleEmergency(message: message, context: context)
        case .urgent:
            return try await handleUrgent(message: message, context: context)
        case .routine:
            return try await handleRoutine(message: message, context: context)
        }
    }
    
    // MARK: - Severity Classification (DETERMINISTIC — never use LLM)
    
    private enum Severity { case emergency, urgent, routine }
    
    private func classifySeverity(_ message: String) -> Severity {
        let emergencyPatterns = ["gas smell", "smell gas", "gas leak", "fire", "smoke", "burning smell",
                                  "sparks", "flood", "burst pipe", "sewage backup", "major leak"]
        let urgentPatterns = ["no heat", "no hot water", "ac broken", "no cooling", "no electricity",
                              "power out", "frozen pipe", "toilet overflow"]
        
        for pattern in emergencyPatterns {
            if message.contains(pattern) { return .emergency }
        }
        for pattern in urgentPatterns {
            if message.contains(pattern) { return .urgent }
        }
        return .routine
    }
    
    // MARK: - Emergency (HARDCODED instructions — never LLM-generated)
    
    private func handleEmergency(message: String, context: SkillContext) -> SkillResult {
        if message.contains("gas") {
            return .response("""
            🚨 GAS EMERGENCY — DO THIS NOW:
            
            1. DO NOT touch ANY switches or appliances
            2. DO NOT use your phone inside
            3. Open windows as you exit
            4. Get everyone outside NOW
            5. Call gas company from OUTSIDE
            6. Call 911 if smell is strong
            
            ❌ DO NOT: light flames, flip switches, start car in garage
            
            This is a life-safety emergency. Exit first, call second.
            """)
        }
        
        if message.contains("fire") || message.contains("smoke") || message.contains("burning") {
            return .response("""
            🚨 FIRE EMERGENCY:
            
            1. Get everyone out immediately
            2. Call 911 from outside
            3. Do NOT go back inside for anything
            4. Meet at your designated meeting spot
            5. Close doors behind you as you leave
            
            If small and contained: Use fire extinguisher ONLY if you can do so safely while staying near an exit.
            """)
        }
        
        // Water emergency
        return .response("""
        🚨 WATER EMERGENCY — ACT FAST:
        
        1. TURN OFF MAIN WATER VALVE
           📍 Check: basement near front wall, near water heater, garage, or street meter box
        2. Turn off electricity in affected areas (if water near outlets)
        3. Move valuables away from water
        4. Take photos/video for insurance
        5. Start removing water (towels, wet vac, mops)
        
        📞 Call an emergency plumber NOW.
        
        Do you know where your main water shutoff is?
        """)
    }
    
    // MARK: - Urgent Issues
    
    private func handleUrgent(message: String, context: SkillContext) async throws -> SkillResult {
        var quickChecks = ""
        var proType = ""
        
        if message.contains("heat") || message.contains("furnace") {
            proType = "HVAC"
            quickChecks = """
            ⚡ Quick checks first:
            1. Thermostat set to HEAT and above room temp?
            2. Filter clean? (dirty = no airflow)
            3. Circuit breaker tripped?
            4. Pilot light on? (gas furnace)
            
            🏠 Stay warm while waiting:
            • Close off unused rooms
            • Hang blankets over windows
            • Let faucets drip slightly to prevent pipe freezing
            """
        } else if message.contains("ac") || message.contains("cool") {
            proType = "HVAC"
            quickChecks = """
            ⚡ Quick checks first:
            1. Thermostat set to COOL and below room temp?
            2. Filter clean?
            3. Outside unit fan spinning?
            4. Circuit breaker tripped?
            5. Ice on lines? (turn off, let thaw 2 hrs)
            """
        } else {
            proType = "electrician"
            quickChecks = """
            ⚡ Quick checks:
            1. Check circuit breaker panel
            2. Flip tripped breaker OFF then ON
            3. Test with a device you KNOW works
            ⚠️ If breaker keeps tripping, leave it off and call electrician
            """
        }
        
        // Check for saved provider
        let provider = try? await context.storage.read(path: "data/providers.json", type: [String: ProviderInfo].self)
        let savedPro = provider?[proType.lowercased()]
        
        var response = "⚠️ URGENT: \(proType) Issue\n\n\(quickChecks)\n\n"
        
        if let pro = savedPro {
            response += "📞 YOUR SAVED \(proType) PRO:\n"
            response += "  \(pro.name)\n  📞 \(pro.phone)\n  ⭐ \(pro.rating)/5\n"
        } else {
            response += "🔍 Search: \"emergency \(proType.lowercased()) near me\"\n"
        }
        
        response += "\nDid any quick checks fix it?"
        
        return .response(response)
    }
    
    // MARK: - Routine Issues
    
    private func handleRoutine(message: String, context: SkillContext) async throws -> SkillResult {
        let prompt = """
        User has a home maintenance issue: "\(context.intent.rawMessage)"
        Classify: is this DIY-friendly or needs a professional?
        If DIY: give 3-5 steps. If pro needed: explain why and what type.
        """
        let schema = JSONSchema.object(properties: [
            "isDIY": "boolean",
            "explanation": "string",
            "steps": "array",
            "proType": "string",
            "estimatedCost": "string"
        ])
        
        let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
        
        guard let data = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .response("🔧 Tell me more about the issue — what exactly is happening, when did it start, and have you tried anything? This helps me determine if it's a DIY fix or needs a pro.")
        }
        
        let isDIY = result["isDIY"] as? Bool ?? false
        let explanation = result["explanation"] as? String ?? ""
        let cost = result["estimatedCost"] as? String ?? "varies"
        
        if isDIY {
            return .response("🛠️ DIY FIX\n\n\(explanation)\n\n💰 Estimated cost: \(cost)\n\n⚠️ Call a pro if the fix doesn't work or you're not comfortable.")
        } else {
            let proType = result["proType"] as? String ?? "handyman"
            return .response("👨🔧 NEEDS A PRO (\(proType))\n\n\(explanation)\n\n💰 Estimated cost: \(cost)\n\nWant me to help find a \(proType)?")
        }
    }
}

private struct ProviderInfo: Codable {
    let name: String
    let phone: String
    let rating: Int
}
