//
//  ContentView.swift
//  moments
//
//  Created by BHARATH SUDHARSAN on 1/15/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionManager.shared
    @AppStorage("welcomeCompleted") private var welcomeCompleted = false
    @AppStorage("valuePropOneCompleted") private var valuePropOneCompleted = false
    @AppStorage("valuePropTwoCompleted") private var valuePropTwoCompleted = false
    @AppStorage("valuePropThreeCompleted") private var valuePropThreeCompleted = false
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @AppStorage("inferenceCompleted") private var inferenceCompleted = false
    @AppStorage("familyConfirmed") private var familyConfirmed = false
    @AppStorage("criticalQuestionsCompleted") private var criticalQuestionsCompleted = false
    @AppStorage("setupCompleted") private var setupCompleted = false

    var body: some View {
        if !session.isAuthenticated {
            AuthView()
                .environmentObject(session)
        } else if !welcomeCompleted {
            WelcomeView(onContinue: {
                welcomeCompleted = true
            }, onSkip: {
                completeAllOnboarding()
            })
        } else if !valuePropOneCompleted {
            ValuePropView(
                step: 1,
                total: 3,
                icon: "sunrise.fill",
                title: "Start calm, finish proud",
                subtitle: "Oi My Day brings your family into focus every morning.",
                bullets: [
                    "Personalized morning brief at the right time",
                    "Top priorities across school, work, and home",
                    "One place to see what matters today"
                ],
                primaryActionTitle: "Continue",
                secondaryActionTitle: "Skip",
                onPrimary: { valuePropOneCompleted = true },
                onSecondary: { skipValueProps() }
            )
        } else if !valuePropTwoCompleted {
            ValuePropView(
                step: 2,
                total: 3,
                icon: "checkmark.seal.fill",
                title: "Oi asks only when needed",
                subtitle: "Approvals stay in one inbox, with full context.",
                bullets: [
                    "Clear approval requests with reasons",
                    "Quick approve for routine actions",
                    "Quiet hours respected by default"
                ],
                primaryActionTitle: "Continue",
                secondaryActionTitle: "Skip",
                onPrimary: { valuePropTwoCompleted = true },
                onSecondary: { skipValueProps() }
            )
        } else if !valuePropThreeCompleted {
            ValuePropView(
                step: 3,
                total: 3,
                icon: "bolt.horizontal.fill",
                title: "Oi sets things up for you",
                subtitle: "We pre-configure services so your family can start fast. Next, we will ask for a few permissions to connect your calendar and contacts.",
                bullets: [
                    "Automatic phone number and Telegram setup",
                    "Calendar and email connections ready",
                    "Skills grouped by life areas, ready to enable"
                ],
                primaryActionTitle: "Continue",
                secondaryActionTitle: "Skip",
                onPrimary: { valuePropThreeCompleted = true },
                onSecondary: { skipValueProps() }
            )
        } else if !onboardingCompleted {
            PermissionsOnboardingView {
                onboardingCompleted = true
            }
        } else if !inferenceCompleted {
            InferenceProgressView {
                inferenceCompleted = true
            }
        } else if !familyConfirmed {
            FamilyConfirmationView {
                familyConfirmed = true
            }
        } else if !criticalQuestionsCompleted {
            CriticalQuestionsView {
                criticalQuestionsCompleted = true
            }
        } else if !setupCompleted {
            SetupCompleteView {
                setupCompleted = true
            }
        } else {
            MainTabView()
        }
    }

    private func completeAllOnboarding() {
        welcomeCompleted = true
        valuePropOneCompleted = true
        valuePropTwoCompleted = true
        valuePropThreeCompleted = true
        onboardingCompleted = true
        inferenceCompleted = true
        familyConfirmed = true
        criticalQuestionsCompleted = true
        setupCompleted = true
    }

    private func skipValueProps() {
        valuePropOneCompleted = true
        valuePropTwoCompleted = true
        valuePropThreeCompleted = true
    }
}

private struct MainTabView: View {
    @AppStorage("selectedTab") private var selectedTabRaw = MainTab.home.rawValue

    private var selectedTab: Binding<MainTab> {
        Binding(
            get: { MainTab(rawValue: selectedTabRaw) ?? .home },
            set: { selectedTabRaw = $0.rawValue }
        )
    }

    var body: some View {
        TabView(selection: selectedTab) {
            HomeView(selectedTab: selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(MainTab.home)

            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(MainTab.chat)

            AutomationsView()
                .tabItem { Label("Auto", systemImage: "gearshape.2.fill") }
                .tag(MainTab.automations)

            InboxView()
                .tabItem { Label("Inbox", systemImage: "tray.fill") }
                .tag(MainTab.inbox)

            SettingsView()
                .tabItem { Label("You", systemImage: "person.crop.circle") }
                .tag(MainTab.settings)
        }
        .tint(AppTheme.primary)
    }
}

#Preview {
    ContentView()
}
