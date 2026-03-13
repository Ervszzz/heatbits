import Foundation
import Combine

class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var logs: [HabitLog] = []

    private let saveKey = "heatmaphabits_v1"
    private let logsKey = "heatmaphabits_logs_v1"

    struct SaveData: Codable {
        var habits: [Habit]
        var logs: [HabitLog]
    }

    init() {
        load()
    }

    // MARK: - Persistence

    func save() {
        let data = SaveData(habits: habits, logs: logs)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode(SaveData.self, from: data) else {
            return
        }
        habits = decoded.habits
        logs = decoded.logs
    }

    // MARK: - Habits CRUD

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        save()
    }

    func updateHabit(_ habit: Habit) {
        if let idx = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[idx] = habit
            save()
        }
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        logs.removeAll { $0.habitID == habit.id }
        save()
    }

    // MARK: - Logging

    func toggleLog(habitID: UUID, date: Date, isAutoLogged: Bool = false) {
        let key = HabitLog.dayKey(for: date)
        if let idx = logs.firstIndex(where: { $0.habitID == habitID && $0.dayKey == key }) {
            logs[idx].isCompleted.toggle()
        } else {
            let log = HabitLog(habitID: habitID, date: date.startOfDay, isCompleted: true, isAutoLogged: isAutoLogged)
            logs.append(log)
        }
        save()
    }

    func setLog(habitID: UUID, date: Date, completed: Bool, isAutoLogged: Bool = false) {
        let key = HabitLog.dayKey(for: date)
        if let idx = logs.firstIndex(where: { $0.habitID == habitID && $0.dayKey == key }) {
            logs[idx].isCompleted = completed
            logs[idx].isAutoLogged = isAutoLogged
        } else if completed {
            let log = HabitLog(habitID: habitID, date: date.startOfDay, isCompleted: true, isAutoLogged: isAutoLogged)
            logs.append(log)
        }
        save()
    }

    func isCompleted(habitID: UUID, date: Date) -> Bool {
        let key = HabitLog.dayKey(for: date)
        return logs.first(where: { $0.habitID == habitID && $0.dayKey == key })?.isCompleted ?? false
    }

    func isAutoLogged(habitID: UUID, date: Date) -> Bool {
        let key = HabitLog.dayKey(for: date)
        return logs.first(where: { $0.habitID == habitID && $0.dayKey == key })?.isAutoLogged ?? false
    }

    // MARK: - Queries

    /// Returns scheduled habits for a date and completion fraction (0.0–1.0)
    func completionRate(for date: Date) -> Double {
        let scheduled = habits.filter { $0.isScheduled(on: date) }
        guard !scheduled.isEmpty else { return 0 }
        let done = scheduled.filter { isCompleted(habitID: $0.id, date: date) }.count
        return Double(done) / Double(scheduled.count)
    }

    func completionRate(forMonth date: Date) -> Double {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date) else { return 0 }
        let startOfMonth = date.startOfMonth
        var total = 0.0
        var count = 0
        for day in range {
            guard let d = cal.date(byAdding: .day, value: day - 1, to: startOfMonth) else { continue }
            let scheduled = habits.filter { $0.isScheduled(on: d) }
            guard !scheduled.isEmpty else { continue }
            let done = scheduled.filter { isCompleted(habitID: $0.id, date: d) }.count
            total += Double(done) / Double(scheduled.count)
            count += 1
        }
        return count > 0 ? total / Double(count) : 0
    }

    /// 30-day completion rate per habit
    func thirtyDayRate(for habit: Habit) -> Double {
        let cal = Calendar.current
        let today = Date()
        var completed = 0
        var scheduled = 0
        for i in 0..<30 {
            guard let d = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            if habit.isScheduled(on: d) {
                scheduled += 1
                if isCompleted(habitID: habit.id, date: d) { completed += 1 }
            }
        }
        return scheduled > 0 ? Double(completed) / Double(scheduled) : 0
    }

    func currentStreak(for habit: Habit) -> Int {
        let cal = Calendar.current
        var streak = 0
        var date = Date()
        while true {
            if habit.isScheduled(on: date) {
                if isCompleted(habitID: habit.id, date: date) {
                    streak += 1
                } else {
                    break
                }
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
            if streak > 365 { break }
        }
        return streak
    }

    func bestStreak(for habit: Habit) -> Int {
        let cal = Calendar.current
        var best = 0
        var current = 0
        // Check last 365 days
        var dates: [Date] = []
        for i in (0..<365).reversed() {
            if let d = cal.date(byAdding: .day, value: -i, to: Date()) {
                dates.append(d)
            }
        }
        for d in dates {
            if habit.isScheduled(on: d) {
                if isCompleted(habitID: habit.id, date: d) {
                    current += 1
                    best = max(best, current)
                } else {
                    current = 0
                }
            }
        }
        return best
    }

    /// Weekly completion counts for last 7 weeks (oldest first)
    func weeklyData(for habit: Habit) -> [Int] {
        let cal = Calendar.current
        var result: [Int] = []
        for week in (0..<7).reversed() {
            var count = 0
            for day in 0..<7 {
                let offset = -(week * 7 + day)
                if let d = cal.date(byAdding: .day, value: offset, to: Date()),
                   habit.isScheduled(on: d),
                   isCompleted(habitID: habit.id, date: d) {
                    count += 1
                }
            }
            result.append(count)
        }
        return result
    }

    func totalCompletions(for habit: Habit) -> Int {
        logs.filter { $0.habitID == habit.id && $0.isCompleted }.count
    }

    func longestStreakEver() -> (habit: Habit?, streak: Int) {
        var best = 0
        var bestHabit: Habit? = nil
        for habit in habits {
            let s = bestStreak(for: habit)
            if s > best { best = s; bestHabit = habit }
        }
        return (bestHabit, best)
    }

    func todayScheduledCount() -> Int {
        habits.filter { $0.isScheduled(on: Date()) }.count
    }

    func todayCompletedCount() -> Int {
        habits.filter { $0.isScheduled(on: Date()) && isCompleted(habitID: $0.id, date: Date()) }.count
    }

    func logHabit(named name: String) -> Bool {
        guard let habit = habits.first(where: {
            $0.name.lowercased() == name.lowercased()
        }) else { return false }
        setLog(habitID: habit.id, date: Date(), completed: true)
        return true
    }
}
