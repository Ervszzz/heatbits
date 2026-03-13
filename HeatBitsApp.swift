import SwiftUI

@main
struct HeatBitsApp: App {
    @StateObject private var habitStore = HabitStore()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                .environmentObject(themeManager)
                .task {
                    await healthKitManager.requestAuthorization()
                    await autoLogHealthKitHabits()
                    await SmartReminderEngine.shared.requestAuthorization()
                    await SmartReminderEngine.shared.scheduleReminders(
                        for: habitStore.habits,
                        store: habitStore
                    )
                    await SmartReminderEngine.shared.scheduleDailySummary(store: habitStore)
                    HabitStoreProvider.shared.configure(with: habitStore)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await autoLogHealthKitHabits()
                        await SmartReminderEngine.shared.scheduleReminders(
                            for: habitStore.habits,
                            store: habitStore
                        )
                        await SmartReminderEngine.shared.scheduleDailySummary(store: habitStore)
                    }
                }
        }
    }

    private func autoLogHealthKitHabits() async {
        guard healthKitManager.isAuthorized else { return }
        await healthKitManager.autoLog(habits: habitStore.habits, store: habitStore, for: Date())
    }
}
