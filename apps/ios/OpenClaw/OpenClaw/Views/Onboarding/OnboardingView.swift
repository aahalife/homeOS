import SwiftUI

/// 7-step onboarding flow
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(viewModel.currentStep + 1), total: Double(viewModel.totalSteps))
                .tint(.blue)
                .padding(.horizontal)
                .padding(.top, 8)

            Text("Step \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            // Step content
            ScrollView {
                VStack(spacing: 24) {
                    switch viewModel.currentStep {
                    case 0: WelcomeStep()
                    case 1: FamilyInfoStep(viewModel: viewModel)
                    case 2: DietaryStep(viewModel: viewModel)
                    case 3: HealthInfoStep(viewModel: viewModel)
                    case 4: EducationStep(viewModel: viewModel)
                    case 5: HomeInfoStep(viewModel: viewModel)
                    case 6: SkillSelectionStep(viewModel: viewModel)
                    default: EmptyView()
                    }
                }
                .padding()
            }

            // Navigation buttons
            HStack(spacing: 16) {
                if viewModel.currentStep > 0 {
                    Button("Back") {
                        withAnimation { viewModel.previousStep() }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if viewModel.currentStep < viewModel.totalSteps - 1 {
                    Button("Next") {
                        withAnimation { viewModel.nextStep() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canProceed)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canProceed)
                }
            }
            .padding()
        }
    }

    private func completeOnboarding() {
        let family = viewModel.buildFamily()
        appState.completeOnboarding(family: family, skills: viewModel.selectedSkills)
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .padding(.top, 32)

            Text("Welcome to OpenClaw")
                .font(.largeTitle.bold())

            Text("Your AI-powered family assistant")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "fork.knife", title: "Meal Planning", description: "Weekly dinners and grocery lists")
                FeatureRow(icon: "heart.text.square", title: "Healthcare", description: "Medication tracking and symptom checks")
                FeatureRow(icon: "book", title: "Education", description: "Homework and grade monitoring")
                FeatureRow(icon: "figure.2.and.child.holdinghands", title: "Elder Care", description: "Compassionate daily check-ins")
                FeatureRow(icon: "house", title: "Home Maintenance", description: "Emergency triage and scheduling")
                FeatureRow(icon: "calendar", title: "Family Coordination", description: "Shared calendar and chores")
                FeatureRow(icon: "brain.head.profile", title: "Mental Load", description: "Briefings and proactive reminders")
            }
            .padding()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Step 2: Family Info

struct FamilyInfoStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tell us about your family")
                .font(.title2.bold())

            TextField("Family Name (e.g., Anderson)", text: $viewModel.familyName)
                .textFieldStyle(.roundedBorder)

            Divider()

            Text("Family Members").font(.headline)

            ForEach(viewModel.members) { member in
                HStack {
                    Image(systemName: member.role == .child ? "person.fill" : (member.role == .elder ? "figure.stand" : "person.fill"))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(member.name).font(.body)
                        Text(member.role.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { viewModel.removeMember(member) } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 4)
            }

            HStack {
                TextField("Name", text: $viewModel.newMemberName)
                    .textFieldStyle(.roundedBorder)
                Picker("Role", selection: $viewModel.newMemberRole) {
                    ForEach(MemberRole.allCases, id: \.self) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(.segmented)
                Button("Add") { viewModel.addMember() }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.newMemberName.isEmpty)
            }
        }
    }
}

// MARK: - Step 3: Dietary

struct DietaryStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Dietary Preferences")
                .font(.title2.bold())

            Text("Select any dietary restrictions that apply to your family:")
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(DietaryRestriction.allCases.filter { $0 != .none }, id: \.self) { restriction in
                    Toggle(restriction.rawValue, isOn: Binding(
                        get: { viewModel.dietaryRestrictions.contains(restriction) },
                        set: { isOn in
                            if isOn { viewModel.dietaryRestrictions.insert(restriction) }
                            else { viewModel.dietaryRestrictions.remove(restriction) }
                        }
                    ))
                    .toggleStyle(.button)
                    .tint(.blue)
                }
            }

            Divider()

            Text("Weekly Grocery Budget").font(.headline)
            HStack {
                Text("$")
                TextField("150", text: $viewModel.weeklyBudget)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                Text("/ week")
            }

            Divider()

            Text("Preferred Cuisines").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(viewModel.availableCuisines, id: \.self) { cuisine in
                    Toggle(cuisine, isOn: Binding(
                        get: { viewModel.preferredCuisines.contains(cuisine) },
                        set: { isOn in
                            if isOn { viewModel.preferredCuisines.insert(cuisine) }
                            else { viewModel.preferredCuisines.remove(cuisine) }
                        }
                    ))
                    .toggleStyle(.button)
                    .tint(.green)
                }
            }
        }
    }
}

// MARK: - Step 4: Health Info

struct HealthInfoStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health & Wellness")
                .font(.title2.bold())

            Text("This information helps us provide relevant health management features.")
                .foregroundStyle(.secondary)

            Toggle("Family has health concerns to track", isOn: $viewModel.hasHealthConcerns)
            Text("We can help with medication reminders, appointment scheduling, and symptom tracking.")
                .font(.caption).foregroundStyle(.secondary)

            Divider()

            Toggle("Caring for an elderly family member", isOn: $viewModel.hasElderCare)
            Text("We provide compassionate daily check-ins, medication tracking, and wellness monitoring for aging adults.")
                .font(.caption).foregroundStyle(.secondary)

            if viewModel.hasElderCare {
                Text("You can set up elder care details in the app after onboarding.")
                    .font(.callout)
                    .foregroundStyle(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Step 5: Education

struct EducationStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Education")
                .font(.title2.bold())

            Toggle("Has school-age children", isOn: $viewModel.hasSchoolAgeChildren)

            if viewModel.hasSchoolAgeChildren {
                VStack(alignment: .leading, spacing: 12) {
                    Text("We can connect to Google Classroom to automatically track:")
                        .font(.callout)

                    HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green); Text("Homework assignments") }
                    HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green); Text("Grade changes") }
                    HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green); Text("Upcoming tests") }
                    HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green); Text("Study plan generation") }

                    Text("You can connect Google Classroom later in Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Step 6: Home Info

struct HomeInfoStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Home Information")
                .font(.title2.bold())

            Text("Optional: helps with weather, contractor search, and emergency services.")
                .foregroundStyle(.secondary)

            TextField("Street Address", text: $viewModel.homeAddress)
                .textFieldStyle(.roundedBorder)

            HStack {
                TextField("City", text: $viewModel.homeCity)
                    .textFieldStyle(.roundedBorder)
                TextField("State", text: $viewModel.homeState)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
        }
    }
}

// MARK: - Step 7: Skills

struct SkillSelectionStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose Your Skills")
                .font(.title2.bold())

            Text("Select which skills you'd like to activate. You can change these later.")
                .foregroundStyle(.secondary)

            ForEach(SkillType.allCases) { skill in
                Toggle(isOn: Binding(
                    get: { viewModel.selectedSkills.contains(skill) },
                    set: { isOn in
                        if isOn { viewModel.selectedSkills.insert(skill) }
                        else { viewModel.selectedSkills.remove(skill) }
                    }
                )) {
                    HStack {
                        Image(systemName: skill.icon)
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 32)
                        VStack(alignment: .leading) {
                            Text(skill.rawValue).font(.headline)
                            Text(skill.description).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
