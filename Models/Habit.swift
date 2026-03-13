import Foundation
import SwiftUI

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case custom = "Custom"
}

enum HealthKitLink: String, Codable, CaseIterable {
    case none = "None"
    case steps = "Steps > 5,000"
    case sleep = "Sleep > 7hrs"
    case workout = "Workout Logged"
}

struct Habit: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var emoji: String
    var colorHex: String
    var reminderEnabled: Bool
    var reminderTime: Date
    var healthKitLink: HealthKitLink
    var frequency: HabitFrequency
    var customDays: Set<Int> // 1 = Sunday, 7 = Saturday

    var color: Color {
        Color(hex: colorHex) ?? .green
    }

    static let presetColors: [String] = [
        "#30D158", "#FF6B6B", "#FFD60A", "#0A84FF",
        "#BF5AF2", "#FF9F0A", "#32ADE6", "#FF375F"
    ]

    static func sampleData() -> [Habit] {
        [
            Habit(
                name: "Morning Run",
                emoji: "🏃",
                colorHex: "#30D158",
                reminderEnabled: true,
                reminderTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!,
                healthKitLink: .workout,
                frequency: .daily,
                customDays: []
            ),
            Habit(
                name: "Read",
                emoji: "📚",
                colorHex: "#0A84FF",
                reminderEnabled: true,
                reminderTime: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!,
                healthKitLink: .none,
                frequency: .daily,
                customDays: []
            ),
            Habit(
                name: "10k Steps",
                emoji: "👟",
                colorHex: "#FFD60A",
                reminderEnabled: false,
                reminderTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!,
                healthKitLink: .steps,
                frequency: .daily,
                customDays: []
            ),
            Habit(
                name: "Sleep Early",
                emoji: "😴",
                colorHex: "#BF5AF2",
                reminderEnabled: true,
                reminderTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!,
                healthKitLink: .sleep,
                frequency: .daily,
                customDays: []
            )
        ]
    }

    func isScheduled(on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch frequency {
        case .daily:
            return true
        case .weekdays:
            return (2...6).contains(weekday)
        case .custom:
            return customDays.contains(weekday)
        }
    }
}
