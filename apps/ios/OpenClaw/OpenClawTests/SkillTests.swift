import XCTest
@testable import OpenClaw

/// Tests for individual skill handlers
final class SkillTests: XCTestCase {

    let testFamily = Family(
        name: "Anderson",
        members: [
            FamilyMember(name: "Sarah", role: .adult),
            FamilyMember(name: "Mike", role: .adult),
            FamilyMember(name: "Emma", role: .child, birthYear: 2016, dietaryRestrictions: [.dairyFree]),
            FamilyMember(name: "Jake", role: .child, birthYear: 2019)
        ],
        preferences: {
            var prefs = FamilyPreferences()
            prefs.weeklyGroceryBudget = 150
            prefs.homeCity = "Chicago"
            return prefs
        }()
    )

    // MARK: - Meal Planning Tests

    func testMealPlanGeneration() async throws {
        let skill = MealPlanningSkill()
        let plan = try await skill.generateWeeklyPlan(family: testFamily)

        XCTAssertEqual(plan.meals.count, 7, "Should generate 7 dinners")
        XCTAssertGreaterThan(plan.estimatedCost, 0)
        XCTAssertNotNil(plan.groceryList)
    }

    func testTonightDinnerSuggestion() async throws {
        let skill = MealPlanningSkill()
        let meal = try await skill.suggestTonightDinner(family: testFamily)

        XCTAssertFalse(meal.recipe.title.isEmpty)
        XCTAssertLessThanOrEqual(meal.recipe.totalTime, 30, "Weeknight dinner should be 30 min or less")
    }

    func testGroceryListGeneration() async throws {
        let skill = MealPlanningSkill()
        let list = try await skill.generateGroceryList(family: testFamily)

        XCTAssertFalse(list.items.isEmpty)
        XCTAssertGreaterThan(list.estimatedTotal, 0)
    }

    func testMealPlanHas7Meals() async throws {
        let skill = MealPlanningSkill()
        let plan = try await skill.generateWeeklyPlan(family: testFamily)
        XCTAssertEqual(plan.meals.count, 7)
    }

    func testMealPlanProteinVariety() async throws {
        let skill = MealPlanningSkill()
        let plan = try await skill.generateWeeklyPlan(family: testFamily)
        let proteins = Set(plan.meals.map { $0.recipe.primaryProtein })
        XCTAssertGreaterThanOrEqual(proteins.count, 2, "Should have at least 2 different proteins")
    }

    // MARK: - Healthcare Tests

    func testEmergencySymptomTriage() async {
        let skill = HealthcareSkill()
        let response = await skill.assessSymptoms(description: "severe chest pain and difficulty breathing", family: testFamily)

        XCTAssertTrue(response.contains("911"), "Emergency symptoms should recommend calling 911")
        XCTAssertTrue(response.contains("IMMEDIATELY") || response.contains("emergency"))
    }

    func testModerateSymptomTriage() async {
        let skill = HealthcareSkill()
        let response = await skill.assessSymptoms(description: "fever of 101 for three days", family: testFamily)

        XCTAssertTrue(response.lowercased().contains("doctor") || response.lowercased().contains("care"),
                       "Moderate symptoms should recommend doctor visit")
    }

    func testMildSymptomTriage() async {
        let skill = HealthcareSkill()
        let response = await skill.assessSymptoms(description: "mild sore throat", family: testFamily)

        XCTAssertTrue(response.lowercased().contains("monitor") || response.lowercased().contains("self-care"),
                       "Mild symptoms should recommend monitoring")
    }

    func testNeverDiagnoses() async {
        let skill = HealthcareSkill()
        let symptoms = [
            "child has a rash and fever",
            "I have a headache and dizziness",
            "back pain for a week"
        ]

        let diagnosisKeywords = ["you have", "diagnosis", "it is", "this is", "you're suffering from"]

        for symptom in symptoms {
            let response = await skill.assessSymptoms(description: symptom, family: testFamily)
            for keyword in diagnosisKeywords {
                XCTAssertFalse(response.lowercased().contains(keyword),
                               "Response should never contain diagnostic language '\(keyword)' for '\(symptom)'")
            }
        }
    }

    func testMedicationLogging() {
        let skill = HealthcareSkill()
        let result = skill.logMedicationTaken(memberName: "Sarah")
        XCTAssertTrue(result.contains("Sarah"))
        XCTAssertTrue(result.contains("Logged"))
    }

    func testProviderSearch() async throws {
        let skill = HealthcareSkill()
        let providers = try await skill.searchProviders(family: testFamily, specialty: "Pediatrics")
        XCTAssertFalse(providers.isEmpty)
        XCTAssertTrue(providers.allSatisfy { $0.rating != nil })
    }

    // MARK: - Education Tests

    func testUpcomingAssignments() async {
        let skill = EducationSkill()
        let assignments = await skill.getUpcomingAssignments(family: testFamily)

        XCTAssertFalse(assignments.isEmpty, "Should have stub assignments")
        XCTAssertTrue(assignments.allSatisfy { !$0.title.isEmpty })
    }

    func testLatestGrades() async {
        let skill = EducationSkill()
        let grades = await skill.getLatestGrades(family: testFamily)

        XCTAssertFalse(grades.isEmpty)
        XCTAssertTrue(grades.allSatisfy { $0.grade >= 0 && $0.grade <= 100 })
    }

    func testStudyPlanCreation() async {
        let skill = EducationSkill()
        let plan = await skill.createStudyPlan(family: testFamily, subject: "Math")

        XCTAssertFalse(plan.sessions.isEmpty)
        XCTAssertGreaterThan(plan.totalTime, 0)
        XCTAssertEqual(plan.subject, "Math")
    }

    func testDailySummary() async {
        let skill = EducationSkill()
        let summary = await skill.getDailySummary(family: testFamily)

        XCTAssertFalse(summary.isEmpty)
        XCTAssertTrue(summary.contains("Education Summary"))
    }

    // MARK: - Elder Care Tests

    func testElderCheckIn() async {
        var elderFamily = testFamily
        elderFamily.members.append(FamilyMember(name: "Grandma", role: .elder))

        let skill = ElderCareSkill()
        let summary = await skill.performCheckIn(family: elderFamily)

        XCTAssertTrue(summary.contains("Grandma"))
    }

    func testElderCareNoElders() async {
        let skill = ElderCareSkill()
        let summary = await skill.performCheckIn(family: testFamily)

        XCTAssertTrue(summary.contains("No elder"), "Should handle families without elders gracefully")
    }

    func testRedFlagDetection() {
        let skill = ElderCareSkill()
        let transcript = "I can't remember if I ate breakfast. I'm confused about what day it is."
        let flags = skill.analyzeForRedFlags(transcript: transcript)

        XCTAssertTrue(flags.contains("confusion"))
        XCTAssertTrue(flags.contains("appetite_loss"))
    }

    func testNoRedFlags() {
        let skill = ElderCareSkill()
        let transcript = "I'm feeling great today! Had a nice breakfast and went for a walk."
        let flags = skill.analyzeForRedFlags(transcript: transcript)

        XCTAssertTrue(flags.isEmpty, "Positive conversation should have no red flags")
    }

    func testWeeklyReport() async {
        var elderFamily = testFamily
        elderFamily.members.append(FamilyMember(name: "Grandma", role: .elder))

        let skill = ElderCareSkill()
        let report = await skill.generateWeeklyReport(family: elderFamily)

        XCTAssertTrue(report.contains("Grandma"))
        XCTAssertTrue(report.contains("Weekly Summary"))
    }

    // MARK: - Home Maintenance Tests

    func testGasLeakEmergency() {
        let skill = HomeMaintenanceSkill()
        let response = skill.handleEmergency(description: "I smell gas in the kitchen", family: testFamily)

        XCTAssertTrue(response.contains("EVACUATE"))
        XCTAssertTrue(response.contains("911"))
        XCTAssertTrue(response.contains("Gas Leak"))
    }

    func testWaterLeakEmergency() {
        let skill = HomeMaintenanceSkill()
        let response = skill.handleEmergency(description: "Water is flooding my basement", family: testFamily)

        XCTAssertTrue(response.contains("water valve") || response.contains("Water Leak"))
    }

    func testElectricalFireEmergency() {
        let skill = HomeMaintenanceSkill()
        let response = skill.handleEmergency(description: "Smoke coming from electrical outlet", family: testFamily)

        XCTAssertTrue(response.contains("911"))
        XCTAssertTrue(response.contains("EVACUATE"))
    }

    func testContractorSearch() async throws {
        let skill = HomeMaintenanceSkill()
        let providers = try await skill.searchContractors(query: "plumber", family: testFamily)

        XCTAssertFalse(providers.isEmpty)
    }

    func testMaintenanceSchedule() {
        let skill = HomeMaintenanceSkill()
        let tasks = skill.getMaintenanceSchedule(family: testFamily)

        XCTAssertFalse(tasks.isEmpty)
        XCTAssertTrue(tasks.contains { $0.title.contains("HVAC") })
        XCTAssertTrue(tasks.contains { $0.title.contains("Smoke") })
    }

    // MARK: - Family Coordination Tests

    func testUpcomingEvents() async {
        let skill = FamilyCoordinationSkill()
        let events = await skill.getUpcomingEvents(family: testFamily)

        XCTAssertFalse(events.isEmpty)
    }

    func testChoreAssignment() {
        let skill = FamilyCoordinationSkill()
        let chore = skill.assignChore(family: testFamily, task: "Clean room", to: "Emma")

        XCTAssertEqual(chore.title, "Clean room")
        XCTAssertTrue(chore.points > 0)
    }

    func testConflictDetection() {
        let skill = FamilyCoordinationSkill()
        let now = Date()
        let events = [
            CalendarEvent(title: "Meeting", startTime: now, endTime: now.addingHours(1)),
            CalendarEvent(title: "Call", startTime: now.addingTimeInterval(1800), endTime: now.addingHours(1))
        ]
        let conflicts = skill.detectConflicts(events: events)
        XCTAssertEqual(conflicts.count, 1)
    }

    func testNoConflicts() {
        let skill = FamilyCoordinationSkill()
        let now = Date()
        let events = [
            CalendarEvent(title: "Meeting", startTime: now, endTime: now.addingHours(1)),
            CalendarEvent(title: "Call", startTime: now.addingHours(2), endTime: now.addingHours(3))
        ]
        let conflicts = skill.detectConflicts(events: events)
        XCTAssertTrue(conflicts.isEmpty)
    }

    // MARK: - Mental Load Tests

    func testMorningBriefing() async {
        let skill = MentalLoadSkill()
        let briefing = await skill.generateMorningBriefing(family: testFamily)

        XCTAssertNotNil(briefing.motivationalNote)
        XCTAssertTrue(briefing.date.isToday)
    }

    func testEveningWindDown() async {
        let skill = MentalLoadSkill()
        let windDown = await skill.generateEveningWindDown(family: testFamily)

        XCTAssertNotNil(windDown.reflectionPrompt)
        XCTAssertFalse(windDown.suggestions.isEmpty)
    }

    func testBriefingFormatting() async {
        let skill = MentalLoadSkill()
        let briefing = await skill.generateMorningBriefing(family: testFamily)
        let formatted = skill.formatBriefing(briefing)

        XCTAssertFalse(formatted.isEmpty)
    }

    func testWindDownFormatting() async {
        let skill = MentalLoadSkill()
        let windDown = await skill.generateEveningWindDown(family: testFamily)
        let formatted = skill.formatWindDown(windDown)

        XCTAssertFalse(formatted.isEmpty)
    }
}
