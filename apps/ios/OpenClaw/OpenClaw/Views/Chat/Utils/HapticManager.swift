import UIKit
import SwiftUI

/// Centralized haptic feedback management
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Notification Feedback

    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Impact Feedback

    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func softImpact() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        } else {
            lightImpact()
        }
    }

    func rigidImpact() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        } else {
            heavyImpact()
        }
    }

    // MARK: - Selection Feedback

    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Custom Patterns

    func messageSent() {
        lightImpact()
    }

    func messageReceived() {
        softImpact()
    }

    func taskApproved() {
        success()
    }

    func taskRejected() {
        warning()
    }

    func swipeAction() {
        selection()
    }

    func cardSwipe() {
        mediumImpact()
    }

    func achievement() {
        // Custom pattern for achievements
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mediumImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.lightImpact()
        }
    }

    func errorOccurred() {
        error()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }

    func longPress() {
        rigidImpact()
    }
}

// MARK: - View Extension for Haptics

extension View {
    func hapticFeedback(_ type: HapticFeedbackType) -> some View {
        self.onChange(of: type) { _, newValue in
            switch newValue {
            case .success:
                HapticManager.shared.success()
            case .warning:
                HapticManager.shared.warning()
            case .error:
                HapticManager.shared.error()
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            case .selection:
                HapticManager.shared.selection()
            case .none:
                break
            }
        }
    }

    func onTapWithHaptic(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticManager.shared.lightImpact()
            action()
        }
    }

    func onLongPressWithHaptic(perform action: @escaping () -> Void) -> some View {
        self.onLongPressGesture {
            HapticManager.shared.longPress()
            action()
        }
    }
}

enum HapticFeedbackType {
    case success
    case warning
    case error
    case light
    case medium
    case heavy
    case selection
    case none
}
