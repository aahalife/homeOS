import Foundation

/// Weather API using wttr.in - FREE, no API key required
/// Documentation: https://github.com/chubin/wttr.in
final class WeatherAPI: BaseAPIClient {
    private let baseURL = "https://wttr.in"

    func getCurrentWeather(city: String) async throws -> WeatherConditions {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/\(encodedCity)?format=j1") else {
            throw APIError.invalidURL
        }

        do {
            let response: WttrResponse = try await request(url: url)
            guard let current = response.currentCondition?.first else {
                throw APIError.noData
            }

            return WeatherConditions(
                temperatureF: Double(current.tempF ?? "0") ?? 0,
                feelsLikeF: Double(current.feelsLikeF ?? "0") ?? 0,
                humidity: Int(current.humidity ?? "0") ?? 0,
                description: current.weatherDesc?.first?.value ?? "Unknown",
                windSpeedMph: Double(current.windspeedMiles ?? "0") ?? 0
            )
        } catch {
            // Fallback to default weather
            logger.warning("Weather API failed: \(error.localizedDescription)")
            return WeatherConditions(
                temperatureF: 70,
                feelsLikeF: 70,
                humidity: 50,
                description: "Weather data unavailable",
                windSpeedMph: 5
            )
        }
    }

    func getForecast(city: String) async throws -> [WeatherSummary] {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/\(encodedCity)?format=j1") else {
            throw APIError.invalidURL
        }

        let response: WttrResponse = try await request(url: url)
        return (response.weather ?? []).map { day in
            WeatherSummary(
                temperatureHigh: Double(day.maxtempF ?? "70") ?? 70,
                temperatureLow: Double(day.mintempF ?? "50") ?? 50,
                description: day.hourly?.first?.weatherDesc?.first?.value ?? "Unknown",
                precipitation: Double(day.hourly?.first?.chanceofrain ?? "0") ?? 0 > 30,
                advisory: nil
            )
        }
    }
}

// MARK: - wttr.in Response Types

struct WttrResponse: Codable {
    let currentCondition: [WttrCurrentCondition]?
    let weather: [WttrWeather]?

    enum CodingKeys: String, CodingKey {
        case currentCondition = "current_condition"
        case weather
    }
}

struct WttrCurrentCondition: Codable {
    let tempF: String?
    let tempC: String?
    let feelsLikeF: String?
    let humidity: String?
    let windspeedMiles: String?
    let weatherDesc: [WttrDescription]?

    enum CodingKeys: String, CodingKey {
        case tempF = "temp_F"
        case tempC = "temp_C"
        case feelsLikeF = "FeelsLikeF"
        case humidity
        case windspeedMiles
        case weatherDesc
    }
}

struct WttrDescription: Codable {
    let value: String
}

struct WttrWeather: Codable {
    let date: String?
    let maxtempF: String?
    let mintempF: String?
    let hourly: [WttrHourly]?
}

struct WttrHourly: Codable {
    let weatherDesc: [WttrDescription]?
    let chanceofrain: String?
}
