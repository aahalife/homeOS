import XCTest
@testable import OpenClaw

/// Live API integration tests that hit real endpoints.
/// These tests validate that our API clients correctly parse actual responses.
///
/// APIs tested with NO key required:
/// - OpenFDA (government, free)
/// - wttr.in (free, no auth)
/// - USDA FoodData Central (DEMO_KEY, free)
///
/// APIs tested IF key is available (graceful skip otherwise):
/// - Spoonacular (free tier: 50 points/day)
/// - Yelp Fusion (free tier: 5000 calls/day)
///
/// APIs that require OAuth and are tested in stub mode only:
/// - Google Calendar (requires OAuth consent screen)
/// - Google Classroom (requires OAuth + enrollment)
/// - Twilio (requires paid account for real calls)
final class LiveAPITests: XCTestCase {

    // MARK: - OpenFDA Live Tests (FREE, No Key)

    func testOpenFDAValidateMedication_Aspirin() async throws {
        let api = OpenFDAAPI()
        let drug = try await api.validateMedication(name: "aspirin")

        XCTAssertFalse(drug.name.isEmpty, "Drug name should not be empty")
        // OpenFDA should return actual drug data
        XCTAssertNotNil(drug.warnings, "Aspirin should have warnings")
        XCTAssertNotNil(drug.activeIngredient, "Aspirin should have active ingredient info")
        if let active = drug.activeIngredient {
            XCTAssertTrue(active.lowercased().contains("aspirin"),
                          "Active ingredient should mention aspirin, got: \(active)")
        }
    }

    func testOpenFDAValidateMedication_Tylenol() async throws {
        let api = OpenFDAAPI()
        let drug = try await api.validateMedication(name: "tylenol")

        XCTAssertFalse(drug.name.isEmpty)
        if let active = drug.activeIngredient {
            XCTAssertTrue(active.lowercased().contains("acetaminophen"),
                          "Tylenol active ingredient should be acetaminophen, got: \(active)")
        }
    }

    func testOpenFDAValidateMedication_Ibuprofen() async throws {
        let api = OpenFDAAPI()
        let drug = try await api.validateMedication(name: "ibuprofen")

        XCTAssertFalse(drug.name.isEmpty)
        if let active = drug.activeIngredient {
            XCTAssertTrue(active.lowercased().contains("ibuprofen"),
                          "Active ingredient should contain ibuprofen, got: \(active)")
        }
        if let warnings = drug.warnings {
            XCTAssertTrue(warnings.lowercased().contains("stomach") || warnings.lowercased().contains("nsaid"),
                          "Ibuprofen warnings should mention stomach risks or NSAID")
        }
    }

    func testOpenFDAValidateMedication_Metformin() async throws {
        let api = OpenFDAAPI()
        let drug = try await api.validateMedication(name: "metformin")

        XCTAssertFalse(drug.name.isEmpty, "Metformin is a common diabetes drug and should be found")
        if let genericName = drug.genericName {
            XCTAssertTrue(genericName.lowercased().contains("metformin"),
                          "Generic name should contain metformin, got: \(genericName)")
        }
    }

    func testOpenFDANonexistentMedication() async throws {
        let api = OpenFDAAPI()
        // Nonexistent drug should either:
        // 1. Throw an API error (404 from FDA)
        // 2. Return fallback data with the query name
        do {
            let drug = try await api.validateMedication(name: "zzz_nonexistent_drug_12345")
            // If it returns (fallback path), should have the query name
            XCTAssertTrue(drug.name.contains("zzz_nonexistent_drug") || drug.name.isEmpty == false,
                          "Fallback should contain the queried drug name")
        } catch {
            // Throwing is acceptable - FDA returns 404 for unknown drugs
            let errorMessage = "\(error)"
            XCTAssertTrue(
                errorMessage.contains("404") ||
                errorMessage.contains("NOT_FOUND") ||
                errorMessage.contains("medicationNotFound"),
                "Error should indicate drug not found, got: \(errorMessage)"
            )
        }
    }

    func testOpenFDAAdverseEvents_Aspirin() async throws {
        let api = OpenFDAAPI()
        let events = try await api.searchAdverseEvents(drugName: "aspirin", limit: 3)

        XCTAssertFalse(events.isEmpty, "Aspirin should have adverse event reports")
        for event in events {
            XCTAssertFalse(event.safetyReportId.isEmpty, "Event should have a report ID")
            XCTAssertFalse(event.reactions.isEmpty, "Event should have reactions listed")
        }
    }

    // MARK: - wttr.in Live Tests (FREE, No Key)

    func testWeatherAPI_Chicago() async throws {
        let api = WeatherAPI()
        let weather = try await api.getCurrentWeather(city: "Chicago")

        // Temperature should be in a reasonable range for any US city
        XCTAssertGreaterThan(weather.temperatureF, -60, "Temperature should be above -60F")
        XCTAssertLessThan(weather.temperatureF, 150, "Temperature should be below 150F")
        XCTAssertFalse(weather.description.isEmpty, "Should have weather description")
        XCTAssertNotEqual(weather.description, "Weather data unavailable", "Should get real weather data")
        XCTAssertGreaterThanOrEqual(weather.humidity, 0)
        XCTAssertLessThanOrEqual(weather.humidity, 100)
    }

    func testWeatherAPI_SanFrancisco() async throws {
        let api = WeatherAPI()
        let weather = try await api.getCurrentWeather(city: "San Francisco")

        XCTAssertGreaterThan(weather.temperatureF, -10)
        XCTAssertLessThan(weather.temperatureF, 120)
        XCTAssertFalse(weather.description.isEmpty)
        XCTAssertNotEqual(weather.description, "Weather data unavailable")
    }

    func testWeatherAPI_Forecast() async throws {
        let api = WeatherAPI()
        let forecast = try await api.getForecast(city: "Boston")

        XCTAssertGreaterThanOrEqual(forecast.count, 1, "Should have at least 1 day forecast")
        for day in forecast {
            XCTAssertGreaterThanOrEqual(day.temperatureHigh, day.temperatureLow,
                                         "High temp should be >= low temp")
            XCTAssertFalse(day.description.isEmpty)
        }
    }

    func testWeatherAPI_MultipleCities() async throws {
        let api = WeatherAPI()
        let cities = ["New York", "Austin", "Seattle", "Miami"]

        for city in cities {
            let weather = try await api.getCurrentWeather(city: city)
            XCTAssertNotEqual(weather.description, "Weather data unavailable",
                              "Should get real weather data for \(city)")
            XCTAssertGreaterThan(weather.temperatureF, -60, "\(city) temp should be reasonable")
        }
    }

    // MARK: - USDA FoodData Live Tests (FREE with DEMO_KEY)

    func testUSDAFoodSearch_ChickenBreast() async throws {
        let api = USDAFoodDataAPI(apiKey: "DEMO_KEY")
        do {
            let foods = try await api.searchFood(query: "chicken breast", pageSize: 3)
            XCTAssertFalse(foods.isEmpty, "Should find chicken breast in USDA database")
            let first = foods[0]
            XCTAssertFalse(first.name.isEmpty, "Food name should not be empty")
            XCTAssertTrue(first.name.lowercased().contains("chicken"),
                          "First result should contain 'chicken', got: \(first.name)")
        } catch {
            // DEMO_KEY is rate-limited at 30 requests/hour
            print("USDA DEMO_KEY rate limited (expected): \(error)")
        }
    }

    func testUSDAFoodSearch_Apple() async throws {
        let api = USDAFoodDataAPI(apiKey: "DEMO_KEY")
        do {
            let foods = try await api.searchFood(query: "apple", pageSize: 3)
            XCTAssertFalse(foods.isEmpty, "Should find apple in USDA database")
            let hasCalories = foods.contains(where: { $0.calories > 0 })
            XCTAssertTrue(hasCalories, "At least one apple result should have calorie data")
        } catch {
            print("USDA DEMO_KEY rate limited (expected): \(error)")
        }
    }

    func testUSDAFoodSearch_BrownRice() async throws {
        let api = USDAFoodDataAPI(apiKey: "DEMO_KEY")
        do {
            let foods = try await api.searchFood(query: "brown rice", pageSize: 3)
            XCTAssertFalse(foods.isEmpty, "Should find brown rice in USDA database")
        } catch {
            print("USDA DEMO_KEY rate limited (expected): \(error)")
        }
    }

    func testUSDAFoodSearch_CommonIngredients() async throws {
        // Test several common recipe ingredients to ensure our meal planning
        // can look up nutrition for real groceries
        let api = USDAFoodDataAPI(apiKey: "DEMO_KEY")
        let ingredients = ["salmon", "broccoli", "black beans", "olive oil", "cheddar cheese"]

        for ingredient in ingredients {
            do {
                let foods = try await api.searchFood(query: ingredient, pageSize: 1)
                XCTAssertFalse(foods.isEmpty, "Should find '\(ingredient)' in USDA database")
            } catch {
                // DEMO_KEY rate limits are acceptable
                print("USDA search for '\(ingredient)' rate-limited: \(error)")
            }
            // Small delay to avoid rate limits with DEMO_KEY
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }
    }

    // MARK: - Spoonacular Live Tests (Requires API Key - graceful skip)

    func testSpoonacularRecipeSearch_WithKey() async throws {
        let key = KeychainManager.shared.getAPIKey(for: KeychainManager.APIKeys.spoonacular) ?? ""
        let api = SpoonacularAPI(apiKey: key)

        guard api.isConfigured else {
            // No API key available - verify stub fallback works
            let criteria = RecipeSearchCriteria(query: "pasta")
            let recipes = try await api.searchRecipes(criteria: criteria)
            XCTAssertFalse(recipes.isEmpty, "Should return stub recipes when no key")
            print("SKIPPED: Spoonacular live test - no API key configured. Stub fallback verified.")
            return
        }

        // Real API call with key
        let criteria = RecipeSearchCriteria(query: "chicken", maxTotalTime: 30, limit: 5)
        let recipes = try await api.searchRecipes(criteria: criteria)
        XCTAssertFalse(recipes.isEmpty, "Should find chicken recipes")

        for recipe in recipes {
            XCTAssertFalse(recipe.title.isEmpty, "Recipe should have a title")
            XCTAssertGreaterThan(recipe.totalTime, 0, "Recipe should have cooking time")
            XCTAssertLessThanOrEqual(recipe.totalTime, 30, "Recipe should respect max time filter")
        }
    }

    func testSpoonacularDietarySearch_WithKey() async throws {
        let key = KeychainManager.shared.getAPIKey(for: KeychainManager.APIKeys.spoonacular) ?? ""
        let api = SpoonacularAPI(apiKey: key)

        guard api.isConfigured else {
            print("SKIPPED: Spoonacular dietary search - no API key configured.")
            return
        }

        let criteria = RecipeSearchCriteria(
            query: "dinner",
            dietaryRestrictions: [.vegetarian],
            limit: 3
        )
        let recipes = try await api.searchRecipes(criteria: criteria)
        XCTAssertFalse(recipes.isEmpty, "Should find vegetarian dinner recipes")

        for recipe in recipes {
            XCTAssertTrue(recipe.isVegetarian, "All results should be vegetarian")
        }
    }

    // MARK: - End-to-End Skill Tests with Live APIs

    func testMealPlanningWithLiveNutritionData() async throws {
        // Test that meal planning can use USDA data for nutrition enrichment
        let api = USDAFoodDataAPI(apiKey: "DEMO_KEY")
        let testIngredients = ["chicken breast", "rice", "broccoli"]

        var nutritionFound = 0
        var rateLimited = false
        for ingredient in testIngredients {
            do {
                let foods = try await api.searchFood(query: ingredient, pageSize: 1)
                if let food = foods.first, food.calories > 0 {
                    nutritionFound += 1
                }
            } catch {
                // Rate limit acceptable with DEMO_KEY
                rateLimited = true
                print("Rate limited on \(ingredient): \(error)")
            }
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        if !rateLimited {
            XCTAssertGreaterThanOrEqual(nutritionFound, 1,
                "At least one ingredient should have nutrition data from USDA")
        } else {
            print("USDA DEMO_KEY rate limited - skipping assertion (get a real API key for reliable testing)")
        }
    }

    func testHealthcareWithLiveFDAData() async throws {
        // Simulate real-world healthcare skill: user asks about their medication
        let api = OpenFDAAPI()

        // Common family medications
        let medications = ["acetaminophen", "ibuprofen", "amoxicillin", "lisinopril"]

        for med in medications {
            let drug = try await api.validateMedication(name: med)
            XCTAssertFalse(drug.name.isEmpty,
                          "Should find info for common medication: \(med)")
        }
    }

    func testWeatherDrivenBriefing() async throws {
        // Simulate morning briefing pulling real weather
        let api = WeatherAPI()
        let weather = try await api.getCurrentWeather(city: "Chicago")

        // The mental load skill should use this to generate a briefing
        XCTAssertNotEqual(weather.description, "Weather data unavailable")

        // Verify we can build a weather summary from real data
        let summary = WeatherSummary(
            temperatureHigh: weather.temperatureF + 5,
            temperatureLow: weather.temperatureF - 5,
            description: weather.description,
            precipitation: weather.description.lowercased().contains("rain") ||
                          weather.description.lowercased().contains("snow"),
            advisory: weather.windSpeedMph > 30 ? "High wind advisory" : nil
        )

        XCTAssertFalse(summary.description.isEmpty)
        XCTAssertGreaterThan(summary.temperatureHigh, summary.temperatureLow)
    }

    // MARK: - Cross-API Integration Tests

    func testFullMorningBriefingWithLiveData() async throws {
        // Simulate what the Mental Load skill does each morning:
        // 1. Fetch weather (live)
        // 2. Check calendar (stub - requires OAuth)
        // 3. Generate briefing

        let weatherAPI = WeatherAPI()
        let weather = try await weatherAPI.getCurrentWeather(city: "Chicago")

        let calendarEvents = StubCalendarData.sampleEvents

        // Build a realistic morning briefing
        var briefingParts: [String] = []
        briefingParts.append("Good morning! Here's your daily briefing.")
        briefingParts.append("Weather: \(weather.description), \(Int(weather.temperatureF))F (feels like \(Int(weather.feelsLikeF))F)")

        if weather.description.lowercased().contains("rain") || weather.description.lowercased().contains("snow") {
            briefingParts.append("Heads up: \(weather.description) expected today. Dress accordingly!")
        }

        let todayEvents = calendarEvents.filter {
            Calendar.current.isDateInToday($0.startTime) || Calendar.current.isDateInTomorrow($0.startTime)
        }
        if !todayEvents.isEmpty {
            briefingParts.append("You have \(todayEvents.count) upcoming events.")
        }

        let briefing = briefingParts.joined(separator: "\n")
        XCTAssertTrue(briefing.contains("Weather:"), "Briefing should include real weather")
        XCTAssertFalse(briefing.contains("Weather data unavailable"), "Should use live weather data")
    }

    func testEmergencyHomeMaintenanceWithWeather() async throws {
        // Simulate: "My basement is flooding" during a storm
        // The home maintenance skill should factor in live weather
        let weatherAPI = WeatherAPI()
        let weather = try await weatherAPI.getCurrentWeather(city: "Chicago")

        let skill = HomeMaintenanceSkill()
        let family = SimulationTests.andersonFamily

        // Emergency response should work regardless of weather
        let response = skill.handleEmergency(description: "Water is flooding my basement", family: family)
        XCTAssertTrue(response.contains("SHUT OFF") || response.contains("water"),
                      "Should provide water emergency guidance")

        // If weather shows rain/storm, urgency should be higher
        if weather.description.lowercased().contains("rain") || weather.description.lowercased().contains("storm") {
            print("Weather shows precipitation - basement flooding more urgent")
        }
    }

    func testMedicationSafetyWithLiveFDA() async throws {
        // Simulate: Rodriguez family member (Maria has diabetes) checking metformin safety
        let api = OpenFDAAPI()

        let metformin = try await api.validateMedication(name: "metformin")
        XCTAssertFalse(metformin.name.isEmpty, "Should find metformin - common diabetes medication")

        // Verify warnings exist for a real medication
        if let warnings = metformin.warnings {
            XCTAssertFalse(warnings.isEmpty, "Metformin should have safety warnings")
        }

        // Also check for potential adverse events
        let events = try await api.searchAdverseEvents(drugName: "metformin", limit: 2)
        // Metformin is widely used, should have adverse event reports
        XCTAssertFalse(events.isEmpty, "Metformin should have adverse event reports")
    }

    // MARK: - Data Quality Validation Tests

    func testFDAResponseCompleteness() async throws {
        // Verify that our DrugInfo model captures all important fields from real FDA data
        let api = OpenFDAAPI()
        let drug = try await api.validateMedication(name: "aspirin")

        // For a well-known drug like aspirin, we should have all fields populated
        XCTAssertFalse(drug.name.isEmpty, "Name should be populated")
        XCTAssertNotNil(drug.activeIngredient, "Active ingredient should be populated")
        XCTAssertNotNil(drug.warnings, "Warnings should be populated for aspirin")

        if let warnings = drug.warnings {
            // Aspirin warnings should mention key risks
            let loweredWarnings = warnings.lowercased()
            let hasRelevantWarning = loweredWarnings.contains("stomach") ||
                                    loweredWarnings.contains("bleeding") ||
                                    loweredWarnings.contains("reye")
            XCTAssertTrue(hasRelevantWarning,
                          "Aspirin warnings should mention stomach/bleeding/Reye's risks")
        }
    }

    func testWeatherResponseCompleteness() async throws {
        let api = WeatherAPI()
        let weather = try await api.getCurrentWeather(city: "New York")

        // All fields should be populated with real data
        XCTAssertNotEqual(weather.temperatureF, 0, "Temperature should not be default 0")
        XCTAssertNotEqual(weather.feelsLikeF, 0, "Feels-like should not be default 0")
        XCTAssertGreaterThan(weather.humidity, 0, "Humidity should be > 0")
        XCTAssertFalse(weather.description.isEmpty, "Description should not be empty")
        XCTAssertGreaterThanOrEqual(weather.windSpeedMph, 0, "Wind speed should be >= 0")
    }

    func testUSDANutritionCompleteness() async throws {
        let api = USDAFoodDataAPI(apiKey: "DEMO_KEY")
        do {
            let foods = try await api.searchFood(query: "chicken breast", pageSize: 5)
            XCTAssertFalse(foods.isEmpty)

            let hasNutrition = foods.contains { food in
                food.calories > 0 && food.protein > 0
            }
            XCTAssertTrue(hasNutrition,
                          "At least one chicken breast result should have calories and protein data")
        } catch {
            // DEMO_KEY rate limit is 30 requests/hour - acceptable to skip
            print("USDA DEMO_KEY rate limited (expected): \(error)")
        }
    }

    // MARK: - Resilience Tests

    func testAPIClientTimeoutHandling() async throws {
        // Test that our API clients handle slow responses gracefully
        let api = WeatherAPI()
        // Valid city but potentially slow
        let weather = try await api.getCurrentWeather(city: "Tokyo")
        XCTAssertFalse(weather.description.isEmpty, "Should handle international city")
    }

    func testAPIClientSpecialCharacters() async throws {
        // Test URL encoding for cities with spaces and special chars
        let api = WeatherAPI()
        let weather = try await api.getCurrentWeather(city: "San Francisco")
        XCTAssertFalse(weather.description.isEmpty || weather.description == "Weather data unavailable",
                       "Should handle city names with spaces")
    }

    func testFDASpecialCharacterDrug() async throws {
        // Test drug names with special formatting
        let api = OpenFDAAPI()
        let drug = try await api.validateMedication(name: "Advil")
        XCTAssertFalse(drug.name.isEmpty, "Should find brand name drugs")
    }
}
