import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundColor(AppTheme.primary)
                .frame(width: 120, height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(AppTheme.surfaceSecondary)
                )

            VStack(spacing: 12) {
                Text("Meet Oi")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.primary)

                Text("Oi My Day keeps your family calm, coordinated, and on track.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppTheme.primary)
                        .cornerRadius(14)
                }

                Button(action: onSkip) {
                    Text("I'll set up later")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.primary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    WelcomeView(onContinue: {}, onSkip: {})
}
