import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    @Published var isAuthorized = false

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        types.insert(HKObjectType.workoutType())
        return types
    }()

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    func fetchSteps(for date: Date) async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let start = date.startOfDay
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let count = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(count))
            }
            store.execute(query)
        }
    }

    func fetchSleepHours(for date: Date) async -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        // Look at sleep ending on this date (previous night)
        let end = date.startOfDay
        let start = Calendar.current.date(byAdding: .hour, value: -12, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let total = (samples as? [HKCategorySample])?
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                              $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                              $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                              $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 3600 }
                    ?? 0
                continuation.resume(returning: total)
            }
            store.execute(query)
        }
    }

    func fetchWorkoutLogged(for date: Date) async -> Bool {
        let start = date.startOfDay
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: !(samples?.isEmpty ?? true))
            }
            store.execute(query)
        }
    }

    /// Auto-log HealthKit-linked habits into the store
    func autoLog(habits: [Habit], store habitStore: HabitStore, for date: Date) async {
        for habit in habits {
            switch habit.healthKitLink {
            case .none: continue
            case .steps:
                let steps = await fetchSteps(for: date)
                if steps > 5000 {
                    habitStore.setLog(habitID: habit.id, date: date, completed: true, isAutoLogged: true)
                }
            case .sleep:
                let hours = await fetchSleepHours(for: date)
                if hours >= 7 {
                    habitStore.setLog(habitID: habit.id, date: date, completed: true, isAutoLogged: true)
                }
            case .workout:
                let worked = await fetchWorkoutLogged(for: date)
                if worked {
                    habitStore.setLog(habitID: habit.id, date: date, completed: true, isAutoLogged: true)
                }
            }
        }
    }
}
