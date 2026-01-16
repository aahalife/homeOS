import SwiftUI

struct FamilyConfirmationView: View {
    @State private var members: [FamilyMemberProfile] = []
    @State private var hasLoaded = false

    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            OnboardingProgressDots(current: 3, total: 5)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Here's what I found")
                    .font(.title.weight(.bold))
                    .foregroundColor(.primary)
                Text("Confirm your family members. You can edit anytime later.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach($members) { $member in
                        FamilyMemberCard(member: $member) {
                            members.removeAll { $0.id == member.id }
                        }
                    }

                    Button(action: addMember) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add someone")
                                .font(.headline)
                            Spacer()
                        }
                        .foregroundColor(AppTheme.primary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.primary.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        )
                    }
                }
                .padding(.horizontal, 8)
            }

            Button(action: complete) {
                Text("Looks good!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppTheme.primary)
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            if !hasLoaded {
                members = FamilyStore.shared.loadCandidates()
                hasLoaded = true
            }
        }
    }

    private func addMember() {
        members.append(FamilyMemberProfile(name: "", role: .other, age: nil))
    }

    private func complete() {
        FamilyStore.shared.saveConfirmed(members)
        Task {
            await FamilyStore.shared.syncConfirmed(members)
            await MainActor.run {
                onComplete()
            }
        }
    }
}

private struct FamilyMemberCard: View {
    @Binding var member: FamilyMemberProfile
    let onDelete: () -> Void

    var body: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.primary)

                    TextField("Name", text: $member.name)
                        .textFieldStyle(.plain)
                        .foregroundColor(.primary)

                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }

                HStack(spacing: 12) {
                    Picker("Role", selection: $member.role) {
                        ForEach(FamilyRole.allCases, id: \.self) { role in
                            Text(role.title).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.primary)

                    if member.role.requiresAge {
                        TextField("Age", value: $member.age, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .foregroundColor(.primary)
                            .frame(width: 60)
                    }

                    Spacer()
                }

                Text("Source: inferred from contacts")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
    }
}

#Preview {
    FamilyConfirmationView(onComplete: {})
}
