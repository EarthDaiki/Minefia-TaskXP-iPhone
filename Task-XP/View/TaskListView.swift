//
//  TaskListView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/16/26.
//

import SwiftUI

enum TaskFilter: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case today = "Today"
    case upcoming = "Upcoming"
    case completed = "Completed"
    case tag = "Tag"
    
    var id: Self { self }
}

enum TaskSort: String, CaseIterable, Identifiable {
    case createdDate = "Created Date"
    case dueDate = "Due Date"
    case priority = "Priority"
    case difficulty = "Difficulty"
    
    var id: Self { self }
}

enum TaskSortOrder: String, CaseIterable, Identifiable {
    case ascending = "Ascending"
    case descending = "Descending"
    
    var id: Self { self }
}

struct TaskListView: View {
    private let taskStore: TaskStore
    private let taskListStore: TaskListStore
    private let tagStore: TagStore
    init(taskStore: TaskStore, taskListStore: TaskListStore, tagStore: TagStore) {
        self.taskStore = taskStore
        self.taskListStore = taskListStore
        self.tagStore = tagStore
    }
    @State private var selectedFilter: TaskFilter = .inbox
    @State private var selectedSort: TaskSort = .createdDate
    @State private var selectedSortOrder: TaskSortOrder = .descending
    @State private var taskToDelete: Task?
    @State private var errorMessage: String?
    @State private var showAddTask: Bool = false
    @State private var expandedTagIds: Set<Int> = []
    
    private func filterPickerView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TaskFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                    }
                    .buttonStyle(.plain)
                    .appFilterButtonStyle(isSelected: selectedFilter == filter)
                }
            }
        }
    }
    
    private func sortSectionView() -> some View {
        Menu {
            Picker("Sort", selection: $selectedSort){
                ForEach(TaskSort.allCases) { sort in
                    Text(sort.rawValue).tag(sort)
                }
            }
        } label: {
            HStack {
                Text(selectedSort.rawValue)
                Image(systemName: "chevron.up.chevron.down")
            }
            .frame(width: 140)
        }
        .appPickerStyle()
    }
    
    private func sortOrderSectionView() -> some View {
        Menu {
            Picker("Sort Order", selection: $selectedSortOrder) {
                ForEach(TaskSortOrder.allCases) { sort in
                    Text(sort.rawValue).tag(sort)
                }
            }
        } label: {
            HStack {
                Text(selectedSortOrder.rawValue)
                Image(systemName: "chevron.up.chevron.down")
            }
            .frame(width: 140)
        }
        .appPickerStyle()
    }
    
    @ViewBuilder
    private func tagFilterView() -> some View {
        if tagStore.tags.isEmpty {
            Text("No tags")
                .primaryTextStyle()
        } else {
            ForEach(tagStore.tags) { tag in
                let tasksWithTags = sortedOrderTasksWithTags.filter {
                    $0.tags.contains(where: { $0.id == tag.id })
                }
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedTagIds.contains(tag.id) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedTagIds.insert(tag.id)
                            } else {
                                expandedTagIds.remove(tag.id)
                            }
                        }
                    )
                ) {
                    LazyVStack(spacing: 12) {
                        if tasksWithTags.count == 0 {
                            Text("No tasks")
                                .primaryTextStyle()
                        } else {
                            ForEach(tasksWithTags) { taskWithTags in
                                TaskNavigation(taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore, taskWithTags: taskWithTags, errorMessage: $errorMessage, onDelete: { _ in requestDelete(task: taskWithTags.task) })
                            }
                        }
                    }
                    .padding(.vertical)
                } label: {
                    HStack {
                        Text(tag.name)
                            .primaryTextStyle()
                        Spacer()
                        Text("\(tasksWithTags.count)")
                            .primaryTextStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(
                    AppColors.card.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.textSecondary.opacity(0.4), lineWidth: 1)
                }
                .disclosureGroupStyle(CustomDisclosureStyle())
            }
        }
    }
    
    private var filteredTasksWithTags: [TaskWithTags] {
        switch selectedFilter {
        case .inbox:
            return taskListStore.tasksWithTags.filter { !$0.task.completed }
        case .today:
            return taskListStore.tasksWithTags.filter { item in
                guard let dueAt = item.task.dueAt else {
                    return false
                }
                let dueDate = Date(timeIntervalSince1970: TimeInterval(dueAt))
                return !item.task.completed && Calendar.current.isDateInToday(dueDate)
            }
        case .upcoming:
            return taskListStore.tasksWithTags.filter { item in
                guard let dueAt = item.task.dueAt else {
                    return false
                }
                let dueDate = Date(timeIntervalSince1970: TimeInterval(dueAt))
                return !item.task.completed && dueDate > Date()
            }
        case .completed:
            return taskListStore.tasksWithTags.filter { $0.task.completed }
        case .tag:
            return taskListStore.tasksWithTags
        }
    }
    
    private var sortedTasksWithTags: [TaskWithTags] {
        switch selectedSort {
        case .createdDate:
            return filteredTasksWithTags
        case .dueDate:
            return filteredTasksWithTags.sorted { lhs, rhs in
                switch (lhs.task.dueAt, rhs.task.dueAt) {
                case let (lhsDueAt?, rhsDueAt?):
                    return lhsDueAt < rhsDueAt
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return false
                }
            }
        case .priority:
            return filteredTasksWithTags.sorted { lhs, rhs in
                if lhs.task.priority == rhs.task.priority {
                    return lhs.task.title.lowercased() < rhs.task.title.lowercased()
                } else {
                    return lhs.task.priority < rhs.task.priority
                }
            }
        case .difficulty:
            return filteredTasksWithTags.sorted { lhs, rhs in
                if lhs.task.difficulty == rhs.task.difficulty {
                    return lhs.task.title.lowercased() < rhs.task.title.lowercased()
                } else {
                    return lhs.task.difficulty < rhs.task.difficulty
                }
            }
        }
    }
    
    private var sortedOrderTasksWithTags: [TaskWithTags] {
        switch selectedSortOrder {
        case .ascending:
            return sortedTasksWithTags
        case .descending:
            return Array(sortedTasksWithTags.reversed())
        }
    }
    
    private func requestDelete(task: Task) {
        taskToDelete = task
    }
    
    private var deleteMessage: String {
        guard let taskToDelete else {
            return ""
        }

        return "\"\(taskToDelete.title)\" will be permanently deleted."
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)
                    VStack(spacing: 10) {
                        filterPickerView()
                            .padding(.horizontal)
                        HStack {
                            sortSectionView()
                            sortOrderSectionView()
                        }
                    }
                    .padding(.vertical, 5)
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)
                }
                .background {
                    AppColors.card.opacity(0.4)
                }
                if sortedOrderTasksWithTags.isEmpty {
                    Spacer()
                    Text("No Tasks")
                        .primaryTextStyle()
                    Spacer()
                } else {
                    // Adding swipe delete would be useful. Need to create costom view.
                    if selectedFilter == .tag {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                tagFilterView()
                            }
                        }
                        .padding()
                        .scrollContentBackground(.hidden)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(sortedOrderTasksWithTags) { taskWithTags in
                                    TaskNavigation(taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore, taskWithTags: taskWithTags, errorMessage: $errorMessage, onDelete: { _ in requestDelete(task: taskWithTags.task) })
                                }
                            }
                        }
                        .padding()
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .appBackground()
            // using an alert but this is confirmation to delete a task.
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTask = true
                    } label: {
                        Label("Add task", systemImage: "plus")
                    }
                    .appButtonImageStyle()
                    .sheet(isPresented: $showAddTask) {
                        AddTaskView(showAddTask: $showAddTask, taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore)
                    }
                }
            }
            .navigationTitle(selectedFilter.rawValue)
            .toolbarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    TaskListView(taskStore: .preview,taskListStore: .preview, tagStore: .preview)
}
