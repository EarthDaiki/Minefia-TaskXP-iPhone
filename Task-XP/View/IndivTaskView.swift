//
//  IndivTaskView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 7/16/26.
//

import SwiftUI

private extension IndivTaskView {
    private func detailCard(title: String, value: String) -> some View {
        VStack (alignment: .leading) {
            Text(title)
                .captionTextStyle()
            Text(value)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private func tagsCard(title: String, tags: [Tag]) -> some View {
        VStack (alignment: .leading) {
            Text(title)
                .captionTextStyle()
            if tags.isEmpty {
                Text("No tags")
                    .primaryTextStyle()
            } else {
                HStack {
                    FlowLayout(spacing: 8) {
                        ForEach(tags, id: \.id) { tag in
                            Text(tag.name)
                                .appFilterButtonStyle(isSelected: true)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private var descriptionText: String {
        let description = task.description?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let description, !description.isEmpty else {
            return "-"
        }

        return description
    }
    private var dueText: String {
        guard let dueAt = task.dueAt else {
            return "-"
        }
        let date = Date(timeIntervalSince1970: TimeInterval(dueAt))
        
        if task.dueHasTime {
            return date.formatted(date: .long, time: .shortened)
        }
        return date.formatted(date: .long, time: .omitted)
    }
    private func realTimeElapsedCard(title: String, from timestamp: Int) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .captionTextStyle()
            let startDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
            TimelineView(.periodic(from:.now, by: 1)) { context in
                let elapsed: Int = Int(context.date.timeIntervalSince(startDate))
                let hours = elapsed / 3600
                let minutes = (elapsed % 3600) / 60
                
                // Needs space between minutes num and m ??
                if hours <= 0 {
                    if minutes <= 0 {
                        Text("less than 1 minute")
                            .primaryTextStyle()
                    } else {
                        Text("\(minutes)m")
                            .primaryTextStyle()
                    }
                } else {
                    Text("\(hours)h \(minutes)m")
                        .primaryTextStyle()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private func minutesText(seconds: Int?) -> String {
        guard let seconds = seconds else {
            return "-"
        }
        let minutes = seconds / 60
        if minutes < 1 {
            return "less than 1 minute"
        } else if (minutes == 1) {
            return "1 minute"
        }
        return "\(minutes) minutes"
    }
    private func minutesText(minutes: Int?) -> String {
        guard let value = minutes else {
            return "-"
        }
        let hour = value / 60
        let minutes = value % 60
        if hour == 0 && minutes < 1 {
            return "less than 1 minute"
        } else if hour == 0 && minutes == 1 {
            return "1 minute"
        }
        
        if hour > 0 {
            return "\(hour)h \(minutes)m"
        }
        return "\(minutes) minutes"
    }
    private func timeText(timestamp: Int?) -> String {
        guard let timestamp = timestamp else {
            return "No date"
        }
        return Date(timeIntervalSince1970: TimeInterval(timestamp)).formatted(date: .long, time: .shortened)
    }
}

struct IndivTaskView: View {
    private let taskStore: TaskStore
    private let tagStore: TagStore
    private let taskListStore: TaskListStore
    private var task: Task {
        currentTaskWithTags.task
    }
    private var tags: [Tag] {
        currentTaskWithTags.tags
    }
    @State private var currentTaskWithTags: TaskWithTags
    @State private var showEditTask: Bool = false
    @State private var errorMessage: String?
    init(taskWithTags: TaskWithTags, taskStore: TaskStore, tagStore: TagStore, taskListStore: TaskListStore) {
        self.taskStore = taskStore
        self.tagStore = tagStore
        self.taskListStore = taskListStore
        _currentTaskWithTags = State(initialValue: taskWithTags)
    }
    var body: some View {
        ScrollView {
            VStack (alignment: .leading, spacing: 10){
                detailCard(title: "title", value: task.title)
                detailCard(title: "Description", value: descriptionText)
                tagsCard(title: "Tags", tags: tags)
                detailCard(title: "Due", value: dueText)
                detailCard(title: "Priority", value: String(task.priority))
                detailCard(title: "Difficulty", value: String(task.difficulty))
                detailCard(title: "Estimated Minutes", value: minutesText(minutes: task.estimatedMinutes))
                if let currentStartedAt = task.currentStartedAt, !task.completed {
                    realTimeElapsedCard(title: "Actual Minutes", from: currentStartedAt)
                } else {
                    detailCard(title: "Actual Minutes", value: minutesText(seconds: task.actualSeconds))
                }
                detailCard(title: "Status", value: task.completed ? "Completed" : "Not Completed")
                detailCard(title: "Started", value: timeText(timestamp: task.startedAt))
                detailCard(title: "Created", value: timeText(timestamp: task.createdAt))
                detailCard(title: "Updated", value: timeText(timestamp: task.updatedAt))
                if task.completed {
                    detailCard(title: "Completed", value: timeText(timestamp: task.completedAt))
                }
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if (!task.completed && task.startedAt == nil) {
                    Button {
                        do {
                            currentTaskWithTags = try taskListStore.startTask(id: task.id)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Image(systemName: "play")
                    }
                    .appButtonImageStyle()
                }
                if (!task.completed && task.startedAt != nil) {
                    Button {
                        do {
                            currentTaskWithTags = try taskListStore.resetStartTask(id: task.id)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Image(systemName: "stop.circle")
                    }
                    .appButtonImageStyle()
                }
                if (!task.completed) {
                    Button {
                        do {
                            currentTaskWithTags = try taskListStore.completeTask(id: task.id)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .appButtonImageStyle()
                } else {
                    Button {
                        do {
                            currentTaskWithTags = try taskListStore.resetCompleteTask(id: task.id)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .appButtonImageStyle()
                }
                Button {
                   showEditTask = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .appButtonImageStyle()
            }
        }
        .sheet(isPresented: $showEditTask) {
            EditTaskView(
                taskWithTags: currentTaskWithTags,
                taskStore: taskStore,
                tagStore: tagStore,
                taskListStore: taskListStore,
                onSave: { updatedTaskWithTags in
                    currentTaskWithTags = updatedTaskWithTags
                }
            )
        }
        .errorAlert(title: "Task Error", errorMessage: $errorMessage)
    }
}

#Preview {
    IndivTaskView(
        taskWithTags: TaskWithTags(
            task: Task(
                id: 1,
                title: "Task-XPを作る",
                description: "",
                dueAt: Int(Date().timeIntervalSince1970),
                dueHasTime: true,
                startedAt: nil,
                currentStartedAt: nil,
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
        taskListStore: .preview
    )
}
