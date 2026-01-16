import SwiftUI

struct InferenceProgressView: View {
    @State private var stepIndex = 0
    @State private var isRunning = false

    let onComplete: () -> Void

    private let steps = [
        "Reading contacts...",
        "Checking calendar...",
        "Finding patterns...",
        "Understanding your family..."
    ]

    var body: some View {
        VStack(spacing: 24) {
            OnboardingProgressDots(current: 2, total: 5)
                .padding(.top, 8)

            Text("Setting things up")
                .font(.title.weight(.bold))
                .foregroundColor(.primary)

            Image(systemName: "sparkles.magnifyingglass")
                .font(.system(size: 56))
                .foregroundColor(AppTheme.primary)

            Text(steps[stepIndex])
                .font(.headline)
                .foregroundColor(AppTheme.textSecondary)

            Text("This takes about 10 seconds")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            guard !isRunning else { return }
            isRunning = true
            await runInference()
            onComplete()
        }
        .task {
            await cycleSteps()
        }
    }

    private func runInference() async {
        let startTime = Date()
        await InferenceService.shared.run()

        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 5 {
            let remaining = UInt64((5 - elapsed) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: remaining)
        }
    }

    private func cycleSteps() async {
        while stepIndex < steps.count - 1 {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            stepIndex = min(stepIndex + 1, steps.count - 1)
        }
    }
}

#Preview {
    InferenceProgressView(onComplete: {})
}
