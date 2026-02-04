import SwiftUI

/// Images, recipes, provider profiles
struct RichMediaMessageView: View {
    let data: RichMediaData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image if available
            if let imageURL = data.imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        placeholderImage
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        failedImageView
                    @unknown default:
                        placeholderImage
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Type badge
                HStack(spacing: 4) {
                    Image(systemName: iconForType)
                        .font(.caption)
                    Text(data.type.rawValue.capitalized)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())

                // Title
                Text(data.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Description
                if let description = data.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                // Metadata
                if !data.metadata.isEmpty {
                    metadataGrid
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray6))
            .frame(height: 200)
            .overlay {
                ProgressView()
            }
    }

    private var failedImageView: some View {
        Rectangle()
            .fill(Color(.systemGray6))
            .frame(height: 200)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Image unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
    }

    private var metadataGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 12
        ) {
            ForEach(Array(data.metadata.keys.sorted()), id: \.self) { key in
                if let value = data.metadata[key] {
                    MetadataItem(key: key, value: value)
                }
            }
        }
        .padding(.top, 4)
    }

    private var iconForType: String {
        switch data.type {
        case .image: return "photo"
        case .recipe: return "book"
        case .providerProfile: return "person.crop.circle"
        case .location: return "mappin.circle"
        case .product: return "cart"
        }
    }

    private var accessibilityLabel: String {
        var label = "\(data.type.rawValue): \(data.title)"
        if let description = data.description {
            label += ". \(description)"
        }
        return label
    }
}

// MARK: - Metadata Item

struct MetadataItem: View {
    let key: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key.capitalized)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Recipe Detail View

struct RecipeDetailView: View {
    let data: RichMediaData

    var body: some View {
        RichMediaMessageView(data: data)
            .onTapGesture {
                // Navigate to full recipe
            }
    }
}

// MARK: - Provider Profile View

struct ProviderProfileView: View {
    let data: RichMediaData

    var body: some View {
        RichMediaMessageView(data: data)
            .onTapGesture {
                // Navigate to provider details
            }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Recipe
            RichMediaMessageView(
                data: RichMediaData(
                    id: UUID(),
                    type: .recipe,
                    title: "Mediterranean Grilled Chicken",
                    description: "A healthy and flavorful chicken dish with olive oil, lemon, and herbs",
                    imageURL: "https://example.com/chicken.jpg",
                    metadata: [
                        "Prep Time": "15 min",
                        "Cook Time": "25 min",
                        "Servings": "4",
                        "Calories": "320 kcal",
                        "Difficulty": "Easy",
                        "Rating": "4.8/5"
                    ]
                )
            )

            // Provider Profile
            RichMediaMessageView(
                data: RichMediaData(
                    id: UUID(),
                    type: .providerProfile,
                    title: "Dr. Sarah Johnson",
                    description: "Board-certified family physician with 15 years of experience",
                    imageURL: "https://example.com/doctor.jpg",
                    metadata: [
                        "Specialty": "Family Medicine",
                        "Experience": "15 years",
                        "Rating": "4.9/5",
                        "Location": "Main St Clinic",
                        "Availability": "Next week",
                        "Insurance": "Accepted"
                    ]
                )
            )

            // Location
            RichMediaMessageView(
                data: RichMediaData(
                    id: UUID(),
                    type: .location,
                    title: "Whole Foods Market",
                    description: "Your nearest organic grocery store",
                    imageURL: nil,
                    metadata: [
                        "Distance": "2.3 miles",
                        "Open Hours": "8 AM - 10 PM",
                        "Phone": "(555) 123-4567",
                        "Rating": "4.5/5"
                    ]
                )
            )

            // Product
            RichMediaMessageView(
                data: RichMediaData(
                    id: UUID(),
                    type: .product,
                    title: "Organic Extra Virgin Olive Oil",
                    description: "Premium quality olive oil from Greece",
                    imageURL: "https://example.com/oliveoil.jpg",
                    metadata: [
                        "Brand": "Kalamata Gold",
                        "Size": "500ml",
                        "Price": "$12.99",
                        "In Stock": "Yes"
                    ]
                )
            )
        }
        .padding()
    }
}
