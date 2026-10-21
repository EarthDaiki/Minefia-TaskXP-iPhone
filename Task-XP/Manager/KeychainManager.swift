//
//  KeychainManager.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 9/16/26.
//

import Foundation
import Security

enum KeychainError: LocalizedError {
    case failedToEncode
    case invalidData
    case notFound(String)
    case failedToGet(String)
    case failedToAdd(String)
    case failedToDelete(String)
    var errorDescription: String? {
        switch self {
        case .failedToEncode:
            return "Failed to encode value to Data"
        case .invalidData:
            return "Failed to get valid data from keychain"
        case .notFound(let message):
            return "Not found item in keychain. \(message)"
        case .failedToGet(let message):
            return "Failed to get item from keychain. \(message)"
        case .failedToAdd(let message):
            return "Failed to add item to keychain. \(message)"
        case .failedToDelete(let message):
            return "Failed to delete item from keychain. \(message)"
        }
    }
}

final class KeychainManager {
    let service = "Task-XP"
    func get(account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            throw KeychainError.notFound("You need to set an API key. Go to Settings -> API Management -> Add API Key.")
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.failedToGet("Failed to get an API key.")
        }
        
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    private func getAll() throws -> [[String: Any]] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: CFTypeRef?
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return []
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.failedToGet("Failed to get APIs.")
        }
        
        guard let data = result as? [[String: Any]] else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    func getAllAccounts() throws -> [String] {
        let items = try getAll()
        return items.compactMap {
            $0[kSecAttrAccount as String] as? String
        }
    }
    
    func add(value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.failedToEncode
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            throw KeychainError.failedToAdd("You already have an API with that name.")
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.failedToAdd("Failed to add an API.")
        }
    }
    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.failedToDelete("Failed to delete an API.")
        }
    }
}
