//
//  AddTaskView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/16/26.
//

import SwiftUI

enum AddTaskMode: Hashable {
    case manual
    case ai
}

private extension AddTaskView {
    // Add button was removed.
//    private var addButton: some View {
//        VStack {
//            Button {
//                do {
//                    try taskStore.addTask(
//                        title: title,
//                        description: description,
//                        combinedDueDate: combinedDueDateAndTime(),
//                        dueHasTime: dueHasTime,
//                        priority: priority,
//                        difficulty: difficulty,
//                        estimatedMinutes: estimatedMinutes,
//                        tagIds: selectedTags.map(\.id)
//                    )
//                    
//                    dismiss()
//                } catch {
//                    errorMessage = error.localizedDescription
//                }
//            } label: {
//                Text("Add Task")
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(AppColors.primary)
//                    .foregroundStyle(AppColors.textPrimary)
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//            }
//            .disabled(isAddButtonDisabled)
//            .opacity(isAddButtonDisabled ? 0.5 : 1)
//        }
//        .padding(.top, 20)
//    }
    private var isAddButtonDisabled: Bool {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
    
    private func combinedDueDateAndTime() -> Date? {
        guard dueHasDate else {
            return nil
        }
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: dueDate
        )
        let timeComponents = calendar.dateComponents(
            [.hour, .minute],
            from: dueTime
        )
        var components = dateComponents
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return calendar.date(from: components)
    }
    
    private var hasUnsavedChanges: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines) != ""
        || description.trimmingCharacters(in: .whitespacesAndNewlines) != ""
        || selectedTags.count > 0
        || dueHasDate
        || dueHasTime
        || priority != 1
        || difficulty != 1
        || estimatedMinutes.trimmingCharacters(in: .whitespacesAndNewlines) != ""
        || prompt.trimmingCharacters(in: .whitespacesAndNewlines) != ""
    }
}

struct AddTaskView: View {
    @Binding private var showAddTask: Bool
    private let taskStore: TaskStore
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    init(
        showAddTask: Binding<Bool>,
        taskStore: TaskStore,
        tagStore: TagStore,
        taskListStore: TaskListStore
    ) {
        self._showAddTask = showAddTask
        self.taskStore = taskStore
        self.tagStore = tagStore
        self.taskListStore = taskListStore
    }
    @Environment(\.dismiss) private var dismiss
    @State private var dueHasDate: Bool = false
    @State private var dueHasTime: Bool = false
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedTags: [Tag] = []
    @State private var dueDate: Date = Date()
    @State private var dueTime: Date = Date()
    @State private var priority: Int = 1
    @State private var difficulty: Int = 1
    @State private var estimatedMinutes: String = ""
    
    @State private var errorMessage: String?
    @State private var showDiscardDialog: Bool = false
    
    @State private var selectedMenu: AddTaskMode = .manual
    
    @State private var aiGeneratedTags: [Tag] = []
    @State private var tempTags: [Tag] = []
    @State private var newTempTagId = -1
    
    @State private var prompt: String = ""
    
    private func manualSection() -> some View {
        VStack(spacing: 20) {
            TitleSection(title: $title)
            DescriptionSection(description: $description)
            TagSection(showDiscardDialog: $showDiscardDialog, selectedTags: $selectedTags,aiGeneratedTags: $aiGeneratedTags, tempTags: $tempTags, newTempTagId: $newTempTagId, showAddTask: $showAddTask, tagStore: tagStore)
            DueSection(dueHasDate: $dueHasDate, dueHasTime: $dueHasTime, dueDate: $dueDate, dueTime: $dueTime)
            PrioritySection(priority: $priority)
            DifficultySection(difficulty: $difficulty)
            EstimatedTimeSection(estimatedMinutes: $estimatedMinutes)
        }
    }
    
    private func makeTempTag(name: String) -> Tag {
        let tag = Tag(id: newTempTagId, name: name)
        newTempTagId -= 1
        return tag
    }
    
    private func aiGeneratedSelectedTags(from generatedTask: GeneratedTask) {
        for generatedTag in generatedTask.tags {
            let trimmedName = generatedTag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                continue
            }
            if let existingTag = tagStore.tags.first(where: {
                $0.name.lowercased() == trimmedName.lowercased()
            }) {
                aiGeneratedTags.append(existingTag)
                if !selectedTags.contains(where: { $0.id == existingTag.id }) {
                    selectedTags.append(existingTag)
                }
            } else {
                let tempTag = makeTempTag(name: trimmedName)
                aiGeneratedTags.append(tempTag)
                if !selectedTags.contains(where: { $0.id == tempTag.id }) {
                    selectedTags.append(tempTag)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20){
                    Picker("Mode", selection: $selectedMenu) {
                        Text("Manual")
                            .tag(AddTaskMode.manual)
                        Text("AI")
                            .tag(AddTaskMode.ai)
                    }
                    .pickerStyle(.segmented)
                    
                    switch selectedMenu {
                    case .manual:
                        manualSection()
                    case .ai:
                        AddTaskAiView(prompt: $prompt, onGenerated: { generatedTask in
                            title = generatedTask.title
                            description = generatedTask.description
                            dueHasTime = generatedTask.dueHasTime
                            priority = generatedTask.priority
                            difficulty = generatedTask.difficulty
                            estimatedMinutes = generatedTask.estimatedMinutes.map(String.init) ?? ""
                            
                            // aiGeneratedはidをai用のidにする。それで識別。
                            aiGeneratedSelectedTags(from: generatedTask)
                            
                            if let dueAt = generatedTask.dueAt {
                                let dueDateValue = Date(timeIntervalSince1970: TimeInterval(dueAt))
                                dueHasDate = true
                                dueDate = dueDateValue
                                if dueHasTime {
                                    dueTime = dueDateValue
                                }
                            } else {
                                dueHasDate = false
                            }
                            
                            selectedMenu = .manual
                        })
                    }
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
                            let existingTagIds = selectedTags.filter { $0.id > 0 }.map(\.id)
                            let newTagNames = selectedTags.filter { $0.id < 0 }.map(\.name)
                            
                            let newTagIds = try tagStore.addTags(names: newTagNames)
                            
                            let tagIds = existingTagIds + newTagIds
                            
                            try taskListStore.addTaskWithTags(
                                title: title,
                                description: description,
                                combinedDueDate: combinedDueDateAndTime(),
                                dueHasTime: dueHasTime,
                                priority: priority,
                                difficulty: difficulty,
                                estimatedMinutes: estimatedMinutes,
                                tagIds: tagIds
                            )
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .appButtonImageStyle()
                    .disabled(isAddButtonDisabled)
                    .opacity(isAddButtonDisabled ? 0.5 : 1)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .appBackground()
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
        .errorAlert(title: "Task Error", errorMessage: $errorMessage)
    }
}

#Preview {
    @Previewable @State var showAddTask: Bool = false
    AddTaskView(
        showAddTask: $showAddTask,
        taskStore: .preview,
        tagStore: .preview,
        taskListStore: .preview
    )
}
