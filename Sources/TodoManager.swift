import Foundation
import Combine
import AppKit

struct BookInfo: Codable, Equatable {
    let id: String
    let title: String
    let authors: [String]
    let thumbnailURL: String?
    var goalStartDate: Date?
    var goalEndDate: Date?
}

extension BookInfo: Identifiable {}

struct WorkSession: Codable, Identifiable, Equatable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let note: String?
    var rating: Int? // 1-5 stars
}

struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var date: Date
    
    // New Fields
    var category: String?
    var book: BookInfo?
    var goalRange: String?
    var actualRange: String?
    var timeSpent: TimeInterval = 0 // In seconds
    var emoji: String? // User selected emoji
    
    // Subtasks & Sessions
    var subtasks: [TodoItem]?
    var sessions: [WorkSession]?
    
    init(title: String, date: Date = Date(), category: String? = nil, book: BookInfo? = nil, goalRange: String? = nil, timeSpent: TimeInterval = 0, emoji: String? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.date = date
        self.category = category
        self.book = book
        self.goalRange = goalRange
        self.timeSpent = timeSpent
        self.emoji = emoji
        self.subtasks = []
        self.sessions = []
    }
}

// Persistence Helper
struct AppData: Codable {
    let todos: [TodoItem]
    let categories: [String]
    let savedBooks: [BookInfo]
}

// ... existing code ...

class TodoManager: ObservableObject {
    @Published var todos: [TodoItem] = [] {
        didSet { saveTodos() }
    }
    @Published var savedCategories: [String] = ["Computer Science", "English", "Math", "Physics", "General"] {
        didSet { saveLibrary() }
    }
    @Published var savedBooks: [BookInfo] = [] {
        didSet { saveLibrary() }
    }
    
    @Published var selectedDate: Date = Date() {
        didSet {
            loadTodos(for: selectedDate)
        }
    }
    
    // Custom Sync Path
    @Published var syncPath: String? {
        didSet {
            // We don't save path string anymore, we save bookmark data in selectSyncFolder
        }
    }
    
    private var syncURL: URL?
    
    init() {
        restoreSyncFolder()
        load()
    }
    
    private func restoreSyncFolder() {
        if let data = UserDefaults.standard.data(forKey: "syncFolderBookmark") {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: data, 
                                  options: .withSecurityScope, 
                                  relativeTo: nil, 
                                  bookmarkDataIsStale: &isStale)
                
                if isStale {
                    // Bookmark is stale, might need to save a new one if possible, 
                    // or just use it one last time to re-save? 
                    // For now, just try to use it.
                    print("Bookmark is stale")
                }
                
                if url.startAccessingSecurityScopedResource() {
                    self.syncURL = url
                    self.syncPath = url.path
                    print("Restored sync folder access: \(url.path)")
                } else {
                    print("Failed to access security scoped resource")
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }
    }
    
    deinit {
        syncURL?.stopAccessingSecurityScopedResource()
    }
    
    // MARK: - Logic
    
    var todosForSelectedDate: [TodoItem] {
        // Since 'todos' now ONLY contains items for the selected date (loaded from file),
        // we just return 'todos'.
        return todos
    }
    
    func addCategory(_ name: String) {
        if !savedCategories.contains(name) {
            savedCategories.append(name)
        }
    }
    
    func addBookToLibrary(_ book: BookInfo) {
        if !savedBooks.contains(where: { $0.id == book.id && $0.title == book.title }) {
            savedBooks.append(book)
        }
    }
    
    func updateBook(_ book: BookInfo) {
        if let index = savedBooks.firstIndex(where: { $0.id == book.id }) {
            savedBooks[index] = book
        }
    }
    
    func removeBookFromLibrary(_ book: BookInfo) {
        savedBooks.removeAll(where: { $0.id == book.id })
    }
    
    // MARK: - Category Management
    
    func renameCategory(from oldName: String, to newName: String) {
        guard !newName.isEmpty, oldName != newName else { return }
        
        // Update Saved Categories
        if let index = savedCategories.firstIndex(of: oldName) {
            savedCategories[index] = newName
        }
        
        // Update All Todos (Current & Saved)
        // Note: For a file-based app, updating "all past todos" is hard without opening every file.
        // For now, we update the *loaded* todos (current day) and maybe we can try to be smart about it later.
        // Or we accept that historical data might keep old category name (which is fine for logs).
        // But for "TodoItem" struct, it's just a string. 
        
        for i in 0..<todos.count {
            if todos[i].category == oldName {
                todos[i].category = newName
            }
        }
    }
    
    func deleteCategory(_ name: String) {
        savedCategories.removeAll(where: { $0 == name })
        
        // Optional: Clear category from tasks? Or leave them?
        // Let's leave them, or set to nil. 
        // Typically deletion means "don't suggest this anymore".
    }

    func addTodo(_ item: TodoItem) {
        todos.append(item)
        if let cat = item.category {
            addCategory(cat)
        }
        if let book = item.book {
            addBookToLibrary(book) // Auto-add used book to library
        }
    }
    
    // Legacy support
    func addTodo(title: String) {
        let newItem = TodoItem(title: title, date: selectedDate)
        todos.append(newItem)
    }
    
    func toggleCompletion(for item: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == item.id }) {
            todos[index].isCompleted.toggle()
        }
    }
    
    func updateTodo(_ item: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == item.id }) {
            todos[index] = item
        }
    }
    
    func addTime(to todoId: UUID, amount: TimeInterval) {
        // Recursive helper that returns true if the task was found (and updated) in this branch
        func updateRecursive(_ item: inout TodoItem) -> Bool {
            if item.id == todoId {
                item.timeSpent += amount
                return true
            }
            
            if item.subtasks != nil {
                for i in 0..<(item.subtasks!.count) {
                    if updateRecursive(&item.subtasks![i]) {
                        // Found in children, so add time to self (bubble up)
                        item.timeSpent += amount
                        return true
                    }
                }
            }
            return false
        }
        
        for i in 0..<todos.count {
            if updateRecursive(&todos[i]) {
                return 
            }
        }
    }
    
    func addSession(to todoId: UUID, session: WorkSession) {
        // We want to add the session to the *parent* task if the target is a subtask.
        // If the target is already a helper, add it there.
        
        // Helper to find parent or self
        func findAndAdd(_ item: inout TodoItem) -> Bool {
            // Case 1: Target is this item (Top Level)
            if item.id == todoId {
                if item.sessions == nil { item.sessions = [] }
                item.sessions?.append(session)
                return true
            }
            
            // Case 2: Target is a subtask of this item
            if item.subtasks != nil {
                for i in 0..<(item.subtasks!.count) {
                    if item.subtasks![i].id == todoId {
                        // Found subtask! Add session to PARENT (item)
                        // Prepend subtask title to note
                        let subTitle = item.subtasks![i].title
                        let originalNote = session.note ?? ""
                        // Format: [Subtask Title] Note...
                        let newNote = "[\(subTitle)] \(originalNote)".trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // We need to create a new WorkSession because 'let' properties
                        // Actually, I made 'rating' var, but others are let.
                        // Let's create a new struct.
                         let updatedSession = WorkSession(
                            id: session.id,
                            startTime: session.startTime,
                            endTime: session.endTime,
                            duration: session.duration,
                            note: newNote,
                            rating: session.rating
                        )
                        
                        if item.sessions == nil { item.sessions = [] }
                        item.sessions?.append(updatedSession)
                        return true
                    }
                    
                    // Case 3: Recursion (Grandchildren?) - Assuming depth 1 for now based on recent plan, 
                    // but let's handle recursion if we supported it.
                    // If we found it deep down, we should probably add it to the *immediate parent* of that subtask in the loop?
                    // Or the top-level parent? 
                    // User said "Subtasks inherit parent".
                    // Let's stick to immediate parent for now, but since we are inside 'findAndAdd', 
                    // if we recursive call findAndAdd(&subtasks[i]), it treats subtasks[i] as the parent.
                    // So yes, it bubbles to immediate parent.
                    if findAndAdd(&item.subtasks![i]) {
                        return true
                    }
                }
            }
            return false
        }
        
        for i in 0..<todos.count {
            if findAndAdd(&todos[i]) {
                return
            }
        }
    }
    
    // Batch update from Calendar Sync (Recursive with Rollup)
    func batchUpdateTime(_ timeMap: [UUID: TimeInterval]) {
        
        // Returns the total time for this item (including children)
        @discardableResult
        func updateRecursive(_ item: inout TodoItem) -> TimeInterval {
            // 1. Get direct time from map (if any events linked to this specific ID)
            let directTime = timeMap[item.id] ?? 0
            
            // 2. Sum up children time
            var childrenTime: TimeInterval = 0
            if item.subtasks != nil {
                for i in 0..<(item.subtasks!.count) {
                    childrenTime += updateRecursive(&item.subtasks![i])
                }
            }
            
            // 3. Update self
            // Note: If we have direct time, use it. But usually calendar events are linked to the specific task/subtask.
            // If this is a parent, its time is (Any direct events on parent) + (Sum of all subtasks).
            // However, 'timeMap' comes from CalendarManager, which calculates duration based on event titles/IDs.
            // If an event is linked to a subtask ID, timeMap[subID] has value.
            // If an event is linked to parent ID, timeMap[parentID] has value.
            // So Total = timeMap[id] + childrenSum.
            
            let total = directTime + childrenTime
            
            if item.timeSpent != total {
                item.timeSpent = total
            }
            
            return total
        }
        
        for i in 0..<todos.count {
            updateRecursive(&todos[i])
        }
    }
    
    func deleteTodo(at offsets: IndexSet) {
        // Since 'todos' only has current date's items, and deleteTodo is likely called from the List showing them:
        todos.remove(atOffsets: offsets)
    }
    
    // MARK: - Persistence
    
    private var iCloudDirectory: URL {
        if let url = syncURL {
             return url
        }
        
        // Fallback for non-sandboxed or default
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/PomodoroCalendar")
    }
    
    private var libraryURL: URL {
        return iCloudDirectory.appendingPathComponent("Library.json")
    }
    
    private func taskURL(for date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let tasksDir = iCloudDirectory.appendingPathComponent("Tasks")
        return tasksDir.appendingPathComponent("\(dateString).json")
    }
    
    func selectSyncFolder() {
        print("selectSyncFolder called. Preparing to show panel...")
        DispatchQueue.main.async {
            print("Dispatching to main thread...")
            NSApp.activate(ignoringOtherApps: true)
            
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = "Select Sync Folder"
            panel.message = "Choose a folder to sync your Pomodoro Calendar data."
            panel.treatsFilePackagesAsDirectories = false
            
            let result = panel.runModal()
            print("Panel closed. Result: \(result.rawValue)")
            
            if result == .OK {
                if let url = panel.url {
                    print("Selected sync path: \(url.path)")
                    
                    // Save Security Scoped Bookmark
                    do {
                        let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                        UserDefaults.standard.set(data, forKey: "syncFolderBookmark")
                        
                        // Start accessing
                        if url.startAccessingSecurityScopedResource() {
                            // Stop accessing old one if exists
                            self.syncURL?.stopAccessingSecurityScopedResource()
                            
                            self.syncURL = url
                            self.syncPath = url.path
                            
                            // Check data and load/save
                            let newLibURL = self.libraryURL
                            if FileManager.default.fileExists(atPath: newLibURL.path) {
                                print("Data found. Loading...")
                                self.load()
                            } else {
                                print("Empty. Saving...")
                                self.forceSync()
                            }
                        } else {
                            print("Failed to start accessing selected resource")
                        }
                    } catch {
                        print("Failed to create bookmark: \(error)")
                    }
                }
            } else {
                print("User cancelled.")
            }
        }
    }
    
    private func ensureDirectoryExists() {
        let fileManager = FileManager.default
        let tasksDir = iCloudDirectory.appendingPathComponent("Tasks")
        
        if !fileManager.fileExists(atPath: tasksDir.path) {
            do {
                try fileManager.createDirectory(at: tasksDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create directory: \(error)")
            }
        }
    }
    
    private func saveLibrary() {
        ensureDirectoryExists()
        let data = AppData(todos: [], categories: savedCategories, savedBooks: savedBooks) 
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: libraryURL)
        }
    }
    
    private func saveTodos() {
        ensureDirectoryExists()
        let data = AppData(todos: todos, categories: [], savedBooks: []) 
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: taskURL(for: selectedDate))
        }
    }
    
    private func load() {
        ensureDirectoryExists()
        
        // 1. Load Library
        if let data = try? Data(contentsOf: libraryURL),
           let decoded = try? JSONDecoder().decode(AppData.self, from: data) {
            self.savedCategories = decoded.categories
            self.savedBooks = decoded.savedBooks
        }
        
        // 2. Load Tasks for Today (Initial)
        loadTodos(for: selectedDate)
    }
    
    func loadTodos(for date: Date) {
        let url = taskURL(for: date)
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(AppData.self, from: data) {
            self.todos = decoded.todos
        } else {
            self.todos = []
        }
    }
    
    func forceSync() {
        if syncPath == nil {
            print("No sync path set. Prompting user...")
            selectSyncFolder()
            return
        }
        
        print("Forcing sync to iCloud...")
        saveLibrary()
        saveTodos()
    }
}
