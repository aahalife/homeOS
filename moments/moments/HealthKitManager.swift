import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    private init() {}

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func permissionState() -> PermissionState {
        guard isAvailable, let sleepType = sleepType else { return .restricted }
        let status = store.authorizationStatus(for: sleepType)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .sharingAuthorized:
            return .authorized
        case .sharingDenied:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }
        store.requestAuthorization(toShare: [], read: readTypes) { success, error in
            completion(success && error == nil)
        }
    }

    func fetchSleepWindow(days: Int = 7) async -> SleepWindow? {
        guard isAvailable,
              permissionState() == .authorized,
              let sleepType = sleepType else { return nil }

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: sort) { _, samples, error in
                guard error == nil, let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                let sleepSamples = samples
                    .filter(isAsleepSample)
                    .filter { $0.endDate.timeIntervalSince($0.startDate) >= 60 * 60 }

                guard !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let startMinutes = sleepSamples.map { bedtimeMinutes(from: $0.startDate) }
                let endMinutes = sleepSamples.map { minutes(from: $0.endDate) }

                let medianStart = median(of: startMinutes)
                let medianEnd = median(of: endMinutes)

                let startDate = date(from: medianStart)
                let endDate = date(from: medianEnd)

                continuation.resume(
                    returning: SleepWindow(
                        start: startDate,
                        end: endDate,
                        note: "Based on recent Apple Health sleep data."
                    )
                )
            }
            store.execute(query)
        }
    }

    private var sleepType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let sleepType {
            types.insert(sleepType)
        }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        return types
    }

    private func isAsleepSample(_ sample: HKCategorySample) -> Bool {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
            return false
        }
        switch value {
        case .asleep, .asleepUnspecified:
            return true
        case .asleepCore, .asleepDeep, .asleepRem:
            return true
        case .inBed:
            return false
        case .awake:
            return false
        @unknown default:
            return false
        }
    }

    private func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func bedtimeMinutes(from date: Date) -> Int {
        let raw = minutes(from: date)
        return raw < 12 * 60 ? raw + 24 * 60 : raw
    }

    private func date(from minutes: Int) -> Date {
        let normalized = minutes % (24 * 60)
        let hour = normalized / 60
        let minute = normalized % 60
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private func median(of values: [Int]) -> Int {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        if sorted.count % 2 == 1 {
            return sorted[sorted.count / 2]
        }
        let lower = sorted[(sorted.count / 2) - 1]
        let upper = sorted[sorted.count / 2]
        return (lower + upper) / 2
    }
}

struct SleepWindow {
    let start: Date
    let end: Date
    let note: String?
}
