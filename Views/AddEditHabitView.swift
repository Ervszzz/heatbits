import SwiftUI

struct AddEditHabitView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) var dismiss

    var habitToEdit: Habit?

    @State private var name: String = ""
    @State private var emoji: String = "⭐"
    @State private var selectedColorHex: String = "#30D158"
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    @State private var healthKitLink: HealthKitLink = .none
    @State private var frequency: HabitFrequency = .daily
    @State private var customDays: Set<Int> = []
    @State private var showEmojiPicker = false

    private let commonEmojis = ["⭐","🏃","📚","💧","🥗","😴","🧘","💪","🎯","✍️","🎵","🌿","☀️","🧠","❤️","🦷"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0C0C0E")!.ignoresSafeArea()

                Form {
                    Section {
                        HStack(spacing: 14) {
                            Button {
                                showEmojiPicker.toggle()
                            } label: {
                                Text(emoji)
                                    .font(.largeTitle)
                                    .frame(width: 52, height: 52)
                                    .background(Color(hex: "#1C1C1E")!)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)

                            TextField("Habit name", text: $name)
                                .foregroundColor(.white)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Name & Icon")
                    }
                    .listRowBackground(Color(hex: "#1C1C1E")!)

                    if showEmojiPicker {
                        Section("Pick Emoji") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                                ForEach(commonEmojis, id: \.self) { e in
                                    Button {
                                        emoji = e
                                        showEmojiPicker = false
                                    } label: {
                                        Text(e).font(.title2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color(hex: "#1C1C1E")!)
                    }

                    Section("Color") {
                        HStack(spacing: 12) {
                            ForEach(Habit.presetColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex)!)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColorHex == hex ? 2 : 0)
                                            .padding(2)
                                    )
                                    .onTapGesture { selectedColorHex = hex }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(hex: "#1C1C1E")!)

                    Section("Schedule") {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(HabitFrequency.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .foregroundColor(.white)

                        if frequency == .custom {
                            CustomDaysPicker(selectedDays: $customDays)
                        }
                    }
                    .listRowBackground(Color(hex: "#1C1C1E")!)

                    Section("Reminder") {
                        Toggle("Enable Reminder", isOn: $reminderEnabled)
                            .tint(Color(hex: "#30D158")!)
                        if reminderEnabled {
                            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .colorScheme(.dark)
                        }
                    }
                    .listRowBackground(Color(hex: "#1C1C1E")!)

                    Section("Health App") {
                        Picker("Auto-log from Health", selection: $healthKitLink) {
                            ForEach(HealthKitLink.allCases, id: \.self) { link in
                                Text(link.rawValue).tag(link)
                            }
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color(hex: "#1C1C1E")!)

                    if habitToEdit != nil {
                        Section {
                            Button(role: .destructive) {
                                if let h = habitToEdit {
                                    store.deleteHabit(h)
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Delete Habit")
                                    Spacer()
                                }
                            }
                        }
                        .listRowBackground(Color(hex: "#1C1C1E")!)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(habitToEdit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#8E8E93")!)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(Color(hex: "#30D158")!)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let h = habitToEdit else { return }
        name = h.name
        emoji = h.emoji
        selectedColorHex = h.colorHex
        reminderEnabled = h.reminderEnabled
        reminderTime = h.reminderTime
        healthKitLink = h.healthKitLink
        frequency = h.frequency
        customDays = h.customDays
    }

    private func save() {
        var habit = habitToEdit ?? Habit(
            name: "", emoji: "", colorHex: "", reminderEnabled: false,
            reminderTime: Date(), healthKitLink: .none, frequency: .daily, customDays: []
        )
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.emoji = emoji
        habit.colorHex = selectedColorHex
        habit.reminderEnabled = reminderEnabled
        habit.reminderTime = reminderTime
        habit.healthKitLink = healthKitLink
        habit.frequency = frequency
        habit.customDays = customDays

        if habitToEdit != nil {
            store.updateHabit(habit)
        } else {
            store.addHabit(habit)
        }
        dismiss()
    }
}

struct CustomDaysPicker: View {
    @Binding var selectedDays: Set<Int>
    private let days = [(1,"S"),(2,"M"),(3,"T"),(4,"W"),(5,"T"),(6,"F"),(7,"S")]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days, id: \.0) { (num, label) in
                let isSelected = selectedDays.contains(num)
                Button {
                    if isSelected { selectedDays.remove(num) } else { selectedDays.insert(num) }
                } label: {
                    Text(label)
                        .font(.caption.bold())
                        .frame(width: 34, height: 34)
                        .background(isSelected ? Color(hex: "#30D158")! : Color(hex: "#2C2C2E")!)
                        .foregroundColor(isSelected ? .black : Color(hex: "#8E8E93")!)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddEditHabitView()
        .environmentObject(HabitStore())
}
