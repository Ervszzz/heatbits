import SwiftUI

struct YearHeatmapView: View {
    @EnvironmentObject var store: HabitStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedDay: Date? = nil
    @State private var showDayDetail = false

    var onMonthSelected: (Date) -> Void = { _ in }

    private let today = Date()
    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal)
                .padding(.vertical, 8)

            GeometryReader { geo in
                monthsScroll(size: geo.size)
            }
        }
        .sheet(isPresented: $showDayDetail) {
            if let day = selectedDay {
                DayDetailView(date: day)
                    .environmentObject(store)
                    .environmentObject(themeManager)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .daySelected)) { notif in
            if let date = notif.object as? Date {
                selectedDay = date
                showDayDetail = true
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedYear)")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                let rate = yearCompletionRate()
                Text("\(Int(rate * 100))% completed this year")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#8E8E93")!)
            }
            Spacer()
            HStack(spacing: 16) {
                Button { selectedYear -= 1 } label: {
                    Image(systemName: "chevron.left").foregroundColor(themeManager.theme.accentColor)
                }
                Button { selectedYear += 1 } label: {
                    Image(systemName: "chevron.right").foregroundColor(themeManager.theme.accentColor)
                }
                .disabled(selectedYear >= cal.component(.year, from: today))
            }
        }
    }

    private func monthsScroll(size: CGSize) -> some View {
        let hPad: CGFloat = 12
        let gap: CGFloat = 8
        let cols: CGFloat = 3
        let rows: CGFloat = 4
        let monthW = (size.width - hPad * 2 - gap * (cols - 1)) / cols
        let monthH = (size.height - gap * (rows - 1)) / rows

        return VStack(spacing: gap) {
            ForEach(0..<4) { row in
                HStack(spacing: gap) {
                    ForEach(1...3, id: \.self) { col in
                        let month = row * 3 + col
                        let monthDate = cal.date(from: DateComponents(year: selectedYear, month: month, day: 1))!
                        MiniMonthView(year: selectedYear, month: month, size: CGSize(width: monthW, height: monthH))
                            .environmentObject(store)
                            .environmentObject(themeManager)
                            .onTapGesture { onMonthSelected(monthDate) }
                    }
                }
            }
        }
        .padding(.horizontal, hPad)
    }

    private func yearCompletionRate() -> Double {
        var comps = DateComponents()
        comps.year = selectedYear; comps.month = 1; comps.day = 1
        guard let start = cal.date(from: comps),
              let yearEnd = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31)) else { return 0 }
        let end = min(today, yearEnd)
        var total = 0.0, count = 0
        var current = start
        while current <= end {
            let scheduled = store.habits.filter { $0.isScheduled(on: current) }
            if !scheduled.isEmpty { total += store.completionRate(for: current); count += 1 }
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }
        return count > 0 ? total / Double(count) : 0
    }
}

struct MiniMonthView: View {
    @EnvironmentObject var store: HabitStore
    @EnvironmentObject var themeManager: ThemeManager
    let year: Int
    let month: Int
    let size: CGSize

    private let cal = Calendar.current
    private let today = Date()
    private let innerPad: CGFloat = 6
    private let cellGap: CGFloat = 2

    private var monthDate: Date {
        cal.date(from: DateComponents(year: year, month: month, day: 1))!
    }

    private var monthName: String {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f.string(from: monthDate)
    }

    private var cellSize: CGFloat {
        let labelH: CGFloat = 14
        let usableW = size.width - innerPad * 2
        let usableH = size.height - innerPad * 2 - labelH - cellGap
        let byWidth = (usableW - cellGap * 6) / 7
        let byHeight = (usableH - cellGap * 5) / 6
        return min(byWidth, byHeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: cellGap) {
            Text(monthName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#8E8E93")!)
                .frame(height: 14)
            monthGrid
        }
        .padding(innerPad)
        .frame(width: size.width, height: size.height)
        .background(Color(hex: "#1C1C1E")!)
        .cornerRadius(10)
    }

    private var monthGrid: some View {
        let days = daysInMonth()
        let rowCount = days.count / 7
        return VStack(spacing: cellGap) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: cellGap) {
                    ForEach(0..<7, id: \.self) { col in
                        miniCell(for: days[safe: row * 7 + col] ?? nil)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func miniCell(for date: Date?) -> some View {
        if let d = date {
            let isFuture = d.startOfDay > today.startOfDay
            let rate: Double = isFuture ? -1.0 : store.completionRate(for: d)
            let color: Color = isFuture ? Color(hex: "#2C2C2E")! : themeManager.theme.heatmapColor(rate: rate)
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(cal.isDateInToday(d) ? Color.white.opacity(0.8) : Color.clear, lineWidth: 1)
                )
        } else {
            Color.clear.frame(width: cellSize, height: cellSize)
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: monthDate) else { return [] }
        let firstWeekday = cal.component(.weekday, from: monthDate) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for i in 0..<range.count {
            days.append(cal.date(byAdding: .day, value: i, to: monthDate))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

extension Notification.Name {
    static let daySelected = Notification.Name("daySelected")
}

private struct SelectedDayKey: EnvironmentKey {
    static let defaultValue: Binding<Date?> = .constant(nil)
}
extension EnvironmentValues {
    var selectedDayBinding: Binding<Date?> {
        get { self[SelectedDayKey.self] }
        set { self[SelectedDayKey.self] = newValue }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0C0C0E")!.ignoresSafeArea()
        YearHeatmapView()
            .environmentObject({
                let s = HabitStore()
                s.habits = Habit.sampleData()
                return s
            }())
            .environmentObject(ThemeManager())
    }
}
