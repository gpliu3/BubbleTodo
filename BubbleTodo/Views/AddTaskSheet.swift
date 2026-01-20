//
//  AddTaskSheet.swift
//  BubbleTodo
//

import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var priority = 3
    @State private var effort: Double = 15.0 // Default to 15 minutes
    @State private var hasDueDate = true // Default to having a due date (one-off task)
    @State private var dueDate = Date() // Default to today + current time
    @State private var dueDateType: DueDateType = .before
    @State private var isRecurring = false
    @State private var recurringInterval: RecurringInterval = .daily
    @State private var recurringCount = 1
    @State private var selectedWeekdays: Set<Weekday> = []
    @State private var useSpecificDays = false
    @State private var hasRecurringTime = false // Whether recurring task has specific time
    @State private var recurringTime = Date() // Time for recurring task occurrence
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var priorityOptions: [(value: Int, label: String, color: Color)] {
        [
            (value: 1, label: L("priority.low"), color: Color.green),
            (value: 2, label: L("priority.medium"), color: Color.yellow),
            (value: 3, label: L("priority.high"), color: Color.orange),
            (value: 4, label: L("priority.urgent"), color: Color.red),
            (value: 5, label: L("priority.critical"), color: Color.purple)
        ]
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title Section
                Section {
                    TextField(L("task.placeholder"), text: $title)
                        .font(.body)
                } header: {
                    Text(L("task.title"))
                        .textCase(nil)
                }

                // Priority Section
                Section {
                    Picker(L("priority.title"), selection: $priority) {
                        ForEach(priorityOptions, id: \.value) { option in
                            HStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 12, height: 12)
                                Text(option.label)
                            }
                            .tag(option.value)
                        }
                    }
                    .pickerStyle(.menu)

                    // Visual priority indicator
                    HStack {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= priority ? priorityColor(for: priority) : Color.gray.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        priority = level
                                    }
                                }
                        }
                        Spacer()
                        Text(priorityLabel(for: priority))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(L("priority.title"))
                } footer: {
                    Text(L("priority.footer"))
                }

                // Effort Section (Time-based)
                Section {
                    VStack(spacing: 8) {
                        // First row: 1 min, 5 min, 15 min
                        HStack(spacing: 8) {
                            ForEach(Array(TaskItem.effortOptions.prefix(3)), id: \.value) { option in
                                Button {
                                    effort = option.value
                                } label: {
                                    Text(option.label)
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(effort == option.value ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(effort == option.value ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Second row: 30 min, 1 hour, 2 hours
                        HStack(spacing: 8) {
                            ForEach(Array(TaskItem.effortOptions.dropFirst(3)), id: \.value) { option in
                                Button {
                                    effort = option.value
                                } label: {
                                    Text(option.label)
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(effort == option.value ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(effort == option.value ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    Text(L("effort.title"))
                } footer: {
                    Text(L("effort.footer"))
                }

                // One-off Task Section
                Section {
                    Toggle("One off task", isOn: $hasDueDate.animation())
                        .onChange(of: hasDueDate) { _, newValue in
                            if newValue {
                                // Turning on one-off task, turn off recurring
                                isRecurring = false
                            } else {
                                // Turning off one-off task, must turn on recurring
                                isRecurring = true
                            }
                        }

                    if hasDueDate {
                        HStack(spacing: 8) {
                            // Tappable type selector
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    dueDateType = dueDateType == .on ? .before : .on
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Text(dueDateType.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(dueDateType == .on ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                )
                            }
                            .buttonStyle(.plain)
                            .fixedSize()

                            Spacer()

                            DatePicker(
                                "",
                                selection: $dueDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                    }
                } footer: {
                    if hasDueDate {
                        Text(dueDateType.description)
                    } else if isRecurring {
                        Text(L("duedate.recurring.disabled"))
                    }
                }

                // Recurring Section
                Section {
                    Toggle(L("recurring.toggle"), isOn: $isRecurring.animation())
                        .onChange(of: isRecurring) { _, newValue in
                            if newValue {
                                // Turning on recurring, turn off due date
                                hasDueDate = false
                            } else {
                                // Turning off recurring, must turn on due date
                                hasDueDate = true
                            }
                        }

                    if isRecurring {
                        Picker(L("recurring.repeat"), selection: $recurringInterval) {
                            ForEach(RecurringInterval.allCases, id: \.self) { interval in
                                Text(interval.displayName).tag(interval)
                            }
                        }

                        // Weekly options
                        if recurringInterval == .weekly {
                            Toggle(L("recurring.specificdays"), isOn: $useSpecificDays.animation())

                            if useSpecificDays {
                                WeekdayPicker(selectedDays: $selectedWeekdays)
                            } else {
                                Stepper(String(format: L("recurring.timesperweek"), recurringCount), value: $recurringCount, in: 1...7)
                            }
                        }

                        // Monthly options
                        if recurringInterval == .monthly {
                            Stepper(String(format: L("recurring.timespermonth"), recurringCount), value: $recurringCount, in: 1...30)
                        }

                        // Time picker for recurring tasks
                        Toggle("Set specific time", isOn: $hasRecurringTime.animation())

                        if hasRecurringTime {
                            DatePicker(
                                "Time",
                                selection: $recurringTime,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                } footer: {
                    if isRecurring {
                        Text(L("recurring.footer"))
                    } else if hasDueDate {
                        Text(L("recurring.duedate.disabled"))
                    }
                }
            }
            .listRowSpacing(8)
            .navigationTitle(L("task.new"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("task.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("task.save")) {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .orange
        }
    }

    private func priorityLabel(for priority: Int) -> String {
        priorityOptions.first { $0.value == priority }?.label ?? "High"
    }

    private func saveTask() {
        let weeklyDays: [Int] = useSpecificDays && recurringInterval == .weekly
            ? selectedWeekdays.map { $0.rawValue }
            : []

        // For recurring tasks, set initial dueDate based on hasRecurringTime
        // For one-time tasks, use the user-selected due date
        let taskDueDate: Date?
        let taskDueDateType: DueDateType

        if isRecurring {
            // Recurring tasks
            if hasRecurringTime {
                // User specified a time - combine today's date with selected time
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: recurringTime)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                taskDueDate = calendar.date(from: dateComponents) ?? Date()
            } else {
                // No specific time - start today
                taskDueDate = Date()
            }
            taskDueDateType = .on // Recurring tasks always use "on" type
        } else {
            // One-off tasks
            taskDueDate = hasDueDate ? dueDate : nil
            taskDueDateType = dueDateType
        }

        let newTask = TaskItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            effort: effort,
            dueDate: taskDueDate,
            dueDateType: taskDueDateType,
            isRecurring: isRecurring,
            recurringInterval: isRecurring ? recurringInterval : nil,
            recurringCount: recurringCount,
            weeklyDays: weeklyDays
        )

        modelContext.insert(newTask)

        // Play satisfying sound when adding task
        SoundManager.playSuccessWithHaptic()

        dismiss()
    }
}

// MARK: - Weekday Picker

struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("recurring.selectdays"))
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(Weekday.allCases) { day in
                    Button {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    } label: {
                        Text(String(day.shortName.prefix(1)))
                            .font(.caption.weight(.semibold))
                            .frame(width: 36, height: 36)
                            .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if !selectedDays.isEmpty {
                Text(selectedDays.sorted { $0.rawValue < $1.rawValue }.map { $0.shortName }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddTaskSheet()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
