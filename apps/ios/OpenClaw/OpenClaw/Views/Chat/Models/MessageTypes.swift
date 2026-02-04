import SwiftUI

// MARK: - Enhanced Message Types

enum MessageType: Codable, Hashable {
    case text
    case skillCard(SkillCardData)
    case action(ActionData)
    case progress(ProgressData)
    case update(UpdateData)
    case achievement(AchievementData)
    case richMedia(RichMediaData)
}

// MARK: - Skill Card Data

struct SkillCardData: Codable, Hashable {
    let id: UUID
    let type: SkillCardType
    let title: String
    let subtitle: String?
    let icon: String
    let color: String // Hex color
    let data: [String: String]
    let actions: [CardAction]

    enum SkillCardType: String, Codable {
        case mealPlan
        case appointment
        case recipe
        case groceryList
        case healthCheckIn
        case homework
        case contractor
        case briefing
    }
}

struct CardAction: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let type: ActionType
    let style: ActionStyle

    enum ActionType: String, Codable {
        case approve
        case modify
        case cancel
        case viewDetails
        case share
        case custom
    }

    enum ActionStyle: String, Codable {
        case primary
        case secondary
        case destructive
    }
}

// MARK: - Action Data

struct ActionData: Codable, Hashable {
    let id: UUID
    let title: String
    let message: String
    let riskLevel: RiskLevel
    let actions: [CardAction]
    let requiresApproval: Bool
    let deadline: Date?

    enum RiskLevel: String, Codable {
        case low
        case medium
        case high
    }
}

// MARK: - Progress Data

struct ProgressData: Codable, Hashable {
    let id: UUID
    let title: String
    let currentStep: Int
    let totalSteps: Int
    let steps: [ProgressStep]
    let estimatedCompletion: Date?
}

struct ProgressStep: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let status: StepStatus
    let icon: String?

    enum StepStatus: String, Codable {
        case completed
        case inProgress
        case pending
        case failed
    }
}

// MARK: - Update Data

struct UpdateData: Codable, Hashable {
    let id: UUID
    let title: String
    let message: String
    let icon: String
    let color: String // Hex color
    let timestamp: Date
    let category: UpdateCategory

    enum UpdateCategory: String, Codable {
        case success
        case info
        case warning
        case error
    }
}

// MARK: - Achievement Data

struct AchievementData: Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let color: String // Hex color
    let showConfetti: Bool
    let milestone: String?
}

// MARK: - Rich Media Data

struct RichMediaData: Codable, Hashable {
    let id: UUID
    let type: MediaType
    let title: String
    let description: String?
    let imageURL: String?
    let metadata: [String: String]

    enum MediaType: String, Codable {
        case image
        case recipe
        case providerProfile
        case location
        case product
    }
}

// MARK: - Message Metadata

struct MessageMetadata: Codable, Hashable {
    let confidence: Double?
    let sources: [String]?
    let reasoning: String?
    let canUndo: Bool
    let requiresHumanFallback: Bool
    let tags: [String]?
}

// MARK: - Quick Reply Suggestion

struct QuickReplySuggestion: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let icon: String?
    let action: String?

    init(text: String, icon: String? = nil, action: String? = nil) {
        self.id = UUID()
        self.text = text
        self.icon = icon
        self.action = action
    }
}

// MARK: - Enhanced Chat Message

struct EnhancedChatMessage: Identifiable, Hashable, Codable {
    let id: UUID
    let role: MessageRole
    let messageType: MessageType
    let content: String
    let timestamp: Date
    let metadata: MessageMetadata?
    let quickReplies: [QuickReplySuggestion]?
    let isEdited: Bool
    let editedAt: Date?

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }

    init(
        id: UUID = UUID(),
        role: MessageRole,
        messageType: MessageType = .text,
        content: String,
        timestamp: Date = Date(),
        metadata: MessageMetadata? = nil,
        quickReplies: [QuickReplySuggestion]? = nil,
        isEdited: Bool = false,
        editedAt: Date? = nil
    ) {
        self.id = id
        self.role = role
        self.messageType = messageType
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
        self.quickReplies = quickReplies
        self.isEdited = isEdited
        self.editedAt = editedAt
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
