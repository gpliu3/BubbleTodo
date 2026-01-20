//
//  EditTaskSheet.swift
//  BubbleTodo
//

import SwiftUI
import SwiftData

struct EditTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var task: TaskItem

    @State private var title: String
    @State private var priority: Int
    @State private var effort: Double
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var dueDateType: DueDateType
    @State private var isRecurring: Bool
    @State private var recurringInterval: RecurringInterval
    @State private var recurringCount: Int
    @State private var selectedWeekdays: Set<Weekday>
    @State private var useSpecificDays: Bool
    @State private var hasRecurringTime: Bool
    @State private var recurringTime: Date
    @State private var showingDeleteConfirmation = false
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

    init(task: TaskItem) {
        self.task = task
        _title = State(initialValue: task.title)
        _priority = State(initialValue: task.priority)
        _effort = State(initialValue: task.effort)
        _hasDueDate = State(initialValue: task.dueDate != nil && !task.isRecurring)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _dueDateType = State(initialValue: task.effectiveDueDateType)
        _isRecurring = State(initialValue: task.isRecurring)
        _recurringInterval = State(initialValue: task.recurringInterval ?? .daily)
        _recurringCount = State(initialValue: task.recurringCount)
        _selectedWeekdays = State(initialValue: Set(task.weeklyDays.compactMap { Weekday(rawValue: $0) }))
        _useSpecificDays = State(initialValue: !task.weeklyDays.isEmpty)
        _hasRecurringTime = State(initialValue: task.isRecurring && task.dueDate != nil)
        _recurringTime = State(initialValue: task.dueDate ?? Date())
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

                // Task Info Section
                Section(header: Text(L("info.title"))) {
                    LabeledContent(L("info.created")) {
                        Text(task.createdAt.formatted(.dateTime.month().day().hour().minute()))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if task.effectiveWeight > 1.0 {
                        LabeledContent(L("info.urgency")) {
                            Text(String(format: "%.1fx", task.effectiveWeight))
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                }

                // Delete Section
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label(L("task.delete"), systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .listRowSpacing(8)
            .navigationTitle(L("task.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("task.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("task.save")) {
                        saveChanges()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                L("task.delete.confirm"),
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(L("task.delete"), role: .destructive) {
                    deleteTask()
                }
                Button(L("task.cancel"), role: .cancel) {}
            } message: {
                Text(L("task.delete.message"))
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

    private func saveChanges() {
        let weeklyDays: [Int] = useSpecificDays && recurringInterval == .weekly
            ? selectedWeekdays.map { $0.rawValue }
            : []

        // For recurring tasks, set dueDate based on hasRecurringTime
        // For one-time tasks, use the user-selected due date
        let taskDueDate: Date?
        let taskDueDateType: DueDateType

        if isRecurring {
            // Recurring tasks
            if hasRecurringTime {
                // User specified a time - combine today's date with selected time
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: recurringTime)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: task.dueDate ?? Date())
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                taskDueDate = calendar.date(from: dateComponents) ?? (task.dueDate ?? Date())
            } else {
                // No specific time - keep existing or start today
                taskDueDate = task.dueDate ?? Date()
            }
            taskDueDateType = .on // Recurring tasks always use "on" type
        } else {
            // One-off tasks
            taskDueDate = hasDueDate ? dueDate : nil
            taskDueDateType = dueDateType
        }

        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.priority = priority
        task.effort = effort
        task.dueDate = taskDueDate
        task.dueDateType = taskDueDateType
        task.isRecurring = isRecurring
        task.recurringInterval = isRecurring ? recurringInterval : nil
        task.recurringCount = recurringCount
        task.weeklyDays = weeklyDays

        // Play subtle success sound
        SoundManager.playSuccessWithHaptic()

        dismiss()
    }

    private func deleteTask() {
        modelContext.delete(task)
        dismiss()
    }
}

#Preview {
    let task = TaskItem(title: "Sample Task", priority: 3)
    return EditTaskSheet(task: task)
        .modelContainer(for: TaskItem.self, inMemory: true)
}
