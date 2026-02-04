import SwiftUI

/// Text message with markdown support and rich formatting
struct TextMessageView: View {
    let message: EnhancedChatMessage
    let isUser: Bool

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
            // Main message bubble
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(.init(message.content))
                    .font(.body)
                    .foregroundStyle(isUser ? .white : .primary)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                // Metadata indicators
                if let metadata = message.metadata {
                    metadataView(metadata)
                }
            }

            // Quick replies
            if let quickReplies = message.quickReplies, !quickReplies.isEmpty {
                QuickRepliesView(suggestions: quickReplies)
            }

            // Timestamp and status
            HStack(spacing: 4) {
                if isUser {
                    Spacer()
                }

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if message.isEdited {
                    Text("• Edited")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !isUser {
                    Spacer()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var bubbleBackground: some View {
        Group {
            if isUser {
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(.systemGray6)
            }
        }
    }

    @ViewBuilder
    private func metadataView(_ metadata: MessageMetadata) -> some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            // Confidence indicator
            if let confidence = metadata.confidence {
                ConfidenceIndicator(confidence: confidence)
            }

            // Sources
            if let sources = metadata.sources, !sources.isEmpty {
                SourcesView(sources: sources)
            }

            // Human fallback indicator
            if metadata.requiresHumanFallback {
                HumanFallbackBadge()
            }

            // Undo option
            if metadata.canUndo {
                Button(action: { /* Handle undo */ }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
    }

    private var accessibilityLabel: String {
        var label = "\(isUser ? "You" : "OpenClaw") said: \(message.content)"
        if let metadata = message.metadata {
            if let confidence = metadata.confidence {
                label += ". Confidence: \(Int(confidence * 100))%"
            }
            if metadata.requiresHumanFallback {
                label += ". May require human verification"
            }
        }
        return label
    }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicator: View {
    let confidence: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
                .font(.caption2)
                .foregroundStyle(confidenceColor)

            Text("\(Int(confidence * 100))% confident")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var confidenceIcon: String {
        if confidence >= 0.9 {
            return "checkmark.circle.fill"
        } else if confidence >= 0.7 {
            return "questionmark.circle"
        } else {
            return "exclamationmark.triangle"
        }
    }

    private var confidenceColor: Color {
        if confidence >= 0.9 {
            return .green
        } else if confidence >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Sources View

struct SourcesView: View {
    let sources: [String]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                    Text("Sources (\(sources.count))")
                        .font(.caption2)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(sources, id: \.self) { source in
                        Text("• \(source)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Human Fallback Badge

struct HumanFallbackBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.caption2)
            Text("Consider verifying with a professional")
                .font(.caption2)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Quick Replies View

struct QuickRepliesView: View {
    let suggestions: [QuickReplySuggestion]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions) { suggestion in
                    Button(action: { /* Handle quick reply */ }) {
                        HStack(spacing: 4) {
                            if let icon = suggestion.icon {
                                Image(systemName: icon)
                                    .font(.caption)
                            }
                            Text(suggestion.text)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // User message
        TextMessageView(
            message: EnhancedChatMessage(
                role: .user,
                content: "What's for dinner tonight?"
            ),
            isUser: true
        )

        // Assistant message with metadata
        TextMessageView(
            message: EnhancedChatMessage(
                role: .assistant,
                content: "I suggest **grilled chicken** with roasted vegetables. You haven't had chicken this week, and it's a good source of protein.",
                metadata: MessageMetadata(
                    confidence: 0.95,
                    sources: ["Your meal history", "Nutritional database"],
                    reasoning: "Balanced nutrition, variety in diet",
                    canUndo: false,
                    requiresHumanFallback: false,
                    tags: ["meal", "health"]
                ),
                quickReplies: [
                    QuickReplySuggestion(text: "Sounds good!", icon: "hand.thumbsup"),
                    QuickReplySuggestion(text: "Show recipe", icon: "book"),
                    QuickReplySuggestion(text: "Something else", icon: "arrow.triangle.2.circlepath")
                ]
            ),
            isUser: false
        )
    }
    .padding()
}
