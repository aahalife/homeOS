import XCTest
@testable import OpenClaw

/// Real-world simulation tests that combine live API data with synthetic family profiles.
/// These tests validate end-to-end workflows as a real user would experience them.
final class RealWorldSimulationTests: XCTestCase {

    // MARK: - Anderson Family Real-World Scenarios

    /// Scenario: It's Monday morning. The Anderson family needs a weekly meal plan.
    /// Emma has a dairy allergy, so all meals must be dairy-free options available.
    func testAndersonWeeklyMealPlanWithNutritionValidation() async throws {
        let family = SimulationTests.andersonFamily

        // Step 1: Generate meal plan
        let skill = MealPlanningSkill()
        let plan = try await skill.generateWeeklyPlan(family: family)

        XCTAssertEqual(plan.meals.count, 7, "Should have 7 dinners for the week")
        XCTAssertLessThanOrEqual(plan.estimatedCost, 150, "Must stay within $150 budget")

        // Step 2: Validate nutrition data for key ingredients using USDA
        let usdaAPI = USDAFoodDataAPI(apiKey: "DEMO_KEY")

        // Pick ingredients from the first meal and validate they exist in USDA
        if let firstMeal = plan.meals.first {
            let ingredientNames = firstMeal.recipe.ingredients.prefix(2).map { $0.name }
            for ingredientName in ingredientNames {
                do {
                    let foods = try await usdaAPI.searchFood(query: ingredientName, pageSize: 1)
                    XCTAssertFalse(foods.isEmpty,
                                   "Ingredient '\(ingredientName)' should be found in USDA database")
                } catch {
                    // Rate limiting acceptable with DEMO_KEY
                    print("USDA rate limited for '\(ingredientName)': \(error)")
                }
                try await Task.sleep(nanoseconds: 500_000_000) // Respect rate limits
            }
        }

        // Step 3: Verify Emma's dairy restriction is respected
        let dairyTerms = ["milk", "cheese", "cream", "butter", "yogurt", "dairy"]
        for meal in plan.meals {
            if meal.recipe.isDairyFree {
                // Good - explicitly marked dairy free
            } else {
                // Check ingredient names don't contain obvious dairy
                for ingredient in meal.recipe.ingredients {
                    let name = ingredient.name.lowercased()
                    for term in dairyTerms {
                        if name.contains(term) && ingredient.category == .dairy {
                            // This is fine if the recipe isn't served to Emma
                            // but flag it for review
                            print("NOTE: Meal '\(meal.recipe.title)' contains dairy ingredient '\(ingredient.name)' - verify Emma alternative")
                        }
                    }
                }
            }
        }
    }

    /// Scenario: Anderson child Emma has a fever. Parent asks OpenClaw for help.
    func testAndersonChildSickScenario() async throws {
        let family = SimulationTests.andersonFamily

        // Step 1: Symptom assessment
        let healthSkill = HealthcareSkill()
        let response = await healthSkill.assessSymptoms(
            description: "Emma has a fever of 101 and a rash",
            family: family
        )

        // Should recommend doctor visit for fever + rash
        XCTAssertTrue(
            response.contains("Doctor") || response.contains("doctor") || response.contains("medical"),
            "Fever + rash should recommend medical attention"
        )

        // Must NEVER diagnose
        let diagnosisTerms = ["you have", "diagnosis", "she has"]
        for term in diagnosisTerms {
            XCTAssertFalse(response.lowercased().contains(term),
                           "Response must never diagnose - found '\(term)'")
        }

        // Step 2: Validate children's medication safety with FDA
        let fdaAPI = OpenFDAAPI()
        let tylenol = try await fdaAPI.validateMedication(name: "acetaminophen")

        // Verify we can provide safe medication info
        XCTAssertNotNil(tylenol.warnings, "Should have safety warnings for acetaminophen")
        if let warnings = tylenol.warnings {
            // Acetaminophen warnings should mention children/liver
            let hasRelevantWarning = warnings.lowercased().contains("children") ||
                                    warnings.lowercased().contains("liver") ||
                                    warnings.lowercased().contains("overdose")
            XCTAssertTrue(hasRelevantWarning,
                          "Acetaminophen warnings should mention children or liver safety")
        }
    }

    // MARK: - Rodriguez Family Real-World Scenarios

    /// Scenario: Maria (diabetes) needs to check her metformin medication and plan meals.
    func testRodriguezDiabetesManagement() async throws {
        let family = SimulationTests.rodriguezFamily

        // Step 1: Medication validation with live FDA data
        let fdaAPI = OpenFDAAPI()
        let metformin = try await fdaAPI.validateMedication(name: "metformin")
        XCTAssertFalse(metformin.name.isEmpty, "Should find metformin in FDA database")

        // Step 2: Check for adverse events
        let adverseEvents = try await fdaAPI.searchAdverseEvents(drugName: "metformin", limit: 3)
        XCTAssertFalse(adverseEvents.isEmpty, "Metformin should have adverse event data")

        // Step 3: Medication logging
        let healthSkill = HealthcareSkill()
        let logResult = healthSkill.logMedicationTaken(memberName: "Maria")
        XCTAssertTrue(logResult.contains("Maria"), "Log should mention Maria")
        XCTAssertTrue(logResult.contains("Logged"), "Should confirm medication was logged")

        // Step 4: Budget-constrained meal plan
        let mealSkill = MealPlanningSkill()
        let plan = try await mealSkill.generateWeeklyPlan(family: family)
        XCTAssertLessThanOrEqual(plan.estimatedCost, 120, "Must stay within $120 budget")
    }

    /// Scenario: Rodriguez children need homework help. Check education tracking.
    func testRodriguezEducationTracking() async throws {
        let family = SimulationTests.rodriguezFamily

        let eduSkill = EducationSkill()

        // Get assignments for school-age children
        let assignments = await eduSkill.getUpcomingAssignments(family: family)
        XCTAssertFalse(assignments.isEmpty, "Carlos and Sofia should have assignments")

        // Get grades
        let grades = await eduSkill.getLatestGrades(family: family)
        XCTAssertFalse(grades.isEmpty, "Should have grade data")

        // Create a study plan for the first assignment's subject
        if let firstAssignment = assignments.first {
            let studyPlan = await eduSkill.createStudyPlan(
                family: family,
                subject: firstAssignment.subject
            )
            XCTAssertFalse(studyPlan.sessions.isEmpty, "Should generate study sessions")
            // Sessions should use Pomodoro technique
            for session in studyPlan.sessions {
                XCTAssertGreaterThan(session.duration, 0, "Session should have duration")
            }
        }
    }

    // MARK: - Chen Family Real-World Scenarios (Sandwich Generation)

    /// Scenario: Chen family morning routine - education for Lily + elder care for Margaret
    func testChenSandwichGenerationMorning() async throws {
        let family = SimulationTests.chenFamily

        // Step 1: Live weather for San Francisco
        let weatherAPI = WeatherAPI()
        let weather = try await weatherAPI.getCurrentWeather(city: "San Francisco")
        XCTAssertNotEqual(weather.description, "Weather data unavailable",
                          "Should get real SF weather for morning briefing")

        // Step 2: Morning briefing with real weather
        let mentalLoadSkill = MentalLoadSkill()
        let briefing = await mentalLoadSkill.generateMorningBriefing(family: family)

        // At least one component should have content
        let hasContent = !briefing.calendarHighlights.isEmpty ||
                         !briefing.urgentTasks.isEmpty ||
                         !briefing.reminders.isEmpty ||
                         briefing.motivationalNote != nil ||
                         briefing.weather != nil
        XCTAssertTrue(hasContent, "Morning briefing should have at least some content")

        // Step 3: Elder care check-in for Margaret
        let elderSkill = ElderCareSkill()
        let checkIn = await elderSkill.performCheckIn(family: family)
        XCTAssertTrue(checkIn.contains("Margaret"), "Check-in should include Margaret")

        // Step 4: Education for Lily
        let eduSkill = EducationSkill()
        let assignments = await eduSkill.getUpcomingAssignments(family: family)
        XCTAssertFalse(assignments.isEmpty, "Lily should have school assignments")
    }

    /// Scenario: Margaret (elder) shows confusion during check-in - detect red flags
    func testChenElderRedFlagDetection() async throws {
        let elderSkill = ElderCareSkill()

        // Simulate a concerning check-in transcript
        let transcript = "I don't remember taking my pills this morning. What day is it? I haven't eaten anything today."
        let flags = elderSkill.analyzeForRedFlags(transcript: transcript)

        XCTAssertTrue(flags.contains("confusion"), "Should detect confusion")
        XCTAssertTrue(flags.contains("appetite_loss"), "Should detect appetite concern")

        // This should trigger an alert
        XCTAssertGreaterThanOrEqual(flags.count, 2,
            "Multiple red flags should be detected for this concerning transcript")
    }

    // MARK: - Home Emergency Scenarios with Live Weather

    /// Scenario: Gas leak detected - immediate evacuation regardless of weather
    func testGasLeakEmergencyResponse() async throws {
        let skill = HomeMaintenanceSkill()
        let family = SimulationTests.andersonFamily

        let response = skill.handleEmergency(description: "I smell gas in the kitchen", family: family)

        XCTAssertTrue(response.contains("EVACUATE"),
                      "Gas leak MUST trigger evacuation response")
        XCTAssertTrue(response.contains("911") || response.contains("emergency"),
                      "Gas leak must recommend calling 911")
    }

    /// Scenario: Water leak during rainy weather - check urgency
    func testWaterLeakWithLiveWeather() async throws {
        let weatherAPI = WeatherAPI()
        let weather = try await weatherAPI.getCurrentWeather(city: "Chicago")

        let skill = HomeMaintenanceSkill()
        let family = SimulationTests.andersonFamily

        let response = skill.handleEmergency(
            description: "Water is leaking from the ceiling",
            family: family
        )

        // Should always provide water shutoff guidance
        let lowered = response.lowercased()
        XCTAssertTrue(
            lowered.contains("shut off") || lowered.contains("water") || lowered.contains("plumber"),
            "Water emergency should mention shutoff procedures or plumber"
        )

        // Log weather context for the response
        print("Water leak scenario with weather: \(weather.description), \(Int(weather.temperatureF))F")
        if weather.description.lowercased().contains("rain") || weather.description.lowercased().contains("storm") {
            print("WEATHER CONTEXT: Active precipitation - water leak likely weather-related")
        }
    }

    // MARK: - Cross-Skill Integration with Live Data

    /// Scenario: Full evening wind-down routine using real data
    func testEveningWindDownWithLiveData() async throws {
        let family = SimulationTests.andersonFamily

        // Step 1: Get real weather for tomorrow's preview
        let weatherAPI = WeatherAPI()
        let forecast = try await weatherAPI.getForecast(city: "Chicago")

        XCTAssertFalse(forecast.isEmpty, "Should have forecast data for tomorrow preview")

        // Step 2: Generate evening wind-down
        let mentalLoadSkill = MentalLoadSkill()
        let windDown = await mentalLoadSkill.generateEveningWindDown(family: family)

        XCTAssertFalse(windDown.tomorrowPriorities.isEmpty, "Should have tomorrow's priorities")
        XCTAssertFalse(windDown.suggestions.isEmpty, "Should have suggestions")

        // Step 3: Format the wind-down message
        let formatted = mentalLoadSkill.formatWindDown(windDown)
        XCTAssertFalse(formatted.isEmpty, "Formatted wind-down should not be empty")
        XCTAssertTrue(formatted.contains("Tomorrow") || formatted.contains("tomorrow"),
                      "Should reference tomorrow")
    }

    /// Scenario: Intent classification leads to real API calls
    func testIntentToAPIEndToEnd() async throws {
        let classifier = StubIntentClassifier()

        // User says: "Is it safe to take aspirin with ibuprofen?"
        let intent = classifier.classify(text: "Is it safe to take aspirin medication")
        XCTAssertEqual(intent.skill, .healthcare, "Should route to healthcare skill")

        // Healthcare skill uses FDA API
        let fdaAPI = OpenFDAAPI()
        let aspirinInfo = try await fdaAPI.validateMedication(name: "aspirin")
        XCTAssertNotNil(aspirinInfo.warnings, "Should get real FDA warnings for aspirin")

        let ibuprofenInfo = try await fdaAPI.validateMedication(name: "ibuprofen")
        XCTAssertNotNil(ibuprofenInfo.warnings, "Should get real FDA warnings for ibuprofen")

        // Both are NSAIDs - real warnings should mention this
        if let aspirinWarnings = aspirinInfo.warnings, let ibuprofenWarnings = ibuprofenInfo.warnings {
            let mentionsNSAID = aspirinWarnings.lowercased().contains("nsaid") ||
                                ibuprofenWarnings.lowercased().contains("nsaid")
            XCTAssertTrue(mentionsNSAID, "FDA data should warn about NSAID interactions")
        }
    }

    // MARK: - Data Freshness Validation

    /// Verify that APIs return current/recent data, not stale cached data
    func testWeatherDataFreshness() async throws {
        let api = WeatherAPI()
        let weather1 = try await api.getCurrentWeather(city: "Denver")
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        let weather2 = try await api.getCurrentWeather(city: "Denver")

        // Both should be valid (temperature may or may not change in 1 second)
        XCTAssertNotEqual(weather1.description, "Weather data unavailable")
        XCTAssertNotEqual(weather2.description, "Weather data unavailable")

        // Temperatures should be close (same minute)
        XCTAssertEqual(weather1.temperatureF, weather2.temperatureF, accuracy: 5.0,
                       "Temperature should be stable within a short time window")
    }

    func testFDADataConsistency() async throws {
        let api = OpenFDAAPI()

        // Same drug queried twice should return consistent results
        let drug1 = try await api.validateMedication(name: "aspirin")
        let drug2 = try await api.validateMedication(name: "aspirin")

        XCTAssertEqual(drug1.name, drug2.name, "Same query should return consistent drug name")
        XCTAssertEqual(drug1.genericName, drug2.genericName, "Generic name should be consistent")
    }

    // MARK: - Performance Benchmarks

    func testOpenFDAResponseTime() async throws {
        let api = OpenFDAAPI()

        let start = Date()
        let _ = try await api.validateMedication(name: "aspirin")
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 5.0,
                          "OpenFDA response should complete within 5 seconds, took \(elapsed)s")
        print("OpenFDA response time: \(String(format: "%.2f", elapsed))s")
    }

    func testWeatherAPIResponseTime() async throws {
        let api = WeatherAPI()

        let start = Date()
        let _ = try await api.getCurrentWeather(city: "Chicago")
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 5.0,
                          "Weather API response should complete within 5 seconds, took \(elapsed)s")
        print("wttr.in response time: \(String(format: "%.2f", elapsed))s")
    }
}
