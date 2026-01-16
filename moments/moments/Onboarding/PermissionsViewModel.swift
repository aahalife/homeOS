import Contacts
import CoreLocation
import EventKit
import Photos
import Combine
import HealthKit
import SwiftUI
import UIKit
import UserNotifications

enum PermissionType: String, CaseIterable, Identifiable {
    case contacts
    case calendar
    case location
    case notifications
    case health
    case photos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .contacts: return "Contacts"
        case .calendar: return "Calendar"
        case .location: return "Location"
        case .notifications: return "Notifications"
        case .health: return "Health"
        case .photos: return "Photos (Optional)"
        }
    }

    var rationale: String {
        switch self {
        case .contacts:
            return "Find your family members and invite them."
        case .calendar:
            return "Understand schedules and coordinate events."
        case .location:
            return "Identify home, work, and school context."
        case .notifications:
            return "Send approvals, reminders, and updates."
        case .health:
            return "Read sleep and wellness signals to personalize quiet hours."
        case .photos:
            return "Optional: improve family recognition (opt-in)."
        }
    }

    var systemIcon: String {
        switch self {
        case .contacts: return "person.2.fill"
        case .calendar: return "calendar"
        case .location: return "location.fill"
        case .notifications: return "bell.fill"
        case .health: return "heart.fill"
        case .photos: return "photo.on.rectangle"
        }
    }

    var isCore: Bool {
        self != .photos
    }
}

enum PermissionState: String {
    case notDetermined = "Not asked"
    case authorized = "Allowed"
    case denied = "Denied"
    case restricted = "Restricted"
    case limited = "Limited"
}

@MainActor
final class PermissionsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var states: [PermissionType: PermissionState] = [:]
    @Published private(set) var skipped: Set<PermissionType> = []

    private let contactStore = CNContactStore()
    private let eventStore = EKEventStore()
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        refreshAll()
    }

    var isCoreResolved: Bool {
        PermissionType.allCases
            .filter { $0.isCore }
            .allSatisfy { states[$0] != .notDetermined || skipped.contains($0) }
    }

    func refreshAll() {
        updateContacts()
        updateCalendar()
        updateLocation()
        updateNotifications()
        updateHealth()
        updatePhotos()
    }

    func request(_ type: PermissionType) {
        switch type {
        case .contacts:
            contactStore.requestAccess(for: .contacts) { [weak self] _, _ in
                Task { @MainActor in self?.updateContacts() }
            }
        case .calendar:
            eventStore.requestAccess(to: .event) { [weak self] _, _ in
                Task { @MainActor in self?.updateCalendar() }
            }
        case .location:
            locationManager.requestWhenInUseAuthorization()
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
                Task { @MainActor in
                    self?.updateNotifications()
                    if granted {
                        PushNotificationManager.shared.registerForRemoteNotifications()
                    }
                }
            }
        case .health:
            HealthKitManager.shared.requestAuthorization { [weak self] _ in
                Task { @MainActor in self?.updateHealth() }
            }
        case .photos:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] _ in
                Task { @MainActor in self?.updatePhotos() }
            }
        }
    }

    func skip(_ type: PermissionType) {
        skipped.insert(type)
        objectWillChange.send()
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Authorization State Updates

    private func updateContacts() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        states[.contacts] = map(status)
    }

    private func updateCalendar() {
        let status = EKEventStore.authorizationStatus(for: .event)
        states[.calendar] = map(status)
    }

    private func updateLocation() {
        let status = CLLocationManager.authorizationStatus()
        states[.location] = map(status)
    }

    private func updateNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.states[.notifications] = self?.map(settings.authorizationStatus) ?? .notDetermined
            }
        }
    }

    private func updateHealth() {
        states[.health] = HealthKitManager.shared.permissionState()
    }

    private func updatePhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        states[.photos] = map(status)
    }

    // MARK: - Mappers

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
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .fullAccess: return .authorized
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

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateLocation()
    }
}
