import SwiftUI

struct EditTodoView: View {
    @EnvironmentObject var todoManager: TodoManager
    @Environment(\.dismiss) var dismiss
    
    let task: TodoItem
    
    @State private var title = ""
    @State private var selectedCategory = ""
    @State private var newCategory = ""
    @State private var isAddingCategory = false
    
    @State private var selectedBook: BookInfo?
    @State private var isBookSearchPresented = false
    
    // Structured Goal
    @State private var chapter = ""
    @State private var startPage = ""
    @State private var endPage = ""
    
    init(task: TodoItem) {
        self.task = task
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Task")
                .font(.title2)
                .fontWeight(.bold)
            
            // Basic Info
            VStack(alignment: .leading, spacing: 8) {
                Text("TITLE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                TextField("Task Title", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Category Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("CATEGORY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(todoManager.savedCategories, id: \.self) { cat in
                            Button(action: { selectedCategory = cat }) {
                                Text(cat)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == cat ? Color.accentColor : Color.gray.opacity(0.1))
                                    .foregroundColor(selectedCategory == cat ? .white : .primary)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button(action: { isAddingCategory.toggle() }) {
                            Image(systemName: "plus")
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $isAddingCategory) {
                            HStack {
                                TextField("New Category", text: $newCategory)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 120)
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
            }
            
            // Study Material (Book)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("STUDY MATERIAL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Change Book") {
                        isBookSearchPresented = true
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                }
                
                if let book = selectedBook {
                    HStack {
                        if let urlString = book.thumbnailURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                            } placeholder: { Color.gray }
                            .frame(width: 30, height: 45)
                            .cornerRadius(2)
                        }
                        VStack(alignment: .leading) {
                            Text(book.title).font(.body)
                            Text(book.authors.first ?? "").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: { selectedBook = nil }) {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                } else {
                    Button(action: { isBookSearchPresented = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Select Book")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $isBookSearchPresented) {
                 BookSearchView(selectedBook: $selectedBook)
                    .onDisappear {
                        if let book = selectedBook {
                            todoManager.addBookToLibrary(book)
                        }
                    }
            }
            
            // Goal Range
            VStack(alignment: .leading, spacing: 8) {
                Text("GOAL RANGE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Chapter")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("e.g. Ch 1", text: $chapter)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Pages")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("Start", text: $startPage)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                            Text("~")
                            TextField("End", text: $endPage)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save Changes") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 450, height: 600)
        .onAppear {
            populateFields()
        }
    }
    
    private func populateFields() {
        title = task.title
        selectedCategory = task.category ?? ""
        selectedBook = task.book
        
        if let goal = task.goalRange {
            // Very basic parsing attempt, or just put whole thing in chapter if complex
            // Format: "Ch 1 p.10 ~ p.20" or just "p.10 ~ p.20"
            // For simplicity, we might just clear structured fields if we can't parse perfectly, 
            // OR we just put the whole string into 'chapter' if it doesn't match our pattern.
            // But to be user friendly, let's just leave them blank if not simple, or user re-enters.
            // Actually, let's try to extract if it contains "p."
            // This is a UI improvement for later. For now, let's just set the raw string to chapter 
            // so user doesn't lose data, but they might need to re-format if they want split fields.
            // Better yet: Just put it in chapter field as a fallback.
            chapter = goal 
            // Refinement: If we want to be fancy, we'd regex it, but let's keep it simple.
        }
    }
    
    private func saveChanges() {
        // Construct goal string
        var goalParts: [String] = []
        
        // If the user didn't touch the page fields and chapter still has the old full string, 
        // we might duplicate "p.x ~ p.y". 
        // Let's assume if they use page fields, they want that format.
        
        // Simple logic:
        var newGoalString: String?
        
        let hasPages = !startPage.isEmpty || !endPage.isEmpty
        if hasPages {
            if !chapter.isEmpty { goalParts.append(chapter) }
            let start = startPage.isEmpty ? "?" : "p.\(startPage)"
            let end = endPage.isEmpty ? "?" : "p.\(endPage)"
            goalParts.append("\(start) ~ \(end)")
            newGoalString = goalParts.joined(separator: " ")
        } else {
            // Just use chapter field (which might contain the old full string)
            newGoalString = chapter.isEmpty ? nil : chapter
        }
        
        var updatedTask = task
        updatedTask.title = title
        updatedTask.category = selectedCategory.isEmpty ? nil : selectedCategory
        updatedTask.book = selectedBook
        updatedTask.goalRange = newGoalString
        
        todoManager.updateTodo(updatedTask)
        dismiss()
    }
}
