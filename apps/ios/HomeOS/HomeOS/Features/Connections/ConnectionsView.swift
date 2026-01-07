import SwiftUI
import AuthenticationServices

struct ConnectionsView: View {
    @StateObject private var viewModel = ConnectionsViewModel()
    @State private var selectedCategory: IntegrationCategory = .productivity
    @State private var showingOAuthSheet = false
    @State private var pendingOAuthIntegration: Integration?

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
                HStack {
                    Text("Connections")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 24) {
                        // AI Providers (BYOK)
                        aiProvidersSection

                        // Integration categories
                        categoryPicker

                        // Integrations for selected category
                        integrationsSection
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingOAuthSheet) {
            if let integration = pendingOAuthIntegration {
                OAuthWebView(
                    integration: integration,
                    onComplete: { success in
                        showingOAuthSheet = false
                        if success {
                            Task { await viewModel.refreshIntegrations() }
                        }
                        pendingOAuthIntegration = nil
                    }
                )
            }
        }
        .task {
            await viewModel.loadIntegrations()
        }
    }

    private var aiProvidersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Providers")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Text("Bring your own API keys")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            VStack(spacing: 12) {
                APIKeyCard(
                    provider: .openai,
                    isConfigured: viewModel.openAIConfigured,
                    lastTested: viewModel.openAILastTested,
                    testSuccessful: viewModel.openAITestSuccessful,
                    onSave: { key in
                        Task { await viewModel.saveAPIKey(.openai, key: key) }
                    },
                    onTest: {
                        Task { await viewModel.testConnection(.openai) }
                    }
                )

                APIKeyCard(
                    provider: .anthropic,
                    isConfigured: viewModel.anthropicConfigured,
                    lastTested: viewModel.anthropicLastTested,
                    testSuccessful: viewModel.anthropicTestSuccessful,
                    onSave: { key in
                        Task { await viewModel.saveAPIKey(.anthropic, key: key) }
                    },
                    onTest: {
                        Task { await viewModel.testConnection(.anthropic) }
                    }
                )
            }
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Text("Connect your accounts to enable smart automation")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(IntegrationCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedCategory == category,
                            connectedCount: viewModel.connectedCount(for: category)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
    }

    private var integrationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let integrations = viewModel.integrations(for: selectedCategory)

            ForEach(integrations, id: \.id) { integration in
                IntegrationCard(
                    integration: integration,
                    onConnect: {
                        pendingOAuthIntegration = integration
                        showingOAuthSheet = true
                    },
                    onDisconnect: {
                        Task { await viewModel.disconnect(integration) }
                    }
                )
            }

            if integrations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "app.connected.to.app.below.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.3))
                    Text("No integrations available")
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

enum AIProvider: String, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"

    var icon: String {
        switch self {
        case .openai: return "brain"
        case .anthropic: return "sparkles"
        }
    }

    var placeholder: String {
        switch self {
        case .openai: return "sk-..."
        case .anthropic: return "sk-ant-..."
        }
    }
}

struct APIKeyCard: View {
    let provider: AIProvider
    let isConfigured: Bool
    let lastTested: Date?
    let testSuccessful: Bool?
    let onSave: (String) -> Void
    let onTest: () -> Void

    @State private var isEditing = false
    @State private var keyInput = ""
    @State private var isTesting = false

    var body: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: provider.icon)
                        .font(.title2)
                        .foregroundColor(.white)

                    Text(provider.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    if isConfigured {
                        StatusPill(
                            status: testSuccessful == true ? "Connected" : "Configured",
                            color: testSuccessful == true ? .green : .yellow
                        )
                    }
                }

                if isEditing {
                    SecureField(provider.placeholder, text: $keyInput)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.1))
                        )

                    HStack {
                        Button("Cancel") {
                            isEditing = false
                            keyInput = ""
                        }
                        .foregroundColor(.white.opacity(0.6))

                        Spacer()

                        LiquidButton(title: "Save", icon: nil) {
                            onSave(keyInput)
                            isEditing = false
                            keyInput = ""
                        }
                    }
                } else {
                    HStack {
                        if isConfigured {
                            Button {
                                isTesting = true
                                onTest()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isTesting = false
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    if isTesting {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    }
                                    Text("Test")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            }
                            .disabled(isTesting)
                        }

                        Spacer()

                        Button {
                            isEditing = true
                        } label: {
                            Text(isConfigured ? "Update Key" : "Add Key")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Integration Models

enum IntegrationCategory: String, CaseIterable {
    case productivity = "Productivity"
    case health = "Health"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case transportation = "Transportation"
    case smartHome = "Smart Home"

    var icon: String {
        switch self {
        case .productivity: return "calendar"
        case .health: return "heart.fill"
        case .entertainment: return "music.note"
        case .shopping: return "cart.fill"
        case .transportation: return "car.fill"
        case .smartHome: return "house.fill"
        }
    }
}

struct Integration: Identifiable {
    let id: String
    let name: String
    let icon: String
    let category: IntegrationCategory
    var isConnected: Bool
    var connectedAt: Date?
    let description: String
}

// MARK: - Category Pill

struct CategoryPill: View {
    let category: IntegrationCategory
    let isSelected: Bool
    let connectedCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if connectedCount > 0 {
                    Text("\(connectedCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .black : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .black.opacity(0.2) : .green)
                        )
                }
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? .white : .white.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Integration Card

struct IntegrationCard: View {
    let integration: Integration
    let onConnect: () -> Void
    let onDisconnect: () -> Void

    @State private var isLoading = false

    var body: some View {
        GlassCard(cornerRadius: 16) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: integration.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white.opacity(0.1))
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(integration.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(integration.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                // Action button
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if integration.isConnected {
                    Menu {
                        Button(role: .destructive) {
                            isLoading = true
                            onDisconnect()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isLoading = false
                            }
                        } label: {
                            Label("Disconnect", systemImage: "xmark.circle")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Connected")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.green.opacity(0.2))
                        )
                    }
                } else {
                    Button {
                        onConnect()
                    } label: {
                        Text("Connect")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - OAuth WebView

struct OAuthWebView: View {
    let integration: Integration
    let onComplete: (Bool) -> Void

    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Integration icon
                    Image(systemName: integration.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    Text("Connect \(integration.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("You'll be redirected to \(integration.name) to authorize access.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer()

                    // Permissions info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HomeOS will be able to:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        ForEach(permissionsForIntegration(), id: \.self) { permission in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(permission)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding()
                    .background(GlassSurface(cornerRadius: 16))
                    .padding(.horizontal)

                    Spacer()

                    // Continue button
                    Button {
                        startOAuthFlow()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isLoading ? "Connecting..." : "Continue to \(integration.name)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete(false)
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func permissionsForIntegration() -> [String] {
        switch integration.category {
        case .productivity:
            return ["Read your calendar events", "Create and update events", "Send notifications"]
        case .health:
            return ["Read activity data", "Access sleep information", "View health metrics"]
        case .entertainment:
            return ["Control playback", "View listening history", "Create playlists"]
        case .shopping:
            return ["View your orders", "Add items to cart", "Access saved lists"]
        case .transportation:
            return ["Request rides", "View ride history", "Track current location"]
        case .smartHome:
            return ["Control devices", "View device status", "Create automations"]
        }
    }

    private func startOAuthFlow() {
        isLoading = true

        // Simulate OAuth flow - in production, this would:
        // 1. Call backend to get OAuth URL from Composio
        // 2. Open ASWebAuthenticationSession
        // 3. Handle callback and exchange code for tokens

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            onComplete(true)
        }
    }
}

// MARK: - View Model

@MainActor
class ConnectionsViewModel: ObservableObject {
    @Published var openAIConfigured = false
    @Published var openAILastTested: Date?
    @Published var openAITestSuccessful: Bool?

    @Published var anthropicConfigured = true
    @Published var anthropicLastTested = Date()
    @Published var anthropicTestSuccessful: Bool? = true

    @Published var isLoading = false
    @Published private var allIntegrations: [Integration] = []

    // All available integrations
    private let availableIntegrations: [Integration] = [
        // Productivity
        Integration(id: "google_calendar", name: "Google Calendar", icon: "calendar", category: .productivity, isConnected: false, description: "Sync family schedules"),
        Integration(id: "gmail", name: "Gmail", icon: "envelope.fill", category: .productivity, isConnected: false, description: "Email notifications"),
        Integration(id: "notion", name: "Notion", icon: "doc.text.fill", category: .productivity, isConnected: false, description: "Notes and tasks"),
        Integration(id: "todoist", name: "Todoist", icon: "checkmark.circle.fill", category: .productivity, isConnected: false, description: "Task management"),

        // Health
        Integration(id: "apple_health", name: "Apple Health", icon: "heart.fill", category: .health, isConnected: false, description: "Activity and wellness"),
        Integration(id: "fitbit", name: "Fitbit", icon: "figure.walk", category: .health, isConnected: false, description: "Fitness tracking"),
        Integration(id: "oura", name: "Oura Ring", icon: "circle.circle", category: .health, isConnected: false, description: "Sleep and recovery"),

        // Entertainment
        Integration(id: "spotify", name: "Spotify", icon: "music.note", category: .entertainment, isConnected: false, description: "Music and podcasts"),
        Integration(id: "youtube", name: "YouTube", icon: "play.rectangle.fill", category: .entertainment, isConnected: false, description: "Videos and content"),

        // Shopping
        Integration(id: "instacart", name: "Instacart", icon: "cart.fill", category: .shopping, isConnected: false, description: "Grocery delivery"),
        Integration(id: "amazon", name: "Amazon", icon: "shippingbox.fill", category: .shopping, isConnected: false, description: "Shopping and orders"),

        // Transportation
        Integration(id: "uber", name: "Uber", icon: "car.fill", category: .transportation, isConnected: false, description: "Ride booking"),
        Integration(id: "lyft", name: "Lyft", icon: "car.side.fill", category: .transportation, isConnected: false, description: "Ride booking"),
        Integration(id: "google_maps", name: "Google Maps", icon: "map.fill", category: .transportation, isConnected: false, description: "Navigation and traffic"),

        // Smart Home
        Integration(id: "smartthings", name: "SmartThings", icon: "house.fill", category: .smartHome, isConnected: false, description: "Home automation"),
        Integration(id: "philips_hue", name: "Philips Hue", icon: "lightbulb.fill", category: .smartHome, isConnected: false, description: "Smart lighting"),
        Integration(id: "ecobee", name: "Ecobee", icon: "thermometer.medium", category: .smartHome, isConnected: false, description: "Smart thermostat"),
    ]

    func loadIntegrations() async {
        isLoading = true
        // In production, fetch connected status from backend
        allIntegrations = availableIntegrations
        isLoading = false
    }

    func refreshIntegrations() async {
        await loadIntegrations()
    }

    func integrations(for category: IntegrationCategory) -> [Integration] {
        allIntegrations.filter { $0.category == category }
    }

    func connectedCount(for category: IntegrationCategory) -> Int {
        allIntegrations.filter { $0.category == category && $0.isConnected }.count
    }

    func disconnect(_ integration: Integration) async {
        if let index = allIntegrations.firstIndex(where: { $0.id == integration.id }) {
            allIntegrations[index].isConnected = false
            allIntegrations[index].connectedAt = nil
        }
    }

    func saveAPIKey(_ provider: AIProvider, key: String) async {
        switch provider {
        case .openai:
            openAIConfigured = true
        case .anthropic:
            anthropicConfigured = true
        }
    }

    func testConnection(_ provider: AIProvider) async {
        switch provider {
        case .openai:
            openAILastTested = Date()
            openAITestSuccessful = true
        case .anthropic:
            anthropicLastTested = Date()
            anthropicTestSuccessful = true
        }
    }
}

#Preview {
    ConnectionsView()
}
