import SwiftUI

/// Collection of reusable animations for the chat interface
struct AnimationHelpers {
    // MARK: - Spring Animations

    static let smoothSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let snappySpring = Animation.spring(response: 0.3, dampingFraction: 0.8)

    // MARK: - Easing Animations

    static let easeInOut = Animation.easeInOut(duration: 0.3)
    static let easeIn = Animation.easeIn(duration: 0.2)
    static let easeOut = Animation.easeOut(duration: 0.3)

    // MARK: - Custom Animations

    static let messageAppear = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let messageDismiss = Animation.easeIn(duration: 0.2)
    static let cardFlip = Animation.spring(response: 0.6, dampingFraction: 0.7)
    static let confetti = Animation.easeOut(duration: 2.0)
}

// MARK: - Custom Transitions

extension AnyTransition {
    static var messageSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }

    static var cardSwipe: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .scale(scale: 0.8)),
            removal: .move(edge: .leading).combined(with: .scale(scale: 0.8))
        )
    }

    static var fadeScale: AnyTransition {
        .scale.combined(with: .opacity)
    }

    static var slideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    static var slideDown: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }
}

// MARK: - Animated Modifiers

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    func shake(amount: CGFloat = 10, shakesPerUnit: Int = 3, animationValue: CGFloat) -> some View {
        self.modifier(ShakeEffect(amount: amount, shakesPerUnit: shakesPerUnit, animatableData: animationValue))
    }
}

// MARK: - Pulsating Effect

struct PulsatingEffect: ViewModifier {
    @State private var isPulsating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsating ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsating
            )
            .onAppear {
                isPulsating = true
            }
    }
}

extension View {
    func pulsating() -> some View {
        self.modifier(PulsatingEffect())
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Bounce Animation

struct BounceAnimation: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .onAppear {
                withAnimation(AnimationHelpers.bouncySpring) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func bounceOnAppear() -> some View {
        self.modifier(BounceAnimation())
    }
}

// MARK: - Rotation Effect

struct ContinuousRotation: ViewModifier {
    @State private var rotation: Double = 0

    let speed: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(Animation.linear(duration: speed).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

extension View {
    func continuousRotation(speed: Double = 2.0) -> some View {
        self.modifier(ContinuousRotation(speed: speed))
    }
}

// MARK: - Slide In Effect

struct SlideInEffect: ViewModifier {
    @State private var offset: CGFloat = 100
    let edge: Edge
    let delay: Double

    func body(content: Content) -> some View {
        content
            .offset(x: edge == .leading || edge == .trailing ? offset : 0,
                   y: edge == .top || edge == .bottom ? offset : 0)
            .opacity(offset == 0 ? 1 : 0)
            .onAppear {
                withAnimation(AnimationHelpers.smoothSpring.delay(delay)) {
                    offset = 0
                }
            }
    }
}

extension View {
    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        self.modifier(SlideInEffect(edge: edge, delay: delay))
    }
}

// MARK: - Typewriter Effect

struct TypewriterEffect: ViewModifier {
    @State private var text = ""
    let fullText: String
    let speed: Double

    func body(content: Content) -> some View {
        Text(text)
            .onAppear {
                animateText()
            }
    }

    private func animateText() {
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * speed) {
                text.append(character)
            }
        }
    }
}

// MARK: - Gradient Animation

struct AnimatedGradient: View {
    @State private var start = UnitPoint.topLeading
    @State private var end = UnitPoint.bottomTrailing

    let colors: [Color]

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: start,
            endPoint: end
        )
        .onAppear {
            withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: true)) {
                start = .bottomLeading
                end = .topTrailing
            }
        }
    }
}

// MARK: - Loading Dots

struct LoadingDots: View {
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentIndex == index ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.4), value: currentIndex)
            }
        }
        .onReceive(timer) { _ in
            currentIndex = (currentIndex + 1) % 3
        }
    }
}

// MARK: - Breath Animation

struct BreathingEffect: ViewModifier {
    @State private var isBreathing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? 1.05 : 1.0)
            .opacity(isBreathing ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

extension View {
    func breathing() -> some View {
        self.modifier(BreathingEffect())
    }
}

// MARK: - Float Animation

struct FloatingEffect: ViewModifier {
    @State private var isFloating = false

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -10 : 10)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

extension View {
    func floating() -> some View {
        self.modifier(FloatingEffect())
    }
}

#Preview("Animations") {
    ScrollView {
        VStack(spacing: 30) {
            Text("Bounce")
                .bounceOnAppear()

            Text("Shimmer")
                .shimmer()

            Text("Pulsating")
                .pulsating()

            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .continuousRotation()

            LoadingDots()

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue)
                .frame(height: 100)
                .breathing()

            Circle()
                .fill(Color.green)
                .frame(width: 50, height: 50)
                .floating()
        }
        .padding()
    }
}
