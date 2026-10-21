//
//  EditTaskView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 8/27/26.
//

import SwiftUI

private extension EditTaskView {
    private func combinedDraftDueDateAndTime() -> Date? {
        guard draftDueHasDate else {
            return nil
        }
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: draftDueDate
        )
        let timeComponents = calendar.dateComponents(
            [.hour, .minute],
            from: draftDueTime
        )
        var components = dateComponents
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return calendar.date(from: components)
    }
    private var draftDueAt: Int? {
        guard draftDueHasDate, let dueAt = combinedDraftDueDateAndTime() else {
            return nil
        }
        
        return Int(dueAt.timeIntervalSince1970)
    }
    private var hasUnsavedChanges: Bool {
        draftTitle.trimmingCharacters(in: .whitespacesAndNewlines) != taskWithTags.task.title
        || draftDescription.trimmingCharacters(in: .whitespacesAndNewlines) != (taskWithTags.task.description ?? "")
        || draftDueAt != taskWithTags.task.dueAt
        || draftDueHasTime != taskWithTags.task.dueHasTime
        || draftPriority != taskWithTags.task.priority
        || draftDifficulty != taskWithTags.task.difficulty
        || draftEstimatedMinutes.trimmingCharacters(in: .whitespacesAndNewlines) != (taskWithTags.task.estimatedMinutes.map(String.init) ?? "")
        || draftSelectedTags.map(\.id).sorted() != taskWithTags.tags.map(\.id).sorted()
    }
}

struct EditTaskView: View {
    private let taskWithTags: TaskWithTags
    private let taskStore: TaskStore
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    private let onSave: (TaskWithTags) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var showAddTag: Bool = false
    @State private var showDiscardDialog: Bool = false
    
    @State private var draftTitle: String
    @State private var draftDescription: String
    @State private var draftDueHasDate: Bool
    @State private var draftDueHasTime: Bool
    @State private var draftDueDate: Date
    @State private var draftDueTime: Date
    @State private var draftPriority: Int
    @State private var draftDifficulty: Int
    @State private var draftEstimatedMinutes: String
    @State private var draftSelectedTags: [Tag]
    
    @State private var tempTags: [Tag]
    @State private var newTempTagId: Int = -1

    init(taskWithTags: TaskWithTags, taskStore: TaskStore, tagStore: TagStore, taskListStore: TaskListStore, onSave: @escaping (TaskWithTags) -> Void) {
        self.taskWithTags = taskWithTags
        self.taskStore = taskStore
        self.tagStore = tagStore
        self.taskListStore = taskListStore
        self.onSave = onSave

        _draftTitle = State(initialValue: taskWithTags.task.title)
        _draftDescription = State(initialValue: taskWithTags.task.description ?? "")
        _draftPriority = State(initialValue: taskWithTags.task.priority)
        _draftDifficulty = State(initialValue: taskWithTags.task.difficulty)
        _draftEstimatedMinutes = State(initialValue: taskWithTags.task.estimatedMinutes.map(String.init) ?? "")
        _draftSelectedTags = State(initialValue: taskWithTags.tags)
        let dueDate = taskWithTags.task.dueAt.map {
            Date(timeIntervalSince1970: TimeInterval($0))
        } ?? Date()

        _draftDueHasDate = State(initialValue: taskWithTags.task.dueAt != nil)
        _draftDueHasTime = State(initialValue: taskWithTags.task.dueHasTime)
        _draftDueDate = State(initialValue: dueDate)
        _draftDueTime = State(initialValue: dueDate)
        
        _tempTags = State(initialValue: [])
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20){
                    TitleSection(title: $draftTitle)
                    DescriptionSection(description: $draftDescription)
                    TagSection(selectedTags: $draftSelectedTags, tempTags: $tempTags, newTempTagId: $newTempTagId, tagStore: tagStore)
                    DueSection(dueHasDate: $draftDueHasDate, dueHasTime: $draftDueHasTime, dueDate: $draftDueDate, dueTime: $draftDueTime)
                    PrioritySection(priority: $draftPriority)
                    DifficultySection(difficulty: $draftDifficulty)
                    EstimatedTimeSection(estimatedMinutes: $draftEstimatedMinutes)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if hasUnsavedChanges {
                            showDiscardDialog = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .appButtonImageStyle()
                    .confirmationDialog("Discard this task?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
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
                            let editedTask = try taskListStore.updateTaskWithTags(taskId: taskWithTags.task.id, title: draftTitle, description: draftDescription, combinedDueDate: combinedDraftDueDateAndTime(), dueHasTime: draftDueHasTime, priority: draftPriority, difficulty: draftDifficulty, estimatedMinutes: draftEstimatedMinutes, tagIds: draftSelectedTags.map(\.id).sorted())
                            
                            onSave(editedTask)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Text("Save")
                            .primaryTextStyle()
                    }
//                    .tint(AppColors.textPrimary)
                }
            }
            .interactiveDismissDisabled(hasUnsavedChanges)
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .appBackground()
            .errorAlert(title: "Edit Task Error", errorMessage: $errorMessage)
        }
        .background {
            UIKitViewController(
                onDismissAttempt: {
                    if hasUnsavedChanges {
                        showDiscardDialog = true
                    }
                }
            )
        }
    }
}

#Preview {
    EditTaskView(
        taskWithTags: TaskWithTags(
            task: Task(
                id: 1,
                title: "Task-XPを作る",
                description: "",
                dueAt: Int(Date().timeIntervalSince1970),
                dueHasTime: true,
                startedAt: nil,
                priority: 4,
                difficulty: 3,
                estimatedMinutes: 60,
                actualSeconds: nil,
                completed: false,
                createdAt: Int(Date().timeIntervalSince1970),
                updatedAt: Int(Date().timeIntervalSince1970),
                completedAt: nil
            ),
            tags: [Tag(id: 1, name: "Swift"), Tag(id: 2, name: "UI")]
        ),
        taskStore: .preview,
        tagStore: .preview,
        taskListStore: .preview,
        onSave: { _ in }
    )
}
