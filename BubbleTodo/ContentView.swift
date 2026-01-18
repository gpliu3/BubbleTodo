//
//  ContentView.swift
//  BubbleTodo
//
//  Created by Gengpu Liu on 18/1/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MainBubbleView()
            }
            .tabItem {
                Label("Bubbles", systemImage: "bubble.fill")
            }
            .tag(0)

            NavigationStack {
                CompletedTasksView()
            }
            .tabItem {
                Label("Done", systemImage: "checkmark.circle.fill")
            }
            .tag(1)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
