//
//  Database.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/16/26.
//

import Foundation
import SQLite3

final class Database {
    private var db: OpaquePointer?
    private var errorMessage: String {
        guard let db else {
            return "Database is not opened."
        }
        return String(cString: sqlite3_errmsg(db))
    }
    
    private func stringValue(statement: OpaquePointer?, index: Int32) -> String?{
        guard sqlite3_column_type(statement, index) != SQLITE_NULL,
              let value = sqlite3_column_text(statement, index) else {
            return nil
        }
        return String(cString: value)
    }
    
    private func integerValue(statement: OpaquePointer?, index: Int32) -> Int?{
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else {
            return nil
        }
        return Int(sqlite3_column_int64(statement, index))
    }
    
    func open() throws {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw DatabaseError.documentDirectoryNotFound
        }
        let databaseURL = documentDirectory
            .appendingPathComponent("task_xp.sqlite")
        if sqlite3_open(databaseURL.path, &db) != SQLITE_OK {
            throw DatabaseError.openFailed(errorMessage)
        }
        
        try createTables()
        
        print("Database Path: \(databaseURL.path)")
    }
    
    func createTables() throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,

            due_at INTEGER,
            due_has_time INTEGER NOT NULL DEFAULT 0
                CHECK (due_has_time IN (0, 1)),
            started_at INTEGER,
            current_started_at INTEGER,

            priority INTEGER NOT NULL DEFAULT 1
                CHECK (priority >= 1 AND priority <= 5),
            difficulty INTEGER NOT NULL DEFAULT 1
                CHECK (difficulty >= 1 AND difficulty <= 5),

            estimated_minutes INTEGER
                CHECK (
                    estimated_minutes IS NULL
                    OR estimated_minutes >= 0
                ),

            actual_seconds INTEGER
                CHECK (
                    actual_seconds IS NULL
                    OR actual_seconds >= 0
                ),

            completed INTEGER NOT NULL DEFAULT 0
                CHECK (completed IN (0, 1)),

            created_at INTEGER NOT NULL DEFAULT (unixepoch()),
            updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
            completed_at INTEGER,

            CHECK (
                (completed = 0 AND completed_at IS NULL)
                OR
                (completed = 1 AND completed_at IS NOT NULL)
            )
        );

        CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
        );

        CREATE TABLE IF NOT EXISTS task_tags (
            task_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,

            PRIMARY KEY (task_id, tag_id),

            FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
        );
        """
        
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            throw DatabaseError.createTableFailed(errorMessage)
        }
    }
    
    func getTask(id: Int) throws -> Task {
        let sql = "SELECT * FROM tasks WHERE id = ?1;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        sqlite3_bind_int(statement, 1, Int32(id))

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw DatabaseError.invalidTask("Task not found: \(errorMessage)")
        }
        return Task(
            id: Int(sqlite3_column_int64(statement, 0)),
            title: String(cString: sqlite3_column_text(statement, 1)),
            description: stringValue(statement: statement, index: 2),
            dueAt: integerValue(statement: statement, index: 3),
            dueHasTime: sqlite3_column_int(statement, 4) == 1,
            startedAt: integerValue(statement: statement, index: 5),
            currentStartedAt: integerValue(statement: statement, index: 6),
            priority: Int(sqlite3_column_int(statement, 7)),
            difficulty: Int(sqlite3_column_int(statement, 8)),
            estimatedMinutes: integerValue(statement: statement, index: 9),
            actualSeconds: integerValue(statement: statement, index: 10),
            completed: Int(sqlite3_column_int(statement, 11)) == 1,
            createdAt: Int(sqlite3_column_int64(statement, 12)),
            updatedAt: Int(sqlite3_column_int64(statement, 13)),
            completedAt: integerValue(statement: statement, index: 14)
        )
    }
    
    func getTasks() throws -> [Task] {
        let sql = """
        SELECT
            id,
            title,
            description,
            due_at,
            due_has_time,
            started_at,
            current_started_at,
            priority,
            difficulty,
            estimated_minutes,
            actual_seconds,
            completed,
            created_at,
            updated_at,
            completed_at
        FROM tasks
        ORDER BY id;
        """
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        var tasks: [Task] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let task = Task(
                id: Int(sqlite3_column_int64(statement, 0)),
                title: String(cString: sqlite3_column_text(statement, 1)),
                description: stringValue(statement: statement, index: 2),
                dueAt: integerValue(statement: statement, index: 3),
                dueHasTime: sqlite3_column_int(statement, 4) == 1,
                startedAt: integerValue(statement: statement, index: 5),
                currentStartedAt: integerValue(statement: statement, index: 6),
                priority: Int(sqlite3_column_int(statement, 7)),
                difficulty: Int(sqlite3_column_int(statement, 8)),
                estimatedMinutes: integerValue(statement: statement, index: 9),
                actualSeconds: integerValue(statement: statement, index: 10),
                completed: Int(sqlite3_column_int(statement, 11)) == 1,
                createdAt: Int(sqlite3_column_int64(statement, 12)),
                updatedAt: Int(sqlite3_column_int64(statement, 13)),
                completedAt: integerValue(statement: statement, index: 14)
            )
            tasks.append(task)
        }
        
        return tasks
    }
    
    func getTag(id: Int) throws -> Tag {
        let sql = """
            SELECT id, name
            FROM tags
            WHERE id = ?
            LIMIT 1;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, Int64(id))
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw DatabaseError.invalidTag("Tag not found \(errorMessage)")
        }
        
        return Tag(
            id: Int(sqlite3_column_int64(statement, 0)),
            name: String(cString: sqlite3_column_text(statement, 1))
        )
    }
    
    func getTags() throws -> [Tag] {
        let sql = """
            SELECT * FROM tags ORDER BY id;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        var tags: [Tag] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let tag = Tag(
                id: Int(sqlite3_column_int64(statement, 0)),
                name: String(cString: sqlite3_column_text(statement, 1))
            )
            tags.append(tag)
        }
        return tags
    }
    
    func getTags(ids: [Int]) throws -> [Tag] {
        try beginTransaction()
        do {
            var tags: [Tag] = []
            for id in ids {
                let tag = try getTag(id: id)
                tags.append(tag)
            }
            try commitTransaction()
            return tags
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }
    
    func getTagsOfTask(id: Int) throws -> [Tag] {
        let sql = """
            SELECT tags.id, tags.name 
            FROM tags
            INNER JOIN task_tags
                ON tags.id = task_tags.tag_id
            WHERE task_tags.task_id = ?;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        sqlite3_bind_int64(statement, 1, Int64(id))
        var tags: [Tag] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let tag = Tag(
                id: Int(sqlite3_column_int64(statement, 0)),
                name: String(cString: sqlite3_column_text(statement, 1))
            )
            tags.append(tag)
        }
        return tags
    }
    
    private func checkTagInUse(tagId: Int) throws -> [Int] {
        let sql = """
            SELECT task_id
            FROM task_tags
            WHERE tag_id = ?
            ORDER BY task_id;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, sqlite3_int64(tagId))
        
        var taskIds: [Int] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            taskIds.append(Int(sqlite3_column_int64(statement, 0)))
        }
        
        return taskIds
    }
    
    func checkTagsInUse(tagIds: Set<Int>) throws -> [TagInUse] {
        var result: [TagInUse] = []
        
        for tagId in tagIds {
            let taskIds = try checkTagInUse(tagId: tagId)
            
            if !taskIds.isEmpty {
                result.append(TagInUse(tagId: tagId, taskIds: taskIds))
            }
        }
        
        return result
    }
    
    func addTask(
        title: String,
        description: String?,
        dueAt: Int?,
        dueHasTime: Bool,
        priority: Int,
        difficulty: Int,
        estimatedMinutes: Int?
    ) throws -> Int64 {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw DatabaseError.invalidTask("Title is required.")
        }
        guard (1...5).contains(priority) else {
            throw DatabaseError.invalidTask("Priority must be between 1 and 5.")
        }
        guard (1...5).contains(difficulty) else {
            throw DatabaseError.invalidTask("Difficulty must be between 1 and 5.")
        }
        if let estimatedMinutes, estimatedMinutes < 0 {
            throw DatabaseError.invalidTask("Estimated minutes cannot be negative.")
        }
        
        let sql = """
            INSERT INTO tasks (
                title,
                description,
                due_at,
                due_has_time,
                priority,
                difficulty,
                estimated_minutes
            )
            VALUES(?,?,?,?,?,?,?);
            """
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        defer {
            sqlite3_finalize(statement)
        }
        
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        
        // title
        sqlite3_bind_text(statement, 1, title, -1, transient)
        
        // description
        let description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let description, !description.isEmpty {
            sqlite3_bind_text(statement, 2, description, -1, transient)
        } else {
            sqlite3_bind_null(statement, 2)
        }
        
        // dueAt
        if let dueAt {
            sqlite3_bind_int64(statement, 3, sqlite3_int64(dueAt))
        } else {
            sqlite3_bind_null(statement, 3)
        }
        
        // dueHasTime
        sqlite3_bind_int(statement, 4, dueHasTime ? 1 : 0)
        
        // priority
        sqlite3_bind_int(statement, 5, Int32(priority))
        
        // difficulty
        sqlite3_bind_int(statement, 6, Int32(difficulty))
        
        // estimated minutes
        if let estimatedMinutes {
            sqlite3_bind_int64(statement, 7, sqlite3_int64(estimatedMinutes))
        } else {
            sqlite3_bind_null(statement, 7)
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.insertFailed("Failed to add task: \(errorMessage)")
        }
        
        return sqlite3_last_insert_rowid(db)
    }
    
    func addTag(name: String) throws -> Int64 {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw DatabaseError.invalidTag("Tag name is required")
        }
        let sql = """
            INSERT INTO tags (
                name
            )
            VALUES(?);
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        
        // name
        sqlite3_bind_text(statement, 1, name, -1, transient)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorCode = sqlite3_extended_errcode(db)
            if errorCode == SQLiteErrorCode.SQLITE_UNIQUE_ERROR.rawValue {
                throw DatabaseError.invalidTag("Failed to add tag: A tag named \"\(name)\" already exists.")
            }
            throw DatabaseError.insertFailed("Failed to add tag: \(errorMessage)")
        }
        
        return sqlite3_last_insert_rowid(db)
    }
    
    func addTags(names: [String]) throws -> [Int64] {
        try beginTransaction()
        do {
            var tagIds: [Int64] = []
            for name in names {
                let newId = try addTag(name: name)
                tagIds.append(newId)
            }
            try commitTransaction()
            return tagIds
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }
    
    func addTagToTask(taskId: Int, tagId: Int) throws {
        let sql = """
            INSERT INTO task_tags (
                task_id,
                tag_id
            )
            VALUES(?,?);
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, sqlite3_int64(taskId))
        sqlite3_bind_int64(statement, 2, sqlite3_int64(tagId))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.insertFailed("Failed to add tag to task: \(errorMessage)")
        }
    }
    
    func addTaskWithTags(
        title: String,
        description: String?,
        dueAt: Int?,
        dueHasTime: Bool,
        priority: Int,
        difficulty: Int,
        estimatedMinutes: Int?,
        tagIds: [Int]
    ) throws -> Int64 {
        try beginTransaction()
        
        do {
            let taskId = try addTask(
                title: title,
                description: description,
                dueAt: dueAt,
                dueHasTime: dueHasTime,
                priority: priority,
                difficulty: difficulty,
                estimatedMinutes: estimatedMinutes
            )
            
            for tagId in tagIds {
                try addTagToTask(taskId: Int(taskId), tagId: tagId)
            }
            
            try commitTransaction()
            return taskId
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }
    
    func updateTask(id: Int, title: String, description: String?, dueAt: Int?, dueHasTime: Bool, priority: Int, difficulty: Int, estimatedMinutes: Int?) throws -> Int64 {
        
        guard try taskExists(id: id) else {
            throw DatabaseError.invalidTask("Task does not exist.")
        }
        
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw DatabaseError.invalidTask("Title is required.")
        }
        guard (1...5).contains(priority) else {
            throw DatabaseError.invalidTask("Priority must be between 1 and 5.")
        }
        guard (1...5).contains(difficulty) else {
            throw DatabaseError.invalidTask("Difficulty must be between 1 and 5.")
        }
        if let estimatedMinutes, estimatedMinutes < 0 {
            throw DatabaseError.invalidTask("Estimated minutes cannot be negative.")
        }
        
        let sql = """
            UPDATE tasks
            SET
                title = ?,
                description = ?,
                due_at = ?,
                due_has_time = ?,
                priority = ?,
                difficulty = ?,
                estimated_minutes = ?,
                updated_at = unixepoch()
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        
        // title
        sqlite3_bind_text(statement, 1, title, -1, transient)
        
        // description
        let description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let description, !description.isEmpty {
            sqlite3_bind_text(statement, 2, description, -1, transient)
        } else {
            sqlite3_bind_null(statement, 2)
        }
        
        // dueAt
        if let dueAt {
            sqlite3_bind_int64(statement, 3, sqlite3_int64(dueAt))
        } else {
            sqlite3_bind_null(statement, 3)
        }
        
        // dueHasTime
        sqlite3_bind_int(statement, 4, dueHasTime ? 1 : 0)
        
        // priority
        sqlite3_bind_int(statement, 5, Int32(priority))
        
        // difficulty
        sqlite3_bind_int(statement, 6, Int32(difficulty))
        
        // estimated minutes
        if let estimatedMinutes {
            sqlite3_bind_int64(statement, 7, sqlite3_int64(estimatedMinutes))
        } else {
            sqlite3_bind_null(statement, 7)
        }
        
        // id
        sqlite3_bind_int64(statement, 8, sqlite3_int64(id))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.updateFailed("Failed to update task: \(errorMessage)")
        }
        
        return Int64(id)
    }
    
    func updateTag(tag: Tag) throws -> Int64 {
        let tagName = tag.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tagName.isEmpty else {
            throw DatabaseError.invalidTag("Tag name is required.")
        }
        
        let sql = """
            UPDATE tags
            SET
                name = ?
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, tagName, -1, transient)
        sqlite3_bind_int64(statement, 2, sqlite_int64(tag.id))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorCode = sqlite3_extended_errcode(db)
            if errorCode == SQLiteErrorCode.SQLITE_UNIQUE_ERROR.rawValue {
                throw DatabaseError.invalidTag("Failed to update tag: A tag named \"\(tag.name)\" already exists.")
            }
            throw DatabaseError.updateFailed("Failed to update tag: \(errorMessage)")
        }
        
        return Int64(tag.id)
    }
    
    func updateStartTaskDate(id: Int) throws {
        let sql = """
            UPDATE tasks
            SET
                started_at = unixepoch(),
                current_started_at = unixepoch(),
                updated_at = unixepoch()
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, sqlite3_int64(id))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.updateFailed("Failed to start task: \(errorMessage)")
        }
    }
    
    func updateResetStartTaskDate(id: Int) throws {
        let sql = """
            UPDATE tasks
            SET
                started_at = NULL,
                current_started_at = NULL,
                updated_at = unixepoch()
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, sqlite3_int64(id))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.updateFailed("Failed to reset task start: \(errorMessage)")
        }
    }
    
    func updateCompleteTask(id: Int) throws {
        let sql = """
            UPDATE tasks
            SET
                completed = 1,
                completed_at = unixepoch(),
                updated_at = unixepoch(),
                actual_seconds = CASE
                    WHEN current_started_at IS NOT NULL
                    THEN COALESCE(actual_seconds, 0) + (unixepoch() - current_started_at)
                    ELSE actual_seconds
                END,
                current_started_at = NULL
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int(statement, 1, Int32(id))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.updateFailed("Failed to finish task: \(errorMessage)")
        }
    }
    
    func updateResetCompleteTask(id: Int) throws {
        let sql = """
            UPDATE tasks
            SET
                completed = 0,
                completed_at = NULL,
                updated_at = unixepoch()
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int(statement, 1, Int32(id))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.updateFailed("Failed to reset completed task: \(errorMessage)")
        }
    }
    
    func updateTaskWithTags(
        id: Int,
        title: String,
        description: String?,
        dueAt: Int?,
        dueHasTime: Bool,
        priority: Int,
        difficulty: Int,
        estimatedMinutes: Int?,
        tagIds: [Int]
    ) throws -> Int64 {
        try beginTransaction()
        do {
            let updatedTaskId = try updateTask(id: id, title: title, description: description, dueAt: dueAt, dueHasTime: dueHasTime, priority: priority, difficulty: difficulty, estimatedMinutes: estimatedMinutes)
            try deleteRow(sql: "DELETE FROM task_tags WHERE task_id = ?;", id: Int(updatedTaskId))
            for tagId in tagIds {
                try addTagToTask(taskId: Int(updatedTaskId), tagId: tagId)
            }
            try commitTransaction()
            
            return updatedTaskId
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }
    
    func deleteRow(sql: String, id: Int, skipIfNotFound: Bool = true) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, sqlite3_int64(id))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.deleteFailed(errorMessage)
        }
        if !skipIfNotFound {
            guard sqlite3_changes(db) > 0 else {
                throw DatabaseError.tableNotFound
            }
        }
    }
    
    func deleteTask(sql: String, id: Int) throws {
//        guard try taskExists(id: id) else {
//            throw DatabaseError.invalidTask("Task does not exist.")
//        }
        try deleteRow(sql: sql, id: id)
    }
    
    func deleteTag(sql: String, id: Int) throws {
        try deleteRow(sql: sql, id: id)
    }
    
    func deleteTags(sql: String, tagIds: [Int]) throws {
        try beginTransaction()
        do {
            for id in tagIds {
                try deleteTag(sql: sql, id: id)
            }
            try commitTransaction()
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }
    
    private func taskExists(id: Int) throws -> Bool {
        let sql = """
            SELECT EXISTS(
                SELECT 1
                FROM tasks
                WHERE id = ?
            );
        """
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, sqlite3_int64(id))
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw DatabaseError.invalidTask("Failed to check task existence: \(errorMessage)")
        }
        
        return sqlite3_column_int64(statement, 0) == 1
    }
    
    private func excuteSQL(sql: String) throws {
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            throw DatabaseError.prepareFailed(errorMessage)
        }
    }
    private func beginTransaction() throws {
        try excuteSQL(sql: "BEGIN TRANSACTION;")
    }
    private func commitTransaction() throws {
        try excuteSQL(sql: "COMMIT;")
    }
    private func rollbackTransaction() throws {
        try excuteSQL(sql: "ROLLBACK;")
    }
}
