import SwiftUI

struct CalendarHeatmapView: View {
    @EnvironmentObject var store: HabitStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var currentMonth: Date = Date()
    @State private var selectedDay: Date? = nil
    @State private var showDayDetail = false
    @State private var quickLogDay: Date? = nil
    @State private var showQuickLog = false
    @State private var viewMode: ViewMode = .month

    enum ViewMode { case month, year }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdayHeaders = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0C0C0E")!.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("View", selection: $viewMode) {
                        Text("Month").tag(ViewMode.month)
                        Text("Year").tag(ViewMode.year)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if viewMode == .year {
                        YearHeatmapView { month in
                            currentMonth = month
                            withAnimation { viewMode = .month }
                        }
                        .environmentObject(store)
                        .environmentObject(themeManager)
                    } else {
                        headerView
                            .padding(.horizontal)
                            .padding(.top, 8)

                        weekdayRow
                            .padding(.horizontal)
                            .padding(.top, 16)

                        calendarGrid
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .gesture(
                                DragGesture(minimumDistance: 40)
                                    .onEnded { value in
                                        if value.translation.width < 0 {
                                            navigateMonth(by: 1)
                                        } else {
                                            navigateMonth(by: -1)
                                        }
                                    }
                            )

                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showDayDetail) {
            if let day = selectedDay {
                DayDetailView(date: day)
                    .environmentObject(store)
                    .environmentObject(themeManager)
            }
        }
        .sheet(isPresented: $showQuickLog) {
            if let day = quickLogDay {
                DayDetailView(date: day)
                    .environmentObject(store)
                    .environmentObject(themeManager)
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(currentMonth.monthYearString)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                let rate = store.completionRate(forMonth: currentMonth)
                Text("\(Int(rate * 100))% completed this month")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#8E8E93")!)
            }

            Spacer()

            HStack(spacing: 16) {
                Button(action: { navigateMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(themeManager.theme.accentColor)
                }
                Button(action: { navigateMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.theme.accentColor)
                }
            }
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdayHeaders.indices, id: \.self) { i in
                Text(weekdayHeaders[i])
                    .font(.caption2.bold())
                    .foregroundColor(Color(hex: "#8E8E93")!)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days.indices, id: \.self) { i in
                let day = days[i]
                if let day {
                    let isFuture = day.startOfDay > Date().startOfDay
                    let rate = store.completionRate(for: day)
                    DayCellView(
                        date: day,
                        rate: rate,
                        isToday: Calendar.current.isDateInToday(day),
                        isFuture: isFuture,
                        accentColor: themeManager.theme.accentColor,
                        heatmapColor: themeManager.theme.heatmapColor(rate: rate)
                    )
                    .onTapGesture {
                        guard !isFuture else { return }
                        selectedDay = day
                        showDayDetail = true
                    }
                    .onLongPressGesture {
                        guard !isFuture else { return }
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        quickLogDay = day
                        showQuickLog = true
                    }
                } else {
                    Color.clear.aspectRatio(1, contentMode: .fill)
                }
            }
        }
    }

    private func navigateMonth(by value: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) ?? currentMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        let cal = Calendar.current
        let start = currentMonth.startOfMonth
        let range = cal.range(of: .day, in: .month, for: start)!
        let firstWeekday = cal.component(.weekday, from: start)

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for i in 0..<range.count {
            if let d = cal.date(byAdding: .day, value: i, to: start) {
                days.append(d)
            }
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

struct DayCellView: View {
    let date: Date
    let rate: Double
    let isToday: Bool
    var isFuture: Bool = false
    var accentColor: Color = Color(hex: "#30D158")!
    var heatmapColor: Color = Color.heatmapGreen(rate: 1.0)

    private var cellColor: Color {
        if isFuture { return Color(hex: "#1C1C1E")! }
        if rate <= 0 { return Color(hex: "#2C2C2E")! }
        return heatmapColor
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(cellColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.white.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption2)
                .foregroundColor(isFuture ? Color(hex: "#3A3A3C")! : (rate > 0 ? .white : Color(hex: "#8E8E93")!))
        }
        .aspectRatio(1, contentMode: .fill)
    }
}

#Preview {
    CalendarHeatmapView()
        .environmentObject({ let s = HabitStore(); s.habits = Habit.sampleData(); return s }())
        .environmentObject(ThemeManager())
}
