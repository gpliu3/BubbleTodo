//
//  TaskItem.swift
//  BubbleTodo
//

import Foundation
import SwiftData

enum RecurringInterval: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var priority: Int = 3 // 1-5, where 5 is highest
    var weight: Double = 1.0 // starts at 1.0, increases over time
    var effort: Double = 1.0 // user-input effort/weight for tracking total work done
    var dueDate: Date?
    var isRecurring: Bool = false
    var recurringInterval: RecurringInterval?
    var recurringCount: Int = 1 // how many times per period (e.g., 3 times per week)
    var weeklyDays: [Int] = [] // specific days for weekly recurrence (1=Sun, 2=Mon, etc.)
    var createdAt: Date = Date()
    var completedAt: Date?
    var isCompleted: Bool = false

    init(
        id: UUID = UUID(),
        title: String,
        priority: Int = 3,
        weight: Double = 1.0,
        effort: Double = 1.0,
        dueDate: Date? = nil,
        isRecurring: Bool = false,
        recurringInterval: RecurringInterval? = nil,
        recurringCount: Int = 1,
        weeklyDays: [Int] = [],
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.priority = min(max(priority, 1), 5) // Clamp between 1-5
        self.weight = weight
        self.effort = effort
        self.dueDate = dueDate
        self.isRecurring = isRecurring
        self.recurringInterval = recurringInterval
        self.recurringCount = recurringCount
        self.weeklyDays = weeklyDays
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.isCompleted = isCompleted
    }

    // MARK: - Computed Properties

    /// Calculates the effective urgency weight (increases over time)
    var effectiveWeight: Double {
        var currentWeight = weight
        let now = Date()

        // If past due date, increase weight by 0.1 every hour
        if let dueDate = dueDate, now > dueDate {
            let hoursOverdue = now.timeIntervalSince(dueDate) / 3600
            currentWeight += hoursOverdue * 0.1
        }
        // For non-due items older than 24h, increase by 0.05 every hour
        else if dueDate == nil {
            let hoursSinceCreation = now.timeIntervalSince(createdAt) / 3600
            if hoursSinceCreation > 24 {
                let hoursAfter24 = hoursSinceCreation - 24
                currentWeight += hoursAfter24 * 0.05
            }
        }

        return currentWeight
    }

    /// Bubble size is based on EFFORT with sqrt scaling
    /// This ensures 120min tasks aren't 120x bigger than 1min tasks
    /// Scale: 1min → ~1, 5min → ~2.2, 15min → ~3.9, 30min → ~5.5, 60min → ~7.7, 120min → ~11
    var bubbleSize: Double {
        sqrt(effort)
    }

    /// Effort displayed as time label
    var effortLabel: String {
        switch Int(effort) {
        case 0...1: return "1m"
        case 2...5: return "5m"
        case 6...15: return "15m"
        case 16...30: return "30m"
        case 31...60: return "1h"
        case 61...120: return "2h"
        default: return "\(Int(effort))m"
        }
    }

    /// Standard effort options in minutes
    static let effortOptions: [(value: Double, label: String)] = [
        (1, "1 min"),
        (5, "5 min"),
        (15, "15 min"),
        (30, "30 min"),
        (60, "1 hour"),
        (120, "2 hours")
    ]

    /// Sort score for ordering (higher = more urgent, appears at top)
    /// Combines priority with time-based urgency
    var sortScore: Double {
        Double(priority) * effectiveWeight
    }

    /// Whether this task should be visible today
    /// Shows: tasks due today, overdue tasks, or tasks without due date
    var shouldShowToday: Bool {
        guard !isCompleted else { return false }

        // No due date = always show
        guard let dueDate = dueDate else { return true }

        let calendar = Calendar.current
        let now = Date()

        // Show if due today or overdue
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        // Due today (any time today) or overdue (before today)
        return dueDate < endOfToday
    }

    /// Check if task is overdue
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return Date() > dueDate
    }

    /// Check if task is due today
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    /// Priority label for display
    var priorityLabel: String {
        switch priority {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        case 4: return "Urgent"
        case 5: return "Critical"
        default: return "Medium"
        }
    }

    /// Color based on priority (green→yellow→orange→red→purple for 1-5)
    var priorityColorName: String {
        switch priority {
        case 1: return "green"
        case 2: return "yellow"
        case 3: return "orange"
        case 4: return "red"
        case 5: return "purple"
        default: return "orange"
        }
    }

    // MARK: - Methods

    /// Marks the task as complete
    func markComplete() {
        isCompleted = true
        completedAt = Date()
    }

    /// Undoes the completion
    func undoComplete() {
        isCompleted = false
        completedAt = nil
    }

    /// Creates the next recurring task if this is a recurring task
    func createNextRecurringTask() -> TaskItem? {
        guard isRecurring, let interval = recurringInterval else { return nil }

        let calendar = Calendar.current
        // Use current due date, or today if no due date was set
        let baseDate = dueDate ?? Date()
        var nextDueDate: Date

        switch interval {
        case .daily:
            nextDueDate = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate

        case .weekly:
            if !weeklyDays.isEmpty {
                // Find next occurrence based on selected weekdays
                nextDueDate = findNextWeeklyDate(from: baseDate, weekdays: weeklyDays, calendar: calendar) ?? baseDate
            } else if recurringCount > 1 {
                // X times per week - space evenly (every 7/count days)
                let dayInterval = max(7 / recurringCount, 1)
                nextDueDate = calendar.date(byAdding: .day, value: dayInterval, to: baseDate) ?? baseDate
            } else {
                nextDueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
            }

        case .monthly:
            // For monthly with count, space them out evenly
            if recurringCount > 1 {
                let daysInMonth = 30 // Approximate
                let dayInterval = daysInMonth / recurringCount
                nextDueDate = calendar.date(byAdding: .day, value: dayInterval, to: baseDate) ?? baseDate
            } else {
                nextDueDate = calendar.date(byAdding: .month, value: 1, to: baseDate) ?? baseDate
            }
        }

        return TaskItem(
            title: title,
            priority: priority,
            weight: 1.0, // Reset weight for new recurring task
            effort: effort,
            dueDate: nextDueDate, // Always has a due date now
            isRecurring: true,
            recurringInterval: interval,
            recurringCount: recurringCount,
            weeklyDays: weeklyDays
        )
    }

    /// Finds the next date that matches one of the selected weekdays
    private func findNextWeeklyDate(from date: Date, weekdays: [Int], calendar: Calendar) -> Date? {
        var checkDate = date
        let sortedWeekdays = weekdays.sorted()

        // Look up to 8 days ahead to find the next matching weekday
        for _ in 1...8 {
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? checkDate
            let weekday = calendar.component(.weekday, from: checkDate)

            if sortedWeekdays.contains(weekday) {
                return checkDate
            }
        }

        // Fallback: just add a week
        return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
    }

    /// Summary of recurring schedule for display
    var recurringDescription: String? {
        guard isRecurring, let interval = recurringInterval else { return nil }

        switch interval {
        case .daily:
            return "Every day"
        case .weekly:
            if !weeklyDays.isEmpty {
                let dayNames = weeklyDays.sorted().compactMap { Weekday(rawValue: $0)?.shortName }
                return dayNames.joined(separator: ", ")
            } else if recurringCount > 1 {
                return "\(recurringCount)x per week"
            }
            return "Every week"
        case .monthly:
            if recurringCount > 1 {
                return "\(recurringCount)x per month"
            }
            return "Every month"
        }
    }
}
