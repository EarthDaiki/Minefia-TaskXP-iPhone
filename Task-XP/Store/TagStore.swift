//
//  TagStore.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 8/21/26.
//

import Foundation

extension TagStore {
    static var preview: TagStore {
        let database = Database()
        let store = TagStore(database: database)
        store.tags = [
            Tag(id: 1, name: "Home"),
            Tag(id: 2, name: "Work"),
            Tag(id: 3, name: "Study"),
            Tag(id: 4, name: "Exercise"),
            Tag(id: 5, name: "Yokohama")
        ]
        return store
    }
}

@Observable
final class TagStore {
    let database: Database
    var tags: [Tag] = []
    var errorMessage: String?
    
    init(database: Database) {
        self.database = database
    }
    
    func loadAllTags() throws -> [Tag] {
        tags = try database.getTags()
        return tags
    }
    
    // Think that this is a good way to load tags.
    func getTagsForTask(taskId: Int) throws -> [Tag]{
        return try database.getTagsOfTask(id: taskId)
    }
    
    func checkTagsInUse(tagIds: Set<Int>) throws -> [TagInUse] {
        return try database.checkTagsInUse(tagIds: tagIds)
    }
    
    func addTag(name: String) throws -> Int {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw TaskValidationError.emptyTagName
        }
        
        let tagId = try database.addTag(name: name)
        let newTags = try database.getTags(ids: [Int(tagId)])
        tags.append(contentsOf: newTags)
        return Int(tagId)
    }
    
    func addTags(names: [String]) throws -> [Int] {
        guard !names.isEmpty else {
            return []
        }
        let trimmedNames = names.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !trimmedNames.isEmpty else {
            throw TaskValidationError.emptyTagName
        }
        
        let existingTagNames = tags.map {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let newTagNames = trimmedNames.filter { name in
            !existingTagNames.contains(name)
        }
        let newIds = try database.addTags(names: newTagNames)
        
        let newTags = try database.getTags(ids: newIds.map { Int($0) })
        
        tags.append(contentsOf: newTags)
        
        return newIds.map { Int($0) }
    }
    
    func updateTag(tag: Tag) throws -> Int {
        let newName = tag.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else {
            throw TagValidationError.emptyTagName
        }
        guard tag.id > 0 else {
            throw TagValidationError.invalidTagId
        }
        
        let id = try database.updateTag(tag: tag)
        
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index].name = newName
        }
        
        return Int(id)
    }
    
    func deleteTag(tag: Tag) throws {
        try database.deleteTag(sql: "DELETE FROM tags WHERE id = ?", id: tag.id)
        tags.removeAll { $0.id == tag.id }
    }
    
    func deleteTags(deleteTags: [Tag]) throws {
        let ids = deleteTags.map(\.id)
        guard !ids.isEmpty else {
            throw TagValidationError.invalidTagSelection("You need to select a tag.")
        }
        try database.deleteTags(sql: "DELETE FROM tags WHERE id = ?", tagIds: ids)
        tags.removeAll { tag in
            ids.contains(tag.id)
        }
    }
}
