//
//  CompletedTasksView.swift
//  BubbleTodo
//

import SwiftUI
import SwiftData

struct CompletedTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted },
           sort: \TaskItem.completedAt,
           order: .reverse)
    private var completedTasks: [TaskItem]

    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingClearConfirmation = false

    enum TimePeriod: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"

        var startDate: Date? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .today:
                return calendar.startOfDay(for: now)
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now)
            case .all:
                return nil
            }
        }
    }

    private var filteredTasks: [TaskItem] {
        guard let startDate = selectedPeriod.startDate else {
            return completedTasks
        }
        return completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= startDate
        }
    }

    private var totalEffort: Double {
        filteredTasks.reduce(0) { $0 + $1.effort }
    }

    private var groupedTasks: [(String, [TaskItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTasks) { task -> String in
            guard let completedAt = task.completedAt else { return "Unknown" }

            if calendar.isDateInToday(completedAt) {
                return "Today"
            } else if calendar.isDateInYesterday(completedAt) {
                return "Yesterday"
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                      completedAt >= weekAgo {
                return "This Week"
            } else {
                return completedAt.formatted(.dateTime.month().day())
            }
        }

        // Sort by most recent first
        let order = ["Today", "Yesterday", "This Week"]
        return grouped.sorted { a, b in
            let aIndex = order.firstIndex(of: a.key) ?? Int.max
            let bIndex = order.firstIndex(of: b.key) ?? Int.max
            if aIndex != bIndex {
                return aIndex < bIndex
            }
            return a.key > b.key
        }
    }

    var body: some View {
        List {
            // Stats Section
            Section {
                statsCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Period Picker
            Section {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            // Completed Tasks
            if filteredTasks.isEmpty {
                Section {
                    emptyStateView
                }
            } else {
                ForEach(groupedTasks, id: \.0) { section, tasks in
                    Section(header: Text(section)) {
                        ForEach(tasks) { task in
                            CompletedTaskRow(task: task)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteTask(task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        restoreTask(task)
                                    } label: {
                                        Label("Restore", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle("Done")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !completedTasks.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingClearConfirmation = true
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear all completed tasks?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                clearAllCompleted()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(completedTasks.count) completed tasks.")
        }
    }

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatBox(
                    title: "Completed",
                    value: "\(filteredTasks.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatBox(
                    title: "Total Effort",
                    value: String(format: "%.1f", totalEffort),
                    icon: "flame.fill",
                    color: .orange
                )
            }

            if !filteredTasks.isEmpty {
                let avgEffort = totalEffort / Double(filteredTasks.count)
                Text("Average effort per task: \(String(format: "%.1f", avgEffort))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No completed tasks")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Pop some bubbles to see them here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func deleteTask(_ task: TaskItem) {
        withAnimation {
            modelContext.delete(task)
        }
    }

    private func restoreTask(_ task: TaskItem) {
        withAnimation {
            task.undoComplete()
        }
    }

    private func clearAllCompleted() {
        withAnimation {
            for task in completedTasks {
                modelContext.delete(task)
            }
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title.weight(.bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Completed Task Row

struct CompletedTaskRow: View {
    let task: TaskItem

    private var priorityColor: Color {
        switch task.priority {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(true, color: .secondary)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    if let completedAt = task.completedAt {
                        Label(completedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    if task.isRecurring, let desc = task.recurringDescription {
                        Label(desc, systemImage: "repeat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Effort badge
            Text(String(format: "%.1f", task.effort))
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CompletedTasksView()
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
