import SwiftUI

// Extension to make BookInfo Identifiable for sheet item if not already (it is in TodoManager, but let's be sure)
// Actually BookInfo has 'id' but doesn't conform to Identifiable explicitly in the struct definition in LibraryView context if it's in another file.
// It was defined as: struct BookInfo: Codable, Equatable { let id: String ... }
// We need to add Identifiable to it in TodoManager or here.
// Since we can't easily edit TodoManager again just for that without viewing, let's assume it has 'id'.
// We need to add `updateBook` to TodoManager. Since I cannot edit TodoManager in this step (Sequential), I will do it in next step.


struct LibraryView: View {
    @EnvironmentObject var todoManager: TodoManager
    @State private var isSearchPresented = false
    @State private var newBook: BookInfo?
    @State private var selectedBookForDetail: BookInfo?
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("My Books")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: { isSearchPresented = true }) {
                        Label("Add Book", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                .padding(.top)
                
                if todoManager.savedBooks.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "books.vertical")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("No books saved yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Add books to easily select them when planning your study.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Find Books") { isSearchPresented = true }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(todoManager.savedBooks, id: \.id) { book in
                            VStack(alignment: .leading) {
                                if let urlString = book.thumbnailURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
                                    }
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 150)
                                    .cornerRadius(8)
                                    .shadow(radius: 2, y: 2)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(8)
                                        .overlay(Image(systemName: "book.closed").foregroundColor(.secondary))
                                }
                                
                                Text(book.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 4)
                                
                                Text(book.authors.first ?? "Unknown")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 100)
                            .onTapGesture {
                                selectedBookForDetail = book
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    todoManager.removeBookFromLibrary(book)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $isSearchPresented) {
            BookSearchView(selectedBook: $newBook)
        }
        .sheet(item: $selectedBookForDetail) { book in
            BookDetailView(book: book, todoManager: todoManager)
        }
        .onChange(of: newBook) { book in
            if let book = book {
                todoManager.addBookToLibrary(book)
                newBook = nil
                isSearchPresented = false
            }
        }
    }
}

struct BookDetailView: View {
    @State var book: BookInfo
    @ObservedObject var todoManager: TodoManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Book Details")
                .font(.headline)
                .padding(.top)
            
            if let urlString = book.thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .aspectRatio(contentMode: .fit)
                .frame(height: 150)
                .cornerRadius(8)
            }
            
            Text(book.title)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(book.authors.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
             
            VStack(alignment: .leading, spacing: 10) {
                Text("Study Goal Period")
                    .font(.headline)
                
                DatePicker("Start Date", selection: Binding(
                    get: { book.goalStartDate ?? Date() },
                    set: { book.goalStartDate = $0 }
                ), displayedComponents: .date)
                
                DatePicker("End Date", selection: Binding(
                    get: { book.goalEndDate ?? Date() },
                    set: { book.goalEndDate = $0 }
                ), displayedComponents: .date)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            Spacer()
            
            Button("Save") {
                todoManager.updateBook(book)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}
