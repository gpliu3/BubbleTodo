//
//  ContentView.swift
//  BubbleTodo
//
//  Created by Gengpu Liu on 18/1/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted },
           sort: \TaskItem.createdAt)
    private var allTasks: [TaskItem]

    @State private var selectedTab = 0
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MainBubbleView()
            }
            .tabItem {
                Label(L("nav.bubbles"), systemImage: "bubble.fill")
            }
            .tag(0)

            NavigationStack {
                CompletedTasksView()
            }
            .tabItem {
                Label(L("nav.done"), systemImage: "checkmark.circle.fill")
            }
            .tag(1)

            SettingsView()
                .tabItem {
                    Label(L("nav.settings"), systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Update notifications with current tasks when app becomes active
                updateNotifications()
            }
        }
        .onChange(of: allTasks.count) { _, _ in
            // Update notifications when task count changes
            updateNotifications()
        }
    }

    private func updateNotifications() {
        guard notificationManager.isAuthorized && notificationManager.notificationsEnabled else {
            return
        }

        // Filter to today's tasks only
        let todayTasks = allTasks.filter { $0.shouldShowToday }

        Task {
            await notificationManager.scheduleNotificationWithTasks(todayTasks)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
