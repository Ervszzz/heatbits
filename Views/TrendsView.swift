import SwiftUI

struct TrendsView: View {
    @EnvironmentObject var store: HabitStore

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
                            ForEach(store.habits) { habit in
                                HabitTrendCard(habit: habit)
                                    .environmentObject(store)
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
}

struct HabitTrendCard: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit

    private var rate: Double { store.thirtyDayRate(for: habit) }
    private var current: Int { store.currentStreak(for: habit) }
    private var best: Int { store.bestStreak(for: habit) }
    private var weekly: [Int] { store.weeklyData(for: habit) }

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
                    .foregroundColor(Color(hex: "#30D158")!)
            }

            // 30-day progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#2C2C2E")!)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: habit.colorHex) ?? Color(hex: "#30D158")!)
                        .frame(width: geo.size.width * rate, height: 8)
                }
            }
            .frame(height: 8)

            // Streaks
            HStack(spacing: 24) {
                streakLabel(title: "Current Streak", value: current)
                streakLabel(title: "Best Streak", value: best)
            }

            // Weekly bar chart
            WeeklyBarChart(data: weekly, color: Color(hex: habit.colorHex) ?? Color(hex: "#30D158")!)
        }
        .padding(16)
        .background(Color(hex: "#1C1C1E")!)
        .cornerRadius(12)
    }

    private func streakLabel(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color(hex: "#8E8E93")!)
            Text("\(value) day\(value == 1 ? "" : "s")")
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
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
}
