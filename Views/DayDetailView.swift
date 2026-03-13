import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var store: HabitStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    let date: Date

    @State private var showConfetti = false

    private var scheduledHabits: [Habit] {
        store.habits.filter { $0.isScheduled(on: date) }
    }

    private var isPast: Bool {
        !Calendar.current.isDateInToday(date) && date < Date()
    }

    private var allDone: Bool {
        !scheduledHabits.isEmpty && scheduledHabits.allSatisfy {
            store.isCompleted(habitID: $0.id, date: date)
        }
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
                                HabitRowView(habit: habit, date: date, isPast: isPast)
                                    .listRowBackground(Color(hex: "#1C1C1E")!)
                                    .listRowSeparatorTint(Color.white.opacity(0.08))
                                    .swipeActions(edge: .leading) {
                                        if date <= Date() {
                                            Button {
                                                toggleWithHaptic(habit: habit)
                                            } label: {
                                                Label(
                                                    store.isCompleted(habitID: habit.id, date: date) ? "Undo" : "Done",
                                                    systemImage: store.isCompleted(habitID: habit.id, date: date) ? "arrow.uturn.backward" : "checkmark"
                                                )
                                            }
                                            .tint(themeManager.theme.accentColor)
                                        }
                                    }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }

                if showConfetti {
                    ConfettiView(accentColor: themeManager.theme.accentColor)
                        .ignoresSafeArea()
                }
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.theme.accentColor)
                }
            }
            .onChange(of: allDone) { _, done in
                if done { triggerConfetti() }
            }
        }
    }

    private func toggleWithHaptic(habit: Habit) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        store.toggleLog(habitID: habit.id, date: date)
    }

    private func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showConfetti = false
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
    @EnvironmentObject var themeManager: ThemeManager
    let habit: Habit
    let date: Date
    let isPast: Bool

    @State private var checkScale: CGFloat = 1.0

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
                guard date <= Date() else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                store.toggleLog(habitID: habit.id, date: date)
                if !isCompleted {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        checkScale = 1.4
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            checkScale = 1.0
                        }
                    }
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? themeManager.theme.accentColor : Color(hex: "#8E8E93")!)
                    .scaleEffect(checkScale)
            }
            .buttonStyle(.plain)
            .disabled(date > Date())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DayDetailView(date: Date())
        .environmentObject({ let s = HabitStore(); s.habits = Habit.sampleData(); return s }())
        .environmentObject(ThemeManager())
}
