import Foundation

/// Home Maintenance Skill - Emergency triage, contractor search, maintenance scheduling
final class HomeMaintenanceSkill {
    private let placesAPI = GooglePlacesAPI()
    private let weatherAPI = WeatherAPI()
    private let persistence = PersistenceController.shared
    private let logger = AppLogger.shared

    // MARK: - Emergency Handling

    func handleEmergency(description: String, family: Family) -> String {
        let lower = description.lowercased()
        let emergencyType = classifyEmergency(lower)
        let protocol_ = getEmergencyProtocol(for: emergencyType)

        var response = ""

        if protocol_.evacuate {
            response += "**EVACUATE IMMEDIATELY**\n\n"
        }

        if protocol_.callEmergencyServices {
            response += "**Call 911 NOW**\n\n"
        }

        response += "**\(emergencyType.rawValue) - Safety Steps:**\n\n"

        for step in protocol_.steps {
            let prefix = step.isUrgent ? "[URGENT] " : ""
            response += "\(step.stepNumber). \(prefix)\(step.instruction)\n"
            if let warning = step.warning {
                response += "   Warning: \(warning)\n"
            }
        }

        // Add shutoff info if available
        let profiles: [HomeProfile] = persistence.loadData(type: "home_profile")
        if let home = profiles.first, let shutoffs = home.shutoffLocations {
            response += "\n**Your Shutoff Locations:**\n"
            if let water = shutoffs.waterMainLocation, emergencyType == .majorWaterLeak {
                response += "- Water main: \(water)\n"
            }
            if let gas = shutoffs.gasShutoffLocation, emergencyType == .gasLeak {
                response += "- Gas shutoff: \(gas)\n"
            }
            if let electric = shutoffs.electricalPanelLocation, emergencyType == .electricalFire {
                response += "- Electrical panel: \(electric)\n"
            }
        }

        // Log the emergency
        let record = RepairRecord(date: Date(), description: description, category: .general, notes: "Emergency reported")
        persistence.saveData(record, type: "repair_record")

        return response
    }

    // MARK: - Contractor Search

    func searchContractors(query: String, family: Family) async throws -> [ServiceProvider] {
        // Try saved contractors first
        let profiles: [HomeProfile] = persistence.loadData(type: "home_profile")
        let saved = profiles.first?.savedContractors.filter {
            $0.serviceType.rawValue.lowercased().contains(query.lowercased()) ||
            $0.name.lowercased().contains(query.lowercased())
        } ?? []

        if !saved.isEmpty { return saved }

        // Search via Google Places
        if placesAPI.isConfigured {
            return try await placesAPI.textSearch(query: "\(query) near me")
        }

        // Fallback to stubs
        return StubContractorData.sampleProviders(for: query)
    }

    // MARK: - Maintenance Schedule

    func getMaintenanceSchedule(family: Family) -> [MaintenanceTask] {
        let stored: [MaintenanceTask] = persistence.loadData(type: "maintenance_tasks")
        if !stored.isEmpty { return stored.sorted { $0.nextDue < $1.nextDue } }

        // Generate default schedule
        let now = Date()
        return [
            MaintenanceTask(title: "Change HVAC Filter", description: "Replace air filter", frequency: .monthly, nextDue: now.addingDays(15), priority: .medium, category: .hvac),
            MaintenanceTask(title: "Test Smoke Detectors", description: "Press test button on all smoke detectors", frequency: .monthly, nextDue: now.addingDays(7), priority: .high, category: .general),
            MaintenanceTask(title: "Clean Gutters", description: "Remove debris from gutters and downspouts", frequency: .semiAnnual, nextDue: now.addingDays(30), priority: .medium, category: .general),
            MaintenanceTask(title: "Service HVAC", description: "Professional HVAC inspection and tune-up", frequency: .semiAnnual, nextDue: now.addingDays(60), priority: .medium, category: .hvac),
            MaintenanceTask(title: "Water Heater Flush", description: "Drain and flush water heater tank", frequency: .annual, nextDue: now.addingDays(90), priority: .low, category: .plumber),
            MaintenanceTask(title: "Inspect Roof", description: "Check for damaged shingles and leaks", frequency: .annual, nextDue: now.addingDays(120), priority: .medium, category: .roofing),
            MaintenanceTask(title: "Pest Inspection", description: "Professional termite and pest inspection", frequency: .annual, nextDue: now.addingDays(180), priority: .low, category: .pest)
        ]
    }

    // MARK: - Environmental Assessment

    func assessEnvironmentalUrgency(emergencyType: EmergencyType, city: String?) async -> String {
        guard let city = city else { return "" }

        do {
            let weather = try await weatherAPI.getCurrentWeather(city: city)

            switch emergencyType {
            case .noHeat:
                if weather.temperatureF < 32 {
                    return "**CRITICAL:** Outside temperature is \(Int(weather.temperatureF))F. This is dangerous. Seek alternative heating immediately."
                } else if weather.temperatureF < 50 {
                    return "**URGENT:** Outside temperature is \(Int(weather.temperatureF))F. Schedule emergency HVAC repair today."
                }
            case .noAC:
                if weather.temperatureF > 95 {
                    return "**CRITICAL:** Outside temperature is \(Int(weather.temperatureF))F. Stay hydrated and find a cool space."
                }
            default: break
            }
        } catch {
            logger.warning("Weather check failed: \(error.localizedDescription)")
        }

        return ""
    }

    // MARK: - Emergency Classification

    private func classifyEmergency(_ description: String) -> EmergencyType {
        if description.contains("gas") && (description.contains("leak") || description.contains("smell")) { return .gasLeak }
        if description.contains("flood") || description.contains("water leak") || description.contains("burst pipe") || description.contains("broken pipe") || description.contains("leaking") { return .majorWaterLeak }
        if description.contains("fire") || description.contains("smoke") || description.contains("burning") { return .electricalFire }
        if description.contains("sewer") || description.contains("sewage") { return .sewageBackup }
        if description.contains("no heat") || description.contains("heater broken") || description.contains("furnace") { return .noHeat }
        if description.contains("no ac") || description.contains("air condition") || description.contains("not cooling") { return .noAC }
        if description.contains("roof") && (description.contains("leak") || description.contains("damage")) { return .roofDamage }
        if description.contains("locked out") { return .lockedOut }
        if description.contains("window") && description.contains("broken") { return .brokenWindow }
        return .other
    }

    private func getEmergencyProtocol(for type: EmergencyType) -> SafetyProtocol {
        switch type {
        case .gasLeak:
            return SafetyProtocol(
                emergencyType: type, level: .emergency, steps: [
                    SafetyStep(stepNumber: 1, instruction: "Do NOT turn on/off any lights or electrical switches", isUrgent: true, warning: "Sparks can ignite gas"),
                    SafetyStep(stepNumber: 2, instruction: "Do NOT use your phone inside the house", isUrgent: true),
                    SafetyStep(stepNumber: 3, instruction: "Open windows if safe to do so on your way out"),
                    SafetyStep(stepNumber: 4, instruction: "Evacuate everyone including pets immediately", isUrgent: true),
                    SafetyStep(stepNumber: 5, instruction: "Once safely outside, call 911"),
                    SafetyStep(stepNumber: 6, instruction: "Call your gas utility company emergency line"),
                    SafetyStep(stepNumber: 7, instruction: "Do not re-enter until cleared by fire department")
                ],
                callEmergencyServices: true, evacuate: true
            )
        case .majorWaterLeak:
            return SafetyProtocol(
                emergencyType: type, level: .critical, steps: [
                    SafetyStep(stepNumber: 1, instruction: "Shut off the main water valve", isUrgent: true),
                    SafetyStep(stepNumber: 2, instruction: "Turn off electricity to affected areas if water is near outlets", isUrgent: true, warning: "Do not touch electrical equipment while standing in water"),
                    SafetyStep(stepNumber: 3, instruction: "Move valuables away from water"),
                    SafetyStep(stepNumber: 4, instruction: "Place towels and buckets to contain water"),
                    SafetyStep(stepNumber: 5, instruction: "Call an emergency plumber"),
                    SafetyStep(stepNumber: 6, instruction: "Document damage with photos for insurance")
                ],
                callEmergencyServices: false, evacuate: false
            )
        case .electricalFire:
            return SafetyProtocol(
                emergencyType: type, level: .emergency, steps: [
                    SafetyStep(stepNumber: 1, instruction: "Call 911 immediately", isUrgent: true),
                    SafetyStep(stepNumber: 2, instruction: "Do NOT use water on electrical fires", isUrgent: true, warning: "Water conducts electricity"),
                    SafetyStep(stepNumber: 3, instruction: "If small, use a Class C fire extinguisher"),
                    SafetyStep(stepNumber: 4, instruction: "If spreading, evacuate immediately", isUrgent: true),
                    SafetyStep(stepNumber: 5, instruction: "Close doors behind you to slow spread"),
                    SafetyStep(stepNumber: 6, instruction: "Meet at your designated meeting spot outside")
                ],
                callEmergencyServices: true, evacuate: true
            )
        default:
            return SafetyProtocol(
                emergencyType: type, level: .urgent, steps: [
                    SafetyStep(stepNumber: 1, instruction: "Assess the situation and ensure everyone is safe"),
                    SafetyStep(stepNumber: 2, instruction: "Document the issue with photos"),
                    SafetyStep(stepNumber: 3, instruction: "Contact a relevant service professional"),
                    SafetyStep(stepNumber: 4, instruction: "Take temporary measures to prevent further damage")
                ],
                callEmergencyServices: false, evacuate: false
            )
        }
    }
}
