//
//  AddTagView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 8/22/26.
//

import SwiftUI

struct TagSelectionView: View {
    @Binding private var showDiscardDialog: Bool
    @Binding private var selectedTags: [Tag]
    @Binding private var aiGeneratedTags: [Tag]
    @Binding private var tempTags: [Tag]
    @Binding private var newTempTagId: Int
    @Binding private var showAddTask: Bool
    private let tagStore: TagStore
    init(
        showDiscardDialog: Binding<Bool>,
        selectedTags: Binding<[Tag]>,
        aiGeneratedTags: Binding<[Tag]>,
        tempTags: Binding<[Tag]>,
        newTempTagId: Binding<Int>,
        showAddTask: Binding<Bool>,
        tagStore: TagStore
    ) {
        self._showDiscardDialog = showDiscardDialog
        self._selectedTags = selectedTags
        self._aiGeneratedTags = aiGeneratedTags
        self._tempTags = tempTags
        self._newTempTagId = newTempTagId
        self._showAddTask = showAddTask
        self.tagStore = tagStore
    }
    @Environment(\.dismiss) private var dismiss
    @State private var tagName: String = ""
    @State private var errorMessage: String?
    
    private var isAddButtonDisabled: Bool {
        tagName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
    
    private func makeTempTag(name: String) -> Tag {
        let tag = Tag(id: newTempTagId, name: name)
        newTempTagId -= 1
        return tag
    }
    
    private func tagButtons(for tags: [Tag]) -> some View {
        FlowLayout() {
            ForEach(tags) { tag in
                Button {
                    if let index = selectedTags.firstIndex(where: {$0.id == tag.id}) {
                        selectedTags.remove(at: index)
                    } else {
                        selectedTags.append(tag)
                    }
                } label: {
                    Text(tag.name)
                        .appFilterButtonStyle(isSelected: selectedTags.contains(tag))
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Tag")
                    .captionTextStyle()
                TextField(
                    "Tag name",
                    text: $tagName,
                    prompt: Text("Tag Name")
                        .appInputPromptStyle()
                )
                    .appInputCard()
            }
            Button {
                do {
                    let newTagName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard !newTagName.isEmpty else {
                        throw TagValidationError.emptyTagName
                    }
                    
                    if tagStore.tags.contains(where: { $0.name == newTagName }) {
                        throw TagValidationError.duplicateTagName("Check in Saved Tags.")
                    }
                    
                    if tempTags.contains(where: { $0.name == newTagName }) {
                        throw TagValidationError.duplicateTagName("Check in Temp Tags.")
                    }
                    
                    if aiGeneratedTags.contains(where: { $0.name == newTagName }) {
                        throw TagValidationError.duplicateTagName("Check in AI Generated Tags.")
                    }
                    
                    let newTag = makeTempTag(name: newTagName)
                    tempTags.append(newTag)
                    selectedTags.append(newTag)
                    tagName = ""
                } catch {
                    errorMessage = error.localizedDescription
                }
                
            } label: {
                Text("Add")
                    .appPrimaryButtonStyle(isDisabled: isAddButtonDisabled)
            }
            
            VStack (alignment: .leading, spacing: 8) {
                if !tempTags.isEmpty {
                    Text("Temp Tags")
                        .captionTextStyle()
                    tagButtons(for: tempTags)
                }
                if !tagStore.tags.isEmpty {
                    Text("Saved Tags")
                        .captionTextStyle()
                    tagButtons(for: tagStore.tags)
                }
                if !aiGeneratedTags.isEmpty {
                    Text("AI Generated Tags")
                        .captionTextStyle()
                    tagButtons(for: aiGeneratedTags)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .appButtonImageStyle()
                .confirmationDialog("Discard this task?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
                    Button(role: .destructive) {
                        showAddTask = false
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
        }
        .errorAlert(title: "Tag Error", errorMessage: $errorMessage)
        .appBackground()
    }
}

#Preview {
    @Previewable @State var showDiscardDialog: Bool = false
    @Previewable @State var selectedTags = [
        Tag(id: 1, name: "Home")
    ]
    
    @Previewable @State var aiGeneratedTags: [Tag] = [
        Tag(id: -1, name: "Home"),
        Tag(id: -2, name: "Work"),
        Tag(id: -3, name: "Gym"),
        Tag(id: -4, name: "Friends"),
        Tag(id: -5, name: "Family"),
        Tag(id: -6, name: "Travel"),
    ]
    
    @Previewable @State var tempTags: [Tag] = [
        Tag(id: -1, name: "Home"),
        Tag(id: -2, name: "Work"),
        Tag(id: -3, name: "Gym"),
        Tag(id: -4, name: "Friends"),
        Tag(id: -5, name: "Family"),
        Tag(id: -6, name: "Travel"),
    ]
    
    @Previewable @State var newTempTagId: Int = -1
    @Previewable @State var showAddTask: Bool = false

    TagSelectionView(
        showDiscardDialog: $showDiscardDialog,
        selectedTags: $selectedTags,
        aiGeneratedTags: $aiGeneratedTags,
        tempTags: $tempTags,
        newTempTagId: $newTempTagId,
        showAddTask: $showAddTask,
        tagStore: .preview
    )
}
