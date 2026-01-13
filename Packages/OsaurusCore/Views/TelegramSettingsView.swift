//
//  TelegramSettingsView.swift
//  OsaurusCore
//
//  Settings view for Telegram Gateway in Oi My AI.
//

import SwiftUI

// MARK: - Telegram Settings View

struct TelegramSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var telegramService = TelegramGatewayService.shared

    private var theme: ThemeProtocol { themeManager.currentTheme }

    @State private var botToken: String = ""
    @State private var showBotToken: Bool = false
    @State private var isTestingConnection: Bool = false
    @State private var testResult: TelegramConnectionStatus?
    @State private var showSaveConfirmation: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            headerSection

            Divider()
                .background(theme.primaryBorder)

            // Connection Status
            statusSection

            // Bot Token Entry
            botTokenSection

            // Settings
            if telegramService.connectionStatus.isConnected {
                settingsSection
                recentMessagesSection
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.primaryBackground)
        .onAppear {
            if TelegramConfigurationStore.hasBotToken() {
                botToken = "••••••••••••••••••••••••••••••••••••••••••••"
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "paperplane.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Telegram Gateway")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.primaryText)

                    Text("Let family members interact via Telegram")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                // Enable toggle
                Toggle("", isOn: Binding(
                    get: { telegramService.configuration.enabled },
                    set: { telegramService.setEnabled($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(!TelegramConfigurationStore.hasBotToken())
            }
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(telegramService.connectionStatus.statusDescription)
                .font(.system(size: 13))
                .foregroundColor(theme.primaryText)

            Spacer()

            if telegramService.configuration.enabled {
                if telegramService.isPolling {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Polling...")
                            .font(.system(size: 11))
                            .foregroundColor(theme.secondaryText)
                    }
                } else {
                    Button("Start") {
                        telegramService.startPolling()
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
        if telegramService.isPolling {
            return .green
        } else if telegramService.connectionStatus.isConnected {
            return .orange
        } else if telegramService.connectionStatus.lastError != nil {
            return .red
        } else {
            return .gray
        }
    }

    // MARK: - Bot Token Section

    private var botTokenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BOT TOKEN")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.secondaryText)
                .tracking(0.5)

            HStack(spacing: 12) {
                Group {
                    if showBotToken {
                        TextField("Enter your Telegram bot token", text: $botToken)
                    } else {
                        SecureField("Enter your Telegram bot token", text: $botToken)
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

                Button {
                    showBotToken.toggle()
                } label: {
                    Image(systemName: showBotToken ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }

            HStack(spacing: 12) {
                Button {
                    saveBotToken()
                } label: {
                    Text("Save Token")
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
                .disabled(botToken.isEmpty || botToken.contains("•"))

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
                .disabled(botToken.isEmpty || botToken.contains("•") || isTestingConnection)

                if TelegramConfigurationStore.hasBotToken() {
                    Button {
                        telegramService.removeBotToken()
                        botToken = ""
                    } label: {
                        Text("Remove")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()

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

            if let result = testResult {
                testResultView(result)
            }

            Text("Get your bot token from @BotFather on Telegram")
                .font(.system(size: 11))
                .foregroundColor(theme.tertiaryText)
        }
    }

    private func testResultView(_ result: TelegramConnectionStatus) -> some View {
        HStack(spacing: 8) {
            Image(systemName: result.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.isConnected ? .green : .red)

            if result.isConnected {
                if let username = result.botUsername {
                    Text("Connected as @\(username)")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                } else {
                    Text("Connection successful")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            } else {
                Text(result.lastError ?? "Connection failed")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill((result.isConnected ? Color.green : Color.red).opacity(0.1))
        )
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SETTINGS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.secondaryText)
                .tracking(0.5)

            VStack(spacing: 12) {
                // Require family membership
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Require Family Membership")
                            .font(.system(size: 13))
                            .foregroundColor(theme.primaryText)
                        Text("Only respond to registered family members")
                            .font(.system(size: 11))
                            .foregroundColor(theme.secondaryText)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { telegramService.configuration.requireFamilyMembership },
                        set: { newValue in
                            var config = telegramService.configuration
                            config.requireFamilyMembership = newValue
                            TelegramConfigurationStore.save(config)
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }

                Divider()

                // Rate limit
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rate Limit")
                            .font(.system(size: 13))
                            .foregroundColor(theme.primaryText)
                        Text("Max messages per user per minute")
                            .font(.system(size: 11))
                            .foregroundColor(theme.secondaryText)
                    }

                    Spacer()

                    Text("\(telegramService.configuration.rateLimitPerMinute)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.secondaryBackground)
                        )
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
    }

    // MARK: - Recent Messages Section

    private var recentMessagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT MESSAGES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.secondaryText)
                    .tracking(0.5)

                Spacer()

                Text("\(telegramService.connectionStatus.messagesProcessed) total")
                    .font(.system(size: 11))
                    .foregroundColor(theme.tertiaryText)
            }

            if telegramService.recentMessages.isEmpty {
                Text("No messages yet")
                    .font(.system(size: 12))
                    .foregroundColor(theme.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(telegramService.recentMessages.prefix(10)) { message in
                            messageRow(message)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private func messageRow(_ message: TelegramIncomingMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(theme.accentColor.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(message.displayName.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.accentColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(message.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.primaryText)

                    Spacer()

                    Text(formatTime(message.date))
                        .font(.system(size: 10))
                        .foregroundColor(theme.tertiaryText)
                }

                Text(message.text)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(theme.secondaryBackground)
        )
    }

    // MARK: - Actions

    private func saveBotToken() {
        guard !botToken.isEmpty, !botToken.contains("•") else { return }

        let success = telegramService.updateBotToken(botToken)
        if success {
            showSaveConfirmation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSaveConfirmation = false
            }
            botToken = "••••••••••••••••••••••••••••••••••••••••••••"
        }
    }

    private func testConnection() {
        guard !botToken.isEmpty, !botToken.contains("•") else { return }

        isTestingConnection = true
        testResult = nil

        // Temporarily save token for testing
        _ = TelegramConfigurationStore.saveBotToken(botToken)

        Task {
            let result = await telegramService.testConnection()
            await MainActor.run {
                testResult = result
                isTestingConnection = false
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    TelegramSettingsView()
}
