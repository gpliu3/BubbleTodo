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

                // Effort Section
                Section {
                    HStack {
                        Text("Effort")
                        Spacer()
                        Text(String(format: "%.1f", effort))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $effort, in: 0.5...10.0, step: 0.5) {
                        Text("Effort")
                    }

                    // Quick effort buttons
                    HStack(spacing: 12) {
                        ForEach([1.0, 2.0, 3.0, 5.0, 8.0], id: \.self) { value in
                            Button {
                                effort = value
                            } label: {
                                Text(String(format: "%.0f", value))
                                    .font(.caption.weight(.medium))
                                    .frame(width: 36, height: 28)
                                    .background(effort == value ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(effort == value ? .white : .primary)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Effort (Weight)")
                } footer: {
                    Text("Track how much work this task requires")
                }

                // Due Date Section
                Section {
                    Toggle("Set due date", isOn: $hasDueDate.animation())

                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                } header: {
                    Text("Due Date")
                }

                // Recurring Section
                Section {
                    Toggle("Recurring task", isOn: $isRecurring.animation())

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

        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.priority = priority
        task.effort = effort
        task.dueDate = hasDueDate ? dueDate : nil
        task.isRecurring = isRecurring
        task.recurringInterval = isRecurring ? recurringInterval : nil
        task.recurringCount = recurringCount
        task.weeklyDays = weeklyDays

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
