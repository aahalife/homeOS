//
//  RubeSettingsView.swift
//  OsaurusCore
//
//  Settings view for Rube (Composio) MCP integration.
//  Includes Dev Mode activation (⌥⌘D or 7 clicks on version).
//

import SwiftUI

// MARK: - Rube Settings View

struct RubeSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var rubeService = RubeService.shared

    private var theme: ThemeProtocol { themeManager.currentTheme }

    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var isTestingConnection: Bool = false
    @State private var testResult: RubeConnectionStatus?
    @State private var showSaveConfirmation: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            headerSection

            Divider()
                .background(theme.primaryBorder)

            // Connection Status
            statusSection

            // API Key Entry (always visible in this view)
            apiKeySection

            // Discovered Tools
            if rubeService.connectionStatus.isConnected {
                toolsSection
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.primaryBackground)
        .onAppear {
            // Load existing API key (masked)
            if RubeConfigurationStore.hasAPIKey() {
                apiKey = "••••••••••••••••"
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Rube Integration")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.primaryText)

                    Text("Connect to 500+ tools via Composio MCP")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                // Enable toggle
                Toggle("", isOn: Binding(
                    get: { rubeService.configuration.enabled },
                    set: { rubeService.setEnabled($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(!RubeConfigurationStore.hasAPIKey())
            }
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(rubeService.connectionStatus.statusDescription)
                .font(.system(size: 13))
                .foregroundColor(theme.primaryText)

            Spacer()

            // Connect/Disconnect button
            if rubeService.configuration.enabled {
                if rubeService.isConnecting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if rubeService.connectionStatus.isConnected {
                    Button("Disconnect") {
                        Task {
                            await rubeService.disconnect()
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                } else {
                    Button("Connect") {
                        Task {
                            await rubeService.connect()
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.accentColor)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
        )
    }

    private var statusColor: Color {
        if rubeService.isConnecting {
            return .orange
        } else if rubeService.connectionStatus.isConnected {
            return .green
        } else if rubeService.connectionStatus.lastError != nil {
            return .red
        } else {
            return .gray
        }
    }

    // MARK: - API Key Section

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPOSIO API KEY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.secondaryText)
                .tracking(0.5)

            HStack(spacing: 12) {
                // API Key field
                Group {
                    if showAPIKey {
                        TextField("Enter your Composio API key", text: $apiKey)
                    } else {
                        SecureField("Enter your Composio API key", text: $apiKey)
                    }
                }
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 13, design: .monospaced))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.secondaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.primaryBorder, lineWidth: 1)
                        )
                )

                // Show/Hide toggle
                Button {
                    showAPIKey.toggle()
                } label: {
                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }

            HStack(spacing: 12) {
                // Save button
                Button {
                    saveAPIKey()
                } label: {
                    Text("Save Key")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.accentColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(apiKey.isEmpty || apiKey.contains("•"))

                // Test button
                Button {
                    testConnection()
                } label: {
                    HStack(spacing: 6) {
                        if isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text("Test Connection")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(theme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.secondaryBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(theme.primaryBorder, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(apiKey.isEmpty || apiKey.contains("•") || isTestingConnection)

                // Remove button
                if RubeConfigurationStore.hasAPIKey() {
                    Button {
                        rubeService.removeAPIKey()
                        apiKey = ""
                    } label: {
                        Text("Remove")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()

                // Success indicator
                if showSaveConfirmation {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("Saved")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                }
            }

            // Test result
            if let result = testResult {
                testResultView(result)
            }

            // Help text
            Text("Get your API key from composio.dev/settings")
                .font(.system(size: 11))
                .foregroundColor(theme.tertiaryText)
        }
    }

    private func testResultView(_ result: RubeConnectionStatus) -> some View {
        HStack(spacing: 8) {
            Image(systemName: result.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.isConnected ? .green : .red)

            if result.isConnected {
                Text("Success! \(result.toolCount) tools available")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            } else {
                Text(result.lastError ?? "Connection failed")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    (result.isConnected ? Color.green : Color.red).opacity(0.1)
                )
        )
    }

    // MARK: - Tools Section

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DISCOVERED TOOLS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.secondaryText)
                    .tracking(0.5)

                Spacer()

                Text("\(rubeService.discoveredTools.count) tools")
                    .font(.system(size: 11))
                    .foregroundColor(theme.tertiaryText)
            }

            // Tools by category
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(RubeToolCategory.allCases, id: \.self) { category in
                        let tools = rubeService.tools(in: category)
                        if !tools.isEmpty {
                            toolCategorySection(category: category, tools: tools)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }

    private func toolCategorySection(category: RubeToolCategory, tools: [RubeToolInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.primaryText)

            FlowLayout(spacing: 6) {
                ForEach(tools) { tool in
                    Text(tool.name)
                        .font(.system(size: 10))
                        .foregroundColor(theme.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(theme.tertiaryBackground)
                        )
                }
            }
        }
    }

    // MARK: - Actions

    private func saveAPIKey() {
        guard !apiKey.isEmpty, !apiKey.contains("•") else { return }

        let success = rubeService.updateAPIKey(apiKey)
        if success {
            showSaveConfirmation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSaveConfirmation = false
            }
            // Mask the key after saving
            apiKey = "••••••••••••••••"
        }
    }

    private func testConnection() {
        guard !apiKey.isEmpty, !apiKey.contains("•") else { return }

        isTestingConnection = true
        testResult = nil

        Task {
            let result = await rubeService.testConnection(apiKey: apiKey)
            await MainActor.run {
                testResult = result
                isTestingConnection = false
            }
        }
    }
}

// MARK: - Flow Layout for Tool Pills

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

// MARK: - Dev Mode Activation

/// View modifier for activating Dev Mode
struct DevModeActivation: ViewModifier {
    @Binding var isDevModeActive: Bool
    @State private var clickCount: Int = 0
    @State private var lastClickTime: Date = Date.distantPast

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                let now = Date()
                // Reset if more than 2 seconds since last click
                if now.timeIntervalSince(lastClickTime) > 2 {
                    clickCount = 0
                }
                lastClickTime = now
                clickCount += 1

                if clickCount >= 7 {
                    withAnimation {
                        isDevModeActive = true
                    }
                    clickCount = 0
                }
            }
            .keyboardShortcut("d", modifiers: [.option, .command])
    }
}

extension View {
    /// Enables Dev Mode activation (⌥⌘D or 7 clicks)
    func devModeActivation(isActive: Binding<Bool>) -> some View {
        modifier(DevModeActivation(isDevModeActive: isActive))
    }
}

#Preview {
    RubeSettingsView()
}
