//
//  FamilySettingsView.swift
//  OsaurusCore
//
//  Settings view for family management in Oi My AI.
//  Handles family creation, member management, and join flow.
//

import SwiftUI

// MARK: - Family Settings View

struct FamilySettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var familyManager = FamilyManager.shared

    private var theme: ThemeProtocol { themeManager.currentTheme }

    @State private var showCreateFamilySheet: Bool = false
    @State private var showInviteSheet: Bool = false
    @State private var showJoinSheet: Bool = false
    @State private var showMemberEditor: FamilyMember?
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            headerSection

            Divider()
                .background(theme.primaryBorder)

            if let family = familyManager.family {
                // Family exists - show management UI
                familyManagementView(family)
            } else {
                // No family - show setup UI
                noFamilyView
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.primaryBackground)
        .sheet(isPresented: $showCreateFamilySheet) {
            CreateFamilySheet(isPresented: $showCreateFamilySheet)
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteMemberSheet(isPresented: $showInviteSheet)
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinFamilySheet(isPresented: $showJoinSheet)
        }
        .sheet(item: $showMemberEditor) { member in
            EditMemberSheet(member: member, isPresented: Binding(
                get: { showMemberEditor != nil },
                set: { if !$0 { showMemberEditor = nil } }
            ))
        }
        .alert("Delete Family?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                familyManager.deleteFamily()
            }
        } message: {
            Text("This will remove all family members and settings. This cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Family")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.primaryText)

                    Text("Manage family members and permissions")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                if familyManager.family != nil {
                    // Family mode toggle would go here if we had a feature flag
                }
            }
        }
    }

    // MARK: - No Family View

    private var noFamilyView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.secondaryText)

                Text("No Family Set Up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                Text("Create a family to share Oi My AI with your household members via Telegram.")
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            HStack(spacing: 16) {
                Button {
                    showCreateFamilySheet = true
                } label: {
                    Label("Create Family", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.accentColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    showJoinSheet = true
                } label: {
                    Label("Join Family", systemImage: "person.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primaryText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.secondaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.primaryBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Family Management View

    private func familyManagementView(_ family: Family) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Family info card
            familyInfoCard(family)

            // Members section
            membersSection(family)

            // Pending requests section
            if !familyManager.pendingJoinRequests.isEmpty {
                pendingRequestsSection
            }

            // Danger zone
            dangerZoneSection
        }
    }

    private func familyInfoCard(_ family: Family) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(family.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                Text("\(family.members.count) member\(family.members.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            Button {
                showInviteSheet = true
            } label: {
                Label("Invite", systemImage: "person.badge.plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.accentColor)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!familyManager.canApproveJoins())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
        )
    }

    private func membersSection(_ family: Family) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEMBERS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.secondaryText)
                .tracking(0.5)

            VStack(spacing: 8) {
                ForEach(family.members) { member in
                    memberRow(member, isPrimary: member.id == family.primaryMemberId)
                }
            }
        }
    }

    private func memberRow(_ member: FamilyMember, isPrimary: Bool) -> some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(roleColor(member.role))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(member.name.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.primaryText)

                    if isPrimary {
                        Text("Primary")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(theme.accentColor))
                    }
                }

                HStack(spacing: 8) {
                    Text(member.role.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryText)

                    if let handle = member.telegramHandle {
                        Text("@\(handle)")
                            .font(.system(size: 11))
                            .foregroundColor(theme.tertiaryText)
                    }
                }
            }

            Spacer()

            if familyManager.canManageFamily() && !isPrimary {
                Menu {
                    Button {
                        showMemberEditor = member
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        familyManager.removeMember(id: member.id)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(theme.secondaryBackground))
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.secondaryBackground)
        )
    }

    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PENDING REQUESTS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.secondaryText)
                    .tracking(0.5)

                Spacer()

                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)

                Text("\(familyManager.pendingJoinRequests.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.secondaryText)
            }

            VStack(spacing: 8) {
                ForEach(familyManager.pendingJoinRequests) { request in
                    joinRequestRow(request)
                }
            }
        }
    }

    private func joinRequestRow(_ request: FamilyJoinRequest) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(request.proposedMember.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.primaryText)

                Text("Wants to join as \(request.proposedMember.role.rawValue)")
                    .font(.system(size: 11))
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    familyManager.approveJoinRequest(request.id)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    familyManager.denyJoinRequest(request.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DANGER ZONE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.red)
                .tracking(0.5)

            Button {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Family")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!familyManager.canManageFamily())
        }
    }

    // MARK: - Helpers

    private func roleColor(_ role: FamilyRole) -> Color {
        switch role {
        case .parent: return .blue
        case .child: return .green
        case .teen: return .orange
        case .grandparent: return .purple
        case .caregiver: return .teal
        case .other: return .gray
        }
    }
}

// MARK: - Create Family Sheet

private struct CreateFamilySheet: View {
    @Binding var isPresented: Bool
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var familyManager = FamilyManager.shared

    private var theme: ThemeProtocol { themeManager.currentTheme }

    @State private var familyName: String = ""
    @State private var memberName: String = ""
    @State private var selectedRole: FamilyRole = .parent

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Create Family")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primaryText)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Family Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryText)

                    TextField("e.g., The Smiths", text: $familyName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.secondaryBackground)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryText)

                    TextField("Your display name", text: $memberName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.secondaryBackground)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Role")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryText)

                    Picker("Role", selection: $selectedRole) {
                        ForEach(FamilyRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(theme.secondaryText)

                Spacer()

                Button {
                    _ = familyManager.createFamily(
                        name: familyName,
                        primaryMemberName: memberName,
                        primaryRole: selectedRole
                    )
                    isPresented = false
                } label: {
                    Text("Create")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.accentColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(familyName.isEmpty || memberName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400, height: 350)
        .background(theme.primaryBackground)
    }
}

// MARK: - Invite Member Sheet

private struct InviteMemberSheet: View {
    @Binding var isPresented: Bool
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var familyManager = FamilyManager.shared

    private var theme: ThemeProtocol { themeManager.currentTheme }

    @State private var invite: FamilyInvite?
    @State private var suggestedName: String = ""
    @State private var suggestedRole: FamilyRole = .other
    @State private var copied: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Invite Member")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primaryText)

            if let invite = invite {
                // Show invite code
                VStack(spacing: 16) {
                    Text("Share this code")
                        .font(.system(size: 13))
                        .foregroundColor(theme.secondaryText)

                    HStack(spacing: 8) {
                        ForEach(Array(invite.code), id: \.self) { char in
                            Text(String(char))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.primaryText)
                                .frame(width: 40, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(theme.secondaryBackground)
                                )
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("Expires in \(Int(invite.timeRemaining / 60)) minutes")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(theme.tertiaryText)

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(invite.code, forType: .string)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        Label(copied ? "Copied!" : "Copy Code", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(copied ? .green : theme.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Create invite form
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Suggested Name (optional)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.secondaryText)

                        TextField("Member's name", text: $suggestedName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 14))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.secondaryBackground)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Role")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.secondaryText)

                        Picker("Role", selection: $suggestedRole) {
                            ForEach(FamilyRole.allCases, id: \.self) { role in
                                Text(role.rawValue).tag(role)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                Spacer()

                Button {
                    invite = familyManager.createInvite(
                        suggestedRole: suggestedRole,
                        suggestedName: suggestedName.isEmpty ? nil : suggestedName
                    )
                } label: {
                    Text("Generate Code")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.accentColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()

            Button("Close") {
                isPresented = false
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(theme.secondaryText)
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .frame(width: 350, height: 400)
        .background(theme.primaryBackground)
    }
}

// MARK: - Join Family Sheet

private struct JoinFamilySheet: View {
    @Binding var isPresented: Bool
    @StateObject private var themeManager = ThemeManager.shared

    private var theme: ThemeProtocol { themeManager.currentTheme }

    @State private var code: String = ""
    @State private var name: String = ""
    @State private var telegramHandle: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Join Family")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primaryText)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Invite Code")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryText)

                    TextField("6-digit code", text: $code)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.secondaryBackground)
                        )
                        .onChange(of: code) { _, newValue in
                            code = String(newValue.filter { $0.isNumber }.prefix(6))
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryText)

                    TextField("Display name", text: $name)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.secondaryBackground)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Telegram Handle (optional)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryText)

                    TextField("@username", text: $telegramHandle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.secondaryBackground)
                        )
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(theme.secondaryText)

                Spacer()

                Button {
                    submitJoinRequest()
                } label: {
                    Text("Join")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.accentColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(code.count != 6 || name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 350, height: 400)
        .background(theme.primaryBackground)
    }

    private func submitJoinRequest() {
        let handle = telegramHandle.hasPrefix("@")
            ? String(telegramHandle.dropFirst())
            : telegramHandle

        if FamilyManager.shared.submitJoinRequest(
            inviteCode: code,
            name: name,
            telegramHandle: handle.isEmpty ? nil : handle
        ) != nil {
            isPresented = false
        } else {
            errorMessage = "Invalid or expired invite code"
        }
    }
}

// MARK: - Edit Member Sheet

private struct EditMemberSheet: View {
    let member: FamilyMember
    @Binding var isPresented: Bool

    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var familyManager = FamilyManager.shared

    private var theme: ThemeProtocol { themeManager.currentTheme }

    @State private var name: String = ""
    @State private var role: FamilyRole = .other
    @State private var telegramHandle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Member")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primaryText)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryText)

                    TextField("Display name", text: $name)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.secondaryBackground)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Role")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryText)

                    Picker("Role", selection: $role) {
                        ForEach(FamilyRole.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Telegram Handle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryText)

                    TextField("@username", text: $telegramHandle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.secondaryBackground)
                        )
                }
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(theme.secondaryText)

                Spacer()

                Button {
                    saveMember()
                } label: {
                    Text("Save")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.accentColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 350, height: 350)
        .background(theme.primaryBackground)
        .onAppear {
            name = member.name
            role = member.role
            telegramHandle = member.telegramHandle ?? ""
        }
    }

    private func saveMember() {
        var updated = member
        updated.name = name
        updated.role = role
        updated.telegramHandle = telegramHandle.isEmpty ? nil : telegramHandle
        updated.permissions = role.defaultPermissions

        familyManager.updateMember(updated)
        isPresented = false
    }
}

#Preview {
    FamilySettingsView()
}
