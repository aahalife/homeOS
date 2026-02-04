import Foundation

/// OpenFDA Drug Information API - FREE, no key required
/// Documentation: https://open.fda.gov/apis/drug/label/
final class OpenFDAAPI: BaseAPIClient {
    private let baseURL = "https://api.fda.gov/drug"

    func validateMedication(name: String) async throws -> DrugInfo {
        let searchQuery = "openfda.brand_name:\"\(name)\"+openfda.generic_name:\"\(name)\""
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/label.json?search=\(encodedQuery)&limit=1") else {
            throw APIError.invalidURL
        }

        do {
            let response: FDAResponse = try await request(url: url)

            guard let result = response.results?.first else {
                throw HealthcareError.medicationNotFound
            }

            return DrugInfo(
                name: result.openfda?.brandName?.first ?? name,
                genericName: result.openfda?.genericName?.first,
                activeIngredient: result.activeIngredient?.first,
                warnings: result.warnings?.joined(separator: "\n"),
                dosage: result.dosageAndAdministration?.first
            )
        } catch let error as APIError {
            throw error
        } catch {
            // Fallback for offline/error - return basic info
            logger.warning("OpenFDA API failed, returning basic drug info: \(error.localizedDescription)")
            return DrugInfo(name: name, genericName: nil, activeIngredient: nil, warnings: nil, dosage: nil)
        }
    }

    func searchAdverseEvents(drugName: String, limit: Int = 5) async throws -> [AdverseEvent] {
        guard let encodedName = drugName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/event.json?search=patient.drug.medicinalproduct:\"\(encodedName)\"&limit=\(limit)") else {
            throw APIError.invalidURL
        }

        let response: FDAEventResponse = try await request(url: url)
        return response.results?.map { event in
            AdverseEvent(
                safetyReportId: event.safetyreportid ?? "unknown",
                reactions: event.patient?.reaction?.compactMap { $0.reactionmeddrapt } ?? [],
                serious: event.serious == "1"
            )
        } ?? []
    }
}

// MARK: - Healthcare Errors

enum HealthcareError: LocalizedError {
    case medicationNotFound
    case symptomAssessmentFailed
    case providerSearchFailed
    case appointmentBookingFailed
    case invalidInsurance

    var errorDescription: String? {
        switch self {
        case .medicationNotFound: return "Medication not found in FDA database"
        case .symptomAssessmentFailed: return "Unable to assess symptoms"
        case .providerSearchFailed: return "Failed to search for providers"
        case .appointmentBookingFailed: return "Failed to book appointment"
        case .invalidInsurance: return "Invalid insurance information"
        }
    }
}

// MARK: - FDA Response Types

struct FDAResponse: Codable {
    let meta: FDAMeta?
    let results: [FDADrugLabel]?
}

struct FDAMeta: Codable {
    let results: FDAResultInfo?
    struct FDAResultInfo: Codable {
        let total: Int?
    }
}

struct FDADrugLabel: Codable {
    let activeIngredient: [String]?
    let warnings: [String]?
    let dosageAndAdministration: [String]?
    let openfda: OpenFDAInfo?

    enum CodingKeys: String, CodingKey {
        case activeIngredient = "active_ingredient"
        case warnings
        case dosageAndAdministration = "dosage_and_administration"
        case openfda
    }
}

struct OpenFDAInfo: Codable {
    let brandName: [String]?
    let genericName: [String]?

    enum CodingKeys: String, CodingKey {
        case brandName = "brand_name"
        case genericName = "generic_name"
    }
}

struct FDAEventResponse: Codable {
    let results: [FDAEvent]?
}

struct FDAEvent: Codable {
    let safetyreportid: String?
    let serious: String?
    let patient: FDAPatient?
}

struct FDAPatient: Codable {
    let reaction: [FDAReaction]?
}

struct FDAReaction: Codable {
    let reactionmeddrapt: String?
}

struct AdverseEvent: Codable {
    let safetyReportId: String
    let reactions: [String]
    let serious: Bool
}
