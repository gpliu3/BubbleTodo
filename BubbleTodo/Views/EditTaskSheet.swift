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
    @State private var showingDeleteConfirmation = false

    private let priorityOptions = [
        (value: 1, label: "Low", color: Color.green),
        (value: 2, label: "Medium", color: Color.yellow),
        (value: 3, label: "High", color: Color.orange),
        (value: 4, label: "Urgent", color: Color.red),
        (value: 5, label: "Critical", color: Color.purple)
    ]

    init(task: TaskItem) {
        self.task = task
        _title = State(initialValue: task.title)
        _priority = State(initialValue: task.priority)
        _effort = State(initialValue: task.effort)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _dueDateType = State(initialValue: task.effectiveDueDateType)
        _isRecurring = State(initialValue: task.isRecurring)
        _recurringInterval = State(initialValue: task.recurringInterval ?? .daily)
        _recurringCount = State(initialValue: task.recurringCount)
        _selectedWeekdays = State(initialValue: Set(task.weeklyDays.compactMap { Weekday(rawValue: $0) }))
        _useSpecificDays = State(initialValue: !task.weeklyDays.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title Section
                Section {
                    TextField("What needs to be done?", text: $title)
                        .font(.body)
                } header: {
                    Text("Task")
                }

                // Priority Section
                Section {
                    Picker("Priority", selection: $priority) {
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
                    Text("Priority")
                }

                // Effort Section (Time-based)
                Section {
                    // Time effort buttons
                    HStack(spacing: 8) {
                        ForEach(TaskItem.effortOptions, id: \.value) { option in
                            Button {
                                effort = option.value
                            } label: {
                                Text(option.label)
                                    .font(.caption.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(effort == option.value ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(effort == option.value ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Time Needed")
                } footer: {
                    Text("Estimated time to complete this task")
                }

                // Due Date Section
                Section {
                    Toggle("Set due date", isOn: $hasDueDate.animation())
                        .disabled(isRecurring)
                        .onChange(of: hasDueDate) { _, newValue in
                            if newValue {
                                isRecurring = false
                            }
                        }

                    if hasDueDate {
                        HStack {
                            // Tappable type selector
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    dueDateType = dueDateType == .on ? .before : .on
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(dueDateType.rawValue)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(dueDateType == .on ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                )
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            DatePicker(
                                "",
                                selection: $dueDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                        }
                    }
                } header: {
                    Text("Due Date")
                } footer: {
                    if hasDueDate {
                        Text(dueDateType == .on ? "Task only shows on the due date" : "Task shows early and urgency increases as deadline approaches")
                    } else if isRecurring {
                        Text("Recurring tasks cannot have due dates")
                    }
                }

                // Recurring Section
                Section {
                    Toggle("Recurring task", isOn: $isRecurring.animation())
                        .disabled(hasDueDate)
                        .onChange(of: isRecurring) { _, newValue in
                            if newValue {
                                hasDueDate = false
                            }
                        }

                    if isRecurring {
                        Picker("Repeat", selection: $recurringInterval) {
                            ForEach(RecurringInterval.allCases, id: \.self) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }

                        // Weekly options
                        if recurringInterval == .weekly {
                            Toggle("Choose specific days", isOn: $useSpecificDays.animation())

                            if useSpecificDays {
                                WeekdayPicker(selectedDays: $selectedWeekdays)
                            } else {
                                Stepper("Times per week: \(recurringCount)", value: $recurringCount, in: 1...7)
                            }
                        }

                        // Monthly options
                        if recurringInterval == .monthly {
                            Stepper("Times per month: \(recurringCount)", value: $recurringCount, in: 1...30)
                        }
                    }
                } header: {
                    Text("Recurring")
                } footer: {
                    if isRecurring {
                        Text("A new task will be created when you complete this one")
                    } else if hasDueDate {
                        Text("Due date tasks cannot be recurring")
                    }
                }

                // Task Info Section
                Section {
                    LabeledContent("Created") {
                        Text(task.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }

                    LabeledContent("Effort") {
                        Text(String(format: "%.1f", task.effort))
                    }

                    if task.effectiveWeight > 1.0 {
                        LabeledContent("Urgency weight") {
                            Text(String(format: "%.2f", task.effectiveWeight))
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text("Info")
                }

                // Delete Section
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Task", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Delete this task?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
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

        // For recurring tasks, ensure dueDate is set (use existing or today)
        // For one-time tasks, use the user-selected due date
        let taskDueDate: Date?
        if isRecurring {
            taskDueDate = task.dueDate ?? Date() // Keep existing or start today
        } else {
            taskDueDate = hasDueDate ? dueDate : nil
        }

        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.priority = priority
        task.effort = effort
        task.dueDate = taskDueDate
        task.dueDateType = dueDateType
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
