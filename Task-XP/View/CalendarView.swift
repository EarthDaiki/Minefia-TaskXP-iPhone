//
//  CalendarView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 9/7/26.
//

import SwiftUI
import UIKit

struct UIKitCalendarView: UIViewRepresentable {
    let tasksWithTags: [TaskWithTags]
    @Binding var selectedDate: Date?
    @Binding var visibleDate: Date
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale.current
        
        calendarView.delegate = context.coordinator
        
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection
        
        calendarView.overrideUserInterfaceStyle = .dark
        calendarView.tintColor = UIColor(AppColors.primary)
        
        return calendarView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(tasksWithTags: tasksWithTags, selectedDate: $selectedDate, visibleDate: $visibleDate)
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // if selectedDate goes to nil, you need to reset UICalendar selection.
        if selectedDate == nil, let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            selection.setSelected(nil, animated: false)
        }
        
        let components = uiView.calendar.dateComponents([.year, .month, .day], from: visibleDate)
        
        if !Calendar.current.isDate(
            uiView.calendar.date(from: uiView.visibleDateComponents) ?? Date(),
            equalTo: visibleDate,
            toGranularity: .month
        ) {
            uiView.setVisibleDateComponents(components, animated: true)
        }
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        let tasksWithTags: [TaskWithTags]
        @Binding var selectedDate: Date?
        @Binding var visibleDate: Date
        
        init(tasksWithTags: [TaskWithTags], selectedDate: Binding<Date?>, visibleDate: Binding<Date>) {
            self.tasksWithTags = tasksWithTags
            _selectedDate = selectedDate
            _visibleDate = visibleDate
        }
        
        func calendarView(
            _ calendarView: UICalendarView,
            didChangeVisibleDateComponentsFrom previousDateComponents: DateComponents
        ) {
            let components = calendarView.visibleDateComponents
            if let date = calendarView.calendar.date(from: components) {
                visibleDate = date
                print("visible date: \(date)")
            }
        }
        
        func calendarView(
            _ calendarView: UICalendarView,
            decorationFor dateComponents: DateComponents,
        ) -> UICalendarView.Decoration? {
            let calendar = Calendar.current
            
            guard let date = calendar.date(from: dateComponents) else {
                return nil
            }
            let hasTask = tasksWithTags.contains { task in
                guard let dueAt = task.task.dueAt else {
                    return false
                }
                let taskDueDate = Date(timeIntervalSince1970: TimeInterval(dueAt))
                
                return calendar.isDate(taskDueDate, inSameDayAs: date)
            }
            return hasTask ? .default() : nil
        }
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents else {
                selectedDate = nil
                return
            }
            selectedDate = Calendar.current.date(from: dateComponents)
        }
    }
}

struct CalendarView: View {
    let taskStore: TaskStore
    let tagStore: TagStore
    let taskListStore: TaskListStore
    @State private var selectedDate: Date?
    @State private var visibleDate: Date = Date()
    @State private var showAddTask: Bool = false
    
    var body: some View {
        NavigationStack {
            UIKitCalendarView(tasksWithTags: taskListStore.tasksWithTags, selectedDate: $selectedDate, visibleDate: $visibleDate)
                .navigationDestination(
                    isPresented: Binding(
                        get: {selectedDate != nil},
                        set: { isPresented in
                            if !isPresented {
                                selectedDate = nil
                            }
                        }
                    )
                ) {
                    if let selectedDate {
                        DayView(
                            taskStore: taskStore,
                            tagStore: tagStore,
                            taskListStore: taskListStore,
                            selectedDate: Binding(
                                get: {self.selectedDate ?? selectedDate},
                                set: {self.selectedDate = $0}
                            ),
                            visibleDate: $visibleDate
                        )
                    }
                }
                .toolbar {
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
                .appBackground()
        }
    }
}

#Preview {
    CalendarView(taskStore: .preview, tagStore: .preview, taskListStore: .preview)
}
