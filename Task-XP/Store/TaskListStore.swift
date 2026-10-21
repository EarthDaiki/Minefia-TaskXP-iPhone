//
//  TaskListStore.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 8/24/26.
//

import Foundation

extension TaskListStore {

    static var preview: TaskListStore {
        let database = Database()
        let taskStore = TaskStore(database: database)
        let tagStore = TagStore(database: database)

        let store = TaskListStore(
            taskStore: taskStore,
            tagStore: tagStore
        )

        let calendar = Calendar.current
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        
        func yesterdayTimestamp(hour: Int, minute: Int) -> Int {
            let date = calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: yesterday ?? today
            )!
            
            return Int(date.timeIntervalSince1970)
        }

        func todayTimestamp(hour: Int, minute: Int) -> Int {
            let date = calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: today
            )!

            return Int(date.timeIntervalSince1970)
        }
        
        func tomorrowTimestamp(hour: Int, minute: Int) -> Int {
            let date = calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: tomorrow ?? today
            )!

            return Int(date.timeIntervalSince1970)
        }

        let now = Int(Date().timeIntervalSince1970)

        let task1 = Task(
            id: 1,
            title: "All Day Task",
            description: "",
            dueAt: todayTimestamp(hour: 0, minute: 0),
            dueHasTime: false,
            startedAt: nil,
            priority: 4,
            difficulty: 3,
            estimatedMinutes: 60,
            actualSeconds: nil,
            completed: false,
            createdAt: now,
            updatedAt: now,
            completedAt: nil
        )

        // 同時刻テスト: 1:30 PM
        let task2 = Task(
            id: 2,
            title: "Task A",
            description: "",
            dueAt: yesterdayTimestamp(hour: 13, minute: 30),
            dueHasTime: true,
            startedAt: nil,
            priority: 5,
            difficulty: 4,
            estimatedMinutes: 90,
            actualSeconds: nil,
            completed: false,
            createdAt: now,
            updatedAt: now,
            completedAt: nil
        )

        // task2と完全に同じ時刻
        let task3 = Task(
            id: 3,
            title: "Task B",
            description: "",
            dueAt: tomorrowTimestamp(hour: 13, minute: 30),
            dueHasTime: true,
            startedAt: nil,
            priority: 2,
            difficulty: 2,
            estimatedMinutes: 45,
            actualSeconds: nil,
            completed: false,
            createdAt: now,
            updatedAt: now,
            completedAt: nil
        )

        // 20分後 → Button高さ40ptなら重なる
        let task4 = Task(
            id: 4,
            title: "Task C",
            description: "",
            dueAt: tomorrowTimestamp(hour: 13, minute: 50),
            dueHasTime: true,
            startedAt: nil,
            priority: 2,
            difficulty: 1,
            estimatedMinutes: 30,
            actualSeconds: nil,
            completed: false,
            createdAt: now,
            updatedAt: now,
            completedAt: nil
        )

        // 十分離れているTask
        let task5 = Task(
            id: 5,
            title: "Task D",
            description: "",
            dueAt: tomorrowTimestamp(hour: 13, minute: 50),
            dueHasTime: true,
            startedAt: nil,
            priority: 3,
            difficulty: 3,
            estimatedMinutes: 120,
            actualSeconds: nil,
            completed: false,
            createdAt: now,
            updatedAt: now,
            completedAt: nil
        )

        store.tasksWithTags = [
            TaskWithTags(
                task: task1,
                tags: [
                    Tag(id: 1, name: "Home")
                ]
            ),

            TaskWithTags(
                task: task2,
                tags: [
                    Tag(id: 2, name: "Work")
                ]
            ),

            TaskWithTags(
                task: task3,
                tags: [
                    Tag(id: 3, name: "Study")
                ]
            ),

            TaskWithTags(
                task: task4,
                tags: [
                    Tag(id: 4, name: "Exercise")
                ]
            ),

            TaskWithTags(
                task: task5,
                tags: [
                    Tag(id: 5, name: "Yokohama")
                ]
            )
        ]

        return store
    }
}

enum TaskStoreError: Error {
    case taskNotFound(String)
    var errorDescription: String? {
        switch self {
        case .taskNotFound(let message):
            return "Unexpected error: task not found. \(message)"
        }
    }
}

@Observable
final class TaskListStore {
    private let taskStore: TaskStore
    private let tagStore: TagStore
    private var needsReload: Bool = true

    var tasksWithTags: [TaskWithTags] = []

    init(taskStore: TaskStore, tagStore: TagStore) {
        self.taskStore = taskStore
        self.tagStore = tagStore
    }
    
    func markNeedsReload() {
        needsReload = true
    }
    
    func addTaskWithTags(
        title: String,
        description: String,
        combinedDueDate: Date?,
        dueHasTime: Bool,
        priority: Int,
        difficulty: Int,
        estimatedMinutes: String,
        tagIds: [Int]
    ) throws {
        let newTaskId = try taskStore.addTask(
            title: title,
            description: description,
            combinedDueDate: combinedDueDate,
            dueHasTime: dueHasTime,
            priority: priority,
            difficulty: difficulty,
            estimatedMinutes: estimatedMinutes,
            tagIds: tagIds
        )
        let newTaskWithTags = try getTaskWithTags(id: Int(newTaskId))
        self.tasksWithTags.append(newTaskWithTags)
    }
    
    func updateTaskWithTags(
        taskId: Int,
        title: String,
        description: String,
        combinedDueDate: Date?,
        dueHasTime: Bool,
        priority: Int,
        difficulty: Int,
        estimatedMinutes: String,
        tagIds: [Int]
    ) throws -> TaskWithTags {
        let updatedTaskId = try taskStore.updateTask(taskId: taskId, title: title, description: description, combinedDueDate: combinedDueDate, dueHasTime: dueHasTime, priority: priority, difficulty: difficulty, estimatedMinutes: estimatedMinutes, tagIds: tagIds)
        let updatedTaskWithTags = try getTaskWithTags(id: Int(updatedTaskId))
        return try replaceTaskWithTags(updated: updatedTaskWithTags)
    }
    
    func removeDeletedTags(tagIds: [Int]) {
        tasksWithTags = tasksWithTags.map { taskWithTags in
            TaskWithTags(
                task: taskWithTags.task,
                tags: taskWithTags.tags.filter {
                    !tagIds.contains($0.id)
                }
            )
        }
    }
    
    func replaceTaskWithTags(updated: TaskWithTags) throws -> TaskWithTags {
        if let index = tasksWithTags.firstIndex(where: {$0.task.id == updated.task.id}) {
            tasksWithTags[index] = updated
            return updated
        }
        throw TaskStoreError.taskNotFound("replace failed")
    }
    
    func loadTasksAndTagsIfNeeded() throws {
        guard needsReload else { return }
        try loadTaskWithTags()
        needsReload = false
    }
    
    func getTaskWithTags(id: Int) throws -> TaskWithTags {
        let task = try taskStore.getTask(id: id)
        let tags = try tagStore.getTagsForTask(taskId: id)
        
        return TaskWithTags(task: task, tags: tags)
    }

    // This function loads all tasks, tags, and taskWithTags.
    func loadTaskWithTags() throws {
        let tasks = try taskStore.loadTasks()
        _ = try tagStore.loadAllTags()
        
        var loadedTaskWithTags: [TaskWithTags] = []
        
        for task in tasks {
            let tags = try tagStore.getTagsForTask(taskId: task.id)
            loadedTaskWithTags.append(TaskWithTags(task: task, tags: tags))
        }
        
        tasksWithTags = loadedTaskWithTags
        print("LOAD ALL TASKS.")
    }
    
    func startTask(id: Int) throws -> TaskWithTags {
        try taskStore.startTask(id: id)
        let startedTask = try getTaskWithTags(id: id)
        return try replaceTaskWithTags(updated: startedTask)
    }
    
    func resetStartTask(id: Int) throws -> TaskWithTags {
        try taskStore.resetStartTask(id: id)
        let resetTask = try getTaskWithTags(id: id)
        return try replaceTaskWithTags(updated: resetTask)
    }
    
    func completeTask(id: Int) throws -> TaskWithTags {
        try taskStore.completeTask(id: id)
        let completedTask = try getTaskWithTags(id: id)
        return try replaceTaskWithTags(updated: completedTask)
    }
    
    func resetCompleteTask(id: Int) throws -> TaskWithTags {
        try taskStore.resetCompleteTask(id: id)
        let resetTask = try getTaskWithTags(id: id)
        return try replaceTaskWithTags(updated: resetTask)
    }
    
    func deleteTaskWithTags(task: Task) throws {
        try taskStore.deleteTask(task: task)
        tasksWithTags.removeAll(where: { $0.task.id == task.id })
    }
}
