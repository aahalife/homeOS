import SwiftUI

struct AutomationsView: View {
    @State private var activePacks: [AutomationPack] = [
        AutomationPack(name: "Morning Launch", description: "Daily briefing at 7:00 AM", status: "Ran today at 7:00 AM", isEnabled: true),
        AutomationPack(name: "School Ops", description: "Homework checks and alerts", status: "2 items need attention", isEnabled: true),
        AutomationPack(name: "Dinner and Groceries", description: "Meal planning and shopping", status: "Sunday plan ready", isEnabled: true)
    ]
    @State private var selectedCatalogItem: AutomationCatalogItem?
    @State private var showCatalog = false

    private let catalogItems: [AutomationCatalogItem] = [
        AutomationCatalogItem(name: "School Ops", description: "Homework checks, grade alerts, and school emails", category: "School & Education"),
        AutomationCatalogItem(name: "Meal Planning", description: "Weekly meal plans and grocery lists", category: "Meals & Groceries"),
        AutomationCatalogItem(name: "Family Comms", description: "Coordinated updates and family reminders", category: "Family Communication"),
        AutomationCatalogItem(name: "Health & Wellness", description: "Appointments, medication, and wellness check-ins", category: "Health & Wellness"),
        AutomationCatalogItem(name: "Transportation", description: "Pickups, carpools, and travel reminders", category: "Transportation"),
        AutomationCatalogItem(name: "Home Maintenance", description: "Repairs, service scheduling, and checklists", category: "Home Maintenance"),
        AutomationCatalogItem(name: "Elder Care Guardian", description: "Daily check-ins and support coordination", category: "Elder Care"),
        AutomationCatalogItem(name: "Mental Load", description: "Shared tasks and invisible work tracking", category: "Mental Load")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "ACTIVE")

                    ForEach($activePacks) { $pack in
                        StandardCard {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(pack.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(pack.description)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                    if let status = pack.status {
                                        Text(status)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                                }
                                Spacer()
                                Toggle("", isOn: $pack.isEnabled)
                                    .labelsHidden()
                            }
                        }
                    }

                    SectionHeader(title: "AVAILABLE")

                    ForEach(catalogItems.prefix(3)) { pack in
                        StandardCard {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(pack.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(pack.description)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                                Button("Get") {
                                    selectedCatalogItem = pack
                                }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                    }

                    Button(action: { showCatalog = true }) {
                        HStack {
                            Text("More automations")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Automations")
            .toolbar {
                Button(action: {}) {
                    Image(systemName: "plus")
                }
            }
            .sheet(item: $selectedCatalogItem) { item in
                AutomationDetailSheet(item: item)
            }
            .sheet(isPresented: $showCatalog) {
                AutomationCatalogSheet(items: catalogItems)
            }
        }
    }
}

private struct AutomationPack: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let status: String?
    var isEnabled: Bool
}

private struct AutomationCatalogItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: String
}

private struct AutomationDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: AutomationCatalogItem

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(item.name)
                    .font(.title2.weight(.bold))
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button("Enable") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.primary)
                .cornerRadius(14)
            }
            .padding(24)
            .navigationTitle(item.category)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AutomationCatalogSheet: View {
    @Environment(\.dismiss) private var dismiss
    let items: [AutomationCatalogItem]

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedKeys, id: \.self) { category in
                    Section(category) {
                        ForEach(groupedItems[category] ?? []) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Automations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var groupedItems: [String: [AutomationCatalogItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }

    private var groupedKeys: [String] {
        groupedItems.keys.sorted()
    }
}
