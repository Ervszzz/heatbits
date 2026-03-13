import Foundation
import UserNotifications

class SmartReminderEngine {
    static let shared = SmartReminderEngine()
    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReminders(for habits: [Habit], store: HabitStore) async {
        let center = UNUserNotificationCenter.current()
        // Remove existing scheduled reminders
        center.removePendingNotificationRequests(withIdentifiers:
            habits.map { "reminder_\($0.id.uuidString)" }
        )

        let hour = Calendar.current.component(.hour, from: Date())
        let isQuietHours = hour >= 22 || hour < 7

        for habit in habits where habit.reminderEnabled {
            let triggerDate = habit.reminderTime
            let components = Calendar.current.dateComponents([.hour, .minute], from: triggerDate)
            guard let h = components.hour else { continue }
            // Respect quiet hours
            if h >= 22 || h < 7 { continue }

            let content = UNMutableNotificationContent()
            content.title = "HeatBits"
            content.body = "Don't forget: \(habit.emoji) \(habit.name)"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "reminder_\(habit.id.uuidString)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }

        if !isQuietHours {
            await scheduleSmartReminders(for: habits, store: store)
        }
    }

    private func scheduleSmartReminders(for habits: [Habit], store: HabitStore) async {
        let center = UNUserNotificationCenter.current()
        let now = Date()
        let cal = Calendar.current

        for habit in habits {
            guard !store.isCompleted(habitID: habit.id, date: now) else { continue }

            // Calculate usual window from last 14 days
            var completionHours: [Int] = []
            for i in 1...14 {
                guard let d = cal.date(byAdding: .day, value: -i, to: now) else { continue }
                let key = HabitLog.dayKey(for: d)
                // We can't get exact time from the store, so use reminder time as proxy
                if store.isCompleted(habitID: habit.id, date: d) {
                    let h = cal.component(.hour, from: habit.reminderTime)
                    completionHours.append(h)
                }
            }

            let windowEndHour: Int
            if completionHours.isEmpty {
                windowEndHour = cal.component(.hour, from: habit.reminderTime)
            } else {
                windowEndHour = (completionHours.reduce(0, +) / completionHours.count) + 1
            }

            let currentHour = cal.component(.hour, from: now)
            let currentMinute = cal.component(.minute, from: now)
            let minutesPastWindow = (currentHour * 60 + currentMinute) - (windowEndHour * 60)

            guard minutesPastWindow >= 30 else { continue }
            guard windowEndHour < 22 else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(habit.emoji) \(habit.name)"
            content.body = "You usually do this by now. Keep your streak going!"
            content.sound = .default

            let fireDate = cal.date(byAdding: .minute, value: 1, to: now) ?? now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let request = UNNotificationRequest(
                identifier: "smart_\(habit.id.uuidString)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}
