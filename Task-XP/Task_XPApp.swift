//
//  Task_XPApp.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/16/26.
//

import SwiftUI

enum StartupState {
    case databaseError(String)
    case ready
    
    var localizedDescription: String {
        switch self {
        case .databaseError(let message):
            return "\(message)"
        case .ready:
            return "Ready"
        }
    }
}

@main
struct Task_XPApp: App {
    private let database: Database
    private let taskStore: TaskStore
    private let taskListStore: TaskListStore
    private let tagStore: TagStore
    
    private let startupState: StartupState
    
    init() {
        let database = Database()
        do {
            try database.open()
            startupState = .ready
        } catch {
            startupState = .databaseError(error.localizedDescription)
//            print("Database initialization failed: \(error)")
        }
        
        self.database = database
        self.taskStore = TaskStore(database: database)
        self.tagStore = TagStore(database: database)
        self.taskListStore = TaskListStore(taskStore: taskStore, tagStore: tagStore)
        
        // NavigationBar
        let navigationBarAppearance = UINavigationBarAppearance()
        let largeBaseFont = UIFont(name: "Poppins-Bold", size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold)
        let inlineBaseFont = UIFont(name: "Poppins-SemiBold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)

        let largeFont = UIFontMetrics(forTextStyle: .largeTitle)
            .scaledFont(for: largeBaseFont)

        let inlineFont = UIFontMetrics(forTextStyle: .headline)
            .scaledFont(for: inlineBaseFont)

        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textPrimary),
            .font: largeFont
        ]

        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textPrimary),
            .font: inlineFont
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        
        //Picker
        let segmentedControlAppearance = UISegmentedControl.appearance()
        segmentedControlAppearance.selectedSegmentTintColor = UIColor(AppColors.primary)
        segmentedControlAppearance.setTitleTextAttributes(
            [.foregroundColor: UIColor(AppColors.textPrimary)],
            for: .selected
        )
        segmentedControlAppearance.setTitleTextAttributes(
            [.foregroundColor: UIColor(AppColors.textSecondary)],
            for: .normal
        )
        segmentedControlAppearance.backgroundColor = UIColor(AppColors.card)
        
        //TabBar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppColors.card)
        
        let normalColor = UIColor(AppColors.textSecondary)
        let selectedColor = UIColor(AppColors.primary)
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor
        ]
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        
    }
    var body: some Scene {
        WindowGroup {
            ContentView(
                taskStore: taskStore,
                taskListStore: taskListStore,
                tagStore: tagStore,
                startupState: startupState
            )
        }
    }
}
