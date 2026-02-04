import SwiftUI

/// Swipeable task cards with approval flows
struct TaskModeView: View {
    @StateObject private var viewModel = TaskModeViewModel()
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Stats header
                    statsHeader

                    // Category tabs
                    categoryTabs

                    // Task cards or empty state
                    if viewModel.filteredTasks.isEmpty {
                        emptyState
                    } else {
                        taskCardsView
                    }

                    // Batch actions (if multiple tasks selected)
                    if viewModel.selectedTasks.count > 1 {
                        batchActionsBar
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $viewModel.selectedTaskForDetails) { task in
                TaskDetailSheet(task: task, viewModel: viewModel)
            }
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 20) {
            StatBox(
                title: "Pending",
                value: "\(viewModel.pendingCount)",
                icon: "clock.fill",
                color: .orange
            )

            StatBox(
                title: "Urgent",
                value: "\(viewModel.urgentCount)",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )

            StatBox(
                title: "Today",
                value: "\(viewModel.todayCount)",
                icon: "sun.max.fill",
                color: .blue
            )
        }
        .padding()
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(UserTask.TaskCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: viewModel.selectedCategory == category,
                        count: viewModel.count(for: category),
                        namespace: animation
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectCategory(category)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Task Cards View

    private var taskCardsView: some View {
        ZStack {
            ForEach(Array(viewModel.filteredTasks.enumerated().reversed()), id: \.element.id) { index, task in
                if index >= viewModel.currentIndex && index < viewModel.currentIndex + 3 {
                    TaskCard(
                        task: task,
                        isTop: index == viewModel.currentIndex,
                        offset: CGFloat(index - viewModel.currentIndex) * 10
                    ) { action in
                        handleTaskAction(task, action: action)
                    } onTap: {
                        viewModel.selectedTaskForDetails = task
                    }
                    .zIndex(Double(viewModel.filteredTasks.count - index))
                }
            }
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("All Caught Up!")
                .font(.title.bold())

            Text("No pending tasks in this category")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Batch Actions Bar

    private var batchActionsBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                Text("\(viewModel.selectedTasks.count) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: { viewModel.approveSelectedTasks() }) {
                    Label("Approve All", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .clipShape(Capsule())
                }

                Button(action: { viewModel.clearSelection() }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Actions

    private func handleTaskAction(_ task: UserTask, action: TaskAction) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            viewModel.performAction(task: task, action: action)
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let category: UserTask.TaskCategory
    let isSelected: Bool
    let count: Int
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)

                Text(category.rawValue)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(category.color)
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(category.color)
                        .matchedGeometryEffect(id: "category", in: namespace)
                } else {
                    Capsule()
                        .fill(Color(.systemGray6))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Card

struct TaskCard: View {
    let task: UserTask
    let isTop: Bool
    let offset: CGFloat
    let onAction: (TaskAction) -> Void
    let onTap: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 0) {
            // Card header
            cardHeader

            // Card content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Description
                    Text(task.description)
                        .font(.body)
                        .foregroundStyle(.primary)

                    // Action required
                    if let action = task.actionRequired {
                        actionRequiredSection(action)
                    }

                    // Metadata
                    if let metadata = task.metadata {
                        metadataSection(metadata)
                    }

                    // Due date
                    if let dueDate = task.dueDate {
                        dueDateSection(dueDate)
                    }
                }
                .padding()
            }

            // Action buttons
            actionButtons
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
        .scaleEffect(isTop ? (isPressed ? 0.98 : 1.0) : 0.95 - (offset * 0.02))
        .offset(y: offset * 5)
        .offset(x: dragOffset.width, y: dragOffset.height)
        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
        .gesture(
            isTop ? DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    handleDragEnd(value: value)
                }
            : nil
        )
        .onTapGesture {
            if isTop {
                onTap()
            }
        }
        .overlay {
            if abs(dragOffset.width) > 50 {
                SwipeIndicator(
                    direction: dragOffset.width > 0 ? .approve : .reject,
                    opacity: min(abs(dragOffset.width) / 150, 1.0)
                )
            }
        }
    }

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Priority badge
                PriorityBadge(priority: task.priority)

                Spacer()

                // Category
                CategoryBadge(category: task.category)
            }

            Text(task.title)
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
        .padding()
        .background(task.category.color.opacity(0.1))
    }

    @ViewBuilder
    private func actionRequiredSection(_ action: ActionRequired) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: riskIcon(action.riskLevel))
                    .foregroundStyle(riskColor(action.riskLevel))
                Text(action.type.rawValue.capitalized + " Required")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(riskColor(action.riskLevel))
            }

            Text(action.details)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let impact = action.estimatedImpact {
                Label(impact, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(riskColor(action.riskLevel).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func metadataSection(_ metadata: TaskMetadata) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let duration = metadata.estimatedDuration {
                Label(formatDuration(duration), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let tags = metadata.tags {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func dueDateSection(_ date: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundStyle(isOverdue(date) ? .red : .orange)
            Text("Due: \(date.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(isOverdue(date) ? .red : .primary)
        }
        .padding()
        .background(isOverdue(date) ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Reject button
            Button(action: { onAction(.reject) }) {
                Image(systemName: "xmark")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Info button
            Button(action: onTap) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Approve button
            Button(action: { onAction(.approve) }) {
                Image(systemName: "checkmark")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
    }

    private func handleDragEnd(value: DragGesture.Value) {
        let threshold: CGFloat = 150

        if value.translation.width > threshold {
            // Swiped right - approve
            withAnimation {
                dragOffset = CGSize(width: 500, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onAction(.approve)
                dragOffset = .zero
            }
        } else if value.translation.width < -threshold {
            // Swiped left - reject
            withAnimation {
                dragOffset = CGSize(width: -500, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onAction(.reject)
                dragOffset = .zero
            }
        } else {
            // Snap back
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
        }
    }

    private func riskIcon(_ level: ActionRequired.RiskLevel) -> String {
        switch level {
        case .low: return "checkmark.shield"
        case .medium: return "exclamationmark.shield"
        case .high: return "xmark.shield"
        }
    }

    private func riskColor(_ level: ActionRequired.RiskLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func isOverdue(_ date: Date) -> Bool {
        date < Date()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            return "\(hours) hr"
        }
    }
}

// MARK: - Supporting Views

struct PriorityBadge: View {
    let priority: UserTask.TaskPriority

    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct CategoryBadge: View {
    let category: UserTask.TaskCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            Text(category.rawValue)
                .font(.caption)
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct SwipeIndicator: View {
    enum Direction {
        case approve, reject
    }

    let direction: Direction
    let opacity: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(opacity * 0.3))

            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                Text(text)
                    .font(.title2.bold())
            }
            .foregroundStyle(color)
            .opacity(opacity)
        }
    }

    private var color: Color {
        direction == .approve ? .green : .red
    }

    private var icon: String {
        direction == .approve ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private var text: String {
        direction == .approve ? "Approve" : "Reject"
    }
}

// MARK: - Task Detail Sheet

struct TaskDetailSheet: View {
    let task: UserTask
    @ObservedObject var viewModel: TaskModeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Similar to card content but with more details
                    Text("Full task details would go here")
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle(task.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - View Model

enum TaskAction {
    case approve
    case reject
    case modify
}

class TaskModeViewModel: ObservableObject {
    @Published var tasks: [UserTask] = []
    @Published var selectedCategory: UserTask.TaskCategory = .urgent
    @Published var filteredTasks: [UserTask] = []
    @Published var currentIndex = 0
    @Published var selectedTasks: Set<UUID> = []
    @Published var selectedTaskForDetails: UserTask?

    var pendingCount: Int { tasks.filter { $0.status == .pending }.count }
    var urgentCount: Int { tasks.filter { $0.category == .urgent }.count }
    var todayCount: Int { tasks.filter { $0.category == .today }.count }

    init() {
        // Load mock tasks for preview
        loadTasks()
    }

    func loadTasks() {
        // Load from storage or API
        filterTasks()
    }

    func selectCategory(_ category: UserTask.TaskCategory) {
        selectedCategory = category
        currentIndex = 0
        filterTasks()
    }

    func filterTasks() {
        filteredTasks = tasks.filter { $0.category == selectedCategory && $0.status == .pending }
    }

    func count(for category: UserTask.TaskCategory) -> Int {
        tasks.filter { $0.category == category && $0.status == .pending }.count
    }

    func performAction(task: UserTask, action: TaskAction) {
        // Handle action
        if currentIndex < filteredTasks.count - 1 {
            currentIndex += 1
        } else {
            // Move to next category or show completion
        }
    }

    func approveSelectedTasks() {
        // Batch approve
    }

    func clearSelection() {
        selectedTasks.removeAll()
    }
}

#Preview {
    TaskModeView()
}
