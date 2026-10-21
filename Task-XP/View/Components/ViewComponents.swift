//
//  TaskNavigationComponents.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 10/11/26.
//

import SwiftUI

private func realTimeElapsedCard(title: String, from timestamp: Int) -> some View {
    VStack(alignment: .leading) {
        let startDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
        TimelineView(.periodic(from:.now, by: 1)) { context in
            let elapsed: Int = Int(context.date.timeIntervalSince(startDate))
            let hours = elapsed / 3600
            let minutes = (elapsed % 3600) / 60
            
            // Needs space between minutes num and m ??
            if hours <= 0 {
                if minutes <= 0 {
                    Text("less than 1 minute")
                        .primaryTextStyle()
                } else {
                    Text("\(minutes)m")
                        .primaryTextStyle()
                }
            } else {
                Text("\(hours)h \(minutes)m")
                    .primaryTextStyle()
            }
        }
    }
}

func emptyStateView(title: String, description: String) -> some View {
    VStack {
        Text(title)
            .emptyStateTextStyle()
        Text(description)
            .primaryTextStyle()
    }
    .padding()
}

struct TaskNavigation: View {
    private let taskStore: TaskStore
    private let tagStore: TagStore
    private let taskListStore:TaskListStore
    private let taskWithTags: TaskWithTags
    @Binding private var errorMessage: String?
    private let onDelete: (Task) -> Void
    
    init(taskStore: TaskStore, tagStore: TagStore, taskListStore: TaskListStore, taskWithTags: TaskWithTags, errorMessage: Binding<String?>, onDelete: @escaping (Task) -> Void) {
        self.taskStore = taskStore
        self.tagStore = tagStore
        self.taskListStore = taskListStore
        self.taskWithTags = taskWithTags
        self._errorMessage = errorMessage
        self.onDelete = onDelete
    }
    
    // add some info for example priority, started, etc..
    
    private var dueDate: String? {
        guard let dueAt = taskWithTags.task.dueAt else {
            return nil
        }
        let dueDate = Date(timeIntervalSince1970: TimeInterval(dueAt))
        
        return dueDate.formatted(.dateTime.month().day().hour().minute())
    }
    var body: some View {
        NavigationLink {
            IndivTaskView(taskWithTags: taskWithTags, taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore)
        } label: {
            VStack {
                HStack {
                    Text(taskWithTags.task.title)
                        .rowTitleTextStyle()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .navigationIndicatorStyle()
                }
                HStack {
                    if let dueDate {
                        Text(dueDate)
                    }
                }
            }
        }
        .appTaskCard()
        .contextMenu {
            if taskWithTags.task.startedAt != nil, !taskWithTags.task.completed {
                Button {
                    do {
                        try taskStore.completeTask(id: taskWithTags.task.id)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } label : {
                    Label("Complete", systemImage: "checkmark")
                }
            } else {
                Button {
                    do {
                        try taskStore.startTask(id: taskWithTags.task.id)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } label : {
                    Label("Start Working", systemImage: "play")
                }
            }
            Button(role: .destructive) {
                onDelete(taskWithTags.task)
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }
}
