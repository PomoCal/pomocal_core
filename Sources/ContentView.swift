import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var todoManager: TodoManager
    
    @State private var selectedTab: Tab = .tasks
    
    enum Tab: String, CaseIterable {
        case tasks = "Tasks"
        case library = "Library"
        case summary = "Summary"
    }
    
    @State private var isNoteSheetPresented = false
    
    var body: some View {
        HSplitView {
            // LEFT: Sidebar (Calendar & Events)
            VStack(spacing: 0) {
                // Calendar Month View
                CalendarGridView() 
                    .padding(.bottom)
                
                Divider()
                
                // Today's Date Header
                HStack {
                    Text("TODAY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                
                // Mini list of system events
                CalendarListView()
                
                Spacer()
                
                Button(action: {
                    todoManager.forceSync()
                }) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                        Text("Sync Now")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 20)
                .help("Force save data to iCloud")
                .contextMenu {
                    Button {
                        todoManager.selectSyncFolder()
                    } label: {
                        Label("Change Folder...", systemImage: "folder.badge.gear")
                    }
                    
                    if let path = todoManager.syncPath {
                        Text(path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(minWidth: 320, maxWidth: 360)
            .background(Color(NSColor.controlBackgroundColor))
            
            // MIDDLE: Content
            VStack(spacing: 0) {
                // Custom Tab Header
                HStack(spacing: 0) {
                    // Tasks Tab
                    Button(action: { selectedTab = .tasks }) {
                        ZStack {
                            Rectangle()
                                .fill(selectedTab == .tasks ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor))
                            Text("TASKS")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedTab == .tasks ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .frame(width: 1)
                    
                    // Library Tab
                    Button(action: { selectedTab = .library }) {
                        ZStack {
                            Rectangle()
                                .fill(selectedTab == .library ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor))
                            Text("LIBRARY")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedTab == .library ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Divider().frame(width: 1)
                    
                    // Summary Tab
                    Button(action: { selectedTab = .summary }) {
                        ZStack {
                            Rectangle()
                                .fill(selectedTab == .summary ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor))
                            Text("SUMMARY")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedTab == .summary ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 32) // Fixed height matching system controls
                
                Divider()
                
                switch selectedTab {
                case .tasks:
                    TodoView()
                case .library:
                    LibraryView()
                case .summary:
                    SummaryView()
                }
            }
            .frame(minWidth: 400)
            .background(Color(NSColor.windowBackgroundColor))
            
            // RIGHT: Timer & Focus
            rightSidePanel
        }
        .frame(minWidth: 1100, minHeight: 700)
        .onAppear {
            calendarManager.fetchEvents(for: todoManager.selectedDate)
        }
        .onChange(of: todoManager.selectedDate) { newDate in
            calendarManager.fetchEvents(for: newDate)
        }
        .onAppear {
            timerManager.onWorkSessionCompleted = { duration, taskTitle, taskId, note, rating in
                // 1. Save to Calendar with ID and Note
                calendarManager.savePomodoroEvent(duration: duration, title: taskTitle ?? "Pomodoro Session", taskId: taskId, note: note)
                
                // 2. Update Task Time & History (Recursive & Bubble-up)
                if let id = taskId {
                    // Update total time (bubbles up to parents)
                    todoManager.addTime(to: id, amount: duration)
                    
                    // Add WorkSession (to the specific task only)
                    let session = WorkSession(
                        id: UUID(),
                        startTime: Date().addingTimeInterval(-duration),
                        endTime: Date(),
                        duration: duration,
                        note: note,
                        rating: rating
                    )
                    todoManager.addSession(to: id, session: session)
                }
            }
        }
        .onChange(of: calendarManager.events) { _ in
            print("Events changed from CalendarManager, syncing time...")
            // Sync time from Calendar events to Tasks
            var legacyMap: [String: UUID] = [:]
            
            func addToMapRecursive(_ items: [TodoItem]) {
                for item in items {
                    legacyMap[item.title] = item.id
                    if let subs = item.subtasks {
                        addToMapRecursive(subs)
                    }
                }
            }
            addToMapRecursive(todoManager.todosForSelectedDate)
            
            let timeMap = calendarManager.calculateTimeSpent(for: todoManager.selectedDate, legacyTitles: legacyMap)
            todoManager.batchUpdateTime(timeMap)
        }
        // Note Sheet (Legacy: kept if needed, but Review replaces it mostly)
        .sheet(isPresented: $isNoteSheetPresented) {
            if timerManager.isWorkMode {
                SessionNoteView(note: $timerManager.currentNote)
            }
        }
        // Session Review Sheet
        .sheet(isPresented: $timerManager.showReviewSheet) {
            SessionReviewView()
                .environmentObject(timerManager)
        }
    }
    
    // MARK: - Right Panel (Refactored)
    var rightSidePanel: some View {
        VStack {
            // ... existing right panel ...
            // (No change needed here)

            // Timer Mode Tabs
            HStack(spacing: 0) {
                Button(action: { timerManager.setMode(.pomodoro) }) {
                    ZStack {
                        Rectangle()
                            .fill(timerManager.mode == .pomodoro ? Color(NSColor.controlBackgroundColor) : Color.clear)
                        Text("POMODORO")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(timerManager.mode == .pomodoro ? .primary : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .frame(height: 30)
                
                Divider().frame(height: 20)
                
                Button(action: { timerManager.setMode(.stopwatch) }) {
                    ZStack {
                        Rectangle()
                            .fill(timerManager.mode == .stopwatch ? Color(NSColor.controlBackgroundColor) : Color.clear)
                        Text("STOPWATCH")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(timerManager.mode == .stopwatch ? .primary : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .frame(height: 30)
            }
            .frame(height: 30)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Spacer to push Timer up a bit, but not too much
            Spacer(minLength: 20)
            
            if timerManager.mode == .pomodoro {
                if let task = timerManager.selectedTask {
                    Text(task.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Select a task to focus")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                // Circular Timer with Editor
                CircularTimerView(timerManager: timerManager)
                    .frame(width: 350, height: 350)
                    
            } else {
                // Stopwatch View
                VStack(spacing: 20) {
                    Text("STOPWATCH")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .tracking(2)
                    
                    Text(timerManager.formattedTime())
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding()
                }
                .frame(height: 300)
            }
            
            HStack(spacing: 30) {
                // Left: Note / Skip
                if timerManager.mode == .pomodoro && !timerManager.isWorkMode {
                    Button(action: timerManager.skipBreak) {
                        Image(systemName: "forward.end.fill")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.orange.opacity(0.2)))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("Skip Break")
                } else if timerManager.isWorkMode {
                    // Note Button in Work Mode
                    Button(action: {
                        isNoteSheetPresented = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.secondary.opacity(0.1)))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .help("Write Session Note")
                } else {
                     // Placeholder to balance layout if needed, or just nothing.
                     // The user asked for "Left", "Center", "Right".
                     // If we want perfect centering of the Start button, we might need a dummy spacer or proper alignment.
                     // But HStack spacing 30 is simple. Let's just put it here.
                     // If not in work mode (e.g. Stopwatch), maybe no note button?
                     // Stopwatch has no note/skip logic usually.
                     // Let's stick to valid logic. `isWorkMode` defaults to true/false.
                     // Actually Stopwatch mode relies on `timerManager.mode`.
                     // If Stopwatch, neither condition might be true?
                     // `isWorkMode` is boolean.
                     // If stopwatch, `isWorkMode` might be irrelevant.
                     // Let's just move the code block as is.
                     
                     // Wait, if Stopwatch, what happens?
                     // In original code:
                     // if timerManager.mode == .pomodoro && !timerManager.isWorkMode { ... }
                     // else if timerManager.isWorkMode { ... }
                     
                     // If mode == .stopwatch, !timerManager.isWorkMode might be false?
                     // Let's assume the previous logic was correct for visibility.
                }

                // Center: Start/Pause
                Button(action: {
                    timerManager.isRunning ? timerManager.pauseTimer() : timerManager.startTimer()
                }) {
                    Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.primary.opacity(0.1)))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: []) // Spacebar to toggle
                
                // Right: Reset
                Button(action: timerManager.resetTimer) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.secondary.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
            
            Spacer()
            
            QuoteView()
                .padding(.bottom, 30)
                .padding(.horizontal, 16)
        }
        .frame(minWidth: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Sub Views

struct CalendarListView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !calendarManager.hasAccess {
                    Text("Access required")
                        .font(.caption)
                    Button("Grant Access") { calendarManager.requestAccess() }
                } else {
                    ForEach(calendarManager.events, id: \.eventIdentifier) { event in
                        HStack(spacing: 12) {
                            Capsule()
                                .fill(Color(cgColor: event.calendar.cgColor))
                                .frame(width: 4)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                Text(event.startDate, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.05))
                        )
                        .padding(.horizontal)
                        .contextMenu {
                            Button(role: .destructive) {
                                calendarManager.deleteEvent(event)
                            } label: {
                                Label("Delete Event", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}

// Helper Struct for Flattened List
struct FlatTodoItem: Identifiable {
    let id: UUID
    let item: TodoItem
    let level: Int
}

struct TodoView: View {
    @EnvironmentObject var todoManager: TodoManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var isAddSheetPresented = false
    @State private var showSwitchAlert = false
    @State private var pendingTask: TodoItem?
    
    // For Editing
    @State private var taskToEdit: TodoItem?
    
    // For Category Management
    @State private var isCategoryManagerPresented = false
    
    // Expanded State for Subtasks
    @State private var expandedTasks: Set<UUID> = []
    
    // Inline Editing
    @State private var editingTaskId: UUID? = nil
    
    // Computed property to flatten the list
    private var flattenedTodos: [FlatTodoItem] {
        var result: [FlatTodoItem] = []
        
        func add(items: [TodoItem], level: Int) {
            for item in items {
                result.append(FlatTodoItem(id: item.id, item: item, level: level))
                // Only look deeper if expanded
                if expandedTasks.contains(item.id), let subtasks = item.subtasks, !subtasks.isEmpty {
                    add(items: subtasks, level: level + 1)
                }
            }
        }
        
        add(items: todoManager.todosForSelectedDate, level: 0)
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Action (Unified Style with Library)
            HStack {
                Text("Tasks")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { isAddSheetPresented = true }) {
                    Label("Add Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // List Area
            List {
                if todoManager.todosForSelectedDate.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "checklist")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.3))
                        .accessibilityHidden(true)
                    Text("No tasks for this day")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
                .listRowBackground(Color.clear)
            }
            
            // Iterate over the Flattened List
            // Note: We use id: \.id which comes from FlatTodoItem (which uses item.id)
            ForEach(flattenedTodos) { flatItem in
                TodoRowView(
                    todo: flatItem.item,
                    level: flatItem.level,
                    expandedTasks: $expandedTasks,
                    selectedTask: $timerManager.selectedTask,
                    taskToEdit: $taskToEdit,
                    editingTaskId: $editingTaskId,
                    onToggleCompletion: { item in
                        toggleCompletion(for: item)
                    },
                    onUpdate: { updatedItem in
                         updateTaskRecursive(targetId: updatedItem.id) { _ in updatedItem }
                    },
                    onAddSubtask: { item in
                        addSubtask(to: item)
                    },
                    onDelete: { item in
                        deleteTodoItem(item)
                    },
                    onSelectTask: { item in
                        selectTask(item)
                    },
                    isTimerRunning: timerManager.isRunning,
                    isTimerSelected: timerManager.selectedTask == flatItem.item
                )
                .listRowSeparator(.visible)
                .listRowBackground(Color.clear)
            }
            // Standard swipe-to-delete might behave weirdly on flat list if we just index.
            // Better to rely on the Row's context menu delete for subtasks, or implement a smarter onDelete.
            // For now, let's KEEP the .onDelete but it needs to map IndexSet to the Flat Items, then find them in real manager.
            // Actually, swipe-to-delete on a flattened tree is tricky. The context menu delete is safer for now.
            // I will remove the simple .onDelete iterator modifier to avoid confusion/bugs, 
            // relying on the explicit Delete button in the row or context menu.
        }
        .scrollContentBackground(.hidden)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: expandedTasks)
    }
    .sheet(isPresented: $isAddSheetPresented) {
        AddTodoView()
        .environmentObject(todoManager) 
    }
    .sheet(item: $taskToEdit) { task in
        TaskDetailView(task: task)
            .environmentObject(todoManager)
            .environmentObject(timerManager)
    }
    .sheet(isPresented: $isCategoryManagerPresented) {
        CategoryManagerView()
            .environmentObject(todoManager)
            .environmentObject(calendarManager)
    }
    .alert(isPresented: $showSwitchAlert) {
        Alert(
            title: Text("Switch Task?"),
            message: Text("Current timer progress will be lost."),
            primaryButton: .destructive(Text("Switch")) {
                if let task = pendingTask {
                    timerManager.resetTimer()
                    timerManager.selectedTask = task
                }
            },
            secondaryButton: .cancel()
        )
    }
}

private func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    return "\(minutes)min"
}

// MARK: - Actions

private func toggleCompletion(for item: TodoItem) {
    // Find parent if item is a subtask
    // Note: The structure might be deep. We need a recursive finder or just use updateTaskRecursive to flip it.
    
    // Let's use the robust recursive update we already have.
    updateTaskRecursive(targetId: item.id) { task in
        var updated = task
        updated.isCompleted.toggle()
        return updated
    }
}

private func deleteTodoItem(_ item: TodoItem) {
    // Recursive Delete Helper
    func deleteRecursive(in tasks: inout [TodoItem]) -> Bool {
        for i in 0..<tasks.count {
            if tasks[i].id == item.id {
                // Found it
                calendarManager.deletePomodoroEvents(for: tasks[i].title, on: tasks[i].date, taskId: tasks[i].id)
                tasks.remove(at: i)
                return true
            }
            
            if var subtasks = tasks[i].subtasks {
                if deleteRecursive(in: &subtasks) {
                    tasks[i].subtasks = subtasks
                    if subtasks.isEmpty { tasks[i].subtasks = nil }
                    return true
                }
            }
        }
        return false
    }
    
    _ = deleteRecursive(in: &todoManager.todos)
}

private func addSubtask(to parent: TodoItem) {
    // Recursive check
    var newId: UUID?
    updateTaskRecursive(targetId: parent.id) { task in
        var updated = task
        let newSub = TodoItem(title: "New Subtask", date: Date())
        newId = newSub.id
        if updated.subtasks == nil { updated.subtasks = [] }
        updated.subtasks?.append(newSub)
        // Expand
        expandedTasks.insert(task.id)
        return updated
    }
    if let id = newId { editingTaskId = id }
}

private func updateTaskRecursive(targetId: UUID, update: (TodoItem) -> TodoItem) {
    for i in 0..<todoManager.todos.count {
        if todoManager.todos[i].id == targetId {
            todoManager.todos[i] = update(todoManager.todos[i])
            return
        }
        // Check subtasks
        if var subtasks = todoManager.todos[i].subtasks {
            if updateSubtasks(in: &subtasks, targetId: targetId, update: update) {
                todoManager.todos[i].subtasks = subtasks
                // Need to update the parent with modified subtasks
                // Since subtasks is value type, modifying the local 'var' doesn't update 'todos[i]'.
                // We must re-assign.
                return
            }
        }
    }
}

private func updateSubtasks(in tasks: inout [TodoItem], targetId: UUID, update: (TodoItem) -> TodoItem) -> Bool {
    for i in 0..<tasks.count {
        if tasks[i].id == targetId {
            tasks[i] = update(tasks[i])
            return true
        }
        if var sub = tasks[i].subtasks {
            if updateSubtasks(in: &sub, targetId: targetId, update: update) {
                tasks[i].subtasks = sub
                return true
            }
        }
    }
    return false
}

private func selectTask(_ item: TodoItem) {
    if timerManager.isRunning || (timerManager.isWorkMode && timerManager.timeRemaining < 25*60) {
         if timerManager.isRunning {
             pendingTask = item
             showSwitchAlert = true
         } else {
             timerManager.selectedTask = item
         }
    } else {
        timerManager.selectedTask = item
    }
}
}


struct QuoteView: View {
    @State private var currentQuoteIndex = 0
    let quotes = [
        "The best way to predict the future is to create it.",
        "Your time is limited, so don't waste it living someone else's life.",
        "The only way to do great work is to love what you do.",
        "Believe you can and you're halfway there.",
        "Don't watch the clock; do what it does. Keep going.",
        "The future starts today, not tomorrow.",
        "Action is the foundational key to all success.",
        "Success is not final, failure is not fatal: It is the courage to continue that counts."
    ]
    
    // Timer to rotate quotes
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Daily Motivation")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(1)
            
            Text("\"\(quotes[currentQuoteIndex])\"")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .id(currentQuoteIndex) // Force redraw for animation
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
            }
        }
    }
}
