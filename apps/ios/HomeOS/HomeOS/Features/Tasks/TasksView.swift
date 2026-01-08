import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @State private var selectedFilter: TaskFilter = .all

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case approval = "Needs Approval"
        case done = "Done"
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Filter tabs
                filterTabs

                // Task list
                taskList
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Tasks")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            // Pending approvals badge
            if viewModel.pendingApprovalCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("\(viewModel.pendingApprovalCount) pending")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.orange.opacity(0.2))
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? .white.opacity(0.2) : .clear)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredTasks(for: selectedFilter)) { task in
                    TaskCard(
                        task: task,
                        onApprove: {
                            Task { await viewModel.approveTask(task) }
                        },
                        onDeny: {
                            Task { await viewModel.denyTask(task) }
                        }
                    )
                }

                if viewModel.filteredTasks(for: selectedFilter).isEmpty {
                    emptyState
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadTasks()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text("No tasks")
                .font(.title3)
                .foregroundColor(.white.opacity(0.6))

            Text("Your tasks will appear here")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var error: String?

    var pendingApprovalCount: Int {
        tasks.filter { $0.status == .needsApproval }.count
    }

    init() {
        // Start with sample tasks, then fetch real data
        loadSampleTasks()
    }

    private func loadSampleTasks() {
        tasks = [
            TaskItem(
                id: "1",
                title: "Book restaurant",
                summary: "Calling Osteria Mozza for Friday reservation",
                category: .telephony,
                status: .needsApproval,
                riskLevel: .high,
                requiresApproval: true,
                details: "Ready to call Osteria Mozza to book a table for 4 at 7pm on Friday. The call will disclose your first name only.",
                createdAt: Date()
            ),
            TaskItem(
                id: "2",
                title: "Sell stroller",
                summary: "Posted on Facebook Marketplace for $150",
                category: .marketplace,
                status: .running,
                riskLevel: .medium,
                requiresApproval: false,
                details: nil,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            TaskItem(
                id: "3",
                title: "Recipe ingredients",
                summary: "Added baked feta pasta ingredients to cart",
                category: .groceries,
                status: .done,
                riskLevel: .low,
                requiresApproval: false,
                details: nil,
                createdAt: Date().addingTimeInterval(-7200)
            )
        ]
    }

    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }

        guard let token = AuthManager.shared.token,
              let workspaceId = AuthManager.shared.workspaceId,
              let url = URL(string: "\(Configuration.runtimeURL)/v1/tasks?workspaceId=\(workspaceId)") else {
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                // If API fails, keep sample data
                return
            }

            // Parse and update tasks if API returns data
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tasksArray = json["tasks"] as? [[String: Any]] {
                // Parse tasks from API response
                // For now, keep sample data if parsing fails
                if tasksArray.isEmpty {
                    loadSampleTasks()
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func filteredTasks(for filter: TasksView.TaskFilter) -> [TaskItem] {
        switch filter {
        case .all:
            return tasks
        case .pending:
            return tasks.filter { $0.status == .running || $0.status == .queued }
        case .approval:
            return tasks.filter { $0.status == .needsApproval }
        case .done:
            return tasks.filter { $0.status == .done }
        }
    }

    func approveTask(_ task: TaskItem) async {
        guard let token = AuthManager.shared.token,
              let workspaceId = AuthManager.shared.workspaceId,
              let url = URL(string: "\(Configuration.runtimeURL)/v1/tasks/\(task.id)/approve?workspaceId=\(workspaceId)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                // Update local state
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index] = TaskItem(
                        id: task.id,
                        title: task.title,
                        summary: task.summary,
                        category: task.category,
                        status: .running,
                        riskLevel: task.riskLevel,
                        requiresApproval: task.requiresApproval,
                        details: task.details,
                        createdAt: task.createdAt
                    )
                }
            }
        } catch {
            self.error = error.localizedDescription
        }

        // Also update local state optimistically
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = TaskItem(
                id: task.id,
                title: task.title,
                summary: task.summary,
                category: task.category,
                status: .running,
                riskLevel: task.riskLevel,
                requiresApproval: task.requiresApproval,
                details: task.details,
                createdAt: task.createdAt
            )
        }
    }

    func denyTask(_ task: TaskItem) async {
        guard let token = AuthManager.shared.token,
              let workspaceId = AuthManager.shared.workspaceId,
              let url = URL(string: "\(Configuration.runtimeURL)/v1/tasks/\(task.id)/deny?workspaceId=\(workspaceId)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            self.error = error.localizedDescription
        }

        // Update local state
        tasks.removeAll { $0.id == task.id }
    }
}

#Preview {
    TasksView()
}
