//
//  TagManagementView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 9/23/26.
//

import SwiftUI

struct AddTagView: View {
    private let tagStore: TagStore
    @State private var tagName: String = ""
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardDialog = false
    @State private var showSavedDialog = false
    
    init(tagStore: TagStore) {
        self.tagStore = tagStore
    }
    
    private var isAddButtonDisabled: Bool {
        tagName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
    
    private var hasUnsavedChanges: Bool {
        !tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Tag")
                    .captionTextStyle()
                TextField(
                    "Tag Name",
                    text: $tagName,
                    prompt: Text("Tag Name")
                        .appInputPromptStyle()
                )
                    .appInputCard()
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .padding()
            .navigationTitle("Add Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if hasUnsavedChanges {
                            showDiscardDialog = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                    .appButtonImageStyle()
                    .confirmationDialog("Discard?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
                        Button(role: .destructive) {
                            dismiss()
                        } label: {
                            Text("Discard")
                        }
                        Button(role: .cancel) {
                            
                        } label: {
                            Text("Cancel")
                        }
                    } message: {
                        Text("Unsaved changes will be lost.")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        do {
                            let newTagName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            guard !newTagName.isEmpty else {
                                throw TagValidationError.emptyTagName
                            }
                            _ = try tagStore.addTag(name: newTagName)
                            
                            showSavedDialog = true
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .disabled(isAddButtonDisabled)
                    .opacity(isAddButtonDisabled ? 0.5 : 1)
                    .appButtonImageStyle()
                    .confirmationAlert(title: "Tag Saved", isPresented: $showSavedDialog, message: "\"\(tagName)\" has been added to your tags.", onContinue: {tagName = ""}, onClose: { dismiss() })
                }
            }
            .errorAlert(title: "Failed to add a tag", errorMessage: $errorMessage)
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
        .background {
            UIKitViewController(
                onDismissAttempt: {
                    if hasUnsavedChanges {
                        showDiscardDialog = true
                    }
                }
            )
        }
        .appBackground()
    }
}

struct ManageTagView: View {
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    @State private var selectedTagIDs: Set<Int> = []
    @State private var showAddView: Bool = false
    
    @State private var editedTags: [Int: String] = [:]
    @FocusState private var focusedTagId: Int?
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation: Bool = false
    @State private var tagsInUse: [TagInUse] = []
    
    @State private var updateFailed: Bool = false
    
    @Environment(\.editMode) private var editMode
    
    init (tagStore: TagStore, taskListStore: TaskListStore) {
        self.tagStore = tagStore
        self.taskListStore = taskListStore
    }
    
    private func tagNameBinding(for tag: Tag) -> Binding<String> {
        Binding(
            get: { editedTags[tag.id] ?? tag.name },
            set: { editedTags[tag.id] = $0 }
        )
    }
    
    private func editTagName(oldValue: Int?, newValue: Int?) {
        guard let oldTagId = oldValue,
              oldTagId != newValue,
              let newName = editedTags[oldTagId]
        else {
            return
        }
        
        do {
            let editedTag = Tag(id: oldTagId, name: newName)
            _ = try tagStore.updateTag(tag: editedTag)
        } catch {
            editedTags[oldTagId] = tagStore.tags.first(where: { $0.id == oldTagId })?.name
            errorMessage = error.localizedDescription
            updateFailed = true
        }
    }
    
    private func deleteSelectedTags() {
        let selectedTags = tagStore.tags.filter {
            selectedTagIDs.contains($0.id)
        }
        
        do {
            try tagStore.deleteTags(deleteTags: selectedTags)
            taskListStore.removeDeletedTags(tagIds: selectedTags.map(\.id))
            editMode?.wrappedValue = .inactive
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func deleteButtonTask() {
        if editMode?.wrappedValue.isEditing == true {
            if selectedTagIDs.isEmpty {
                editMode?.wrappedValue = .inactive
            } else {
                do {
                    tagsInUse = try tagStore.checkTagsInUse(tagIds: selectedTagIDs)
                    showDeleteConfirmation = true
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            editMode?.wrappedValue = .active
        }
    }
    
    private var isDeleteDisabled: Bool {
        editMode?.wrappedValue.isEditing == true && selectedTagIDs.isEmpty
    }
    
    private var deleteConfirmationMessage: String {
        if tagsInUse.isEmpty {
            return "Are you sure you want to delete this tag?"
        }
        
        return "Some selected tags are used by existing tasks. Deleting them will remove these tags from those tasks. This action cannot be undone."
    }
    
    var body: some View {
        VStack {
            if tagStore.tags.isEmpty {
                Text("No tags stored.")
                    .primaryTextStyle()
            } else {
                List(tagStore.tags, selection: $selectedTagIDs) { tag in
                    TextField(
                        "Tag Name",
                        text: tagNameBinding(for: tag),
                        prompt: Text("Enter a tag name")
                            .appInputPromptStyle()
                    )
                    .disabled(editMode?.wrappedValue.isEditing == true)
                    .focused($focusedTagId, equals: tag.id)
                    .primaryTextStyle()
                    .appListRowStyle()
                }
            }
        }
        .onChange(of: focusedTagId) { oldValue, newValue in
            editTagName(oldValue: oldValue, newValue: newValue)
        }
        .toolbar {
            Button {
                showAddView = true
            } label: {
                Label("Add Tag", systemImage: "plus")
            }
            .appButtonImageStyle()
            .sheet(isPresented: $showAddView) {
                AddTagView(tagStore: tagStore)
            }
            Button {
                deleteButtonTask()
            } label: {
                if editMode?.wrappedValue.isEditing == true {
                    Label("Check", systemImage: "checkmark")
                } else {
                    Text("Edit")
                }
            }
            .appButtonImageStyle()
            .confirmationDialog("Delete selected tags?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button(role: .destructive) {
                    deleteSelectedTags()
                } label: {
                    Text("Delete")
                }
                Button(role: .cancel) {
                    
                } label: {
                    Text("Cancel")
                }
            } message: {
                Text(deleteConfirmationMessage)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: editMode?.wrappedValue.isEditing)
        .errorAlert(title: updateFailed ? "Failed to update a tag" : "Failed to delete a tag", errorMessage: $errorMessage, onDismiss: { updateFailed = false })
        .navigationTitle("Manage Tag")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .appBackground()
    }
}

struct TagManagementView: View {
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    init(tagStore: TagStore, taskListStore: TaskListStore) {
        self.tagStore = tagStore
        self.taskListStore = taskListStore
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink() {
                        ManageTagView(tagStore: tagStore, taskListStore: taskListStore)
                    } label: {
                        Text("Manage Tags")
                            .primaryTextStyle()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .navigationIndicatorStyle()
                    }
                    .appListRowStyle()
                }
            }
            .navigationLinkIndicatorVisibility(.hidden)
            .scrollContentBackground(.hidden)
            .appBackground()
        }
    }
}

#Preview {
    TagManagementView(tagStore: .preview, taskListStore: .preview)
}
