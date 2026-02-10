import SwiftUI

struct AddTodoView: View {
    @EnvironmentObject var todoManager: TodoManager
    @Environment(\.dismiss) var dismiss
    
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Study Session")
                .font(.title2)
                .fontWeight(.bold)
            
            // Basic Info
            VStack(alignment: .leading, spacing: 8) {
                Text("TITLE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                TextField("What are you studying?", text: $title)
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
                    Button("Manage Library") {
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
                    // Library Scroll
                    if !todoManager.savedBooks.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(todoManager.savedBooks, id: \.id) { book in
                                    Button(action: { selectedBook = book }) {
                                        VStack {
                                            if let urlString = book.thumbnailURL, let url = URL(string: urlString) {
                                                AsyncImage(url: url) { image in
                                                    image.resizable()
                                                } placeholder: { Color.gray.opacity(0.3) }
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 85)
                                                .cornerRadius(4)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.1))
                                                    .frame(width: 60, height: 85)
                                                    .cornerRadius(4)
                                            }
                                            Text(book.title)
                                                .font(.caption2)
                                                .lineLimit(1)
                                                .frame(width: 60)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Button(action: { isBookSearchPresented = true }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add to Library")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .sheet(isPresented: $isBookSearchPresented) {
                 BookSearchView(selectedBook: $selectedBook)
                    .onDisappear {
                        // Auto-add to library if selected from search
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
                
                Button("Add Task") {
                    addTask()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 450, height: 600)
    }
    
    private func addTask() {
        // Construct goal string
        var goalParts: [String] = []
        if !chapter.isEmpty { goalParts.append(chapter) }
        if !startPage.isEmpty || !endPage.isEmpty {
            let start = startPage.isEmpty ? "?" : "p.\(startPage)"
            let end = endPage.isEmpty ? "?" : "p.\(endPage)"
            goalParts.append("\(start) ~ \(end)")
        }
        let goalString = goalParts.isEmpty ? nil : goalParts.joined(separator: " ")
        
        let newItem = TodoItem(
            title: title,
            date: todoManager.selectedDate,
            category: selectedCategory.isEmpty ? nil : selectedCategory,
            book: selectedBook,
            goalRange: goalString
        )
        todoManager.addTodo(newItem)
        dismiss()
    }
}
