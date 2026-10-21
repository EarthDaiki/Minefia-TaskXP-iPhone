//
//  TaskStore.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/24/26.
//

import Foundation

extension TaskStore {
    static var preview: TaskStore {
        let database = Database()
        let store = TaskStore(database: database)
        return store
    }
}

// This class does not have tasks. Use taskListStore.tasksWithTags
@Observable
final class TaskStore {
    let database: Database
    var errorMessage: String?
    
    init(database: Database) {
        self.database = database
    }

    func loadTasks() throws -> [Task] {
        return try database.getTasks()
    }
    func getTask(id: Int) throws -> Task {
        return try database.getTask(id: id)
    }
    func addTask (
        title: String,
        description: String,
        combinedDueDate: Date?,
        dueHasTime: Bool,
        priority: Int,
        difficulty: Int,
        estimatedMinutes: String,
        tagIds: [Int]
    ) throws -> Int64 {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw TaskValidationError.emptyTitle
        }
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptionText: String? = description.isEmpty ? nil : description
        let dueAt: Int?
        if let combinedDueDate {
            dueAt = Int(combinedDueDate.timeIntervalSince1970)
        } else {
            dueAt = nil
        }
        
        let estimatedMinutes = estimatedMinutes.trimmingCharacters(in: .whitespacesAndNewlines)
        let minutesValue: Int?
        if estimatedMinutes.isEmpty {
            minutesValue = nil
        } else if let value = Int(estimatedMinutes), value >= 0 {
            minutesValue = value
        } else {
            throw TaskValidationError.invalidEstimatedMinutes
        }
        
        guard (1...5).contains(priority) else {
            throw TaskValidationError.invalidPriority
        }
        
        guard (1...5).contains(difficulty) else {
            throw TaskValidationError.invalidDifficulty
        }
        
        return try database.addTaskWithTags(
            title: title,
            description: descriptionText,
            dueAt: dueAt,
            dueHasTime: dueHasTime,
            priority: priority,
            difficulty: difficulty,
            estimatedMinutes: minutesValue,
            tagIds: tagIds
        )
    }
    
    func updateTask(
        taskId: Int,
        title: String,
        description: String,
        combinedDueDate: Date?,
        dueHasTime: Bool,
        priority: Int,
        difficulty: Int,
        estimatedMinutes: String,
        tagIds: [Int]
    ) throws -> Int64 {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw TaskValidationError.emptyTitle
        }
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptionText: String? = description.isEmpty ? nil : description
        let dueAt: Int?
        if let combinedDueDate {
            dueAt = Int(combinedDueDate.timeIntervalSince1970)
        } else {
            dueAt = nil
        }
        
        let estimatedMinutes = estimatedMinutes.trimmingCharacters(in: .whitespacesAndNewlines)
        let minutesValue: Int?
        if estimatedMinutes.isEmpty {
            minutesValue = nil
        } else if let value = Int(estimatedMinutes), value >= 0 {
            minutesValue = value
        } else {
            throw TaskValidationError.invalidEstimatedMinutes
        }
        
        guard (1...5).contains(priority) else {
            throw TaskValidationError.invalidPriority
        }
        
        guard (1...5).contains(difficulty) else {
            throw TaskValidationError.invalidDifficulty
        }
        
        return try database.updateTaskWithTags(id: taskId, title: title, description: descriptionText, dueAt: dueAt, dueHasTime: dueHasTime, priority: priority, difficulty: difficulty, estimatedMinutes: minutesValue, tagIds: tagIds)
    }
    
    func startTask(id: Int) throws {
        try database.updateStartTaskDate(id: id)
    }
    
    func resetStartTask(id: Int) throws {
        try database.updateResetStartTaskDate(id: id)
    }
    
    func completeTask(id: Int) throws {
        try database.updateCompleteTask(id: id)
    }
    
    func resetCompleteTask(id: Int) throws {
        try database.updateResetCompleteTask(id: id)
    }
    
    func deleteTask(task: Task) throws {
        try database.deleteTask(sql: "DELETE FROM tasks WHERE id = ?", id: task.id)
    }
}
