import SwiftUI

/// Beautiful cards for meal plans, appointments, recipes, etc.
struct SkillCardView: View {
    let data: SkillCardData
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            cardHeader

            // Content
            cardContent
                .padding()

            // Actions
            if !data.actions.isEmpty {
                cardActions
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: data.color).opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var cardHeader: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: data.color).opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: data.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: data.color))
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle = data.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Expand/collapse button
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(hex: data.color).opacity(0.05))
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(data.data.keys.sorted()), id: \.self) { key in
                if let value = data.data[key] {
                    if isExpanded || data.data.count <= 3 {
                        DataRow(key: key, value: value, color: Color(hex: data.color))
                    }
                }
            }

            if !isExpanded && data.data.count > 3 {
                Text("Tap to see \(data.data.count - 3) more details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private var cardActions: some View {
        HStack(spacing: 8) {
            ForEach(data.actions) { action in
                ActionButton(action: action, accentColor: Color(hex: data.color))
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
    }

    private var accessibilityLabel: String {
        var label = "\(data.type.rawValue) card: \(data.title)"
        if let subtitle = data.subtitle {
            label += ", \(subtitle)"
        }
        label += ". \(data.data.count) details available"
        return label
    }
}

// MARK: - Data Row

struct DataRow: View {
    let key: String
    let value: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconForKey(key))
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(key.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
    }

    private func iconForKey(_ key: String) -> String {
        let lowercased = key.lowercased()
        if lowercased.contains("time") || lowercased.contains("when") {
            return "clock"
        } else if lowercased.contains("date") {
            return "calendar"
        } else if lowercased.contains("location") || lowercased.contains("where") {
            return "mappin"
        } else if lowercased.contains("person") || lowercased.contains("who") {
            return "person"
        } else if lowercased.contains("calories") || lowercased.contains("nutrition") {
            return "flame"
        } else if lowercased.contains("ingredients") {
            return "list.bullet"
        } else if lowercased.contains("price") || lowercased.contains("cost") {
            return "dollarsign.circle"
        } else {
            return "info.circle"
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let action: CardAction
    let accentColor: Color
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            // Handle action
        }) {
            Text(action.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(action.title) button")
    }

    private var backgroundColor: Color {
        switch action.style {
        case .primary:
            return accentColor
        case .secondary:
            return accentColor.opacity(0.15)
        case .destructive:
            return Color.red.opacity(0.15)
        }
    }

    private var textColor: Color {
        switch action.style {
        case .primary:
            return .white
        case .secondary:
            return accentColor
        case .destructive:
            return .red
        }
    }
}

// MARK: - Specific Card Types

struct MealPlanCardView: View {
    let data: SkillCardData

    var body: some View {
        SkillCardView(data: data)
    }
}

struct AppointmentCardView: View {
    let data: SkillCardData

    var body: some View {
        SkillCardView(data: data)
    }
}

struct RecipeCardView: View {
    let data: SkillCardData

    var body: some View {
        SkillCardView(data: data)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Meal Plan Card
            SkillCardView(
                data: SkillCardData(
                    id: UUID(),
                    type: .mealPlan,
                    title: "Tonight's Dinner",
                    subtitle: "Healthy & Balanced",
                    icon: "fork.knife",
                    color: "FF6B6B",
                    data: [
                        "Main": "Grilled Chicken Breast",
                        "Side": "Roasted Vegetables",
                        "Calories": "450 kcal",
                        "Protein": "35g",
                        "Prep Time": "30 minutes",
                        "Difficulty": "Easy"
                    ],
                    actions: [
                        CardAction(
                            id: UUID(),
                            title: "Cook Now",
                            type: .approve,
                            style: .primary
                        ),
                        CardAction(
                            id: UUID(),
                            title: "View Recipe",
                            type: .viewDetails,
                            style: .secondary
                        )
                    ]
                )
            )

            // Appointment Card
            SkillCardView(
                data: SkillCardData(
                    id: UUID(),
                    type: .appointment,
                    title: "Doctor Appointment",
                    subtitle: "Annual Checkup",
                    icon: "stethoscope",
                    color: "4ECDC4",
                    data: [
                        "Doctor": "Dr. Sarah Johnson",
                        "Date": "March 15, 2026",
                        "Time": "2:30 PM",
                        "Location": "Main Street Clinic",
                        "Duration": "30 minutes",
                        "Type": "Annual Physical"
                    ],
                    actions: [
                        CardAction(
                            id: UUID(),
                            title: "Confirm",
                            type: .approve,
                            style: .primary
                        ),
                        CardAction(
                            id: UUID(),
                            title: "Reschedule",
                            type: .modify,
                            style: .secondary
                        ),
                        CardAction(
                            id: UUID(),
                            title: "Cancel",
                            type: .cancel,
                            style: .destructive
                        )
                    ]
                )
            )

            // Recipe Card
            SkillCardView(
                data: SkillCardData(
                    id: UUID(),
                    type: .recipe,
                    title: "Chocolate Chip Cookies",
                    subtitle: "Classic Recipe",
                    icon: "birthday.cake",
                    color: "FFD93D",
                    data: [
                        "Servings": "24 cookies",
                        "Prep Time": "15 minutes",
                        "Cook Time": "12 minutes",
                        "Difficulty": "Easy",
                        "Calories": "150 per cookie"
                    ],
                    actions: [
                        CardAction(
                            id: UUID(),
                            title: "Start Baking",
                            type: .approve,
                            style: .primary
                        ),
                        CardAction(
                            id: UUID(),
                            title: "Add to Meal Plan",
                            type: .custom,
                            style: .secondary
                        )
                    ]
                )
            )
        }
        .padding()
    }
}
