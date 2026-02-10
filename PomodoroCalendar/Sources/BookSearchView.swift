import SwiftUI

struct BookSearchView: View {
    @StateObject private var bookManager = BookAPIManager()
    @Binding var selectedBook: BookInfo?
    @Environment(\.dismiss) var dismiss
    @State private var query = ""
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search for books...", text: $query)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await bookManager.searchBooks(query: query)
                        }
                    }
                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding()
            
            // Results List
            if bookManager.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Searching...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                }
            } else if let error = bookManager.errorMessage {
                VStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            } else {
                List(bookManager.searchResults, id: \.id) { book in
                   Button(action: {
                        selectedBook = book
                        dismiss()
                    }) {
                        HStack(alignment: .top) {
                            if let urlString = book.thumbnailURL, let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 60)
                                .cornerRadius(4)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 60)
                                    .cornerRadius(4)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(book.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(book.authors.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}
