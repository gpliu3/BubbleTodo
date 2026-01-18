//
//  MainBubbleView.swift
//  BubbleTodo
//

import SwiftUI
import SwiftData

struct MainBubbleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted },
           sort: \TaskItem.createdAt)
    private var tasks: [TaskItem]

    @State private var showingAddSheet = false
    @State private var selectedTask: TaskItem?
    @State private var showingEditSheet = false

    // Undo state
    @State private var recentlyCompletedTask: TaskItem?
    @State private var createdRecurringTask: TaskItem?
    @State private var showUndoToast = false
    @State private var undoTimer: Timer?

    // Sort tasks by bubble size (biggest first - they float to top)
    private var sortedTasks: [TaskItem] {
        tasks.sorted { $0.bubbleSize > $1.bubbleSize }
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if tasks.isEmpty {
                emptyStateView
            } else {
                bubbleGridView
            }

            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                }
            }
            .padding()
            .padding(.bottom, showUndoToast ? 60 : 0)

            // Undo toast
            if showUndoToast, let completedTask = recentlyCompletedTask {
                VStack {
                    Spacer()
                    UndoToastView(
                        taskTitle: completedTask.title,
                        onUndo: {
                            undoCompletion()
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Bubbles")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddSheet) {
            AddTaskSheet()
        }
        .sheet(isPresented: $showingEditSheet) {
            if let task = selectedTask {
                EditTaskSheet(task: task)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No tasks yet!")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Tap + to add your first bubble")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var bubbleGridView: some View {
        GeometryReader { geometry in
            ScrollView {
                BubbleLayoutView(
                    tasks: sortedTasks,
                    containerWidth: geometry.size.width,
                    onTap: { task in
                        completeTask(task)
                    },
                    onLongPress: { task in
                        selectedTask = task
                        showingEditSheet = true
                    }
                )
                .padding(.top, 20)
                .padding(.bottom, 100) // Space for add button
            }
        }
    }

    private var addButton: some View {
        Button(action: {
            showingAddSheet = true
        }) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }

    private func completeTask(_ task: TaskItem) {
        // Cancel any existing undo timer
        undoTimer?.invalidate()

        withAnimation {
            task.markComplete()

            // Store for undo
            recentlyCompletedTask = task
            createdRecurringTask = nil

            // If recurring, create the next instance
            if let nextTask = task.createNextRecurringTask() {
                modelContext.insert(nextTask)
                createdRecurringTask = nextTask
            }

            // Show undo toast
            showUndoToast = true
        }

        // Start 3 second timer
        undoTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                showUndoToast = false
                recentlyCompletedTask = nil
                createdRecurringTask = nil
            }
        }
    }

    private func undoCompletion() {
        undoTimer?.invalidate()

        withAnimation {
            // Undo the task completion
            recentlyCompletedTask?.undoComplete()

            // Remove the recurring task if one was created
            if let recurringTask = createdRecurringTask {
                modelContext.delete(recurringTask)
            }

            showUndoToast = false
            recentlyCompletedTask = nil
            createdRecurringTask = nil
        }
    }
}

// MARK: - Undo Toast View

struct UndoToastView: View {
    let taskTitle: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            Text("Completed: \(taskTitle)")
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Button(action: onUndo) {
                Text("Undo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Bubble Layout View

struct BubbleLayoutView: View {
    let tasks: [TaskItem]
    let containerWidth: CGFloat
    let onTap: (TaskItem) -> Void
    let onLongPress: (TaskItem) -> Void

    var body: some View {
        let positions = calculateBubblePositions()

        ZStack(alignment: .top) {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                if index < positions.count {
                    BubbleView(
                        task: task,
                        onTap: { onTap(task) },
                        onLongPress: { onLongPress(task) }
                    )
                    .position(positions[index])
                }
            }
        }
        .frame(width: containerWidth, height: calculateTotalHeight())
    }

    private func bubbleDiameter(for task: TaskItem) -> CGFloat {
        let baseSize: CGFloat = 60
        let scaleFactor: CGFloat = 15
        let size = baseSize + CGFloat(task.bubbleSize) * scaleFactor
        return min(max(size, 60), 180)
    }

    private func calculateBubblePositions() -> [CGPoint] {
        var positions: [CGPoint] = []
        var currentY: CGFloat = 0
        var currentRowBubbles: [(task: TaskItem, x: CGFloat, width: CGFloat)] = []
        var currentRowWidth: CGFloat = 0
        let padding: CGFloat = 16
        let availableWidth = containerWidth - (padding * 2)

        for task in tasks {
            let diameter = bubbleDiameter(for: task)
            let bubbleWidth = diameter + 8 // Add some spacing

            // Check if bubble fits in current row
            if currentRowWidth + bubbleWidth > availableWidth && !currentRowBubbles.isEmpty {
                // Finalize current row - center it
                let rowHeight = currentRowBubbles.map { bubbleDiameter(for: $0.task) }.max() ?? 0
                let totalRowWidth = currentRowBubbles.reduce(0) { $0 + bubbleDiameter(for: $1.task) + 8 }
                var xOffset = (containerWidth - totalRowWidth) / 2

                for bubble in currentRowBubbles {
                    let d = bubbleDiameter(for: bubble.task)
                    positions.append(CGPoint(
                        x: xOffset + d / 2,
                        y: currentY + rowHeight / 2
                    ))
                    xOffset += d + 8
                }

                // Start new row
                currentY += rowHeight + 16
                currentRowBubbles = []
                currentRowWidth = 0
            }

            currentRowBubbles.append((task: task, x: currentRowWidth, width: bubbleWidth))
            currentRowWidth += bubbleWidth
        }

        // Finalize last row
        if !currentRowBubbles.isEmpty {
            let rowHeight = currentRowBubbles.map { bubbleDiameter(for: $0.task) }.max() ?? 0
            let totalRowWidth = currentRowBubbles.reduce(0) { $0 + bubbleDiameter(for: $1.task) + 8 }
            var xOffset = (containerWidth - totalRowWidth) / 2

            for bubble in currentRowBubbles {
                let d = bubbleDiameter(for: bubble.task)
                positions.append(CGPoint(
                    x: xOffset + d / 2,
                    y: currentY + rowHeight / 2
                ))
                xOffset += d + 8
            }
        }

        return positions
    }

    private func calculateTotalHeight() -> CGFloat {
        var currentY: CGFloat = 0
        var currentRowBubbles: [TaskItem] = []
        var currentRowWidth: CGFloat = 0
        let padding: CGFloat = 16
        let availableWidth = containerWidth - (padding * 2)

        for task in tasks {
            let diameter = bubbleDiameter(for: task)
            let bubbleWidth = diameter + 8

            if currentRowWidth + bubbleWidth > availableWidth && !currentRowBubbles.isEmpty {
                let rowHeight = currentRowBubbles.map { bubbleDiameter(for: $0) }.max() ?? 0
                currentY += rowHeight + 16
                currentRowBubbles = []
                currentRowWidth = 0
            }

            currentRowBubbles.append(task)
            currentRowWidth += bubbleWidth
        }

        // Add last row height
        if !currentRowBubbles.isEmpty {
            let rowHeight = currentRowBubbles.map { bubbleDiameter(for: $0) }.max() ?? 0
            currentY += rowHeight
        }

        return currentY + 50 // Extra padding at bottom
    }
}

#Preview {
    NavigationStack {
        MainBubbleView()
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
