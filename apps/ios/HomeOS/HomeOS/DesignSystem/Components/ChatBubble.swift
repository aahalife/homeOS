import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    @State private var showRipple = false

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        bubbleBackground
                    )
                    .overlay(rippleEffect)

                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
        .onAppear {
            if message.role == .assistant && message.isNew {
                triggerRipple()
            }
        }
    }

    private var bubbleBackground: some View {
        Group {
            if message.role == .user {
                LinearGradient(
                    colors: [
                        Color(hex: "4361ee"),
                        Color(hex: "3a0ca3")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(BubbleShape(isUser: true))
            } else {
                GlassSurface(cornerRadius: 0, opacity: 0.1)
                    .clipShape(BubbleShape(isUser: false))
            }
        }
    }

    private var rippleEffect: some View {
        Circle()
            .fill(.white.opacity(showRipple ? 0 : 0.3))
            .scaleEffect(showRipple ? 3 : 0.5)
            .opacity(showRipple ? 0 : 1)
            .animation(.easeOut(duration: 0.6), value: showRipple)
            .allowsHitTesting(false)
    }

    private func triggerRipple() {
        showRipple = false
        withAnimation {
            showRipple = true
        }
    }
}

struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 18
        let tailSize: CGFloat = 8

        var path = Path()

        if isUser {
            // User bubble - tail on right
            path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            // Tail
            path.addLine(to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + tailSize))
            path.addLine(to: CGPoint(x: rect.maxX - tailSize * 2, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // Assistant bubble - tail on left
            path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + tailSize * 2, y: rect.maxY))
            // Tail
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY + tailSize))
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }

        path.closeSubpath()
        return path
    }
}

// Chat message model
struct ChatMessage: Identifiable {
    let id: String
    let role: Role
    let content: String
    let timestamp: Date
    var isNew: Bool = false

    enum Role {
        case user, assistant, system
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
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

        VStack(spacing: 16) {
            ChatBubble(message: ChatMessage(
                id: "1",
                role: .user,
                content: "Book a quiet Italian place for Friday around 7pm. Party of 4.",
                timestamp: Date()
            ))

            ChatBubble(message: ChatMessage(
                id: "2",
                role: .assistant,
                content: "I found 3 great Italian restaurants nearby. Here are my top picks:\n\n1. Osteria Mozza - 4.8★\n2. Chi Spacca - 4.7★\n3. Pizzeria Mozza - 4.6★\n\nWhich one should I call?",
                timestamp: Date(),
                isNew: true
            ))
        }
        .padding()
    }
}
