import SwiftUI

struct PermissionsOnboardingView: View {
    @StateObject private var viewModel = PermissionsViewModel()
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingProgressDots(current: 1, total: 5)
                    .padding(.top, 8)

                header

                permissionList

                continueSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .background(Color(.systemBackground))
        .onAppear {
            viewModel.refreshAll()
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("Let Oi understand your family")
                .font(.title.weight(.bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("These permissions help us personalize schedules and workflows. You can change them anytime.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var permissionList: some View {
        VStack(spacing: 12) {
            ForEach(PermissionType.allCases.filter { $0.isCore }) { permission in
                PermissionCard(
                    permission: permission,
                    state: viewModel.states[permission] ?? .notDetermined,
                    isSkipped: viewModel.skipped.contains(permission),
                    onAllow: { viewModel.request(permission) },
                    onSkip: { viewModel.skip(permission) },
                    onOpenSettings: viewModel.openSettings
                )
            }

            if PermissionType.allCases.contains(where: { !$0.isCore }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optional")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.textTertiary)

                    ForEach(PermissionType.allCases.filter { !$0.isCore }) { permission in
                        PermissionCard(
                            permission: permission,
                            state: viewModel.states[permission] ?? .notDetermined,
                            isSkipped: viewModel.skipped.contains(permission),
                            onAllow: { viewModel.request(permission) },
                            onSkip: { viewModel.skip(permission) },
                            onOpenSettings: viewModel.openSettings
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var continueSection: some View {
        VStack(spacing: 12) {
            Button {
                onComplete()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppTheme.primary)
                    .cornerRadius(14)
            }
            .disabled(!viewModel.isCoreResolved)
            .opacity(viewModel.isCoreResolved ? 1 : 0.5)

            Text("You can enable more permissions later in Settings.")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
    }
}

private struct PermissionCard: View {
    let permission: PermissionType
    let state: PermissionState
    let isSkipped: Bool
    let onAllow: () -> Void
    let onSkip: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: permission.systemIcon)
                .font(.title2)
                .foregroundColor(AppTheme.primary)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.surfaceSecondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(permission.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(permission.rationale)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(statusColor)
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: primaryAction) {
                    Text(actionTitle)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.surfaceSecondary)
                        .cornerRadius(10)
                }
                .foregroundColor(AppTheme.primary)
                .disabled(state == .authorized)

                if state == .notDetermined && !isSkipped {
                    Button("Not now", action: onSkip)
                        .font(.caption2)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var statusText: String {
        if isSkipped {
            return "Skipped"
        }
        return state.rawValue
    }

    private var statusColor: Color {
        switch state {
        case .authorized:
            return Color(hex: "34C759")
        case .denied, .restricted:
            return Color(hex: "FF3B30")
        case .limited:
            return Color(hex: "FF9500")
        case .notDetermined:
            return AppTheme.textTertiary
        }
    }

    private var actionTitle: String {
        switch state {
        case .authorized:
            return "Allowed"
        case .denied, .restricted:
            return "Settings"
        case .limited:
            return "Manage"
        case .notDetermined:
            return "Allow"
        }
    }

    private func primaryAction() {
        switch state {
        case .authorized:
            return
        case .denied, .restricted, .limited:
            onOpenSettings()
        case .notDetermined:
            onAllow()
        }
    }
}

#Preview {
    PermissionsOnboardingView(onComplete: {})
}
