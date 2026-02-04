import Foundation
import Combine

/// ViewModel for the 7-step onboarding flow
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var isLoading: Bool = false

    // Step 1: Welcome
    // Step 2: Family Info
    @Published var familyName: String = ""
    @Published var members: [FamilyMember] = []
    @Published var newMemberName: String = ""
    @Published var newMemberRole: MemberRole = .adult

    // Step 3: Dietary Preferences
    @Published var dietaryRestrictions: Set<DietaryRestriction> = []
    @Published var weeklyBudget: String = "150"
    @Published var preferredCuisines: Set<String> = []

    // Step 4: Health Info
    @Published var hasHealthConcerns: Bool = false
    @Published var hasElderCare: Bool = false

    // Step 5: Education Setup
    @Published var hasSchoolAgeChildren: Bool = false

    // Step 6: Home Info
    @Published var homeAddress: String = ""
    @Published var homeCity: String = ""
    @Published var homeState: String = ""

    // Step 7: Skills Selection
    @Published var selectedSkills: Set<SkillType> = Set(SkillType.allCases)

    let totalSteps = 7

    var availableCuisines: [String] {
        ["American", "Italian", "Mexican", "Chinese", "Indian", "Japanese", "Thai", "Mediterranean", "Korean", "French"]
    }

    var canProceed: Bool {
        switch currentStep {
        case 0: return true // Welcome
        case 1: return !familyName.isEmpty && !members.isEmpty
        case 2: return true // Dietary is optional
        case 3: return true // Health is optional
        case 4: return true // Education is optional
        case 5: return true // Home is optional
        case 6: return !selectedSkills.isEmpty
        default: return false
        }
    }

    // MARK: - Member Management

    func addMember() {
        guard !newMemberName.isEmpty else { return }
        let member = FamilyMember(
            name: newMemberName,
            role: newMemberRole,
            dietaryRestrictions: Array(dietaryRestrictions)
        )
        members.append(member)
        newMemberName = ""
    }

    func removeMember(_ member: FamilyMember) {
        members.removeAll { $0.id == member.id }
    }

    // MARK: - Navigation

    func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        currentStep += 1
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    // MARK: - Complete Onboarding

    func buildFamily() -> Family {
        // Apply dietary restrictions to all members
        var updatedMembers = members
        for i in updatedMembers.indices {
            updatedMembers[i].dietaryRestrictions = Array(dietaryRestrictions)
        }

        var preferences = FamilyPreferences()
        preferences.weeklyGroceryBudget = Decimal(string: weeklyBudget)
        preferences.preferredCuisines = Array(preferredCuisines)
        preferences.healthcareEnabled = hasHealthConcerns || selectedSkills.contains(.healthcare)
        preferences.educationEnabled = hasSchoolAgeChildren || selectedSkills.contains(.education)
        preferences.elderCareEnabled = hasElderCare || selectedSkills.contains(.elderCare)
        preferences.homeAddress = homeAddress.nilIfEmpty
        preferences.homeCity = homeCity.nilIfEmpty
        preferences.homeState = homeState.nilIfEmpty

        for skill in SkillType.allCases {
            switch skill {
            case .mealPlanning: preferences.mealPlanningEnabled = selectedSkills.contains(skill)
            case .healthcare: preferences.healthcareEnabled = selectedSkills.contains(skill)
            case .education: preferences.educationEnabled = selectedSkills.contains(skill)
            case .elderCare: preferences.elderCareEnabled = selectedSkills.contains(skill)
            case .homeMaintenance: preferences.homeMaintenanceEnabled = selectedSkills.contains(skill)
            case .familyCoordination: preferences.familyCoordinationEnabled = selectedSkills.contains(skill)
            case .mentalLoad: preferences.mentalLoadEnabled = selectedSkills.contains(skill)
            }
        }

        return Family(
            name: familyName,
            members: updatedMembers,
            preferences: preferences
        )
    }
}
