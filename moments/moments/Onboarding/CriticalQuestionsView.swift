import SwiftUI

struct CriticalQuestionsView: View {
    @State private var dietarySelections: Set<String> = ["None"]
    @State private var autoApproveBelow: Double = 50
    @State private var morningBriefTime = Self.defaultTime(hour: 7, minute: 0)
    @State private var quietStart = Self.defaultTime(hour: 21, minute: 0)
    @State private var quietEnd = Self.defaultTime(hour: 7, minute: 0)
    @State private var shouldAskQuietHours = true
    @State private var quietHoursNote: String?
    @State private var emergencyName = ""
    @State private var emergencyPhone = ""
    @State private var showDefaultInfo = false
    @State private var emergencySuggestion: EmergencyContactSuggestion?
    @State private var useSuggestedEmergency = false

    let onComplete: () -> Void

    private let dietaryOptions = [
        "None",
        "Vegetarian",
        "Vegan",
        "Gluten-Free",
        "Nut Allergy",
        "Dairy-Free",
        "Other"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingProgressDots(current: 4, total: 5)
                    .padding(.top, 8)

                header

                questionCard(title: "Dietary restrictions") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(dietaryOptions, id: \.self) { option in
                            ChipButton(
                                title: option,
                                isSelected: dietarySelections.contains(option)
                            ) {
                                toggleDietary(option)
                            }
                        }
                    }
                    Text("Defaults to None. You can change this later.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }

                questionCard(title: "Auto-approve purchases under") {
                    VStack(spacing: 10) {
                        Text("$\(Int(autoApproveBelow))")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                        Slider(value: $autoApproveBelow, in: 0...200, step: 5)
                            .tint(AppTheme.primary)
                        Button("Why this default?") {
                            showDefaultInfo = true
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    }
                }

                questionCard(title: "Morning brief time") {
                    DatePicker("", selection: $morningBriefTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxHeight: 120)
                }

                if shouldAskQuietHours {
                    questionCard(title: "Quiet hours") {
                        VStack(spacing: 10) {
                            DatePicker("Start", selection: $quietStart, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                            DatePicker("End", selection: $quietEnd, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                } else {
                    questionCard(title: "Quiet hours") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Using your last saved quiet hours.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            HStack {
                                Text("\(displayTime(from: quietStart)) - \(displayTime(from: quietEnd))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button("Change") {
                                    shouldAskQuietHours = true
                                }
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                            }
                            if let quietHoursNote {
                                Text(quietHoursNote)
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                }

                questionCard(title: "Emergency contact") {
                    VStack(alignment: .leading, spacing: 12) {
                        if let suggestion = emergencySuggestion {
                            HStack(spacing: 6) {
                                Text("Suggested: \(suggestion.name)")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                if let last4 = suggestion.phoneLast4 {
                                    Text("**** \(last4)")
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                                Spacer()
                            }
                            if useSuggestedEmergency {
                                Text("Using suggested contact")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textTertiary)
                                Button("Choose different") {
                                    useSuggestedEmergency = false
                                    emergencyName = ""
                                    emergencyPhone = ""
                                }
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                            } else {
                                Button("Confirm suggestion") {
                                    emergencyName = suggestion.name
                                    useSuggestedEmergency = true
                                }
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                            }
                        } else {
                            Text("Suggested: None available")
                                .font(.caption)
                                .foregroundColor(AppTheme.textTertiary)
                        }

                        if !useSuggestedEmergency {
                            TextField("Name", text: $emergencyName)
                                .textFieldStyle(.plain)
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(AppTheme.surfaceSecondary)
                                .cornerRadius(10)
                            TextField("Phone number", text: $emergencyPhone)
                                .textFieldStyle(.plain)
                                .foregroundColor(.primary)
                                .keyboardType(.phonePad)
                                .padding(12)
                                .background(AppTheme.surfaceSecondary)
                                .cornerRadius(10)
                        }
                    }
                }

                VStack(spacing: 10) {
                    Button(action: complete) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppTheme.primary)
                            .cornerRadius(14)
                    }

                    Button(action: completeWithDefaults) {
                        Text("Skip and use defaults")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .background(Color(.systemBackground))
        .alert("Defaults", isPresented: $showDefaultInfo) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("We use $50 because most families approve routine expenses under that amount. You can change it anytime.")
        }
        .onAppear {
            if let inferred = loadInferredQuietHours() {
                quietStart = inferred.start
                quietEnd = inferred.end
                shouldAskQuietHours = false
                quietHoursNote = inferred.note
            }
            if emergencySuggestion == nil {
                emergencySuggestion = FamilyStore.shared.suggestedEmergencyContact()
                useSuggestedEmergency = emergencySuggestion != nil
                if let suggestion = emergencySuggestion {
                    emergencyName = suggestion.name
                }
            }
            if shouldAskQuietHours {
                Task {
                    if let window = await HealthKitManager.shared.fetchSleepWindow() {
                        quietStart = window.start
                        quietEnd = window.end
                        shouldAskQuietHours = false
                        quietHoursNote = window.note
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("A few quick questions")
                .font(.title.weight(.bold))
                .foregroundColor(.primary)
            Text("We'll use this to personalize Oi My Day. You can change these later.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func questionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        StandardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                content()
            }
        }
    }

    private func toggleDietary(_ option: String) {
        if option == "None" {
            dietarySelections = ["None"]
            return
        }

        dietarySelections.remove("None")
        if dietarySelections.contains(option) {
            dietarySelections.remove(option)
        } else {
            dietarySelections.insert(option)
        }
    }

    private func complete() {
        let prefs = OnboardingPreferences(
            dietaryRestrictions: Array(dietarySelections.isEmpty ? ["None"] : dietarySelections),
            autoApproveBelow: autoApproveBelow,
            morningBriefTime: timeString(from: morningBriefTime),
            quietHoursStart: timeString(from: quietStart),
            quietHoursEnd: timeString(from: quietEnd),
            emergencyContactName: emergencyName.isEmpty ? nil : emergencyName,
            emergencyContactPhone: emergencyPhone.isEmpty ? nil : emergencyPhone
        )
        OnboardingPreferencesStore.shared.save(prefs)
        Task {
            await ControlPlaneClient.shared.sendOnboardingPreferences(prefs)
        }
        onComplete()
    }

    private func completeWithDefaults() {
        dietarySelections = ["None"]
        autoApproveBelow = 50
        morningBriefTime = Self.defaultTime(hour: 7, minute: 0)
        quietStart = Self.defaultTime(hour: 21, minute: 0)
        quietEnd = Self.defaultTime(hour: 7, minute: 0)
        emergencyName = ""
        emergencyPhone = ""
        complete()
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func displayTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private static func defaultTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private func loadInferredQuietHours() -> QuietHoursInferenceResult? {
        if let prefs = OnboardingPreferencesStore.shared.load(),
           let start = parseTime(prefs.quietHoursStart),
           let end = parseTime(prefs.quietHoursEnd) {
            return QuietHoursInferenceResult(start: start, end: end, note: "Loaded from your last saved preferences.")
        }
        return nil
    }

    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
}

private struct QuietHoursInferenceResult {
    let start: Date
    let end: Date
    let note: String?
}

private struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AppTheme.primary : AppTheme.surfaceSecondary)
                )
        }
    }
}

#Preview {
    CriticalQuestionsView(onComplete: {})
}
