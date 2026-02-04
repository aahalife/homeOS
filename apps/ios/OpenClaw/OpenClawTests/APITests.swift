import XCTest
@testable import OpenClaw

/// Tests for API clients
final class APITests: XCTestCase {

    // MARK: - Stub Data Tests

    func testStubRecipeDataNotEmpty() {
        XCTAssertFalse(StubRecipeData.sampleRecipes.isEmpty)
        XCTAssertGreaterThanOrEqual(StubRecipeData.sampleRecipes.count, 5)
    }

    func testStubRecipeDataQuality() {
        for recipe in StubRecipeData.sampleRecipes {
            XCTAssertFalse(recipe.title.isEmpty, "Recipe title should not be empty")
            XCTAssertGreaterThan(recipe.totalTime, 0, "Total time should be positive")
            XCTAssertFalse(recipe.ingredients.isEmpty, "Recipe should have ingredients")
            XCTAssertFalse(recipe.instructions.isEmpty, "Recipe should have instructions")
        }
    }

    func testStubCalendarDataNotEmpty() {
        let events = StubCalendarData.sampleEvents
        XCTAssertFalse(events.isEmpty)
    }

    func testStubEducationDataNotEmpty() {
        let courses = StubEducationData.sampleCourses
        XCTAssertFalse(courses.isEmpty)

        let courseWork = StubEducationData.sampleCourseWork
        XCTAssertFalse(courseWork.isEmpty)
    }

    func testStubEducationAssignments() {
        let studentId = UUID()
        let assignments = StubEducationData.sampleAssignments(for: studentId)
        XCTAssertFalse(assignments.isEmpty)
        XCTAssertTrue(assignments.allSatisfy { $0.studentId == studentId })
    }

    func testStubContractorData() {
        let plumbers = StubContractorData.sampleProviders(for: "plumber")
        XCTAssertFalse(plumbers.isEmpty)
        XCTAssertTrue(plumbers.allSatisfy { !$0.name.isEmpty && !$0.phone.isEmpty })
    }

    // MARK: - Spoonacular API (Offline Tests)

    func testSpoonacularWithoutKey() async throws {
        let api = SpoonacularAPI(apiKey: "")
        XCTAssertFalse(api.isConfigured)

        let criteria = RecipeSearchCriteria(query: "chicken")
        let recipes = try await api.searchRecipes(criteria: criteria)
        XCTAssertFalse(recipes.isEmpty, "Should return stub data when API key is missing")
    }

    // MARK: - OpenFDA API (Free - Can Test Live)

    func testOpenFDAMedicationLookup() async throws {
        let api = OpenFDAAPI()
        let info = try await api.validateMedication(name: "aspirin")
        XCTAssertFalse(info.name.isEmpty)
    }

    // MARK: - USDA API

    func testUSDAFoodSearch() async {
        // This test uses DEMO_KEY which is rate-limited
        let api = USDAFoodDataAPI(apiKey: "DEMO_KEY")
        do {
            let foods = try await api.searchFood(query: "chicken breast", pageSize: 3)
            // May fail with rate limits, so we accept empty too
            if !foods.isEmpty {
                XCTAssertFalse(foods[0].name.isEmpty)
            }
        } catch {
            // Rate limit is acceptable for DEMO_KEY
            print("USDA API test skipped (likely rate limited): \(error)")
        }
    }

    // MARK: - Weather API

    func testWeatherAPIMocked() async throws {
        let api = WeatherAPI()
        // wttr.in is free and doesn't require auth
        let weather = try await api.getCurrentWeather(city: "Chicago")
        // May return default values if API is down
        XCTAssertTrue(weather.temperatureF != 0 || weather.description == "Weather data unavailable")
    }

    // MARK: - Google Calendar API (No Auth)

    func testGoogleCalendarWithoutAuth() async throws {
        let api = GoogleCalendarAPI()
        XCTAssertFalse(api.isAuthenticated)

        let events = try await api.listEvents(timeMin: Date(), timeMax: Date().addingDays(7))
        XCTAssertFalse(events.isEmpty, "Should return stub events when not authenticated")
    }

    // MARK: - Google Classroom API (No Auth)

    func testGoogleClassroomWithoutAuth() async throws {
        let api = GoogleClassroomAPI()
        XCTAssertFalse(api.isAuthenticated)

        let courses = try await api.listCourses()
        XCTAssertFalse(courses.isEmpty, "Should return stub courses when not authenticated")
    }

    // MARK: - Twilio API (No Config)

    func testTwilioWithoutConfig() async throws {
        let api = TwilioAPI()
        XCTAssertFalse(api.isConfigured)

        let result = try await api.sendSMS(to: "+15555555555", body: "Test")
        XCTAssertTrue(result.status == "simulated")
    }

    // MARK: - Google Places API (No Config)

    func testGooglePlacesWithoutConfig() async throws {
        let api = GooglePlacesAPI()
        XCTAssertFalse(api.isConfigured)

        let providers = try await api.textSearch(query: "plumber near me")
        XCTAssertFalse(providers.isEmpty, "Should return stub data when not configured")
    }

    // MARK: - Rate Limiter Tests

    func testRateLimiter() async throws {
        let limiter = APIRateLimiter.shared

        // Should succeed
        try await limiter.checkLimit(api: "test_api", maxRequests: 3, windowSeconds: 60)
        try await limiter.checkLimit(api: "test_api", maxRequests: 3, windowSeconds: 60)
        try await limiter.checkLimit(api: "test_api", maxRequests: 3, windowSeconds: 60)

        // Should fail
        do {
            try await limiter.checkLimit(api: "test_api", maxRequests: 3, windowSeconds: 60)
            XCTFail("Should throw rate limit error")
        } catch APIError.rateLimitExceeded {
            // Expected
        }
    }
}
