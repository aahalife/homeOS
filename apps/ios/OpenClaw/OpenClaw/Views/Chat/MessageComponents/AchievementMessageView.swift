import SwiftUI

/// Celebrate milestones
struct AchievementMessageView: View {
    let data: AchievementData
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = -10

    var body: some View {
        VStack(spacing: 16) {
            // Icon with animation
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: data.color).opacity(0.3),
                                Color(hex: data.color).opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 10)

                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: data.color),
                                Color(hex: data.color).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: data.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))

            // Title
            Text(data.title)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            // Description
            Text(data.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Milestone badge
            if let milestone = data.milestone {
                MilestoneBadge(milestone: milestone, color: Color(hex: data.color))
            }

            // Celebration button
            Button(action: {}) {
                Label("Share Achievement", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: data.color))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color(hex: data.color).opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: data.color).opacity(0.5),
                            Color(hex: data.color).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .overlay {
            if showConfetti && data.showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            // Entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                rotation = 0
            }

            // Show confetti
            if data.showConfetti {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                }
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Achievement unlocked: \(data.title). \(data.description)")
    }
}

// MARK: - Milestone Badge

struct MilestoneBadge: View {
    let milestone: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.caption)
            Text(milestone)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

        for i in 0..<50 {
            let piece = ConfettiPiece(
                id: i,
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement() ?? .blue,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5)
            )
            confettiPieces.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let rotation: Double
    let scale: CGFloat
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var offsetY: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 8 * piece.scale, height: 8 * piece.scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(x: piece.x, y: piece.y + offsetY)
            .onAppear {
                withAnimation(
                    .easeIn(duration: Double.random(in: 1.5...2.5))
                        .delay(Double.random(in: 0...0.3))
                ) {
                    offsetY = 600
                    rotation = Double.random(in: 360...720)
                    opacity = 0
                }
            }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AchievementMessageView(
                data: AchievementData(
                    id: UUID(),
                    title: "Week Streak!",
                    description: "You've successfully planned meals for 7 days in a row!",
                    icon: "flame.fill",
                    color: "FF6B35",
                    showConfetti: true,
                    milestone: "7 Day Streak"
                )
            )

            AchievementMessageView(
                data: AchievementData(
                    id: UUID(),
                    title: "Health Champion",
                    description: "You've maintained a balanced diet for an entire month",
                    icon: "heart.fill",
                    color: "FF006E",
                    showConfetti: false,
                    milestone: "30 Days"
                )
            )

            AchievementMessageView(
                data: AchievementData(
                    id: UUID(),
                    title: "Time Saver",
                    description: "OpenClaw has saved you 10 hours this month!",
                    icon: "clock.badge.checkmark.fill",
                    color: "06FFA5",
                    showConfetti: true,
                    milestone: "10 Hours Saved"
                )
            )
        }
        .padding()
    }
}
