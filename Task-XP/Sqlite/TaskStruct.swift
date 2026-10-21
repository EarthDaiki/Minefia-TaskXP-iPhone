//
//  DataStruct.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/16/26.
//

import Foundation

struct Task: Identifiable, Codable {
    let id: Int
    var title: String
    var description: String?

    var dueAt: Int?
    var dueHasTime: Bool
    var startedAt: Int?
    var currentStartedAt: Int?

    var priority: Int
    var difficulty: Int

    var estimatedMinutes: Int?
    var actualSeconds: Int?

    var completed: Bool
    var createdAt: Int
    var updatedAt: Int
    var completedAt: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case dueAt = "due_at"
        case dueHasTime = "due_has_time"
        case startedAt = "started_at"
        case currentStartedAt = "current_started_at"
        case priority
        case difficulty
        case estimatedMinutes = "estimated_minutes"
        case actualSeconds = "actual_seconds"
        case completed
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
    }
}

struct Tag: Identifiable, Codable, Hashable {
    var id: Int
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}

struct TaskWithTags: Identifiable {
    let task: Task
    let tags: [Tag]
    
    var id: Int { task.id }
}

struct TagInUse: Identifiable {
    let tagId: Int
    var taskIds: [Int]
    
    var id: Int { tagId }
}
