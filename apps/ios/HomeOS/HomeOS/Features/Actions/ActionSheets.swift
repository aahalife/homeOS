import SwiftUI

// MARK: - Make a Call Sheet

struct MakeCallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var callDescription = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header illustration
                    VStack(spacing: 16) {
                        Image(systemName: "phone.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("What call should I make?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Describe the call and I'll handle it for you")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Examples
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Examples:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        ForEach(callExamples, id: \.self) { example in
                            Button {
                                callDescription = example
                            } label: {
                                HStack {
                                    Text(example)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                }
                                .padding(12)
                                .background(GlassSurface(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Describe your call")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        TextEditor(text: $callDescription)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                            .frame(height: 100)
                            .padding(12)
                            .background(GlassSurface(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Submit button
                    Button {
                        submitCallRequest()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "phone.arrow.up.right")
                                Text("Request Call")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.green, Color(hex: "0f9b0f")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(callDescription.isEmpty || isSubmitting)
                    .opacity(callDescription.isEmpty ? 0.5 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Make a Call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Call Requested", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your call request has been submitted. You'll receive an approval request before the call is made.")
            }
        }
    }

    private var callExamples: [String] {
        [
            "Call Olive Garden to make a reservation for 4 at 7pm Friday",
            "Schedule a dentist appointment for next week",
            "Call the pharmacy to check if my prescription is ready"
        ]
    }

    private func submitCallRequest() {
        isSubmitting = true

        Task {
            do {
                try await sendChatMessage("Make a phone call: \(callDescription)")
                await MainActor.run {
                    isSubmitting = false
                    showConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }

    private func sendChatMessage(_ message: String) async throws {
        guard let url = URL(string: "\(Configuration.runtimeURL)/v1/chat/turn") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authManager.token ?? "")", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "workspaceId": authManager.workspaceId ?? "",
            "message": message
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Action", code: 1)
        }
    }
}

// MARK: - Sell Item Sheet

struct SellItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var itemName = ""
    @State private var itemDescription = ""
    @State private var askingPrice = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "bag.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)

                            Text("What are you selling?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        // Form fields
                        VStack(alignment: .leading, spacing: 16) {
                            FormField(title: "Item Name", text: $itemName, placeholder: "e.g., Baby stroller, iPhone 12...")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))

                                TextEditor(text: $itemDescription)
                                    .scrollContentBackground(.hidden)
                                    .foregroundColor(.white)
                                    .frame(height: 80)
                                    .padding(12)
                                    .background(GlassSurface(cornerRadius: 12))
                            }

                            FormField(title: "Asking Price", text: $askingPrice, placeholder: "$0.00")
                        }
                        .padding(.horizontal)

                        // Photo section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photos")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))

                            HStack(spacing: 12) {
                                PhotoPlaceholder()
                                PhotoPlaceholder()
                                PhotoPlaceholder()
                            }
                        }
                        .padding(.horizontal)

                        // Marketplace selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Post to")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))

                            HStack(spacing: 12) {
                                MarketplaceChip(name: "Facebook", isSelected: true)
                                MarketplaceChip(name: "Craigslist", isSelected: false)
                                MarketplaceChip(name: "eBay", isSelected: false)
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                }

                // Submit button
                VStack {
                    Spacer()

                    Button {
                        submitSellRequest()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "tag.fill")
                                Text("Create Listing")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.orange, Color(hex: "ff6b35")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(itemName.isEmpty || isSubmitting)
                    .opacity(itemName.isEmpty ? 0.5 : 1)
                    .padding()
                    .background(Color(hex: "1a1a2e"))
                }
            }
            .navigationTitle("Sell an Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Listing Created", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("I'll create a listing for \(itemName) and notify you when there are interested buyers.")
            }
        }
    }

    private func submitSellRequest() {
        isSubmitting = true
        showConfirmation = true
        isSubmitting = false
    }
}

// MARK: - Groceries Sheet

struct GroceriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var groceryRequest = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "cart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("What groceries do you need?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("I'll add items to your Instacart cart")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Quick suggestions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick options:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                QuickChip(text: "Weekly essentials") { groceryRequest = "Order my weekly grocery essentials" }
                                QuickChip(text: "Dinner tonight") { groceryRequest = "Get ingredients for a quick dinner for 4" }
                                QuickChip(text: "Snacks") { groceryRequest = "Order some healthy snacks for the week" }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or describe what you need")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        TextEditor(text: $groceryRequest)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                            .frame(height: 120)
                            .padding(12)
                            .background(GlassSurface(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Submit button
                    Button {
                        submitGroceryRequest()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "cart.badge.plus")
                                Text("Add to Cart")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, Color(hex: "4361ee")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(groceryRequest.isEmpty || isSubmitting)
                    .opacity(groceryRequest.isEmpty ? 0.5 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Groceries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Request Submitted", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("I'll prepare your grocery cart. You'll get a notification when it's ready for review.")
            }
        }
    }

    private func submitGroceryRequest() {
        isSubmitting = true
        showConfirmation = true
        isSubmitting = false
    }
}

// MARK: - Schedule Sheet

struct ScheduleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var eventDescription = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.pink)

                        Text("What would you like to schedule?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    // Examples
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Examples:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        ForEach(scheduleExamples, id: \.self) { example in
                            Button {
                                eventDescription = example
                            } label: {
                                HStack {
                                    Text(example)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                }
                                .padding(12)
                                .background(GlassSurface(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Describe your event or reminder")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        TextEditor(text: $eventDescription)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                            .frame(height: 100)
                            .padding(12)
                            .background(GlassSurface(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        isSubmitting = true
                        showConfirmation = true
                        isSubmitting = false
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "calendar.badge.plus")
                                Text("Add to Calendar")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.pink, Color(hex: "ff6b9d")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(eventDescription.isEmpty || isSubmitting)
                    .opacity(eventDescription.isEmpty ? 0.5 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Event Scheduled", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("I've added this to your calendar.")
            }
        }
    }

    private var scheduleExamples: [String] {
        [
            "Remind me to pick up dry cleaning tomorrow at 5pm",
            "Schedule a family game night for Saturday evening",
            "Block time for gym on weekday mornings"
        ]
    }
}

// MARK: - Hire Helper Sheet

struct HireHelperSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var helperRequest = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)

                        Text("What help do you need?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("I'll find and book the right person")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Service types
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular services:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ServiceButton(icon: "house.fill", title: "Cleaning") { helperRequest = "Find a house cleaner for this week" }
                            ServiceButton(icon: "wrench.fill", title: "Handyman") { helperRequest = "Find a handyman for home repairs" }
                            ServiceButton(icon: "leaf.fill", title: "Landscaping") { helperRequest = "Find someone for yard work" }
                            ServiceButton(icon: "figure.child", title: "Babysitter") { helperRequest = "Find a babysitter for Saturday night" }
                        }
                    }
                    .padding(.horizontal)

                    // Custom request
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or describe what you need")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        TextEditor(text: $helperRequest)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                            .frame(height: 80)
                            .padding(12)
                            .background(GlassSurface(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        isSubmitting = true
                        showConfirmation = true
                        isSubmitting = false
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "magnifyingglass")
                                Text("Find Helpers")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.purple, Color(hex: "7b2cbf")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(helperRequest.isEmpty || isSubmitting)
                    .opacity(helperRequest.isEmpty ? 0.5 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Hire Helper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Searching...", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("I'll search for available helpers and present options for your approval.")
            }
        }
    }
}

// MARK: - Note to Action Sheet

struct NoteToActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var noteText = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.cyan)

                        Text("Turn any note into action")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Paste a note and I'll extract actionable tasks")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Paste your note")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))

                            Spacer()

                            Button {
                                if let clipboard = UIPasteboard.general.string {
                                    noteText = clipboard
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.clipboard")
                                    Text("Paste")
                                }
                                .font(.caption)
                                .foregroundColor(.cyan)
                            }
                        }

                        TextEditor(text: $noteText)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                            .frame(height: 200)
                            .padding(12)
                            .background(GlassSurface(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        isSubmitting = true
                        showConfirmation = true
                        isSubmitting = false
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                Text("Extract Actions")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.cyan, Color(hex: "00b4d8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(noteText.isEmpty || isSubmitting)
                    .opacity(noteText.isEmpty ? 0.5 : 1)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Note to Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Actions Extracted", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("I've identified actionable items and added them to your tasks.")
            }
        }
    }
}

// MARK: - Helper Views

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .padding(12)
                .background(GlassSurface(cornerRadius: 10))
        }
    }
}

struct PhotoPlaceholder: View {
    var body: some View {
        Button {
            // Open camera/photos
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.title2)
                Text("Add Photo")
                    .font(.caption2)
            }
            .foregroundColor(.white.opacity(0.5))
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(.white.opacity(0.2))
            )
        }
    }
}

struct MarketplaceChip: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        Text(name)
            .font(.subheadline)
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? .white : .white.opacity(0.1))
            )
    }
}

struct QuickChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(GlassSurface(cornerRadius: 20))
        }
    }
}

struct ServiceButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(GlassSurface(cornerRadius: 12))
        }
    }
}

// MARK: - Previews

#Preview("Make Call") {
    MakeCallSheet()
        .environmentObject(AuthManager())
}

#Preview("Sell Item") {
    SellItemSheet()
        .environmentObject(AuthManager())
}

#Preview("Groceries") {
    GroceriesSheet()
        .environmentObject(AuthManager())
}
