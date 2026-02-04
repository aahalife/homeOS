import SwiftUI

/// Root view that switches between onboarding and main app
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                LoadingView()
            } else if !appState.isOnboardingComplete {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: appState.isOnboardingComplete)
    }
}

struct LoadingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "house.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("OpenClaw")
                .font(.largeTitle.bold())

            Text("Family Assistant")
                .font(.title3)
                .foregroundStyle(.secondary)

            if appState.modelManager.modelLoadProgress < 1.0 {
                VStack(spacing: 8) {
                    ProgressView(value: appState.modelManager.modelLoadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)

                    Text("Loading AI models...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
            }
        }
        .padding()
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
