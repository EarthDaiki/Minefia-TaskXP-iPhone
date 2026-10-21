//
//  ContentView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/16/26.
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case taskList
    case calendar
    case settings
}

struct ContentView: View {
    private let taskStore: TaskStore
    private let taskListStore: TaskListStore
    private let tagStore: TagStore
    private let startupState: StartupState
    @State private var selectedTab: AppTab = .home
    @State private var errorMessage: String?
    
    init(taskStore: TaskStore, taskListStore: TaskListStore, tagStore: TagStore, startupState: StartupState) {
        self.taskStore = taskStore
        self.taskListStore = taskListStore
        self.tagStore = tagStore
        self.startupState = startupState
    }
    
    var body: some View {
        TabView(selection: $selectedTab){
            HomeView(taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)
            
            TaskListView(taskStore: taskStore, taskListStore: taskListStore, tagStore: tagStore)
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.square")
                }
                .tag(AppTab.taskList)
            
            CalendarView(taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(AppTab.calendar)
            
            SettingsView(tagStore: tagStore, taskListStore: taskListStore)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(AppColors.primary)
        .task {
            do {
                switch startupState {
                case .ready:
                    break

                case .databaseError(let message):
                    errorMessage = message
                    return
                }
                try taskListStore.loadTasksAndTagsIfNeeded()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .errorAlert(title: "Load tasks and tags error", errorMessage: $errorMessage)
    }
}

private func makePreviewContentView() -> some View {
    let database = Database()
    let taskStore = TaskStore(database: database)
    let tagStore = TagStore(database: database)
    let taskListStore = TaskListStore(taskStore: taskStore, tagStore: tagStore)
    var startupState: StartupState = .ready
    do {
        try database.open()
    } catch {
        startupState = .databaseError(error.localizedDescription)
    }
    return ContentView(
        taskStore: taskStore,
        taskListStore: taskListStore,
        tagStore: tagStore,
        startupState: startupState
    )
}

#Preview {
    makePreviewContentView()
}
