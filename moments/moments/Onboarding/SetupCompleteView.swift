import SwiftUI

struct SetupCompleteView: View {
    @State private var summaryTime = "7:00 AM"

    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            OnboardingProgressDots(current: 5, total: 5)
                .padding(.top, 8)

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "34C759"))

            VStack(spacing: 12) {
                Text("You're all set!")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.primary)

                Text("Oi will send your first morning brief tomorrow at \(summaryTime).")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            StandardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What's configured")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ChecklistRow(text: "Morning briefs enabled")
                    ChecklistRow(text: "Family members confirmed")
                    ChecklistRow(text: "Approval thresholds saved")
                    ChecklistRow(text: "Calendar permissions captured")
                }
            }

            Spacer()

            Button(action: onComplete) {
                Text("Go to Home")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppTheme.primary)
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            if let prefs = OnboardingPreferencesStore.shared.load(),
               let time = displayTime(from: prefs.morningBriefTime) {
                summaryTime = time
            }
        }
    }

    private func displayTime(from timeString: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let date = formatter.date(from: timeString) else { return nil }
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

private struct ChecklistRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "34C759"))
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
    }
}

#Preview {
    SetupCompleteView(onComplete: {})
}
