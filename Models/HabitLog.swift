import Foundation

struct HabitLog: Identifiable, Codable {
    var id: UUID = UUID()
    var habitID: UUID
    var date: Date
    var isCompleted: Bool
    var isAutoLogged: Bool // true = came from HealthKit

    var dayKey: String {
        HabitLog.dayKey(for: date)
    }

    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
