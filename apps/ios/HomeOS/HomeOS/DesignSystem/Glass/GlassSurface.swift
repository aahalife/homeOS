import SwiftUI

/// Liquid Glass design system - translucent glass surfaces with subtle effects
struct GlassSurface: View {
    let cornerRadius: CGFloat
    var opacity: Double = 0.15
    var blur: CGFloat = 20
    var borderWidth: CGFloat = 0.5
    var borderOpacity: Double = 0.3

    init(
        cornerRadius: CGFloat = 20,
        opacity: Double = 0.15,
        blur: CGFloat = 20,
        borderWidth: CGFloat = 0.5,
        borderOpacity: Double = 0.3
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.blur = blur
        self.borderWidth = borderWidth
        self.borderOpacity = borderOpacity
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(opacity),
                                .white.opacity(opacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(borderOpacity),
                                .white.opacity(borderOpacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            )
    }
}

/// Card with glass surface styling
struct GlassCard<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(GlassSurface(cornerRadius: cornerRadius))
    }
}

/// Status pill with glass styling
struct StatusPill: View {
    let status: String
    let color: Color

    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 0.5)
            )
    }
}

/// Liquid button with glass effect
struct LiquidButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: Style = .primary

    enum Style {
        case primary
        case secondary
        case destructive

        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .white.opacity(0.8)
            case .destructive: return .red
            }
        }

        var backgroundColor: Color {
            switch self {
            case .primary: return .white.opacity(0.2)
            case .secondary: return .white.opacity(0.1)
            case .destructive: return .red.opacity(0.2)
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(style.backgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(style.foregroundColor.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Glowing divider
struct GlowDivider: View {
    var color: Color = .white
    var opacity: Double = 0.2

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0),
                        color.opacity(opacity),
                        color.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCard {
                Text("Glass Card")
                    .foregroundColor(.white)
            }

            StatusPill(status: "Running", color: .green)

            LiquidButton(title: "Approve", icon: "checkmark") {}

            GlowDivider()
                .padding(.horizontal)
        }
        .padding()
    }
}
