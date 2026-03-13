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

    func scheduleDailySummary(store: HabitStore) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_summary"])

        let completed = store.todayCompletedCount()
        let total = store.todayScheduledCount()
        guard total > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "HeatBits Daily Summary"
        content.body = completed == total
            ? "🎉 You completed all \(total) habits today!"
            : "You completed \(completed)/\(total) habits today. Finish strong!"
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 21
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_summary", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func checkStreakMilestones(for habit: Habit, store: HabitStore) async {
        let milestones = [7, 14, 30, 60, 100]
        let streak = store.currentStreak(for: habit)
        guard milestones.contains(streak) else { return }

        let center = UNUserNotificationCenter.current()
        let id = "streak_\(habit.id.uuidString)_\(streak)"

        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()
        let alreadySent = pending.contains { $0.identifier == id } ||
                          delivered.contains { $0.request.identifier == id }
        guard !alreadySent else { return }

        let content = UNMutableNotificationContent()
        content.title = "🔥 \(streak)-Day Streak!"
        content.body = "\(habit.emoji) \(habit.name) — keep it up!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
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
