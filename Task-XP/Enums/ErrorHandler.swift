//
//  ErrorHandler.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/22/26.
//

import Foundation

enum TaskValidationError: LocalizedError {
    case emptyTitle
    case invalidEstimatedMinutes
    case invalidPriority
    case invalidDifficulty
    case emptyTagName
    case duplicateTagName

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Please enter a task title."

        case .invalidEstimatedMinutes:
            return "Estimated minutes must be zero or greater."

        case .invalidPriority:
            return "Priority must be between 1 and 5."

        case .invalidDifficulty:
            return "Difficulty must be between 1 and 5."
            
        case .emptyTagName:
            return "Please enter a tag name."
            
        case .duplicateTagName:
            return "This tag already exists."
        }
    }
}

enum TagValidationError: LocalizedError {
    case invalidTagId
    case emptyTagName
    case duplicateTagName(String)
    case invalidTagSelection(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidTagId:
            return "Invalid tag ID."
        case .emptyTagName:
            return "Please enter a tag name."
        case .duplicateTagName(let message):
            return "This tag already exists. \(message)"
        case .invalidTagSelection(let message):
            return "Invalid tag selection. \(message)"
        }
    }
}

enum KeychainValidationError: LocalizedError {
    case emptyAccount
    case emptyValue
    var errorDescription: String? {
        switch self {
        case .emptyAccount:
            return "Name is empty"
        case .emptyValue:
            return "API key is empty"
        }
    }
}

enum OpenAIApiError: LocalizedError {
    case invalidApiKey
    case missingOutput
    case apiError(String)
    var errorDescription: String? {
        switch self {
        case .invalidApiKey:
            return "Failed to authenticate with API key. Please check your API key."
        case .missingOutput:
            return "Failed to get output. Please check your request."
        case .apiError(let message):
            return "Failed to get an output. \(message)"
        }
    }
}
