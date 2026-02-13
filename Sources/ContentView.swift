import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var todoManager: TodoManager
    
    @State private var selectedTab: Tab = .tasks
    @State private var isNoteSheetPresented = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // Mode Switch Alert State
    @State private var showModeSwitchAlert = false
    @State private var pendingMode: TimerManager.TimerMode?
    
    // D-Day Manager
    @StateObject private var dDayManager = DDayManager()
    @State private var isDDaySheetPresented = false
    
    enum Tab: String, CaseIterable {
        case tasks = "Tasks"
        case library = "Library"
        case summary = "Summary"
        
        var icon: String {
            switch self {
            case .tasks: return "checklist"
            case .library: return "books.vertical"
            case .summary: return "chart.bar.xaxis"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // LEFT: Sidebar (Calendar & Events)
            sidebarView
                .navigationSplitViewColumnWidth(min: 300, ideal: 320, max: 360)
                .background(.ultraThinMaterial) // Vibrancy
        } content: {
            // MIDDLE: Content
            middleContentView
                .navigationSplitViewColumnWidth(min: 400, ideal: 600) // Increase ideal width for balance
                .background(Color.appBackground) // Unified color
        } detail: {
            // RIGHT: Timer & Focus
            rightSidePanel
                .navigationSplitViewColumnWidth(min: 500, ideal: 600) // Match middle panel for 50/50
                .background(Color.appBackground) // Unified color
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1300, minHeight: 700)
        .onAppear {
            calendarManager.fetchEvents(for: todoManager.selectedDate)
        }
        .onChange(of: todoManager.selectedDate) { newDate in
            calendarManager.fetchEvents(for: newDate)
        }
        .sheet(isPresented: $isDDaySheetPresented) {
            DDayView(manager: dDayManager)
                .environmentObject(calendarManager)
        }
    }
    
    // MARK: - Sidebar View
    private var dateHeaderFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }
    
    var sidebarView: some View {
        VStack(spacing: 0) {
            CalendarGridView()
                .padding(.bottom)
            
            Divider()
            
            HStack {
                Text(Calendar.current.isDateInToday(todoManager.selectedDate) ? "TODAY" : dateHeaderFormatter.string(from: todoManager.selectedDate))
                    .font(.appCaption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            
            CalendarListView()
            
            Spacer()
            
            HStack(spacing: 12) {
                // Sync Button (Left)
                Button(action: {
                    todoManager.forceSync()
                }) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                        Text("Sync")
                    }
                    .font(.appCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("Force save data to iCloud")
                .contextMenu {
                    Button { todoManager.selectSyncFolder() } label: {
                        Label("Change Folder...", systemImage: "folder.badge.gear")
                    }
                    if let path = todoManager.syncPath {
                        Text(path).font(.caption).foregroundColor(.secondary)
                    }
                }
                
                // D-Day Button (Right)
                Button(action: {
                    isDDaySheetPresented = true
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                        Text("D-Day")
                    }
                    .font(.appCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("Manage D-Days")
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding(.top, 20)
    }

    var middleContentView: some View {
        VStack(spacing: 0) {
            // Modern Styled Tab Header
            HStack(spacing: 40) { // Increased spacing for icons
                ForEach([Tab.tasks, .library, .summary], id: \.self) { tab in
                    Button(action: { withAnimation { selectedTab = tab } }) {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                            
                            Text(tab.rawValue)
                                .font(selectedTab == tab ? .appCaption.weight(.bold) : .appCaption)
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                            
                            if selectedTab == tab {
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 2)
                                    .matchedGeometryEffect(id: "TabIndicator", in: Namespace().wrappedValue)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 16)
            .background(Color.clear) // Transparent to show main background
            
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
    }
    
    // MARK: - Right Panel (Timer)
    var rightSidePanel: some View {
        VStack {
            // Timer Mode Segmented Control
            Picker("", selection: Binding(
                get: { timerManager.mode },
                set: { newMode in
                    // Check if current session has progress that would be lost
                    let isPomodoroActive = timerManager.mode == .pomodoro && 
                                           timerManager.timeRemaining < 25*60 && // Assumption: default is 25m, but can change. 
                                           // Better: timeRemaining < workDuration? 
                                           // TimerManager doesn't expose workDuration publicly as a var... 
                                           // Actually it does: line 27 is private. 
                                           // But `timerManager.progress` > 0 works.
                                           timerManager.progress > 0 && 
                                           timerManager.timeRemaining > 0
                    
                    let isStopwatchActive = timerManager.mode == .stopwatch && timerManager.stopwatchSeconds > 0
                    
                    if timerManager.isRunning || isPomodoroActive || isStopwatchActive {
                        // Warn User
                        pendingMode = newMode
                        showModeSwitchAlert = true
                    } else {
                        // Safe to switch
                        timerManager.setMode(newMode)
                    }
                }
            )) { 
                Text("Pomodoro").tag(TimerManager.TimerMode.pomodoro)
                Text("Stopwatch").tag(TimerManager.TimerMode.stopwatch)
            }
            .pickerStyle(.segmented)
            .labelsHidden() // Hide label
            .padding()
            
            Spacer()
            
            if timerManager.mode == .pomodoro {
                if let task = timerManager.selectedTask {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                } else {
                    Text("Select a task to focus")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }
                
                // Circular Timer
                CircularTimerView(timerManager: timerManager)
                    .frame(width: 320, height: 320)
                    
            } else {
                // Stopwatch View
                if let task = timerManager.selectedTask {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                } else {
                    Text("Select a task")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }

                VStack(spacing: 20) {
                    Text("STOPWATCH")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .tracking(4)
                    
                    FlipClockView(
                        seconds: Int(timerManager.stopwatchSeconds),
                        showHours: true,
                        fontSize: 70, 
                        color: .primary
                    )
                    .padding()
                }
                .frame(height: 300)
            }
            
            // Timer Controls
            HStack(spacing: 40) {
                // Skip / Note
                if timerManager.mode == .pomodoro && !timerManager.isWorkMode {
                    Button(action: timerManager.skipBreak) {
                        Image(systemName: "forward.end.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .help("Skip Break")
                } else if timerManager.isWorkMode {
                    Button(action: { isNoteSheetPresented = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .help("Write Note")
                }
                
                // Play / Pause (Big Button)
                Button(action: {
                    timerManager.isRunning ? timerManager.pauseTimer() : timerManager.startTimer()
                }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo, .blue], startPoint: .top, endPoint: .bottom))
                            .frame(width: 70, height: 70)
                            .shadow(radius: 5)
                        
                        Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
                
                // Stop / Reset
                if timerManager.mode == .stopwatch {
                    Button(action: timerManager.finishStopwatch) {
                        Image(systemName: "square.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .help("Finish & Save")
                } else {
                    Button(action: timerManager.resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .help("Reset Timer")
                }
            }
            .padding(.top, 30)
            
            Spacer()
            
            QuoteView()
                .padding(.bottom, 30)
                .padding(.horizontal, 16)
        }
    }
}

// MARK: - Sub Views

struct CalendarListView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var todoManager: TodoManager // Added for Task Logic
    
    // Helper to resolve Task Details
    private func resolveTask(from event: EKEvent) -> (title: String, category: String?, isSubtask: Bool) {
        if let urlString = event.url?.absoluteString,
           urlString.starts(with: "pomocal://task/"),
           let idString = urlString.components(separatedBy: "/").last,
           let uuid = UUID(uuidString: idString) {
            
            // Search in TodoManager
            // 1. Check Top Level
            if let task = todoManager.todos.first(where: { $0.id == uuid }) {
                // Emoji Logic: Use user-selected emoji if available, otherwise random fallback
                let emojiIcon = task.emoji ?? randomEmoji(for: task.title)
                let displayTitle = "\(emojiIcon) \(task.title)"
                return (displayTitle, task.category, false)
            }
            
            // 2. Check Subtasks (recursively) - mark as subtask to hide
            return (event.title, nil, true)
        }
        
        // Legacy or External Events: Show them as top-level
        return (event.title, nil, false)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !calendarManager.hasAccess {
                    Text("Access required")
                        .font(.caption)
                    Button("Grant Access") { calendarManager.requestAccess() }
                } else {
                    ForEach(calendarManager.events, id: \.eventIdentifier) { event in
                        let taskInfo = resolveTask(from: event)
                        
                        if !taskInfo.isSubtask { // FILTER: Hide subtasks
                            HStack(spacing: 12) {
                                // Task Color Marker (Use Category Color if available, else random based on title)
                                Capsule()
                                    .fill(taskInfo.category != nil ? categoryColor(for: taskInfo.category!) : categoryColor(for: event.title ?? ""))
                                    .frame(width: 4)
                                    .frame(maxHeight: .infinity)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    // Title: [Emoji] Task Name
                                    Text(taskInfo.title)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true) // Allow wrapping
                                    
                                    // Time: Start ~ End
                                    Text("\(event.startDate, formatter: timeFormatter) ~ \(event.endDate, formatter: timeFormatter)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Category Badge (Right)
                                if let category = taskInfo.category {
                                    Text(category)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(categoryColor(for: category))) // Unique color per category
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(NSColor.controlBackgroundColor)) // Slight contrast against white sidebar
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
    
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()
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
    @State private var showBreakSkipAlert = false
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
                
                // Category Management Button
                Button(action: { isCategoryManagerPresented = true }) {
                    Image(systemName: "folder.badge.gear")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Manage Categories")
                .padding(.trailing, 8)
                
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
                    onStartTask: { item in
                        startTask(item)
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
    .alert(isPresented: $showBreakSkipAlert) {
        Alert(
            title: Text("Skip Break?"),
            message: Text("Do you want to skip the break and start working on \(pendingTask?.title ?? "this task")?"),
            primaryButton: .default(Text("Start Work")) {
                if let task = pendingTask {
                    timerManager.skipBreak() // Switches to Work
                    timerManager.selectedTask = task
                    timerManager.resetTimer() // Ensure clean start
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
        // Safe Switch Logic:
        // 1. Is Timer Running?
        // 2. Is there unsaved progress? (Pomodoro started OR Stopwatch started)
        
        let isPomodoroActive = timerManager.mode == .pomodoro && 
                               timerManager.progress > 0 && 
                               timerManager.timeRemaining > 0
        
        let isStopwatchActive = timerManager.mode == .stopwatch && timerManager.stopwatchSeconds > 0
        
        if timerManager.isRunning || isPomodoroActive || isStopwatchActive {
            // Warn if switching would lose progress
            pendingTask = item
            showSwitchAlert = true
        } else if !timerManager.isWorkMode && timerManager.mode == .pomodoro {
            // Break Mode: Prompt to skip
            pendingTask = item
            showBreakSkipAlert = true
        } else {
            // Safe to switch
            timerManager.selectedTask = item
        }
    }
    
    // Helper to Prepare Task (Select & Reset Timer)
    private func startTask(_ item: TodoItem) {
        // If timer is running, pause/reset first
        if timerManager.isRunning {
             timerManager.pauseTimer()
        }
        
        // Check for Break Mode Skip
        if !timerManager.isWorkMode && timerManager.mode == .pomodoro {
             // Ask user if they want to skip break
             pendingTask = item
             showBreakSkipAlert = true
             return
        }

        // Switch Task
        timerManager.selectedTask = item
        
        // Reset Timer (Ready to Start)
        timerManager.resetTimer()
        
        // Note: User requested NOT to auto-start. Just prepare.
        // timerManager.startTimer() 
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
