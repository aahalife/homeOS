import XCTest
@testable import OpenClaw

/// Simulation tests using synthetic family profiles
final class SimulationTests: XCTestCase {

    // MARK: - Family Profiles

    static let andersonFamily = Family(
        name: "Anderson",
        members: [
            FamilyMember(name: "Sarah", role: .adult, birthYear: 1988),
            FamilyMember(name: "Mike", role: .adult, birthYear: 1986),
            FamilyMember(name: "Emma", role: .child, birthYear: 2016, dietaryRestrictions: [.dairyFree], allergies: ["dairy"]),
            FamilyMember(name: "Jake", role: .child, birthYear: 2019)
        ],
        preferences: {
            var p = FamilyPreferences()
            p.weeklyGroceryBudget = 150
            p.homeCity = "Chicago"
            p.homeState = "IL"
            return p
        }()
    )

    static let rodriguezFamily = Family(
        name: "Rodriguez",
        members: [
            FamilyMember(name: "Maria", role: .adult, birthYear: 1982, healthConditions: ["diabetes"]),
            FamilyMember(name: "Carlos", role: .child, birthYear: 2010),
            FamilyMember(name: "Sofia", role: .child, birthYear: 2012)
        ],
        preferences: {
            var p = FamilyPreferences()
            p.weeklyGroceryBudget = 120
            p.homeCity = "Austin"
            p.homeState = "TX"
            return p
        }()
    )

    static let chenFamily = Family(
        name: "Chen",
        members: [
            FamilyMember(name: "Linda", role: .adult, birthYear: 1974),
            FamilyMember(name: "James", role: .adult, birthYear: 1972),
            FamilyMember(name: "Lily", role: .child, birthYear: 2009),
            FamilyMember(name: "Margaret", role: .elder, birthYear: 1948, healthConditions: ["mild cognitive decline"])
        ],
        preferences: {
            var p = FamilyPreferences()
            p.weeklyGroceryBudget = 200
            p.homeCity = "San Francisco"
            p.homeState = "CA"
            p.elderCareEnabled = true
            return p
        }()
    )

    // MARK: - Anderson Family Simulation

    func testAndersonFamilyMealPlanning() async throws {
        let skill = MealPlanningSkill()
        let plan = try await skill.generateWeeklyPlan(family: Self.andersonFamily)

        // 7 dinners
        XCTAssertEqual(plan.meals.count, 7)

        // Budget compliance
        XCTAssertLessThanOrEqual(plan.estimatedCost, 150, "Should stay within $150 budget")

        // Verify servings for family of 4
        for meal in plan.meals {
            XCTAssertEqual(meal.servings, 4)
        }
    }

    func testAndersonFamilyEducation() async {
        let skill = EducationSkill()
        let assignments = await skill.getUpcomingAssignments(family: Self.andersonFamily)

        XCTAssertFalse(assignments.isEmpty, "Should have assignments for school-age children")

        let grades = await skill.getLatestGrades(family: Self.andersonFamily)
        XCTAssertFalse(grades.isEmpty)
    }

    // MARK: - Rodriguez Family Simulation

    func testRodriguezBudgetMealPlanning() async throws {
        let skill = MealPlanningSkill()
        let plan = try await skill.generateWeeklyPlan(family: Self.rodriguezFamily)

        XCTAssertLessThanOrEqual(plan.estimatedCost, 120, "Should stay within $120 budget")
    }

    func testRodriguezHealthcare() async {
        let skill = HealthcareSkill()

        // Maria has diabetes - medication tracking
        let status = skill.logMedicationTaken(memberName: "Maria")
        XCTAssertTrue(status.contains("Maria"))
    }

    // MARK: - Chen Family Simulation (Sandwich Generation)

    func testChenElderCare() async {
        let skill = ElderCareSkill()

        // Margaret is an elder with mild cognitive decline
        let summary = await skill.performCheckIn(family: Self.chenFamily)
        XCTAssertTrue(summary.contains("Margaret"), "Check-in should include elder member")
    }

    func testChenMultiSkillWorkflow() async throws {
        // Education + Elder Care coordination
        let eduSkill = EducationSkill()
        let elderSkill = ElderCareSkill()

        let assignments = await eduSkill.getUpcomingAssignments(family: Self.chenFamily)
        XCTAssertFalse(assignments.isEmpty, "Lily should have assignments")

        let elderSummary = await elderSkill.performCheckIn(family: Self.chenFamily)
        XCTAssertFalse(elderSummary.isEmpty)
    }

    // MARK: - Cross-Family Intent Classification

    func testIntentClassificationAcrossFamilies() {
        let classifier = StubIntentClassifier()

        let familyRequests = [
            ("Plan dinners for this week", SkillType.mealPlanning),
            ("Emma has a fever", SkillType.healthcare),
            ("What homework is due?", SkillType.education),
            ("How is Grandma doing?", SkillType.elderCare),
            ("My basement is flooding", SkillType.homeMaintenance),
            ("What's on the calendar?", SkillType.familyCoordination),
            ("Give me my morning briefing", SkillType.mentalLoad)
        ]

        for (request, expectedSkill) in familyRequests {
            let result = classifier.classify(text: request)
            XCTAssertEqual(result.skill, expectedSkill, "'\(request)' should route to \(expectedSkill.rawValue)")
        }
    }

    // MARK: - Response Generation Consistency

    func testResponseGeneratorConsistency() async {
        let generator = StubResponseGenerator()
        let context = ConversationContext(
            familyName: "Anderson",
            memberCount: 4,
            recentMessages: [],
            activeSkills: Set(SkillType.allCases),
            currentTime: Date()
        )

        // Test multiple times for consistency
        for _ in 0..<5 {
            let intent = IntentResult(skill: .mealPlanning, action: .planWeek, confidence: 0.9, entities: [:])
            let response = generator.generate(intent: intent, context: context)
            XCTAssertFalse(response.isEmpty)
        }
    }

    // MARK: - Safety Compliance

    func testHealthcareSafetyCompliance() async {
        let skill = HealthcareSkill()

        let emergencyScenarios = [
            "My child is having a seizure",
            "I can't breathe and have chest pain",
            "Severe allergic reaction after eating nuts"
        ]

        for scenario in emergencyScenarios {
            let response = await skill.assessSymptoms(description: scenario, family: Self.andersonFamily)
            XCTAssertTrue(
                response.contains("911") || response.contains("emergency"),
                "Emergency scenario '\(scenario)' must recommend calling 911"
            )
        }
    }

    func testHomeEmergencySafety() {
        let skill = HomeMaintenanceSkill()

        // Gas leak must always evacuate
        let gasResponse = skill.handleEmergency(description: "I smell gas", family: Self.andersonFamily)
        XCTAssertTrue(gasResponse.contains("EVACUATE"))

        // Electrical fire must evacuate
        let fireResponse = skill.handleEmergency(description: "Fire from electrical outlet", family: Self.andersonFamily)
        XCTAssertTrue(fireResponse.contains("EVACUATE"))
    }
}
