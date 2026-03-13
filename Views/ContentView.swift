import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: HabitStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @State private var showAddHabit = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarHeatmapView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .tabItem {
                    Label("Calendar", systemImage: selectedTab == 0 ? "calendar.circle.fill" : "calendar.circle")
                }
                .tag(0)

            TrendsView()
                .environmentObject(store)
                .environmentObject(themeManager)
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
        .tint(themeManager.theme.accentColor)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddHabit) {
            AddEditHabitView()
                .environmentObject(store)
                .environmentObject(themeManager)
        }
    }

    private var profileTab: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0C0C0E")!.ignoresSafeArea()

                List {
                    Section {
                        ForEach(store.habits) { habit in
                            NavigationLink {
                                AddEditHabitView(habitToEdit: habit)
                                    .environmentObject(store)
                                    .environmentObject(themeManager)
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

                    Section("Theme") {
                        ForEach(AppTheme.allCases) { theme in
                            Button {
                                themeManager.themeRaw = theme.rawValue
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(theme.accentColor)
                                        .frame(width: 20, height: 20)
                                    Text(theme.rawValue)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if themeManager.theme == theme {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.theme.accentColor)
                                    }
                                }
                            }
                            .listRowBackground(Color(hex: "#1C1C1E")!)
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                        }
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
                            .foregroundColor(themeManager.theme.accentColor)
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
        .environmentObject(ThemeManager())
}
