import SwiftUI

/// Main tab navigation after onboarding
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .chat

    enum Tab: String {
        case chat = "Chat"
        case skills = "Skills"
        case calendar = "Calendar"
        case settings = "Settings"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView(viewModel: ChatViewModel(appState: appState))
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
                .tag(Tab.chat)

            SkillsDashboardView()
                .tabItem {
                    Label("Skills", systemImage: "square.grid.2x2")
                }
                .tag(Tab.skills)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
