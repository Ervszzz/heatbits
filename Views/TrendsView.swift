import SwiftUI

struct TrendsView: View {
    @EnvironmentObject var store: HabitStore
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0C0C0E")!.ignoresSafeArea()

                if store.habits.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#8E8E93")!)
                        Text("Add habits to see trends")
                            .foregroundColor(Color(hex: "#8E8E93")!)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            overallStatsCard
                            ForEach(store.habits) { habit in
                                HabitTrendCard(habit: habit)
                                    .environmentObject(store)
                                    .environmentObject(themeManager)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var overallStatsCard: some View {
        let (bestHabit, bestStreak) = store.longestStreakEver()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Overall")
                .font(.caption)
                .foregroundColor(Color(hex: "#8E8E93")!)
            HStack(spacing: 0) {
                statItem(label: "Longest Streak", value: "\(bestStreak)d",
                         sub: bestHabit.map { "\($0.emoji) \($0.name)" } ?? "—")
                Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                statItem(label: "Total Logs",
                         value: "\(store.logs.filter { $0.isCompleted }.count)", sub: "all time")
                Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                statItem(label: "Habits", value: "\(store.habits.count)", sub: "tracked")
            }
        }
        .padding(16)
        .background(Color(hex: "#1C1C1E")!)
        .cornerRadius(12)
    }

    private func statItem(label: String, value: String, sub: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(themeManager.theme.accentColor)
            Text(label)
                .font(.caption2)
                .foregroundColor(Color(hex: "#8E8E93")!)
            Text(sub)
                .font(.caption2)
                .foregroundColor(Color(hex: "#636366")!)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HabitTrendCard: View {
    @EnvironmentObject var store: HabitStore
    @EnvironmentObject var themeManager: ThemeManager
    let habit: Habit

    private var rate: Double { store.thirtyDayRate(for: habit) }
    private var current: Int { store.currentStreak(for: habit) }
    private var best: Int { store.bestStreak(for: habit) }
    private var weekly: [Int] { store.weeklyData(for: habit) }
    private var total: Int { store.totalCompletions(for: habit) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(habit.emoji)
                    .font(.title2)
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(rate * 100))%")
                    .font(.headline.bold())
                    .foregroundColor(themeManager.theme.accentColor)
            }

            // 30-day progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#2C2C2E")!)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.theme.accentColor)
                        .frame(width: geo.size.width * rate, height: 8)
                }
            }
            .frame(height: 8)

            // Streaks + totals
            HStack(spacing: 0) {
                streakLabel(title: "Current", value: "\(current)d")
                streakLabel(title: "Best", value: "\(best)d")
                streakLabel(title: "Total", value: "\(total)")
            }

            // Weekly bar chart
            WeeklyBarChart(data: weekly, color: themeManager.theme.accentColor)
        }
        .padding(16)
        .background(Color(hex: "#1C1C1E")!)
        .cornerRadius(12)
    }

    private func streakLabel(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color(hex: "#8E8E93")!)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WeeklyBarChart: View {
    let data: [Int] // counts per week, oldest first
    let color: Color

    private var maxValue: Int { max(data.max() ?? 1, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Last 7 Weeks")
                .font(.caption)
                .foregroundColor(Color(hex: "#8E8E93")!)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, value in
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color.opacity(value == 0 ? 0.2 : 0.85))
                                .frame(height: max(4, geo.size.height * CGFloat(value) / CGFloat(maxValue)))
                        }
                    }
                }
            }
            .frame(height: 60)
        }
    }
}

#Preview {
    TrendsView()
        .environmentObject({
            let s = HabitStore()
            s.habits = Habit.sampleData()
            return s
        }())
        .environmentObject(ThemeManager())
}
