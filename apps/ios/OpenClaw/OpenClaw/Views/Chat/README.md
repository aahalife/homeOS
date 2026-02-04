# OpenClaw Chat Interface

A comprehensive, production-quality chat interface with integrated task tracking, transparency dashboard, and approval flows.

## 📁 Directory Structure

```
Chat/
├── Models/
│   ├── MessageTypes.swift           # All message type definitions
│   ├── TaskModels.swift             # Task and approval models
│   └── TransparencyModels.swift     # Activity logs and privacy models
├── MessageComponents/
│   ├── TextMessageView.swift        # Text messages with markdown
│   ├── SkillCardView.swift          # Beautiful skill cards
│   ├── ActionMessageView.swift      # Action approval messages
│   ├── ProgressMessageView.swift    # Progress tracking
│   ├── UpdateMessageView.swift      # Key updates
│   ├── AchievementMessageView.swift # Celebration moments
│   └── RichMediaMessageView.swift   # Images, recipes, profiles
├── ApprovalFlow/
│   └── ApprovalFlowView.swift       # Complete approval system
├── Utils/
│   ├── DensityController.swift      # Information density manager
│   ├── HapticManager.swift          # Haptic feedback system
│   ├── AnimationHelpers.swift       # Reusable animations
│   └── AccessibilityHelpers.swift   # Accessibility utilities
├── EnhancedChatView.swift           # Main chat interface
├── TaskModeView.swift               # Swipeable task cards
├── TransparencyView.swift           # Transparency dashboard
└── README.md                        # This file
```

## 🎨 Features

### 1. Modern Chat Interface (`EnhancedChatView.swift`)

**Key Features:**
- Beautiful message bubbles (user vs assistant)
- Typing indicators with animation
- Rich message types support
- Quick reply suggestions
- Voice input button
- Search in chat history
- Pull-to-refresh
- Context menus for messages
- Information density controls

**Usage:**
```swift
EnhancedChatView()
```

**Customization:**
- Toggle density mode (Conversational, Detailed, Summary)
- Search messages
- Export chat
- Clear chat history

### 2. Message Types

#### TextMessage
Standard text with markdown support, metadata indicators, and quick replies.

```swift
TextMessageView(
    message: EnhancedChatMessage(
        role: .assistant,
        content: "Your message here",
        metadata: MessageMetadata(confidence: 0.95),
        quickReplies: [...]
    ),
    isUser: false
)
```

#### SkillCard
Beautiful cards for meal plans, appointments, recipes, etc.

```swift
SkillCardView(
    data: SkillCardData(
        type: .mealPlan,
        title: "Tonight's Dinner",
        subtitle: "Healthy & Balanced",
        icon: "fork.knife",
        color: "FF6B6B",
        data: ["Main": "Grilled Chicken", ...],
        actions: [...]
    )
)
```

#### ActionMessage
Buttons for approve, modify, cancel with risk levels.

```swift
ActionMessageView(
    data: ActionData(
        title: "Book Appointment",
        message: "Schedule with Dr. Smith?",
        riskLevel: .medium,
        actions: [...],
        requiresApproval: true
    )
)
```

#### ProgressMessage
Show workflow progress (Step 2 of 5).

```swift
ProgressMessageView(
    data: ProgressData(
        title: "Planning Your Meals",
        currentStep: 2,
        totalSteps: 5,
        steps: [...]
    )
)
```

#### UpdateMessage
Key updates with icons and categories.

```swift
UpdateMessageView(
    data: UpdateData(
        title: "Appointment Confirmed",
        message: "Your appointment is confirmed",
        icon: "checkmark.circle.fill",
        color: "4CAF50",
        category: .success
    )
)
```

#### AchievementMessage
Celebrate milestones with confetti!

```swift
AchievementMessageView(
    data: AchievementData(
        title: "Week Streak!",
        description: "7 days in a row!",
        icon: "flame.fill",
        color: "FF6B35",
        showConfetti: true,
        milestone: "7 Day Streak"
    )
)
```

#### RichMediaMessage
Images, recipes, provider profiles.

```swift
RichMediaMessageView(
    data: RichMediaData(
        type: .recipe,
        title: "Mediterranean Chicken",
        description: "A healthy chicken dish",
        imageURL: "...",
        metadata: [...]
    )
)
```

### 3. Task Mode (`TaskModeView.swift`)

**Features:**
- Swipeable task cards (like Tinder)
- Visual progress indicators
- Category filtering (Urgent, Today, This Week, Later)
- Priority badges
- Risk level indicators
- Batch approval
- Detailed task views

**Swipe Actions:**
- Swipe right → Approve
- Swipe left → Reject
- Tap info → View details

**Usage:**
```swift
TaskModeView()
```

### 4. Transparency Dashboard (`TransparencyView.swift`)

**Features:**
- Trust score visualization
- Daily summary statistics
- Key actions today
- Planned actions
- API calls with explanations
- Data usage tracking
- Activity log with filtering
- Privacy controls

**Sections:**
- **Trust Score**: Overall reliability metric
- **Daily Stats**: Actions, API calls, time saved
- **Key Actions**: What OpenClaw did today
- **Planned Actions**: What's coming up
- **API Calls**: External service calls with purposes
- **Data Usage**: What data accessed and why
- **Activity Log**: Detailed timeline with reasoning

**Usage:**
```swift
TransparencyView()
```

### 5. Approval Flow (`ApprovalFlow/ApprovalFlowView.swift`)

**Risk Levels:**
- **Low**: Routine actions, minimal impact
- **Medium**: Requires attention and review
- **High**: Significant actions, careful consideration needed

**Features:**
- Risk assessment visualization
- Detailed action breakdown
- Important details highlighting
- Optional notes
- Explanation of why approval needed
- Modification options
- Approval history with undo

**Usage:**
```swift
ApprovalFlowView(
    request: ApprovalRequest(...),
    onApprove: { result in },
    onReject: { result in }
)
```

### 6. Information Density Controller

**Density Levels:**
- **Conversational**: Concise, friendly (default)
- **Detailed**: Show all steps and reasoning
- **Summary**: Just final results

**Usage:**
```swift
let controller = DensityController.shared
controller.setGlobalDensity(.detailed)
controller.setDensity(.summary, forMessage: messageId)
```

**Inline Toggle:**
```swift
InlineDensityToggle(
    controller: controller,
    messageId: messageId
)
```

### 7. Haptic Feedback System

**Built-in Patterns:**
- `messageSent()` - Light impact
- `messageReceived()` - Soft impact
- `taskApproved()` - Success notification
- `taskRejected()` - Warning notification
- `swipeAction()` - Selection feedback
- `achievement()` - Custom celebration pattern

**Usage:**
```swift
HapticManager.shared.taskApproved()

// Or use view extensions
Button("Approve") {
    // action
}
.onTapWithHaptic {
    // action with automatic haptic
}
```

### 8. Animation System

**Pre-configured Animations:**
- `smoothSpring` - General purpose
- `bouncySpring` - Playful interactions
- `snappySpring` - Quick responses
- `messageAppear` - Message entrance
- `cardFlip` - Card transitions

**Custom Effects:**
```swift
// Shimmer
Text("Loading").shimmer()

// Pulsating
Circle().pulsating()

// Bounce on appear
View().bounceOnAppear()

// Slide in
View().slideIn(from: .bottom)

// Continuous rotation
Image(systemName: "arrow.clockwise").continuousRotation()
```

**Transitions:**
```swift
.transition(.messageSlide)
.transition(.cardSwipe)
.transition(.fadeScale)
```

### 9. Accessibility Support

**Voice Over:**
```swift
AccessibilityHelpers.announce("Task approved")
AccessibilityHelpers.announcePageChange("Switched to Task Mode")
```

**Smart Labels:**
```swift
let label = AccessibilityHelpers.messageLabel(from: message)
let taskLabel = AccessibilityHelpers.taskLabel(from: task)
```

**Components:**
```swift
// Accessible card
AccessibleCard(
    label: "Meal plan card",
    hint: "Double tap to view details"
) {
    // content
}

// Accessible progress
AccessibleProgressIndicator(
    progress: 7,
    total: 10,
    label: "Task completion"
)

// Accessible toggle
AccessibleToggle(
    isOn: $setting,
    label: "Enable Notifications",
    description: "Receive important updates"
)
```

**Support for:**
- Dynamic Type (text scaling)
- VoiceOver
- High Contrast
- Reduce Motion
- Focus management
- Custom accessibility actions

## 🎯 Design Principles

### 1. Trust Building
- Explain decisions with reasoning
- Show confidence indicators
- Provide sources
- Human fallback options
- Clear error messages

### 2. Transparency
- Visible action history
- API call logging
- Data usage explanations
- Privacy controls
- Audit trail

### 3. User Control
- Approval flows for risky actions
- Information density preferences
- Batch operations
- Undo capabilities
- Customizable quick replies

### 4. Delight
- Smooth animations
- Haptic feedback
- Achievement celebrations
- Personalized greetings
- Contextual suggestions

### 5. Accessibility
- Full VoiceOver support
- Dynamic Type
- Reduce Motion respect
- High Contrast adaptation
- Comprehensive labels

## 🚀 Integration

### Basic Setup

```swift
import SwiftUI

@main
struct OpenClawApp: App {
    var body: some Scene {
        WindowGroup {
            EnhancedChatView()
        }
    }
}
```

### With Navigation

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            EnhancedChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            TaskModeView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }

            TransparencyView()
                .tabItem {
                    Label("Activity", systemImage: "chart.bar")
                }
        }
    }
}
```

### Custom Message Handling

```swift
class CustomChatViewModel: EnhancedChatViewModel {
    override func sendMessage() async {
        guard !inputText.isEmpty else { return }

        // Add user message
        let userMessage = EnhancedChatMessage(
            role: .user,
            content: inputText
        )
        messages.append(userMessage)

        // Process with your backend
        isProcessing = true
        let response = await yourBackend.process(inputText)

        // Add assistant response
        let assistantMessage = EnhancedChatMessage(
            role: .assistant,
            messageType: determineMessageType(response),
            content: response.content,
            metadata: response.metadata,
            quickReplies: response.suggestedReplies
        )
        messages.append(assistantMessage)

        isProcessing = false
        inputText = ""
    }
}
```

## 📱 Platform Support

- **iOS**: 15.0+
- **iPadOS**: Optimized layouts
- **Dark Mode**: Full support
- **Accessibility**: VoiceOver, Dynamic Type, etc.

## 🎨 Customization

### Colors

```swift
// Extend Color for your brand
extension Color {
    static let brandPrimary = Color(hex: "YOUR_COLOR")
    static let brandSecondary = Color(hex: "YOUR_COLOR")
}
```

### Animations

```swift
// Override animation preferences
struct AnimationHelpers {
    static let customSpring = Animation.spring(
        response: 0.5,
        dampingFraction: 0.7
    )
}
```

### Message Styles

```swift
// Custom message bubble
struct CustomMessageBubble: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(yourCustomBackground)
            .clipShape(yourCustomShape)
    }
}
```

## 🔧 Configuration

### Privacy Settings

```swift
var privacySettings = PrivacySettings(
    allowDataCollection: true,
    allowAPILogging: true,
    allowActivityTracking: true,
    dataRetentionDays: 30,
    requireApprovalForSensitiveData: true,
    shareUsageStatistics: false
)
```

### Density Defaults

```swift
DensityController.shared.setGlobalDensity(.conversational)
```

### Haptic Preferences

```swift
// Disable haptics if needed
extension HapticManager {
    var isEnabled: Bool = true
}
```

## 📊 Performance

### Best Practices

1. **Lazy Loading**: Messages use `LazyVStack` for efficient rendering
2. **Image Caching**: Use AsyncImage with caching
3. **State Management**: Minimize @Published properties
4. **Animation**: Use `.animation()` modifier sparingly
5. **Memory**: Clear old messages periodically

### Optimization Tips

```swift
// Limit visible messages
let visibleMessages = messages.suffix(50)

// Pagination
func loadMoreMessages() async {
    // Load in batches
}

// Image optimization
AsyncImage(url: url) { image in
    image.resizable()
        .aspectRatio(contentMode: .fill)
} placeholder: {
    ProgressView()
}
```

## 🧪 Testing

### Unit Tests

```swift
func testMessageSending() async {
    let viewModel = EnhancedChatViewModel()
    viewModel.inputText = "Test message"
    await viewModel.sendMessage()
    XCTAssertTrue(viewModel.messages.count > 0)
}
```

### Accessibility Tests

```swift
func testVoiceOverLabels() {
    let message = EnhancedChatMessage(...)
    let label = AccessibilityHelpers.messageLabel(from: message)
    XCTAssertFalse(label.isEmpty)
}
```

## 🐛 Troubleshooting

### Common Issues

**Messages not appearing:**
- Check that messages are added to the published array
- Verify ScrollViewReader is scrolling to correct ID

**Animations not smooth:**
- Use `.animation()` modifier correctly
- Check for unnecessary state changes

**VoiceOver not working:**
- Ensure accessibility labels are set
- Test with VoiceOver enabled

**Haptics not triggering:**
- Check device support for haptics
- Verify HapticManager calls

## 📚 Additional Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Accessibility Guidelines](https://developer.apple.com/accessibility/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## 🎉 Credits

Built with love for the OpenClaw project. Designed to be delightful, trustworthy, and accessible.

---

**Version**: 1.0.0
**Last Updated**: February 2026
**Maintainer**: OpenClaw Team
