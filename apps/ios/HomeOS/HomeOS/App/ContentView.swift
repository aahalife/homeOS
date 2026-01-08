import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: Tab = .chat
    @State private var showSetupFlow = false
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    enum Tab: String, CaseIterable {
        case chat = "Chat"
        case tasks = "Tasks"
        case actions = "Actions"
        case connections = "Connections"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .chat: return "bubble.left.and.bubble.right"
            case .tasks: return "checklist"
            case .actions: return "bolt"
            case .connections: return "link"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if !onboardingCompleted && showSetupFlow {
                    SetupFlowView {
                        onboardingCompleted = true
                        showSetupFlow = false
                    }
                } else {
                    mainContent
                }
            } else {
                OnboardingView()
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated && !onboardingCompleted {
                showSetupFlow = true
            }
        }
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label(Tab.chat.rawValue, systemImage: Tab.chat.icon)
                }
                .tag(Tab.chat)

            TasksView()
                .tabItem {
                    Label(Tab.tasks.rawValue, systemImage: Tab.tasks.icon)
                }
                .tag(Tab.tasks)

            ActionsView()
                .tabItem {
                    Label(Tab.actions.rawValue, systemImage: Tab.actions.icon)
                }
                .tag(Tab.actions)

            ConnectionsView()
                .tabItem {
                    Label(Tab.connections.rawValue, systemImage: Tab.connections.icon)
                }
                .tag(Tab.connections)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(.white)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(NetworkManager())
}
