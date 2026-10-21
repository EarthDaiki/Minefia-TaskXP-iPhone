//
//  DayView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 9/7/26.
//

import SwiftUI

private struct TimelineTaskLayout: Identifiable {
    let id: Int
    let taskWithTags: TaskWithTags
    let y: CGFloat
    let column: Int
    let columnCount: Int
    let isOverlapping: Bool
}

struct DayTimelineView: View {
    let taskStore: TaskStore
    let tagStore: TagStore
    let taskListStore: TaskListStore
    let tasksWithTags: [TaskWithTags]
    
    private let hourHeight: CGFloat = 60
    private let taskButtonHeight: CGFloat = 40
    
    @State private var timelineAlignmentOffset: CGFloat = 0
    @State private var selectedTaskWithTags: TaskWithTags?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0){
                    ForEach(0..<25, id: \.self) { hour in
                        HStack(alignment: .top) {
                            Text(hourText(hour: hour))
                                .frame(width: 70)
                                .secondaryTextStyle()
                                .alignmentGuide(.top) { text in
                                    text.height / 2
                                }
                                .background {
                                    GeometryReader { geometry in
                                        Color.clear
                                            .onAppear {
                                                timelineAlignmentOffset = geometry.size.height / 2
                                            }
                                    }
                                }
                            
                            Rectangle()
                                .fill(AppColors.separator)
                                .frame(height: 1)
                            
                        }
                        .frame(height: hourHeight, alignment: .top)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                GeometryReader { geometry in
                    let leftPadding: CGFloat = 80
                    let spacing: CGFloat = 30
                    ForEach(groupedTasks) { layout in
                        let y = timelineAlignmentOffset + layout.y
                        Rectangle()
                            .fill(AppColors.primary.opacity(0.65))
                            .frame(height: 1)
                            .padding(.leading, leftPadding)
                            .offset(y: y)
                    }
                    ForEach(groupedTasks) { layout in
                        let contentWidth: CGFloat = geometry.size.width - leftPadding
                        let laneWidth = contentWidth / CGFloat(layout.columnCount)
                        let x = leftPadding + laneWidth * CGFloat(layout.column)
                        let defaultWidth = CGFloat(180)
                        let defaultTaskX = leftPadding + (contentWidth - defaultWidth) / 2
                        NavigationLink {
                            IndivTaskView(taskWithTags: layout.taskWithTags, taskStore: taskStore, tagStore: tagStore, taskListStore: taskListStore)
                        } label: {
                            Text(layout.taskWithTags.task.title)
                                .frame(width: layout.isOverlapping ? laneWidth - spacing : defaultWidth, height: taskButtonHeight)
                                .appCardWithStrokeStyle()
                        }
                        .frame(width: layout.isOverlapping ? laneWidth - spacing : defaultWidth, height: taskButtonHeight)
                        .offset(
                            x: layout.isOverlapping ? x : defaultTaskX,
                            y: timelineAlignmentOffset + layout.y - taskButtonHeight / 2
                        )
                    }
                }
            }
        }
        .safeAreaPadding(.top)
        .appBackground()
    }
    private func yPosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
//        print(CGFloat(hour) * hourHeight + CGFloat(minute) / 60 * hourHeight)
        
        return CGFloat(hour) * hourHeight + CGFloat(minute) / 60 * hourHeight
    }
    private func hourText(hour: Int) -> String {
        return DateComponents(calendar: .current, hour: hour)
            .date?.formatted(.dateTime.hour()) ?? ""
    }
    
    private var tasksWithYPosition: [(taskWithTags: TaskWithTags, y: CGFloat)] {
        let items = tasksWithTags.compactMap { taskWithTags -> (taskWithTags: TaskWithTags, y: CGFloat)? in
            guard let dueAt = taskWithTags.task.dueAt else {
                return nil
            }
            let dueDate = Date(timeIntervalSince1970: TimeInterval(dueAt))
            return (taskWithTags, yPosition(for: dueDate))
        }
        return items.sorted { $0.1 < $1.1 }
    }
    
    private func isOverlapping(
        item: (taskWithTags: TaskWithTags, y: CGFloat),
        in items: [(taskWithTags: TaskWithTags, y: CGFloat)]
    ) -> Bool {
        let itemTop = item.y - taskButtonHeight / 2
        let itemBottom = item.y + taskButtonHeight / 2
        
        return items.contains { other in
            guard other.taskWithTags.task.id != item.taskWithTags.task.id else {
                return false
            }
            let otherTop = other.y - taskButtonHeight / 2
            let otherBottom = other.y + taskButtonHeight / 2
            
            return itemTop < otherBottom && itemBottom > otherTop
        }
    }
    
    private var groupedTasks: [TimelineTaskLayout] {
        var columnBottoms: [CGFloat] = []
        var temporaryLayouts: [(taskWithTags: TaskWithTags, y: CGFloat, column: Int, isOverlapping: Bool)] = []
        for item in tasksWithYPosition {
            let top = item.1 - taskButtonHeight / 2
            let bottom = item.1 + taskButtonHeight / 2
            
            var placedColumn: Int?
            
            for column in columnBottoms.indices {
                if columnBottoms[column] <= top {
                    placedColumn = column
                    columnBottoms[column] = bottom
                    break
                }
            }
            
            if placedColumn == nil {
                placedColumn = columnBottoms.count
                columnBottoms.append(bottom)
            }
            
            temporaryLayouts.append(
                (
                    taskWithTags: item.taskWithTags,
                    y: item.y,
                    column: placedColumn!,
                    isOverlapping(item: item, in: tasksWithYPosition)
                )
            )
        }
        let columnCount = max(columnBottoms.count, 1)
        return temporaryLayouts.map { item in
            TimelineTaskLayout(
                id: item.taskWithTags.task.id,
                taskWithTags: item.taskWithTags,
                y: item.y,
                column: item.column,
                columnCount: columnCount,
                isOverlapping: item.isOverlapping
            )
        }
    }
}

#Preview {
    let taskListStore = TaskListStore.preview
    DayTimelineView(taskStore: .preview, tagStore: .preview, taskListStore: taskListStore, tasksWithTags: taskListStore.tasksWithTags)
}
