import SwiftUI

@main
struct HeatBitsApp: App {
    @StateObject private var habitStore = HabitStore()
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                .task {
                    await healthKitManager.requestAuthorization()
                    await autoLogHealthKitHabits()
                    await SmartReminderEngine.shared.requestAuthorization()
                    await SmartReminderEngine.shared.scheduleReminders(
                        for: habitStore.habits,
                        store: habitStore
                    )
                    HabitStoreProvider.shared.configure(with: habitStore)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await autoLogHealthKitHabits()
                        await SmartReminderEngine.shared.scheduleReminders(
                            for: habitStore.habits,
                            store: habitStore
                        )
                    }
                }
        }
    }

    private func autoLogHealthKitHabits() async {
        guard healthKitManager.isAuthorized else { return }
        await healthKitManager.autoLog(habits: habitStore.habits, store: habitStore, for: Date())
    }
}
