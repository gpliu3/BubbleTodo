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

    var displayName: String {
        switch self {
        case .daily: return L("recurring.daily")
        case .weekly: return L("recurring.weekly")
        case .monthly: return L("recurring.monthly")
        }
    }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return L("weekday.sun.short")
        case .monday: return L("weekday.mon.short")
        case .tuesday: return L("weekday.tue.short")
        case .wednesday: return L("weekday.wed.short")
        case .thursday: return L("weekday.thu.short")
        case .friday: return L("weekday.fri.short")
        case .saturday: return L("weekday.sat.short")
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return L("weekday.sunday")
        case .monday: return L("weekday.monday")
        case .tuesday: return L("weekday.tuesday")
        case .wednesday: return L("weekday.wednesday")
        case .thursday: return L("weekday.thursday")
        case .friday: return L("weekday.friday")
        case .saturday: return L("weekday.saturday")
        }
    }
}

enum DueDateType: String, Codable, CaseIterable {
    case on = "On"       // Task only for that specific day
    case before = "Before"  // Deadline - must be done before/at date

    var displayName: String {
        switch self {
        case .on: return L("duedate.on")
        case .before: return L("duedate.before")
        }
    }

    var description: String {
        switch self {
        case .on: return L("duedate.on.footer")
        case .before: return L("duedate.before.footer")
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
    var dueDateType: DueDateType? = nil // "On" vs "Before"
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
        dueDateType: DueDateType = .before,
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
        self.dueDateType = dueDateType
        self.isRecurring = isRecurring
        self.recurringInterval = recurringInterval
        self.recurringCount = recurringCount
        self.weeklyDays = weeklyDays
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.isCompleted = isCompleted
    }

    // MARK: - Computed Properties

    /// Effective due date type with default fallback
    var effectiveDueDateType: DueDateType {
        dueDateType ?? .before
    }

    /// Calculates the effective urgency weight (increases over time)
    var effectiveWeight: Double {
        var currentWeight = weight
        let now = Date()

        if let dueDate = dueDate {
            if now > dueDate {
                // Past due date - increase weight significantly
                let hoursOverdue = now.timeIntervalSince(dueDate) / 3600
                currentWeight += hoursOverdue * 0.1
            } else if effectiveDueDateType == .before {
                // "Before" type: Gradually increase urgency as approaching deadline
                let hoursUntilDue = dueDate.timeIntervalSince(now) / 3600

                if hoursUntilDue < 24 {
                    // Within 24 hours: urgency increases dramatically
                    let urgencyMultiplier = 1.0 + (24 - hoursUntilDue) / 24 * 0.5
                    currentWeight *= urgencyMultiplier
                } else if hoursUntilDue < 72 {
                    // Within 3 days: moderate urgency increase
                    let urgencyMultiplier = 1.0 + (72 - hoursUntilDue) / 72 * 0.3
                    currentWeight *= urgencyMultiplier
                }
            }
            // For "on" type: no early urgency increase
        } else {
            // No due date - slight increase for old tasks
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
    static var effortOptions: [(value: Double, label: String)] {
        [
            (1, L("effort.1min")),
            (5, L("effort.5min")),
            (15, L("effort.15min")),
            (30, L("effort.30min")),
            (60, L("effort.1hour")),
            (120, L("effort.2hours"))
        ]
    }

    /// Sort score for ordering (higher = more urgent, appears at top)
    /// Based on: 1) Priority, 2) Due time today, 3) Time-based urgency
    var sortScore: Double {
        let now = Date()
        let calendar = Calendar.current

        // Base score from priority (1-5) - scale to 1000-5000
        var score = Double(priority) * 1000.0

        // Add urgency from due date/time
        if let dueDate = dueDate {
            // Check if due today
            if calendar.isDateInToday(dueDate) {
                // Due today: add score based on time of day (earlier = higher)
                let hoursUntilDue = dueDate.timeIntervalSince(now) / 3600

                if hoursUntilDue > 0 {
                    // Due later today: 0-24 hours away, add 0-500 points (sooner = more points)
                    score += max(0, 500 - (hoursUntilDue * 20))
                } else {
                    // Overdue today: add even more urgency
                    let hoursOverdue = abs(hoursUntilDue)
                    score += 500 + (hoursOverdue * 100)
                }
            } else if dueDate < now {
                // Overdue from previous days: very high urgency
                let hoursOverdue = now.timeIntervalSince(dueDate) / 3600
                score += 1000 + (hoursOverdue * 50)
            } else if effectiveDueDateType == .before {
                // "Before" type with future due date: add urgency as deadline approaches
                let hoursUntilDue = dueDate.timeIntervalSince(now) / 3600

                if hoursUntilDue < 24 {
                    // Within 24 hours: 200-400 points
                    score += 200 + (24 - hoursUntilDue) * 8
                } else if hoursUntilDue < 72 {
                    // Within 3 days: 0-200 points
                    score += (72 - hoursUntilDue) * 2.8
                }
            }
        } else {
            // No due date: slight boost for older tasks
            let hoursSinceCreation = now.timeIntervalSince(createdAt) / 3600
            if hoursSinceCreation > 24 {
                score += min((hoursSinceCreation - 24) * 2, 100)
            }
        }

        return score
    }

    /// Whether this task should be visible today
    /// Behavior depends on dueDateType
    var shouldShowToday: Bool {
        guard !isCompleted else { return false }

        // No due date = always show
        guard let dueDate = dueDate else { return true }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        // Recurring tasks always use .on behavior (only show on scheduled day)
        let typeToUse = isRecurring ? DueDateType.on : effectiveDueDateType

        switch typeToUse {
        case .on:
            // "On" type: Only show on the specific day
            let startOfDueDate = calendar.startOfDay(for: dueDate)
            let endOfDueDate = calendar.date(byAdding: .day, value: 1, to: startOfDueDate)!

            // Show if today is the due date OR if overdue
            if now >= startOfDueDate && now < endOfDueDate {
                return true // Today is the due date
            } else if now >= endOfDueDate {
                return true // Overdue
            } else {
                return false // Before the due date - don't show
            }

        case .before:
            // "Before" type: Show from creation until end of deadline day
            // This ensures task shows all day on the due date, not just until the exact time
            let endOfDueDateDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: dueDate))!
            return now < endOfDueDateDay
        }
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
        case 1: return L("priority.low")
        case 2: return L("priority.medium")
        case 3: return L("priority.high")
        case 4: return L("priority.urgent")
        case 5: return L("priority.critical")
        default: return L("priority.medium")
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

        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 1st day of week

        let now = Date()
        var nextDueDate: Date

        switch interval {
        case .daily:
            // Next occurrence is tomorrow
            nextDueDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now

        case .weekly:
            if !weeklyDays.isEmpty {
                // Find next occurrence based on selected weekdays (Mon/Wed/Fri)
                nextDueDate = findNextWeeklyDate(from: now, weekdays: weeklyDays, calendar: calendar) ?? now
            } else if recurringCount > 1 {
                // X times per week - find next slot starting from Monday
                nextDueDate = findNextWeeklySlot(from: now, count: recurringCount, calendar: calendar) ?? now
            } else {
                // Once per week - next Monday
                nextDueDate = findNextMonday(from: now, calendar: calendar) ?? now
            }

        case .monthly:
            if recurringCount > 1 {
                // X times per month - space evenly from 1st of month
                nextDueDate = findNextMonthlySlot(from: now, count: recurringCount, calendar: calendar) ?? now
            } else {
                // Once per month - 1st of next month
                nextDueDate = findFirstOfNextMonth(from: now, calendar: calendar) ?? now
            }
        }

        return TaskItem(
            title: title,
            priority: priority,
            weight: 1.0,
            effort: effort,
            dueDate: nextDueDate,
            dueDateType: effectiveDueDateType,
            isRecurring: true,
            recurringInterval: interval,
            recurringCount: recurringCount,
            weeklyDays: weeklyDays
        )
    }

    /// Finds the next date that matches one of the selected weekdays (starting tomorrow)
    private func findNextWeeklyDate(from date: Date, weekdays: [Int], calendar: Calendar) -> Date? {
        var checkDate = date

        // Convert iOS weekday (1=Sun, 2=Mon) to our weekday (1=Sun, 2=Mon)
        // weekdays array uses iOS convention where 1=Sun, 2=Mon, etc.

        for _ in 1...8 {
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? checkDate
            let weekday = calendar.component(.weekday, from: checkDate)

            if weekdays.contains(weekday) {
                return checkDate
            }
        }

        return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
    }

    /// Find next Monday (week start)
    private func findNextMonday(from date: Date, calendar: Calendar) -> Date? {
        var checkDate = date

        for _ in 1...8 {
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? checkDate
            let weekday = calendar.component(.weekday, from: checkDate)

            if weekday == 2 { // Monday (in iOS calendar: 1=Sun, 2=Mon)
                return checkDate
            }
        }

        return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
    }

    /// Find next slot for X times per week (space evenly Mon-Sun)
    private func findNextWeeklySlot(from date: Date, count: Int, calendar: Calendar) -> Date? {
        let dayInterval = 7 / count // e.g., 3x/week = every 2-3 days

        // Get current day of week (Mon=1, Sun=7)
        let currentWeekday = calendar.component(.weekday, from: date)
        let mondayOffset = (2 - currentWeekday + 7) % 7 // Days to Monday

        // If today is not a slot day, find next slot
        var nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date

        // Simple approach: add dayInterval days from today
        nextDate = calendar.date(byAdding: .day, value: dayInterval, to: date) ?? date

        // If we've gone past Sunday, wrap to next Monday
        let nextWeekday = calendar.component(.weekday, from: nextDate)
        if nextWeekday == 1 { // Sunday, wrap to Monday
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        }

        return nextDate
    }

    /// Find 1st of next month
    private func findFirstOfNextMonth(from date: Date, calendar: Calendar) -> Date? {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        let components = calendar.dateComponents([.year, .month], from: nextMonth)
        return calendar.date(from: components)
    }

    /// Find next slot for X times per month (starting from 1st)
    private func findNextMonthlySlot(from date: Date, count: Int, calendar: Calendar) -> Date? {
        let dayInterval = 30 / count // e.g., 3x/month = every ~10 days

        let currentDay = calendar.component(.day, from: date)
        var nextDate = calendar.date(byAdding: .day, value: dayInterval, to: date) ?? date

        // Check if we've crossed into next month
        let nextMonth = calendar.component(.month, from: nextDate)
        let currentMonth = calendar.component(.month, from: date)

        if nextMonth != currentMonth {
            // Wrap to 1st of next month
            let components = calendar.dateComponents([.year, .month], from: nextDate)
            nextDate = calendar.date(from: components) ?? nextDate
        }

        return nextDate
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
