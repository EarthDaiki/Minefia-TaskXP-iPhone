//
//  DayView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 9/8/26.
//

import SwiftUI

struct DayView: View {
    @Environment(\.dismiss) private var dismiss
    let taskStore: TaskStore
    let tagStore: TagStore
    let taskListStore: TaskListStore
    @Binding var selectedDate: Date
    @Binding var visibleDate: Date
    
    @State private var page: Int? = 0
    @State private var showAddTask: Bool = false
    
    private let calendar = Calendar.current
    
    private func hasTask(on date: Date) -> Bool {
        taskListStore.tasksWithTags.contains { taskWithTags in
            guard let dueAt = taskWithTags.task.dueAt else {
                return false
            }

            let dueDate = Date(timeIntervalSince1970: TimeInterval(dueAt))
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    private func weekView(for date: Date) -> some View {
        HStack(spacing: 0){
            ForEach(makeDatesInWeek(for: date), id: \.self) { date in
                let hasTask = hasTask(on: date)
                Button {
                    selectedDate = date
                    visibleDate = date
                } label: {
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let isToday = calendar.isDateInToday(date)
                    VStack(spacing: 5) {
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .emphasizedTextStyle()
                        Text(date.formatted(.dateTime.day()))
                            .emphasizedTextStyle()
                            .padding()
                            .background {
                                if isSelected {
                                    Circle()
                                        .fill(AppColors.primary)
                                }
                            }
                            .overlay {
                                if isToday && !isSelected {
                                    Circle()
                                        .stroke(AppColors.secondary, lineWidth: 1)
                                }
                            }
                        Circle()
                            .fill(hasTask ? AppColors.secondary : .clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func dayLabelSection() -> some View {
        VStack {
            Text(selectedDate.formatted(.dateTime.year().month(.wide).day().weekday(.wide)))
                .primaryTextStyle()
        }
    }
    
    private func allDayTasksSection() -> some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        return LazyVGrid(columns: columns) {
            ForEach(allDayTasks, id: \.self.task.id) { taskWithTags in
                NavigationLink {
                    IndivTaskView(taskWithTags: taskWithTags, taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore)
                } label: {
                    Text(taskWithTags.task.title)
                        .primaryTextStyle()
                }
                .appCard()
            }
        }
    }
    
    private var visibleDateMonthText: String {
        return visibleDate.formatted(.dateTime.month(.wide))
    }
    
    private func getSelectedDateTasksWithTags() -> [TaskWithTags] {
        let calendar = Calendar.current
        return taskListStore.tasksWithTags.filter { taskWithTags in
            guard let dueAt = taskWithTags.task.dueAt else {
                return false
            }
            let dueDate = Date(timeIntervalSince1970: TimeInterval(dueAt))
            return calendar.isDate(dueDate, inSameDayAs: selectedDate)
        }
    }
    
    private var allDayTasks: [TaskWithTags] {
        getSelectedDateTasksWithTags().filter { taskWithTags in
            return !taskWithTags.task.dueHasTime
        }
    }
    
    private var timedTasks: [TaskWithTags] {
        getSelectedDateTasksWithTags().filter { taskWithTags in
            return taskWithTags.task.dueHasTime
        }
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach([-1, 0, 1], id: \.self) { offset in
                            weekView(
                                for: calendar.date(
                                    byAdding: .weekOfYear,
                                    value: offset,
                                    to: selectedDate
                                ) ?? selectedDate
                            )
                            .containerRelativeFrame(.horizontal)
                            .id(offset)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $page)
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(0, anchor: .center)
                    }
                }
                .onChange(of: page) {
                    guard let page, page != 0 else {
                        return
                    }
                    let newDate = calendar.date(
                        byAdding: .weekOfYear,
                        value: page,
                        to: selectedDate
                    ) ?? selectedDate
                    
                    selectedDate = newDate
                    visibleDate = newDate
                    
                    self.page = 0
                }
            }
            dayLabelSection()
            if !allDayTasks.isEmpty {
                allDayTasksSection()
                    .padding(.horizontal)
            }
            DayTimelineView(taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore, tasksWithTags: timedTasks)
        }
        .appBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack (spacing: 4){
                        Image(systemName: "chevron.left")
                            .appButtonImageStyle()
                        Text(visibleDateMonthText)
                            .primaryTextStyle()
                    }
//                    .foregroundStyle(AppColors.textPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTask = true
                } label: {
                    Label("Add task", systemImage: "plus")
                }
                .appButtonImageStyle()
                .sheet(isPresented: $showAddTask) {
                    AddTaskView(showAddTask: $showAddTask, taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore)
                }
            }
        }
    }
}

private func makeDatesInWeek(for date: Date) -> [Date] {
    let calendar = Calendar.current

    guard let weekInterval = calendar.dateInterval(
        of: .weekOfYear,
        for: date
    ) else {
        return []
    }

    return (0..<7).compactMap { day in
        calendar.date(
            byAdding: .day,
            value: day,
            to: weekInterval.start
        )
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    @Previewable @State var visibleDate = Date()

    DayView(
        taskStore: .preview,
        tagStore: .preview,
        taskListStore: .preview,
        selectedDate: $selectedDate,
        visibleDate: $visibleDate
    )
}
