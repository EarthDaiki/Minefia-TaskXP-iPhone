//
//  TaskInputComponents.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 8/27/26.
//

import SwiftUI

struct TitleSection: View {
    @Binding var title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Text("Title")
                .captionTextStyle()
            TextField(
                "Title",
                text: $title,
                prompt: Text("Task Title")
                    .appInputPromptStyle()
            )
            .appInputCard()
        }
    }
}
struct DescriptionSection: View {
    @Binding var description: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Text("Description")
                .captionTextStyle()
            TextField(
                "",
                text: $description,
                prompt: Text("Task Description")
                    .appInputPromptStyle(),
                axis: .vertical
            )
            .appInputCard()
        }
    }
}
struct DueSection: View {
    @Binding var dueHasDate: Bool
    @Binding var dueHasTime: Bool
    @Binding var dueDate: Date
    @Binding var dueTime: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Text("Due At")
                .captionTextStyle()
            VStack {
                Toggle("Date", isOn: $dueHasDate)
                    .foregroundStyle(AppColors.textPrimary)
                    .tint(AppColors.primary)
                if dueHasDate {
                    Text("\(dueDate.formatted(date: .long, time: .omitted))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .primaryTextStyle()
                    DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                        .foregroundStyle(AppColors.textPrimary)
                        .datePickerStyle(.graphical)
                        .tint(AppColors.primary)
                        .colorScheme(.dark)
                    Toggle("Time", isOn: $dueHasTime)
                        .foregroundStyle(AppColors.textPrimary)
                        .tint(AppColors.primary)
                    if dueHasTime {
                        Text("\(dueTime.formatted(date: .omitted, time: .shortened))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .primaryTextStyle()
                        DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                            .foregroundStyle(AppColors.textPrimary)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .tint(AppColors.primary)
                    }
                }
            }
            .appInputCard()
        }
    }
}
struct PrioritySection: View {
    @Binding var priority: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority")
                .captionTextStyle()
            HStack {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        priority = value
                    } label: {
                        Image(systemName: "flame")
                            .font(.title2)
                            .foregroundStyle(
                                value <= priority
                                ? AppColors.primary
                                : AppColors.textSecondary
                            )
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .appInputCard()
        }
    }
}
struct DifficultySection: View {
    @Binding var difficulty: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Difficulty")
                .captionTextStyle()
            HStack {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        difficulty = value
                    } label: {
                        Image(systemName: "brain")
                            .font(.title2)
                            .foregroundStyle(
                                value <= difficulty
                                ? AppColors.primary
                                : AppColors.textSecondary
                            )
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .appInputCard()
        }
    }
}
struct EstimatedTimeSection: View {
    @Binding var estimatedMinutes: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimated Time")
                .captionTextStyle()
            HStack {
                TextField(
                    "Estimated Time",
                    text: $estimatedMinutes,
                    prompt: Text("30")
                        .appInputPromptStyle()
                )
                .keyboardType(.numberPad)
                .onChange(of: estimatedMinutes) { _, newValue in
                    estimatedMinutes = newValue.filter(\.isNumber)
                }
                Text("Minutes")
                    .secondaryTextStyle()
            }
            .appInputCard()
        }
    }
}
struct TagSection: View {
    @Binding private var showDiscardDialog: Bool
    @Binding private var selectedTags: [Tag]
    @Binding private var aiGeneratedTags: [Tag]
    @Binding private var tempTags: [Tag]
    @Binding private var newTempTagId: Int
    @Binding private var showAddTask: Bool
    private let tagStore: TagStore
    init (
        showDiscardDialog: Binding<Bool> = .constant(false),
        selectedTags: Binding<[Tag]>,
        aiGeneratedTags: Binding<[Tag]> = .constant([]),
        tempTags: Binding<[Tag]>,
        newTempTagId: Binding<Int>,
        showAddTask: Binding<Bool> = .constant(false),
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
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .captionTextStyle()
            HStack(spacing: 8) {
                HStack {
                    FlowLayout(spacing: 8) {
                        ForEach(selectedTags) { selectedTag in
                            Text(selectedTag.name)
                                .appFilterButtonStyle(isSelected: true)
                                .contextMenu{
                                    Button(role: .destructive){
                                        selectedTags.removeAll() { $0.id == selectedTag.id }
                                    } label: {
                                        Label("Remove Tag", systemImage: "xmark")
                                    }
                                }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 44)
                .appInputCard()
                // This is also for adding a tag (idea 2)
                NavigationLink {
                    TagSelectionView(showDiscardDialog: $showDiscardDialog,selectedTags: $selectedTags, aiGeneratedTags: $aiGeneratedTags, tempTags: $tempTags, newTempTagId: $newTempTagId, showAddTask: $showAddTask, tagStore: tagStore)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                }
                .frame(width: 44, height: 44)
                .appInputCard()
            }
        }
    }
}
