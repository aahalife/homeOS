import SwiftUI

/// Show workflow progress (Step 2 of 5)
struct ProgressMessageView: View {
    let data: ProgressData
    @State private var animateProgress = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection

            // Progress bar
            progressBar

            // Steps list
            stepsList

            // Estimated completion
            if let completion = data.estimatedCompletion {
                estimatedCompletionView(completion)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                animateProgress = true
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Step \(data.currentStep) of \(data.totalSteps)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: animateProgress ? progress : 0)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animateProgress)

                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 8)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: animateProgress ? geometry.size.width * progress : 0,
                        height: 8
                    )
                    .animation(.easeInOut(duration: 1.0), value: animateProgress)
            }
        }
        .frame(height: 8)
    }

    private var stepsList: some View {
        VStack(spacing: 12) {
            ForEach(Array(data.steps.enumerated()), id: \.element.id) { index, step in
                StepRow(
                    step: step,
                    stepNumber: index + 1,
                    isActive: index + 1 == data.currentStep
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
    }

    private func estimatedCompletionView(_ completion: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Est. completion: \(completion.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.top, 4)
    }

    private var progress: CGFloat {
        CGFloat(data.currentStep) / CGFloat(data.totalSteps)
    }
}

// MARK: - Step Row

struct StepRow: View {
    let step: ProgressStep
    let stepNumber: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 32, height: 32)

                if step.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else if step.status == .failed {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else if step.status == .inProgress {
                    ProgressSpinner()
                } else {
                    Text("\(stepNumber)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(textColor)
                }
            }

            // Step content
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.body.weight(isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? .primary : .secondary)

                if let icon = step.icon {
                    Label(statusText, systemImage: icon)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step.title), \(statusText)")
    }

    private var backgroundColor: Color {
        switch step.status {
        case .completed:
            return .green
        case .inProgress:
            return .blue
        case .pending:
            return Color(.systemGray5)
        case .failed:
            return .red
        }
    }

    private var textColor: Color {
        step.status == .pending ? .secondary : .white
    }

    private var statusText: String {
        switch step.status {
        case .completed: return "Completed"
        case .inProgress: return "In progress"
        case .pending: return "Pending"
        case .failed: return "Failed"
        }
    }

    private var statusColor: Color {
        switch step.status {
        case .completed: return .green
        case .inProgress: return .blue
        case .pending: return .secondary
        case .failed: return .red
        }
    }
}

// MARK: - Progress Spinner

struct ProgressSpinner: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [.white, .white.opacity(0.3)],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: 16, height: 16)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Animated Progress View

struct AnimatedProgressView: View {
    let progress: Double
    @State private var animatedProgress: Double = 0

    var body: some View {
        ProgressView(value: animatedProgress, total: 1.0)
            .tint(.blue)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = progress
                }
            }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Early progress
            ProgressMessageView(
                data: ProgressData(
                    id: UUID(),
                    title: "Planning Your Meals",
                    currentStep: 2,
                    totalSteps: 5,
                    steps: [
                        ProgressStep(
                            id: UUID(),
                            title: "Analyzing dietary preferences",
                            status: .completed,
                            icon: "checkmark.circle"
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Searching for recipes",
                            status: .inProgress,
                            icon: "magnifyingglass"
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Checking nutritional balance",
                            status: .pending,
                            icon: nil
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Creating grocery list",
                            status: .pending,
                            icon: nil
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Finalizing meal plan",
                            status: .pending,
                            icon: nil
                        )
                    ],
                    estimatedCompletion: Date().addingTimeInterval(120)
                )
            )

            // Nearly complete
            ProgressMessageView(
                data: ProgressData(
                    id: UUID(),
                    title: "Booking Appointment",
                    currentStep: 4,
                    totalSteps: 4,
                    steps: [
                        ProgressStep(
                            id: UUID(),
                            title: "Checking availability",
                            status: .completed,
                            icon: "checkmark.circle"
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Confirming insurance",
                            status: .completed,
                            icon: "checkmark.circle"
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Sending booking request",
                            status: .completed,
                            icon: "checkmark.circle"
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Waiting for confirmation",
                            status: .inProgress,
                            icon: "clock"
                        )
                    ],
                    estimatedCompletion: Date().addingTimeInterval(300)
                )
            )

            // With failure
            ProgressMessageView(
                data: ProgressData(
                    id: UUID(),
                    title: "Ordering Groceries",
                    currentStep: 3,
                    totalSteps: 5,
                    steps: [
                        ProgressStep(
                            id: UUID(),
                            title: "Creating order",
                            status: .completed,
                            icon: "checkmark.circle"
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Checking stock",
                            status: .completed,
                            icon: "checkmark.circle"
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Processing payment",
                            status: .failed,
                            icon: "xmark.circle"
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Confirming delivery time",
                            status: .pending,
                            icon: nil
                        ),
                        ProgressStep(
                            id: UUID(),
                            title: "Sending confirmation",
                            status: .pending,
                            icon: nil
                        )
                    ],
                    estimatedCompletion: nil
                )
            )
        }
        .padding()
    }
}
