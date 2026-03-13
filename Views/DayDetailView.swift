import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) var dismiss

    let date: Date

    private var scheduledHabits: [Habit] {
        store.habits.filter { $0.isScheduled(on: date) }
    }

    private var isPast: Bool {
        !Calendar.current.isDateInToday(date) && date < Date()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0C0C0E")!.ignoresSafeArea()

                Group {
                    if scheduledHabits.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "#8E8E93")!)
                            Text("No habits scheduled")
                                .foregroundColor(Color(hex: "#8E8E93")!)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(scheduledHabits) { habit in
                                HabitRowView(
                                    habit: habit,
                                    date: date,
                                    isPast: isPast
                                )
                                .listRowBackground(Color(hex: "#1C1C1E")!)
                                .listRowSeparatorTint(Color.white.opacity(0.08))
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#30D158")!)
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

struct HabitRowView: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit
    let date: Date
    let isPast: Bool

    private var isCompleted: Bool {
        store.isCompleted(habitID: habit.id, date: date)
    }

    private var isAutoLogged: Bool {
        store.isAutoLogged(habitID: habit.id, date: date)
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(habit.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .foregroundColor(.white)
                    .font(.body)

                if isAutoLogged {
                    Text("Auto-logged from Health")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "#8E8E93")!)
                }
            }

            Spacer()

            Button {
                store.toggleLog(habitID: habit.id, date: date)
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? Color(hex: "#30D158")! : Color(hex: "#8E8E93")!)
            }
            .buttonStyle(.plain)
            .disabled(date > Date())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DayDetailView(date: Date())
        .environmentObject({
            let s = HabitStore()
            s.habits = Habit.sampleData()
            return s
        }())
}
