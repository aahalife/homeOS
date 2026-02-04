import XCTest
@testable import OpenClaw

/// Tests for the stub intent classifier
final class IntentClassifierTests: XCTestCase {

    let classifier = StubIntentClassifier()

    // MARK: - Meal Planning Intent Tests

    func testPlanWeekIntent() {
        let result = classifier.classify(text: "Plan dinners for this week")
        XCTAssertEqual(result.skill, .mealPlanning)
        XCTAssertEqual(result.action, .planWeek)
        XCTAssertGreaterThan(result.confidence, 0.5)
    }

    func testPlanTonightIntent() {
        let result = classifier.classify(text: "What should I make for dinner tonight?")
        XCTAssertEqual(result.skill, .mealPlanning)
        XCTAssertEqual(result.action, .planTonight)
    }

    func testGroceryListIntent() {
        let result = classifier.classify(text: "Generate a grocery list")
        XCTAssertEqual(result.skill, .mealPlanning)
        XCTAssertEqual(result.action, .generateGroceryList)
    }

    func testRecipeSearchIntent() {
        let result = classifier.classify(text: "Find a recipe for pasta")
        XCTAssertEqual(result.skill, .mealPlanning)
        XCTAssertEqual(result.action, .searchRecipe)
    }

    // MARK: - Healthcare Intent Tests

    func testSymptomCheckIntent() {
        let result = classifier.classify(text: "Emma has a fever of 101")
        XCTAssertEqual(result.skill, .healthcare)
        XCTAssertEqual(result.action, .checkSymptom)
    }

    func testMedicationTrackingIntent() {
        let result = classifier.classify(text: "Did I take my medication today?")
        XCTAssertEqual(result.skill, .healthcare)
        XCTAssertEqual(result.action, .trackMedication)
    }

    func testAppointmentBookingIntent() {
        let result = classifier.classify(text: "Book a doctor appointment")
        XCTAssertEqual(result.skill, .healthcare)
        XCTAssertEqual(result.action, .bookAppointment)
    }

    func testFindProviderIntent() {
        let result = classifier.classify(text: "Find a pediatrician in network")
        XCTAssertEqual(result.skill, .healthcare)
        XCTAssertEqual(result.action, .findProvider)
    }

    // MARK: - Education Intent Tests

    func testHomeworkCheckIntent() {
        let result = classifier.classify(text: "What homework is due this week?")
        XCTAssertEqual(result.skill, .education)
        XCTAssertEqual(result.action, .checkHomework)
    }

    func testGradeCheckIntent() {
        let result = classifier.classify(text: "How is Emma doing in Math?")
        XCTAssertEqual(result.skill, .education)
        XCTAssertEqual(result.action, .checkGrades)
    }

    func testStudyPlanIntent() {
        let result = classifier.classify(text: "Create a study plan for the test")
        XCTAssertEqual(result.skill, .education)
        XCTAssertEqual(result.action, .createStudyPlan)
    }

    // MARK: - Elder Care Intent Tests

    func testCheckStatusIntent() {
        let result = classifier.classify(text: "How is Mom doing today?")
        XCTAssertEqual(result.skill, .elderCare)
        XCTAssertEqual(result.action, .checkStatus)
    }

    func testWeeklyReportIntent() {
        let result = classifier.classify(text: "Show me the weekly elder care report")
        XCTAssertEqual(result.skill, .elderCare)
        XCTAssertEqual(result.action, .weeklyReport)
    }

    // MARK: - Home Maintenance Intent Tests

    func testEmergencyIntent() {
        let result = classifier.classify(text: "My basement is flooding!")
        XCTAssertEqual(result.skill, .homeMaintenance)
        XCTAssertEqual(result.action, .reportEmergency)
    }

    func testGasLeakIntent() {
        let result = classifier.classify(text: "I smell gas in the house")
        XCTAssertEqual(result.skill, .homeMaintenance)
        XCTAssertEqual(result.action, .reportEmergency)
    }

    func testContractorSearchIntent() {
        let result = classifier.classify(text: "Find a plumber near me")
        XCTAssertEqual(result.skill, .homeMaintenance)
        XCTAssertEqual(result.action, .findContractor)
    }

    func testMaintenanceCalendarIntent() {
        let result = classifier.classify(text: "What maintenance is due?")
        XCTAssertEqual(result.skill, .homeMaintenance)
        XCTAssertEqual(result.action, .maintenanceCalendar)
    }

    // MARK: - Family Coordination Intent Tests

    func testCalendarCheckIntent() {
        let result = classifier.classify(text: "What's on the calendar this week?")
        XCTAssertEqual(result.skill, .familyCoordination)
        XCTAssertEqual(result.action, .checkCalendar)
    }

    func testChoreAssignmentIntent() {
        let result = classifier.classify(text: "Assign Emma to clean her room")
        XCTAssertEqual(result.skill, .familyCoordination)
        XCTAssertEqual(result.action, .assignChore)
    }

    func testBroadcastIntent() {
        let result = classifier.classify(text: "Tell everyone dinner is ready")
        XCTAssertEqual(result.skill, .familyCoordination)
        XCTAssertEqual(result.action, .broadcastMessage)
    }

    func testLocationIntent() {
        let result = classifier.classify(text: "Where is everyone?")
        XCTAssertEqual(result.skill, .familyCoordination)
        XCTAssertEqual(result.action, .whereIsEveryone)
    }

    // MARK: - Mental Load Intent Tests

    func testMorningBriefingIntent() {
        let result = classifier.classify(text: "Give me my morning briefing")
        XCTAssertEqual(result.skill, .mentalLoad)
        XCTAssertEqual(result.action, .morningBriefing)
    }

    func testEveningWindDownIntent() {
        let result = classifier.classify(text: "Time for my evening wind down")
        XCTAssertEqual(result.skill, .mentalLoad)
        XCTAssertEqual(result.action, .eveningWindDown)
    }

    func testReminderIntent() {
        let result = classifier.classify(text: "Remind me to pick up groceries")
        XCTAssertEqual(result.skill, .mentalLoad)
        XCTAssertEqual(result.action, .setReminder)
    }

    // MARK: - Greeting Tests

    func testGreetingDetection() {
        let greetings = ["Hello", "Hi there", "Hey", "Good morning"]
        for greeting in greetings {
            let result = classifier.classify(text: greeting)
            XCTAssertEqual(result.action, .greeting, "Failed for: \(greeting)")
        }
    }

    // MARK: - Help Tests

    func testHelpDetection() {
        let result = classifier.classify(text: "What can you help me with?")
        XCTAssertEqual(result.action, .help)
    }

    // MARK: - Entity Extraction Tests

    func testPersonExtraction() {
        let result = classifier.classify(text: "What homework is due for Emma?")
        XCTAssertNotNil(result.entities["person"])
    }

    func testTimeExtraction() {
        let result = classifier.classify(text: "Plan dinner for tonight")
        XCTAssertEqual(result.entities["time"], "tonight")
    }

    func testBudgetExtraction() {
        let result = classifier.classify(text: "Plan meals under $100")
        XCTAssertEqual(result.entities["budget"], "100")
    }
}
