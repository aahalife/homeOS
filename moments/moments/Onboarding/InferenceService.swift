import Contacts
import CoreLocation
import EventKit
import Foundation
import Photos
import UIKit
import UserNotifications

final class InferenceService: NSObject, CLLocationManagerDelegate {
    static let shared = InferenceService()

    private let contactStore = CNContactStore()
    private let eventStore = EKEventStore()
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func run() async {
        let permissions = await gatherPermissionStates()
        let contacts = fetchContacts(limit: 200)
        let events = fetchEvents(daysBack: 7, daysForward: 21, limit: 200)
        let location = await fetchLocationIfAuthorized()
        let photosOptIn = isPhotosAuthorized()

        let snapshot = InferenceSnapshot(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            device: DeviceMetadata.current(),
            permissions: permissions,
            contacts: contacts,
            events: events,
            location: location,
            photosOptIn: photosOptIn
        )

        saveSnapshot(snapshot)
        await sendSnapshot(snapshot)
    }

    // MARK: - Contacts

    private func fetchContacts(limit: Int) -> [InferredContact] {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        guard status == .authorized else { return [] }

        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactRelationsKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor
        ]

        var results: [InferredContact] = []
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.unifyResults = true

        do {
            try contactStore.enumerateContacts(with: request) { contact, stop in
                if results.count >= limit {
                    stop.pointee = true
                    return
                }

                let relationNames = contact.contactRelations.map { $0.value.name.lowercased() }
                let candidate = isFamilyRelation(relationNames)

                let phoneLast4 = contact.phoneNumbers
                    .compactMap { $0.value.stringValue.filter(\.isNumber) }
                    .compactMap { $0.count >= 4 ? String($0.suffix(4)) : nil }

                let emailDomains = contact.emailAddresses
                    .map { String($0.value) }
                    .compactMap { $0.split(separator: "@").last.map(String.init) }

                let displayName = [contact.givenName, contact.familyName]
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespaces)

                results.append(
                    InferredContact(
                        identifier: contact.identifier,
                        displayName: displayName.isEmpty ? contact.organizationName : displayName,
                        relationHints: relationNames,
                        isFamilyCandidate: candidate,
                        phoneLast4: phoneLast4,
                        emailDomains: emailDomains
                    )
                )
            }
        } catch {
            print("Contact inference error: \(error)")
        }

        return results
    }

    private func isFamilyRelation(_ relations: [String]) -> Bool {
        let keywords = ["spouse", "wife", "husband", "partner", "child", "son", "daughter", "parent", "mom", "dad"]
        return relations.contains { relation in
            keywords.contains { relation.contains($0) }
        }
    }

    // MARK: - Calendar

    private func fetchEvents(daysBack: Int, daysForward: Int, limit: Int) -> [InferredEvent] {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .authorized || status == .fullAccess else { return [] }

        let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let end = Calendar.current.date(byAdding: .day, value: daysForward, to: Date()) ?? Date()

        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = eventStore.events(matching: predicate).prefix(limit)

        return events.map { event in
            InferredEvent(
                title: event.title ?? "Untitled",
                startDate: ISO8601DateFormatter().string(from: event.startDate),
                endDate: ISO8601DateFormatter().string(from: event.endDate),
                isAllDay: event.isAllDay,
                location: event.location,
                calendarName: event.calendar.title,
                hasRecurrence: event.hasRecurrenceRules
            )
        }
    }

    // MARK: - Location

    private func fetchLocationIfAuthorized() async -> InferredLocation? {
        let status = CLLocationManager.authorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return nil }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
        .map { location in
            InferredLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracyMeters: location.horizontalAccuracy,
                timestamp: ISO8601DateFormatter().string(from: location.timestamp)
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.first)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location inference error: \(error)")
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }

    // MARK: - Photos

    private func isPhotosAuthorized() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    // MARK: - Permissions Summary

    private func gatherPermissionStates() async -> [String: String] {
        var states: [String: String] = [:]
        states["contacts"] = map(CNContactStore.authorizationStatus(for: .contacts)).rawValue
        states["calendar"] = map(EKEventStore.authorizationStatus(for: .event)).rawValue
        states["location"] = map(CLLocationManager.authorizationStatus()).rawValue
        states["photos"] = map(PHPhotoLibrary.authorizationStatus(for: .readWrite)).rawValue
        states["health"] = HealthKitManager.shared.permissionState().rawValue

        let notificationSettings = await getNotificationSettings()
        states["notifications"] = map(notificationSettings.authorizationStatus).rawValue

        return states
    }

    private func getNotificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func map(_ status: CNAuthorizationStatus) -> PermissionState {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }

    private func map(_ status: EKAuthorizationStatus) -> PermissionState {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized, .fullAccess: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .writeOnly: return .limited
        @unknown default: return .notDetermined
        }
    }

    private func map(_ status: CLAuthorizationStatus) -> PermissionState {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }

    private func map(_ status: UNAuthorizationStatus) -> PermissionState {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        @unknown default: return .notDetermined
        }
    }

    private func map(_ status: PHAuthorizationStatus) -> PermissionState {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }

    // MARK: - Persistence + Sync

    private func saveSnapshot(_ snapshot: InferenceSnapshot) {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("inference_snapshot.json") else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url)
        } catch {
            print("Failed to save inference snapshot: \(error)")
        }
    }

    private func sendSnapshot(_ snapshot: InferenceSnapshot) async {
        do {
            try await ControlPlaneClient.shared.sendInference(snapshot)
        } catch {
            print("Inference sync failed: \(error)")
        }
    }
}

// MARK: - Models

struct InferenceSnapshot: Codable {
    let timestamp: String
    let device: DeviceMetadata
    let permissions: [String: String]
    let contacts: [InferredContact]
    let events: [InferredEvent]
    let location: InferredLocation?
    let photosOptIn: Bool
}

struct DeviceMetadata: Codable {
    let deviceId: String?
    let model: String
    let systemVersion: String
    let appVersion: String

    static func current() -> DeviceMetadata {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        return DeviceMetadata(
            deviceId: UIDevice.current.identifierForVendor?.uuidString,
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: version
        )
    }
}

struct InferredContact: Codable {
    let identifier: String
    let displayName: String
    let relationHints: [String]
    let isFamilyCandidate: Bool
    let phoneLast4: [String]
    let emailDomains: [String]
}

struct InferredEvent: Codable {
    let title: String
    let startDate: String
    let endDate: String
    let isAllDay: Bool
    let location: String?
    let calendarName: String
    let hasRecurrence: Bool
}

struct InferredLocation: Codable {
    let latitude: Double
    let longitude: Double
    let accuracyMeters: Double
    let timestamp: String
}

// MARK: - Control Plane Client

enum ControlPlaneClientError: Error {
    case missingBaseURL
    case badResponse
}

final class ControlPlaneClient {
    static let shared = ControlPlaneClient()

    private init() {}

    func sendInference(_ snapshot: InferenceSnapshot) async throws {
        guard let baseURLString = Bundle.main.infoDictionary?["ControlPlaneBaseURL"] as? String,
              !baseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: baseURLString)?.appendingPathComponent("/v1/onboarding/inference") else {
            print("Control plane base URL missing; skipping inference upload.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainStore.shared.getString(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(snapshot)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw ControlPlaneClientError.badResponse
        }
    }

    func sendFamilyMembers(_ members: [FamilyMemberProfile]) async throws {
        guard let baseURLString = Bundle.main.infoDictionary?["ControlPlaneBaseURL"] as? String,
              !baseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: baseURLString)?.appendingPathComponent("/v1/onboarding/family") else {
            print("Control plane base URL missing; skipping family upload.")
            return
        }

        guard let workspaceId = UserDefaults.standard.string(forKey: "workspaceId"), !workspaceId.isEmpty else {
            print("Workspace ID missing; skipping family upload.")
            return
        }

        let payload = FamilyUploadPayload(
            workspaceId: workspaceId,
            members: members.map { member in
                FamilyUploadMember(
                    name: member.name,
                    role: member.role.rawValue,
                    age: member.age
                )
            }
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainStore.shared.getString(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw ControlPlaneClientError.badResponse
        }
    }

    func sendOnboardingPreferences(_ prefs: OnboardingPreferences) async {
        guard let baseURLString = Bundle.main.infoDictionary?["ControlPlaneBaseURL"] as? String,
              !baseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let baseURL = URL(string: baseURLString) else {
            print("Control plane base URL missing; skipping preference upload.")
            return
        }

        guard let workspaceId = UserDefaults.standard.string(forKey: "workspaceId"), !workspaceId.isEmpty else {
            print("Workspace ID missing; skipping preference upload.")
            return
        }

        let approvals = PreferencesUpdatePayload(preferences: ApprovalPreferences(autoApproveBelow: prefs.autoApproveBelow))
        let notifications = PreferencesUpdatePayload(
            preferences: NotificationPreferences(
                quietHoursEnabled: true,
                quietHoursStart: prefs.quietHoursStart,
                quietHoursEnd: prefs.quietHoursEnd,
                morningBriefTime: prefs.morningBriefTime
            )
        )
        let general = PreferencesUpdatePayload(
            preferences: GeneralPreferences(
                dietaryRestrictions: prefs.dietaryRestrictions,
                emergencyContactName: prefs.emergencyContactName,
                emergencyContactPhone: prefs.emergencyContactPhone
            )
        )

        do {
            try await sendPreferences(baseURL: baseURL, category: "approvals", workspaceId: workspaceId, payload: approvals)
            try await sendPreferences(baseURL: baseURL, category: "notifications", workspaceId: workspaceId, payload: notifications)
            try await sendPreferences(baseURL: baseURL, category: "general", workspaceId: workspaceId, payload: general)
        } catch {
            print("Preference sync failed: \(error)")
        }
    }

    private func sendPreferences<T: Encodable>(
        baseURL: URL,
        category: String,
        workspaceId: String,
        payload: T
    ) async throws {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/v1/preferences/\(category)"), resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "workspaceId", value: workspaceId)]
        guard let url = urlComponents?.url else {
            throw ControlPlaneClientError.missingBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainStore.shared.getString(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw ControlPlaneClientError.badResponse
        }
    }
}

private struct FamilyUploadPayload: Codable {
    let workspaceId: String
    let members: [FamilyUploadMember]
}

private struct FamilyUploadMember: Codable {
    let name: String
    let role: String
    let age: Int?
}

private struct PreferencesUpdatePayload<T: Encodable>: Encodable {
    let preferences: T
}

private struct ApprovalPreferences: Encodable {
    let autoApproveBelow: Double
}

private struct NotificationPreferences: Encodable {
    let quietHoursEnabled: Bool
    let quietHoursStart: String
    let quietHoursEnd: String
    let morningBriefTime: String
}

private struct GeneralPreferences: Encodable {
    let dietaryRestrictions: [String]
    let emergencyContactName: String?
    let emergencyContactPhone: String?
}
