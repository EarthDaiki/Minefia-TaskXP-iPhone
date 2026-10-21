//
//  DatabaseError.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/22/26.
//

import Foundation

enum DatabaseError: LocalizedError {
    case documentDirectoryNotFound
    case openFailed(String)
    case createTableFailed(String)
    case prepareFailed(String)
    case invalidTask(String)
    case invalidTag(String)
    case insertFailed(String)
    case loadFailed(String)
    case getFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case tableNotFound
    
    var errorDescription: String? {
        switch self {
        case .documentDirectoryNotFound:
            return "Document directory not found."
        case .openFailed(let message):
            return "Failed to open database. \(message)"
        case .createTableFailed(let message):
            return "Failed to create table. \(message)"
        case .prepareFailed(let message):
            return "Failed to prepare statement. \(message)"
        case .invalidTask(let message):
            return "Invalid Task. \(message)"
        case .invalidTag(let message):
            return "Invalid Tag. \(message)"
        case .insertFailed(let message):
            return "Failed to insert. \(message)"
        case .loadFailed(let message):
            return "Failed to load. \(message)"
        case .getFailed(let message):
            return "Failed to get. \(message)"
        case .updateFailed(let message):
            return "Failed to update. \(message)"
        case .deleteFailed(let message):
            return "Failed to delete. \(message)"
        case .tableNotFound:
            return "Table not found."
        }
    }
}

enum SQLiteErrorCode: Int32 {
    case SQLITE_UNIQUE_ERROR = 2067
}
