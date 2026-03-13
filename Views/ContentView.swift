import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: HabitStore
    @State private var selectedTab = 0
    @State private var showAddHabit = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarHeatmapView()
                .environmentObject(store)
                .tabItem {
                    Label("Calendar", systemImage: selectedTab == 0 ? "calendar.circle.fill" : "calendar.circle")
                }
                .tag(0)

            TrendsView()
                .environmentObject(store)
                .tabItem {
                    Label("Trends", systemImage: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(1)

            profileTab
                .tabItem {
                    Label("Habits", systemImage: selectedTab == 2 ? "list.bullet.circle.fill" : "list.bullet.circle")
                }
                .tag(2)
        }
        .tint(Color(hex: "#30D158")!)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddHabit) {
            AddEditHabitView()
                .environmentObject(store)
        }
    }

    private var profileTab: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0C0C0E")!.ignoresSafeArea()

                List {
                    ForEach(store.habits) { habit in
                        NavigationLink {
                            AddEditHabitView(habitToEdit: habit)
                                .environmentObject(store)
                        } label: {
                            HStack(spacing: 12) {
                                Text(habit.emoji).font(.title3)
                                Text(habit.name).foregroundColor(.white)
                                Spacer()
                                Circle()
                                    .fill(Color(hex: habit.colorHex)!)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .listRowBackground(Color(hex: "#1C1C1E")!)
                        .listRowSeparatorTint(Color.white.opacity(0.08))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "#30D158")!)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject({
            let s = HabitStore()
            s.habits = Habit.sampleData()
            return s
        }())
}
