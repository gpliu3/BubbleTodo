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
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var isRecurring = false
    @State private var recurringInterval: RecurringInterval = .daily
    @State private var recurringCount = 1
    @State private var selectedWeekdays: Set<Weekday> = []
    @State private var useSpecificDays = false

    private let priorityOptions = [
        (value: 1, label: "Low", color: Color.green),
        (value: 2, label: "Medium", color: Color.yellow),
        (value: 3, label: "High", color: Color.orange),
        (value: 4, label: "Urgent", color: Color.red),
        (value: 5, label: "Critical", color: Color.purple)
    ]

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
                } footer: {
                    Text("Higher priority tasks appear as larger bubbles")
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

                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                } header: {
                    Text("Due Date")
                } footer: {
                    if hasDueDate {
                        Text("Overdue tasks will grow larger over time")
                    }
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
                } footer: {
                    if isRecurring {
                        Text("A new task will be created when you complete this one")
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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

        let newTask = TaskItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            effort: effort,
            dueDate: hasDueDate ? dueDate : nil,
            isRecurring: isRecurring,
            recurringInterval: isRecurring ? recurringInterval : nil,
            recurringCount: recurringCount,
            weeklyDays: weeklyDays
        )

        modelContext.insert(newTask)
        dismiss()
    }
}

// MARK: - Weekday Picker

struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select days")
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
