//
//  HomeView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/16/26.
//

import SwiftUI
import Charts

struct TaskChartData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct CurrentRunningTaskView: View {
    private let taskStore: TaskStore
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    @State private var isExpanded: Bool = false
    @Binding private var taskToDelete: Task?
    @Binding private var errorMessage: String?
    
    init(taskStore: TaskStore, tagStore: TagStore, taskListStore: TaskListStore, taskToDelete: Binding<Task?>, errorMessage: Binding<String?>) {
        self.taskStore = taskStore
        self.tagStore = tagStore
        self.taskListStore = taskListStore
        self._taskToDelete = taskToDelete
        self._errorMessage = errorMessage
    }
    
    private var currentRunningTasks: [TaskWithTags] {
        taskListStore.tasksWithTags.filter {
            guard $0.task.startedAt != nil else {
                return false
            }
            
            if $0.task.completed {
                return false
            }
            return true
        }
    }
    
    private func requestDelete(task: Task) {
        taskToDelete = task
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if currentRunningTasks.isEmpty {
                emptyStateView(title: "No current task running", description: "")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(currentRunningTasks) { taskWithTags in
                            TaskNavigation(taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore, taskWithTags: taskWithTags, errorMessage: $errorMessage, onDelete: { _ in requestDelete(task: taskWithTags.task) })
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        } label: {
            HStack {
                Text("Running Tasks")
                    .emphasizedTextStyle()
                Spacer()
                Text("\(currentRunningTasks.count)")
                    .primaryTextStyle()
            }
        }
        .appDisclosureCard()
    }
}

struct OverdueTaskView: View {
    private let taskStore: TaskStore
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    @State private var isExpanded: Bool = false
    @Binding private var taskToDelete: Task?
    @Binding private var errorMessage: String?
    
    init(taskStore: TaskStore, tagStore: TagStore, taskListStore: TaskListStore, taskToDelete: Binding<Task?>, errorMessage: Binding<String?>) {
        self.taskStore = taskStore
        self.tagStore = tagStore
        self.taskListStore = taskListStore
        self._taskToDelete = taskToDelete
        self._errorMessage = errorMessage
    }
    
    private var overdueTasks: [TaskWithTags] {
        taskListStore.tasksWithTags.filter {
            guard let dueAt = $0.task.dueAt else {
                return false
            }
            
            if $0.task.completed || !$0.task.dueHasTime {
                return false
            }
            
            let dueDate = Date(timeIntervalSince1970: TimeInterval(dueAt))
            
            return dueDate < Date()
        }
    }
    
    private func requestDelete(task: Task) {
        taskToDelete = task
    }
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded
        ) {
            if overdueTasks.isEmpty {
                emptyStateView(title: "No overdue tasks", description: "")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(overdueTasks) { taskWithTags in
                            TaskNavigation(taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore, taskWithTags: taskWithTags, errorMessage: $errorMessage, onDelete: { _ in requestDelete(task: taskWithTags.task) })
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        } label: {
            HStack {
                Text("Overdue Tasks")
                    .emphasizedTextStyle()
                Spacer()
                Text("\(overdueTasks.count)")
                    .primaryTextStyle()
            }
        }
        .appDisclosureCard()
    }
}

struct TodayTaskView: View {
    private let taskStore: TaskStore
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    @State private var isExpanded: Bool = false
    @Binding private var taskToDelete: Task?
    @Binding private var errorMessage: String?
    
    init(taskStore: TaskStore, tagStore: TagStore, taskListStore: TaskListStore, taskToDelete: Binding<Task?>, errorMessage: Binding<String?>) {
        self.taskStore = taskStore
        self.tagStore = tagStore
        self.taskListStore = taskListStore
        self._taskToDelete = taskToDelete
        self._errorMessage = errorMessage
    }
    
    private var todayTasks: [TaskWithTags] {
        let todayTask = taskListStore.tasksWithTags.filter {
            guard let dueAt = $0.task.dueAt else {
                return false
            }
            let dueDate = Date(timeIntervalSince1970: TimeInterval(dueAt))
            return Calendar.current.isDateInToday(dueDate)
        }
        
        return todayTask.sorted { lhs, rhs in
            guard let lhsDueAt = lhs.task.dueAt, let rhsDueAt = rhs.task.dueAt else {
                return false
            }
            
            if lhsDueAt != rhsDueAt {
                return lhsDueAt < rhsDueAt
            }
            
            if lhs.task.priority != rhs.task.priority {
                return lhs.task.priority > rhs.task.priority
            }
            if lhs.task.difficulty != rhs.task.difficulty {
                return lhs.task.difficulty > rhs.task.difficulty
            }
            
            return lhs.task.title < rhs.task.title
        }
    }
    
    private var completedData: TaskChartData {
        let completedCount = todayTasks.filter {
            $0.task.completed
        }.count
        
        return TaskChartData(name: "Completed", count: completedCount)
    }
    
    private var notCompletedData: TaskChartData {
        let notCompletedCount = todayTasks.filter {
            !$0.task.completed
        }.count
        
        return TaskChartData(name: "Not Completed", count: notCompletedCount)
    }
    
    private var completePercent: Double {
        Double(completedData.count) / Double(completedData.count + notCompletedData.count)
    }
    
    private var completeChartData: [TaskChartData] {
        [completedData, notCompletedData]
    }
    
    private func requestDelete(task: Task) {
        taskToDelete = task
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if todayTasks.isEmpty {
                emptyStateView(title: "No today's task", description: "")
            } else {
                HStack(spacing: 10) {
                    VStack {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(todayTasks) { taskWithTags in
                                    TaskNavigation(taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore, taskWithTags: taskWithTags, errorMessage: $errorMessage, onDelete: { _ in requestDelete(task: taskWithTags.task) })
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    Chart(completeChartData) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.6)
                        )
                        .foregroundStyle(by: .value("Type", item.name))
                    }
                    .frame(height: 250)
                    .chartText(text: "\(completePercent)%")
                    .chartForegroundStyleScale([
                        completedData.name: .green,
                        notCompletedData.name: .gray
                    ])
                }
            }
        } label: {
            HStack {
                Text("Today's Tasks")
                    .emphasizedTextStyle()
                Spacer()
                Text("\(todayTasks.count)")
                    .primaryTextStyle()
            }
        }
        .appDisclosureCard()
    }
}

struct HomeView: View {
    private let taskStore: TaskStore
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    @State private var taskToDelete: Task?
    @State private var errorMessage: String?
    
    init(taskStore: TaskStore, tagStore: TagStore, taskListStore: TaskListStore) {
        self.taskStore = taskStore
        self.tagStore = tagStore
        self.taskListStore = taskListStore
    }
    
    private var deleteMessage: String {
        guard let taskToDelete else {
            return ""
        }
        return "\"\(taskToDelete.title)\" will be permanently deleted."
    }
    
    private var completedData: TaskChartData {
        let completedCount = taskListStore.tasksWithTags.filter {
            $0.task.completed
        }.count
        
        return TaskChartData(name: "Completed", count: completedCount)
    }
    
    private var notCompletedData: TaskChartData {
        let notCompletedCount = taskListStore.tasksWithTags.filter {
            !$0.task.completed
        }.count
        
        return TaskChartData(name: "Not Completed", count: notCompletedCount)
    }
    
    private var completePercent: Double {
        Double(completedData.count) / Double(completedData.count + notCompletedData.count)
    }
    
    private var completeChartData: [TaskChartData] {
        [completedData, notCompletedData]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    CurrentRunningTaskView(
                        taskStore: taskStore,
                        tagStore: tagStore,
                        taskListStore: taskListStore,
                        taskToDelete: $taskToDelete,
                        errorMessage: $errorMessage
                    )
                    OverdueTaskView(
                        taskStore: taskStore,
                        tagStore: tagStore,
                        taskListStore: taskListStore,
                        taskToDelete: $taskToDelete,
                        errorMessage: $errorMessage
                    )
                    TodayTaskView(
                        taskStore: taskStore,
                        tagStore: tagStore,
                        taskListStore: taskListStore,
                        taskToDelete: $taskToDelete,
                        errorMessage: $errorMessage
                    )
                    if taskListStore.tasksWithTags.isEmpty {
                        emptyStateView(title: "No tasks", description: "")
                    } else {
                        Chart(completeChartData) { item in
                            SectorMark(
                                angle: .value("Count", item.count),
                                innerRadius: .ratio(0.6)
                            )
                            .foregroundStyle(by: .value("Type", item.name))
                        }
                        .frame(height: 350)
                        .chartText(title: "Completed Tasks", text: "\(completePercent)%")
                        .chartForegroundStyleScale([
                            completedData.name: .green,
                            notCompletedData.name: .gray
                        ])
                    }
                }
                .padding(.horizontal, 16)
            }
            .confirmationAlert(
                title: "Delete this task?",
                isPresented: Binding(
                    get: {
                        taskToDelete != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            taskToDelete = nil
                        }
                    }
                ),
                message: deleteMessage
            )
            .errorAlert(title: "Task Error", errorMessage: $errorMessage)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .appBackground()
        }
    }
}

#Preview {
    HomeView(taskStore: .preview, tagStore: .preview, taskListStore: .preview)
}
