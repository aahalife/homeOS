import Foundation

/// Google Places API (used for contractor/provider search)
/// Documentation: https://developers.google.com/maps/documentation/places/web-service
final class GooglePlacesAPI: BaseAPIClient {
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    private let apiKey: String

    var isConfigured: Bool { !apiKey.isEmpty }

    init(apiKey: String = "") {
        self.apiKey = KeychainManager.shared.getAPIKey(for: KeychainManager.APIKeys.googlePlaces) ?? apiKey
        super.init()
    }

    // MARK: - Nearby Search

    func searchNearby(
        query: String,
        latitude: Double,
        longitude: Double,
        radius: Int = 40000 // 25 miles in meters
    ) async throws -> [ServiceProvider] {
        guard isConfigured else {
            logger.warning("Google Places API not configured, using stub data")
            return StubContractorData.sampleProviders(for: query)
        }

        var components = URLComponents(string: "\(baseURL)/nearbysearch/json")!
        components.queryItems = [
            URLQueryItem(name: "keyword", value: query),
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "type", value: "home_goods_store"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: PlacesSearchResponse = try await request(url: url)

        return (response.results ?? []).compactMap { place in
            ServiceProvider(
                name: place.name ?? "Unknown",
                serviceType: inferServiceType(from: query),
                phone: place.formattedPhoneNumber ?? "",
                address: place.vicinity,
                rating: place.rating,
                reviewCount: place.userRatingsTotal,
                source: "Google"
            )
        }
    }

    // MARK: - Text Search

    func textSearch(query: String) async throws -> [ServiceProvider] {
        guard isConfigured else {
            return StubContractorData.sampleProviders(for: query)
        }

        var components = URLComponents(string: "\(baseURL)/textsearch/json")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: PlacesSearchResponse = try await request(url: url)

        return (response.results ?? []).compactMap { place in
            ServiceProvider(
                name: place.name ?? "Unknown",
                serviceType: inferServiceType(from: query),
                phone: place.formattedPhoneNumber ?? "",
                address: place.formattedAddress ?? place.vicinity,
                rating: place.rating,
                reviewCount: place.userRatingsTotal,
                source: "Google"
            )
        }
    }

    private func inferServiceType(from query: String) -> ServiceType {
        let lower = query.lowercased()
        if lower.contains("plumb") { return .plumber }
        if lower.contains("electr") { return .electrician }
        if lower.contains("hvac") || lower.contains("air condition") || lower.contains("heating") { return .hvac }
        if lower.contains("appli") { return .appliance }
        if lower.contains("roof") { return .roofing }
        if lower.contains("lock") { return .locksmith }
        if lower.contains("pest") { return .pest }
        if lower.contains("clean") { return .cleaning }
        if lower.contains("landsc") { return .landscaping }
        return .general
    }
}

// MARK: - Places Response Types

struct PlacesSearchResponse: Codable {
    let results: [PlaceResult]?
    let status: String?
}

struct PlaceResult: Codable {
    let placeId: String?
    let name: String?
    let rating: Double?
    let userRatingsTotal: Int?
    let vicinity: String?
    let formattedAddress: String?
    let formattedPhoneNumber: String?
    let geometry: PlaceGeometry?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, rating
        case userRatingsTotal = "user_ratings_total"
        case vicinity
        case formattedAddress = "formatted_address"
        case formattedPhoneNumber = "formatted_phone_number"
        case geometry
    }
}

struct PlaceGeometry: Codable {
    let location: PlaceLocation?
}

struct PlaceLocation: Codable {
    let lat: Double?
    let lng: Double?
}
