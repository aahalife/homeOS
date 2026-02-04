import SwiftUI

/// Key updates with icons
struct UpdateMessageView: View {
    let data: UpdateData

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 40, height: 40)

                Image(systemName: data.icon)
                    .font(.body)
                    .foregroundStyle(Color(hex: data.color))
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(data.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(data.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: data.color).opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(categoryAccessibility): \(data.title). \(data.message)")
    }

    private var iconBackground: Color {
        Color(hex: data.color).opacity(0.15)
    }

    private var categoryAccessibility: String {
        switch data.category {
        case .success: return "Success"
        case .info: return "Information"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        UpdateMessageView(
            data: UpdateData(
                id: UUID(),
                title: "Appointment Confirmed",
                message: "Your dentist appointment is confirmed for Tuesday at 2 PM",
                icon: "checkmark.circle.fill",
                color: "4CAF50",
                timestamp: Date(),
                category: .success
            )
        )

        UpdateMessageView(
            data: UpdateData(
                id: UUID(),
                title: "Meal Plan Ready",
                message: "Your weekly meal plan has been created with 7 new recipes",
                icon: "fork.knife",
                color: "2196F3",
                timestamp: Date(),
                category: .info
            )
        )

        UpdateMessageView(
            data: UpdateData(
                id: UUID(),
                title: "Low on Milk",
                message: "You're running low on milk. Should I add it to your grocery list?",
                icon: "exclamationmark.triangle.fill",
                color: "FF9800",
                timestamp: Date(),
                category: .warning
            )
        )

        UpdateMessageView(
            data: UpdateData(
                id: UUID(),
                title: "Payment Failed",
                message: "Unable to process payment. Please check your payment method.",
                icon: "xmark.circle.fill",
                color: "F44336",
                timestamp: Date(),
                category: .error
            )
        )
    }
    .padding()
}
