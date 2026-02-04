import XCTest
@testable import OpenClaw

/// Unit Tests for OpenClaw
final class OpenClawTests: XCTestCase {

    // MARK: - Model Tests

    func testFamilyCreation() {
        let family = Family(
            name: "Anderson",
            members: [
                FamilyMember(name: "Sarah", role: .adult),
                FamilyMember(name: "Mike", role: .adult),
                FamilyMember(name: "Emma", role: .child, dietaryRestrictions: [.dairyFree]),
                FamilyMember(name: "Jake", role: .child)
            ],
            preferences: FamilyPreferences()
        )

        XCTAssertEqual(family.name, "Anderson")
        XCTAssertEqual(family.members.count, 4)
        XCTAssertEqual(family.adults.count, 2)
        XCTAssertEqual(family.children.count, 2)
        XCTAssertTrue(family.dietaryRestrictions.contains(.dairyFree))
    }

    func testFamilyMemberAge() {
        let member = FamilyMember(name: "Emma", role: .child, birthYear: 2016)
        XCTAssertNotNil(member.age)
        XCTAssertTrue(member.age! >= 9) // Should be ~10 in 2026
    }

    func testFamilyCodable() throws {
        let family = Family(
            name: "Test",
            members: [FamilyMember(name: "User", role: .adult)],
            preferences: FamilyPreferences()
        )

        let data = try JSONEncoder().encode(family)
        let decoded = try JSONDecoder().decode(Family.self, from: data)

        XCTAssertEqual(decoded.name, "Test")
        XCTAssertEqual(decoded.members.count, 1)
    }

    // MARK: - Dietary Restriction Tests

    func testDietaryRestrictionEnum() {
        XCTAssertEqual(DietaryRestriction.allCases.count, 9)
        XCTAssertEqual(DietaryRestriction.vegetarian.rawValue, "Vegetarian")
    }

    // MARK: - Skill Type Tests

    func testSkillTypeProperties() {
        for skill in SkillType.allCases {
            XCTAssertFalse(skill.rawValue.isEmpty)
            XCTAssertFalse(skill.icon.isEmpty)
            XCTAssertFalse(skill.description.isEmpty)
        }
    }

    func testAllSevenSkillsExist() {
        XCTAssertEqual(SkillType.allCases.count, 7)
        XCTAssertTrue(SkillType.allCases.contains(.mealPlanning))
        XCTAssertTrue(SkillType.allCases.contains(.healthcare))
        XCTAssertTrue(SkillType.allCases.contains(.education))
        XCTAssertTrue(SkillType.allCases.contains(.elderCare))
        XCTAssertTrue(SkillType.allCases.contains(.homeMaintenance))
        XCTAssertTrue(SkillType.allCases.contains(.familyCoordination))
        XCTAssertTrue(SkillType.allCases.contains(.mentalLoad))
    }

    // MARK: - Recipe Model Tests

    func testRecipeCreation() {
        let recipe = Recipe(
            title: "Test Recipe",
            cuisine: "American",
            prepTime: 10,
            cookTime: 20,
            totalTime: 30,
            servings: 4,
            ingredients: [
                Ingredient(name: "Chicken", amount: 1, unit: "lb", category: .meat)
            ],
            instructions: [InstructionStep(stepNumber: 1, text: "Cook")],
            primaryProtein: .chicken
        )

        XCTAssertEqual(recipe.title, "Test Recipe")
        XCTAssertEqual(recipe.totalTime, 30)
        XCTAssertEqual(recipe.ingredients.count, 1)
    }

    func testRecipeCodable() throws {
        let recipe = StubRecipeData.sampleRecipes[0]
        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        XCTAssertEqual(decoded.title, recipe.title)
    }

    // MARK: - Healthcare Model Tests

    func testSymptomEmergencyDetection() {
        let emergencySymptom = Symptom(
            type: .chestPain,
            severity: .high,
            duration: 3600,
            description: "Severe chest pain"
        )
        XCTAssertTrue(emergencySymptom.isEmergency)

        let mildSymptom = Symptom(
            type: .headache,
            severity: .low,
            duration: 3600,
            description: "Mild headache"
        )
        XCTAssertFalse(mildSymptom.isEmergency)
    }

    func testTriageActionUrgency() {
        XCTAssertEqual(TriageAction.call911.urgencyLevel, .emergency)
        XCTAssertEqual(TriageAction.urgentCare.urgencyLevel, .urgent)
        XCTAssertEqual(TriageAction.scheduleDoctorVisit.urgencyLevel, .moderate)
        XCTAssertEqual(TriageAction.selfCareWithMonitoring.urgencyLevel, .routine)
    }

    // MARK: - Emergency Type Tests

    func testEmergencyTypeEvacuation() {
        XCTAssertTrue(EmergencyType.gasLeak.requiresEvacuation)
        XCTAssertTrue(EmergencyType.electricalFire.requiresEvacuation)
        XCTAssertFalse(EmergencyType.majorWaterLeak.requiresEvacuation)
        XCTAssertFalse(EmergencyType.noHeat.requiresEvacuation)
    }

    // MARK: - Education Model Tests

    func testGradeChangeDetection() {
        let change = GradeChange(
            studentId: UUID(),
            studentName: "Emma",
            subject: "Math",
            previousGrade: 85.0,
            currentGrade: 78.0,
            delta: -7.0
        )
        XCTAssertTrue(change.isSignificantDrop)
        XCTAssertFalse(change.isCritical)

        let criticalChange = GradeChange(
            studentId: UUID(),
            studentName: "Emma",
            subject: "Math",
            previousGrade: 72.0,
            currentGrade: 65.0,
            delta: -7.0
        )
        XCTAssertTrue(criticalChange.isCritical)
    }

    // MARK: - Mood Rating Tests

    func testMoodRatingValues() {
        XCTAssertEqual(MoodRating.great.numericValue, 5)
        XCTAssertEqual(MoodRating.poor.numericValue, 1)
    }

    // MARK: - Date Extensions Tests

    func testDateIsWeekday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Monday Feb 3, 2026
        let monday = formatter.date(from: "2026-02-03")!
        XCTAssertTrue(monday.isWeekday)

        // Saturday Feb 7, 2026
        let saturday = formatter.date(from: "2026-02-07")!
        XCTAssertTrue(saturday.isWeekend)
    }

    func testDateAddingDays() {
        let now = Date()
        let tomorrow = now.addingDays(1)
        let diff = Calendar.current.dateComponents([.day], from: now, to: tomorrow).day
        XCTAssertEqual(diff, 1)
    }

    // MARK: - String Extensions Tests

    func testContainsAny() {
        let text = "I have a headache and fever"
        XCTAssertTrue(text.containsAny(["headache", "cough"]))
        XCTAssertFalse(text.containsAny(["rash", "broken"]))
    }

    func testNilIfEmpty() {
        XCTAssertNil("".nilIfEmpty)
        XCTAssertEqual("hello".nilIfEmpty, "hello")
    }

    // MARK: - Priority Tests

    func testPriorityComparable() {
        XCTAssertTrue(Priority.low < Priority.medium)
        XCTAssertTrue(Priority.medium < Priority.high)
        XCTAssertTrue(Priority.high < Priority.urgent)
    }

    // MARK: - Decimal Extension Tests

    func testCurrencyString() {
        let amount: Decimal = 150.50
        XCTAssertTrue(amount.currencyString.contains("150"))
    }
}
