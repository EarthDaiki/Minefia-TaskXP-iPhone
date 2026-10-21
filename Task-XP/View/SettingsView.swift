//
//  SettingsView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/16/26.
//

import SwiftUI

struct SettingsView: View {
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    init(tagStore: TagStore, taskListStore: TaskListStore) {
        self.tagStore = tagStore
        self.taskListStore = taskListStore
    }
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ApiKeyView()
                } label: {
                    Text("API Management")
                        .primaryTextStyle()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .navigationIndicatorStyle()
                }
                .appListRowStyle()
                NavigationLink {
                    TagManagementView(tagStore: tagStore, taskListStore: taskListStore)
                } label: {
                    Text("Tag Management")
                        .primaryTextStyle()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .navigationIndicatorStyle()
                }
                .appListRowStyle()
            }
            .navigationLinkIndicatorVisibility(.hidden)
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .appBackground()
        }
    }
}

#Preview {
    SettingsView(tagStore: .preview, taskListStore: .preview)
}
