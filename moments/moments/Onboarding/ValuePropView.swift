import SwiftUI

struct ValuePropView: View {
    let step: Int
    let total: Int
    let icon: String
    let title: String
    let subtitle: String
    let bullets: [String]
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            OnboardingProgressDots(current: step, total: total)
                .padding(.top, 8)

            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(AppTheme.primary)

            VStack(spacing: 10) {
                Text(title)
                    .font(.title.weight(.bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            StandardCard {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "34C759"))
                            Text(bullet)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: onPrimary) {
                    Text(primaryActionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppTheme.primary)
                        .cornerRadius(14)
                }

                Button(action: onSecondary) {
                    Text(secondaryActionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ValuePropView(
        step: 1,
        total: 3,
        icon: "sunrise.fill",
        title: "Start calm, finish proud",
        subtitle: "Oi My Day brings your family into focus every morning.",
        bullets: [
            "Personalized morning brief at the right time",
            "Top priorities across school, work, and home",
            "A single place to see what matters today"
        ],
        primaryActionTitle: "Continue",
        secondaryActionTitle: "Skip",
        onPrimary: {},
        onSecondary: {}
    )
}
