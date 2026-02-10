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
            VStack {
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
                    
                    Button(action: timerManager.resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.secondary.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    
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
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Motivation Quote Box
                QuoteView()
                    .padding(.bottom, 30)
                    .padding(.horizontal)
            }
            .frame(minWidth: 300) // Reduced based on user feedback
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 1100, minHeight: 700)
        .onAppear {
            calendarManager.fetchEvents(for: todoManager.selectedDate)
        }
        .onChange(of: todoManager.selectedDate) { newDate in
            calendarManager.fetchEvents(for: newDate)
        }
        .onAppear {
            timerManager.onWorkSessionCompleted = { duration, taskTitle in
                // 1. Save to Calendar
                calendarManager.savePomodoroEvent(duration: duration, title: taskTitle ?? "Pomodoro Session")
                // 2. Update Task Time
                if let task = timerManager.selectedTask {
                    todoManager.addTime(to: task.id, amount: duration)
                }
            }
        }
    }
}

// ... (CalendarListView remains unchanged) ...

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
                
                ForEach(todoManager.todosForSelectedDate) { todo in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top) {
                            Button(action: { todoManager.toggleCompletion(for: todo) }) {
                                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(todo.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // Title
                                Text(todo.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .strikethrough(todo.isCompleted)
                                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                                    .onTapGesture(count: 2) { // Double tap to edit
                                        taskToEdit = todo
                                    }
                                
                                if let category = todo.category {
                                    Text(category.uppercased())
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.accentColor)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Spacer()
                            
                            // Time Spent Display
                            if todo.timeSpent > 0 {
                                Text(formatTime(todo.timeSpent))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.indigo)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.indigo.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            // Focus Button
                            if timerManager.selectedTask == todo {
                                Image(systemName: "timer")
                                    .foregroundColor(.indigo)
                                    .font(.title3)
                            } else {
                                Button(action: {
                                    if timerManager.isRunning || (timerManager.isWorkMode && timerManager.timeRemaining < 25*60) {
                                         // If timer is running or progress has been made (assuming 25 min default for simplicity check, or just check isRunning/paused with progress)
                                         // Simplified: If timerManager.isRunning, show alert.
                                         if timerManager.isRunning {
                                             pendingTask = todo
                                             showSwitchAlert = true
                                         } else {
                                             timerManager.selectedTask = todo
                                         }
                                    } else {
                                        timerManager.selectedTask = todo
                                    }
                                }) {
                                    Image(systemName: "play.circle")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .contextMenu {
                            Button {
                                taskToEdit = todo
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                // Also delete matching calendar events
                                calendarManager.deletePomodoroEvents(for: todo.title, on: todo.date)
                                if let index = todoManager.todos.firstIndex(where: { $0.id == todo.id }) {
                                    todoManager.todos.remove(at: index)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        
                        // Book Info & Goal
                        if let book = todo.book {
                            HStack(alignment: .top, spacing: 10) {
                                if let urlString = book.thumbnailURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.gray.opacity(0.1)
                                    }
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 45)
                                    .cornerRadius(2)
                                } else {
                                    Image(systemName: "book.closed")
                                        .frame(width: 30, height: 45)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(2)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    if let goal = todo.goalRange {
                                        Text("Goal: \(goal)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.leading, 34) // Indent to align with text
                            .padding(.top, 4)
                        } else if let goal = todo.goalRange {
                            Text("Goal: \(goal)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading, 34)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowSeparator(.visible)
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: todoManager.deleteTodo)
            }
            .scrollContentBackground(.hidden)
        }
        .sheet(isPresented: $isAddSheetPresented) {
            AddTodoView()
            .environmentObject(todoManager) 
        }
        .sheet(item: $taskToEdit) { task in
            EditTodoView(task: task)
                .environmentObject(todoManager)
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
