import XCTest
@testable import HomeOSCore

final class FamilyTests: XCTestCase {
    
    func testFamilyMembersByRole() {
        let family = Family(members: [
            FamilyMember(id: "1", name: "Mom", role: .parent),
            FamilyMember(id: "2", name: "Dad", role: .parent),
            FamilyMember(id: "3", name: "Emma", role: .child, age: 10),
            FamilyMember(id: "4", name: "Grandma", role: .elder, age: 75)
        ])
        
        XCTAssertEqual(family.parents.count, 2)
        XCTAssertEqual(family.children.count, 1)
        XCTAssertEqual(family.elders.count, 1)
    }
    
    func testAgeGroups() {
        XCTAssertEqual(FamilyMember(id: "1", name: "Baby", role: .child, age: 2).ageGroup, .toddler)
        XCTAssertEqual(FamilyMember(id: "2", name: "Pre-K", role: .child, age: 4).ageGroup, .preschool)
        XCTAssertEqual(FamilyMember(id: "3", name: "Kid", role: .child, age: 8).ageGroup, .schoolAge)
        XCTAssertEqual(FamilyMember(id: "4", name: "Tween", role: .child, age: 12).ageGroup, .tween)
        XCTAssertEqual(FamilyMember(id: "5", name: "Teen", role: .child, age: 15).ageGroup, .teen)
        XCTAssertEqual(FamilyMember(id: "6", name: "Adult", role: .parent, age: 35).ageGroup, .adult)
        XCTAssertNil(FamilyMember(id: "7", name: "NoAge", role: .child).ageGroup)
    }
    
    func testChildrenSortedByAge() {
        let family = Family(members: [
            FamilyMember(id: "1", name: "Older", role: .child, age: 12),
            FamilyMember(id: "2", name: "Younger", role: .child, age: 5),
            FamilyMember(id: "3", name: "Mom", role: .parent)
        ])
        
        XCTAssertEqual(family.children.first?.name, "Younger")
        XCTAssertEqual(family.children.last?.name, "Older")
    }
    
    func testFamilyMemberLookup() {
        let family = Family(members: [
            FamilyMember(id: "mom-1", name: "Sarah", role: .parent)
        ])
        
        XCTAssertNotNil(family.member(id: "mom-1"))
        XCTAssertNil(family.member(id: "nonexistent"))
    }
    
    func testMedicationRefillCheck() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let refillDate = formatter.string(from: threeDaysFromNow)
        
        let profile = HealthProfile(
            memberId: "dad",
            medications: [
                Medication(name: "Lisinopril", dosage: "10mg", times: ["08:00"], refillDate: refillDate),
                Medication(name: "Vitamin D", dosage: "2000IU", times: ["08:00"], refillDate: nil)
            ]
        )
        
        let needsRefill = profile.refillsNeeded(withinDays: 7)
        XCTAssertEqual(needsRefill.count, 1)
        XCTAssertEqual(needsRefill.first?.name, "Lisinopril")
        
        let noRefills = profile.refillsNeeded(withinDays: 1)
        XCTAssertEqual(noRefills.count, 0)
    }
    
    func testMedicationsDueAtTime() {
        let profile = HealthProfile(
            memberId: "dad",
            medications: [
                Medication(name: "Morning Med", dosage: "10mg", times: ["08:00"]),
                Medication(name: "Evening Med", dosage: "20mg", times: ["20:00"]),
                Medication(name: "Twice Daily", dosage: "5mg", times: ["08:00", "20:00"])
            ]
        )
        
        let morningMeds = profile.medicationsDue(at: "08:00")
        XCTAssertEqual(morningMeds.count, 2) // Morning Med + Twice Daily
        
        let eveningMeds = profile.medicationsDue(at: "20:00")
        XCTAssertEqual(eveningMeds.count, 2) // Evening Med + Twice Daily
        
        let noonMeds = profile.medicationsDue(at: "12:00")
        XCTAssertEqual(noonMeds.count, 0)
    }
    
    func testHabitSuccessRate() {
        let habit = Habit(
            name: "Exercise",
            memberId: "dad",
            atomicVersion: "1 pushup",
            cue: "After waking up",
            currentStreak: 5,
            completionLog: ["2024-01-01", "2024-01-02", "2024-01-03", "2024-01-04", "2024-01-05"]
        )
        
        XCTAssertGreaterThan(habit.successRate, 0)
    }
    
    func testEmptyHabitSuccessRate() {
        let habit = Habit(name: "New", memberId: "dad", atomicVersion: "do it", cue: "after lunch")
        XCTAssertEqual(habit.successRate, 0)
    }
    
    func testFamilyCodable() throws {
        let family = Family(members: [
            FamilyMember(id: "1", name: "Test", role: .parent, age: 35, allergies: ["peanuts"])
        ])
        
        let data = try JSONEncoder().encode(family)
        let decoded = try JSONDecoder().decode(Family.self, from: data)
        
        XCTAssertEqual(decoded.members.count, 1)
        XCTAssertEqual(decoded.members[0].allergies, ["peanuts"])
    }
    
    func testInMemoryStorage() async throws {
        let storage = InMemoryStorage()
        
        let family = Family(members: [FamilyMember(id: "1", name: "Test", role: .parent)])
        try await storage.write(path: "data/family.json", value: family)
        
        let exists = await storage.exists(path: "data/family.json")
        XCTAssertTrue(exists)
        
        let loaded = try await storage.read(path: "data/family.json", type: Family.self)
        XCTAssertEqual(loaded.members.count, 1)
        
        let notExists = await storage.exists(path: "nonexistent.json")
        XCTAssertFalse(notExists)
    }
}
