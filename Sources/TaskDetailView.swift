import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var todoManager: TodoManager
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    @State var task: TodoItem
    
    @State private var selectedTab: DetailTab = .subtasks
    @State private var newSubtaskTitle = ""
    @State private var isAddingSubtask = false
    
    // For Settings Tab (Edit Logic)
    @State private var title = ""
    @State private var selectedCategory = ""
    @State private var newCategory = ""
    @State private var isAddingCategory = false
    @State private var selectedBook: BookInfo?
    @State private var isBookSearchPresented = false
    @State private var chapter = ""
    @State private var startPage = ""
    @State private var endPage = ""
    
    enum DetailTab: String, CaseIterable {
        case subtasks = "Subtasks"
        case timeline = "Timeline"
        case settings = "Settings"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(formatTime(task.timeSpent))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Tabs
            Picker("Tab", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            // Content
            Group {
                switch selectedTab {
                case .subtasks:
                    SubtasksView
                case .timeline:
                    TimelineView
                case .settings:
                    SettingsView
                }
            }
            .frame(maxHeight: .infinity)
            
            Divider()
            
            // Footer Actions
            HStack {
                Button("Done") {
                    saveChanges() // Save specific settings if any changed
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 650)
        .onAppear {
            populateFields()
        }
    }
    
    // MARK: - Subtasks View
    var SubtasksView: some View {
        VStack {
            List {
                if let subtasks = task.subtasks, !subtasks.isEmpty {
                    ForEach(subtasks) { subtask in
                        HStack {
                            Button(action: { toggleSubtaskCompletion(subtask) }) {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(subtask.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                            
                            Text(subtask.title)
                                .strikethrough(subtask.isCompleted)
                            
                            Spacer()
                            
                            if subtask.timeSpent > 0 {
                                Text(formatTime(subtask.timeSpent))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                // Start timer for subtask
                                // Note: This might be complex if we switch context entirely.
                                // For now, let's just allow selecting it as the main task if that's the design.
                                // But the prompt implies subtask time adds to task time.
                                // To keep it simple: We set this subtask as the selectedTask in TimerManager.
                                // BUT TodoManager needs to know it's a subtask to update the parent?
                                // Or we just treat it as a task.
                                // Let's simplify: A subtask is just a task.
                                // If we want aggregation, we need to handle that in TodoManager.
                                // For MVP: Changing selection to a subtask might be tricky if it's not in the main list.
                                // Let's just focus on UI for now.
                            }) {
                                Image(systemName: "play.circle")
                            }
                            .buttonStyle(.plain)
                            .disabled(true) // Disable for now until logic is clearer
                            .help("Subtask timer usage pending implementation")
                        }
                    }
                    .onDelete(perform: deleteSubtask)
                } else {
                    Text("No subtasks")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            
            HStack {
                TextField("New Subtask", text: $newSubtaskTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addSubtask() }
                
                Button(action: addSubtask) {
                    Image(systemName: "plus")
                }
                .disabled(newSubtaskTitle.isEmpty)
            }
            .padding()
        }
    }
    
    // MARK: - Timeline View
    var TimelineView: some View {
        List {
            if let sessions = task.sessions?.sorted(by: { $0.startTime > $1.startTime }), !sessions.isEmpty {
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(session.startTime, style: .date)
                            Text(session.startTime, style: .time)
                            ArrowShape()
                                .stroke(Color.secondary, lineWidth: 1.5)
                                .frame(width: 20, height: 6)
                            Text(session.endTime, style: .time)
                            
                            Spacer()
                            
                            Text(formatTime(session.duration))
                                .fontWeight(.bold)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        if let note = session.note, !note.isEmpty {
                            Text(note)
                                .font(.body)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No history yet")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    // MARK: - Settings View (Original Edit Logic)
    var SettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Basic Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("TITLE")
                        .font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                    TextField("Task Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORY")
                        .font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                    HStack {
                        ForEach(todoManager.savedCategories, id: \.self) { cat in
                            Button(action: { selectedCategory = cat }) {
                                Text(cat)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(selectedCategory == cat ? Color.accentColor : Color.gray.opacity(0.1))
                                    .foregroundColor(selectedCategory == cat ? .white : .primary)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                         Button(action: { isAddingCategory.toggle() }) {
                             Image(systemName: "plus")
                         }
                         .buttonStyle(.plain)
                         .popover(isPresented: $isAddingCategory) {
                             HStack {
                                 TextField("New", text: $newCategory).frame(width: 100)
                                 Button("Add") {
                                     if !newCategory.isEmpty {
                                         todoManager.addCategory(newCategory)
                                         selectedCategory = newCategory
                                         newCategory = ""
                                         isAddingCategory = false
                                     }
                                 }
                             }
                             .padding()
                         }
                    }
                }
                
                // Book
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("STUDY MATERIAL").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                        Spacer()
                        Button("Change") { isBookSearchPresented = true }.font(.caption)
                    }
                    if let book = selectedBook {
                        HStack {
                            Text(book.title)
                            Spacer()
                            Button(action: { selectedBook = nil }) { Image(systemName: "xmark") }.buttonStyle(.plain)
                        }
                        .padding().background(Color.gray.opacity(0.1)).cornerRadius(8)
                    } else {
                        Button("Select Book") { isBookSearchPresented = true }
                    }
                }
                .sheet(isPresented: $isBookSearchPresented) {
                    BookSearchView(selectedBook: $selectedBook)
                }
                
                // Goal
                VStack(alignment: .leading, spacing: 8) {
                    Text("GOAL RANGE").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                    TextField("e.g. Ch 1 or p.10-20", text: $chapter).textFieldStyle(.roundedBorder)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Logic
    
    private func populateFields() {
        title = task.title
        selectedCategory = task.category ?? ""
        selectedBook = task.book
        chapter = task.goalRange ?? ""
    }
    
    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.category = selectedCategory.isEmpty ? nil : selectedCategory
        updatedTask.book = selectedBook
        updatedTask.goalRange = chapter.isEmpty ? nil : chapter
        
        todoManager.updateTodo(updatedTask)
        // Note: Subtasks are updated in real-time on the local state copy, 
        // need to make sure they are saved back to todoManager.
        // Actually, since we modified 'task' (State), we need to write it back.
        // The subtask modifications below modify 'task'.
    }
    
    private func addSubtask() {
        guard !newSubtaskTitle.isEmpty else { return }
        let newSub = TodoItem(title: newSubtaskTitle, date: Date())
        if task.subtasks == nil { task.subtasks = [] }
        task.subtasks?.append(newSub)
        newSubtaskTitle = ""
        saveChanges()
    }
    
    private func deleteSubtask(at offsets: IndexSet) {
        task.subtasks?.remove(atOffsets: offsets)
        saveChanges()
    }
    
    private func toggleSubtaskCompletion(_ subtask: TodoItem) {
        if let index = task.subtasks?.firstIndex(where: { $0.id == subtask.id }) {
            task.subtasks?[index].isCompleted.toggle()
            saveChanges()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        return "\(minutes)min"
    }
}

// Helper for Arrow
struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.midY - 4))
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.midY + 4))
        return path
    }
}
