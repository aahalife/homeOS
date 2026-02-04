import SwiftUI

/// Skills overview dashboard
struct SkillsDashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(SkillType.allCases) { skill in
                        NavigationLink(destination: skillDetailView(for: skill)) {
                            SkillCard(skill: skill)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Skills")
        }
    }

    @ViewBuilder
    private func skillDetailView(for skill: SkillType) -> some View {
        switch skill {
        case .mealPlanning: MealPlanningDetailView()
        case .healthcare: HealthcareDetailView()
        case .education: EducationDetailView()
        case .elderCare: ElderCareDetailView()
        case .homeMaintenance: HomeMaintenanceDetailView()
        case .familyCoordination: FamilyCoordinationDetailView()
        case .mentalLoad: MentalLoadDetailView()
        }
    }
}

struct SkillCard: View {
    let skill: SkillType

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: skill.icon)
                .font(.system(size: 32))
                .foregroundStyle(.blue)

            Text(skill.rawValue)
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)

            Text(skill.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Skill Detail Views

struct MealPlanningDetailView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPlan: MealPlan?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let plan = currentPlan {
                    ForEach(plan.meals) { meal in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(meal.date.dayOfWeek).font(.caption).foregroundStyle(.secondary)
                                Text(meal.recipe.title).font(.headline)
                                Text("\(meal.recipe.totalTime) min | \(meal.recipe.cuisine)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(meal.recipe.primaryProtein.rawValue)
                                .font(.caption)
                                .padding(6)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text("Estimated cost: \(plan.estimatedCost.currencyString)")
                        .font(.headline)
                        .padding(.top)
                } else if isLoading {
                    ProgressView("Generating plan...")
                } else {
                    ContentUnavailableView("No Meal Plan", systemImage: "fork.knife", description: Text("Generate a weekly plan to get started."))
                }

                Button("Generate Weekly Plan") {
                    generatePlan()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("Meal Planning")
        .onAppear { loadPlan() }
    }

    private func loadPlan() {
        let plans: [MealPlan] = PersistenceController.shared.loadData(type: "meal_plan")
        currentPlan = plans.first
    }

    private func generatePlan() {
        guard let family = appState.currentFamily else { return }
        isLoading = true
        Task {
            do {
                currentPlan = try await MealPlanningSkill().generateWeeklyPlan(family: family)
            } catch {
                AppLogger.shared.error("Failed to generate plan: \(error)")
            }
            isLoading = false
        }
    }
}

struct HealthcareDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Medication Tracking", icon: "pills")
                Text("Track family medications and get reminders.")
                    .foregroundStyle(.secondary)

                SectionHeader(title: "Symptom Assessment", icon: "stethoscope")
                Text("Get guidance on symptom severity and next steps.")
                    .foregroundStyle(.secondary)

                SectionHeader(title: "Appointments", icon: "calendar.badge.clock")
                Text("Find in-network providers and schedule visits.")
                    .foregroundStyle(.secondary)

                Text(HealthcareSkill.safetyDisclaimer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .navigationTitle("Healthcare")
    }
}

struct EducationDetailView: View {
    @EnvironmentObject var appState: AppState
    @State private var assignments: [Assignment] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Upcoming Assignments", icon: "pencil")

                if assignments.isEmpty {
                    Text("No assignments loaded. Connect Google Classroom in Settings.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(assignments) { assignment in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(assignment.title).font(.headline)
                                Text(assignment.subject).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(assignment.dueDate.shortDateString).font(.caption)
                                Text(assignment.status.rawValue).font(.caption2)
                                    .foregroundStyle(assignment.status == .overdue ? .red : .green)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Education")
        .task {
            guard let family = appState.currentFamily else { return }
            assignments = await EducationSkill().getUpcomingAssignments(family: family)
        }
    }
}

struct ElderCareDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Daily Check-Ins", icon: "heart.text.square")
                Text("Compassionate wellness check-ins for elderly family members.")
                    .foregroundStyle(.secondary)

                SectionHeader(title: "Medication Adherence", icon: "pills")
                Text("Track medication compliance and send gentle reminders.")
                    .foregroundStyle(.secondary)

                SectionHeader(title: "Red Flag Detection", icon: "exclamationmark.triangle")
                Text("Automated detection of health concerns from check-in conversations.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Elder Care")
    }
}

struct HomeMaintenanceDetailView: View {
    @State private var tasks: [MaintenanceTask] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Maintenance Schedule", icon: "wrench")

                ForEach(tasks) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.title).font(.headline)
                            Text(task.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(task.nextDue.shortDateString)
                            .font(.caption)
                            .foregroundStyle(task.nextDue < Date() ? .red : .primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Home Maintenance")
        .onAppear {
            tasks = HomeMaintenanceSkill().getMaintenanceSchedule(family: Family(name: "", members: [], preferences: FamilyPreferences()))
        }
    }
}

struct FamilyCoordinationDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Family Calendar", icon: "calendar")
                Text("Unified view of all family schedules with conflict detection.")
                    .foregroundStyle(.secondary)

                SectionHeader(title: "Chore Management", icon: "checkmark.circle")
                Text("Assign chores with points and track completion.")
                    .foregroundStyle(.secondary)

                SectionHeader(title: "Family Messaging", icon: "message")
                Text("Broadcast messages to all family members.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Family Coordination")
    }
}

struct MentalLoadDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Morning Briefing", icon: "sun.max")
                Text("Daily overview at 7:00 AM with weather, schedule, and priorities.")
                    .foregroundStyle(.secondary)

                SectionHeader(title: "Evening Wind-Down", icon: "moon")
                Text("End-of-day review at 8:00 PM with tomorrow's prep list.")
                    .foregroundStyle(.secondary)

                SectionHeader(title: "Weekly Planning", icon: "calendar.badge.plus")
                Text("Comprehensive week-ahead plan every Sunday at 6:00 PM.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Mental Load")
    }
}

// MARK: - Helpers

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(title)
                .font(.headline)
        }
        .padding(.top, 8)
    }
}

#Preview {
    SkillsDashboardView()
        .environmentObject(AppState())
}
