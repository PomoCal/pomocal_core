import Foundation

struct NaverBookResult: Codable {
    let items: [NaverBookItem]?
}

struct NaverBookItem: Codable {
    let title: String
    let link: String
    let image: String?
    let author: String?
    let isbn: String?
}

class BookAPIManager: ObservableObject {
    @Published var searchResults: [BookInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let clientID = "fPTtFb61O9VCqkjBqW9U"
    private let clientSecret = "oaR0P4GPOD"
    
    func searchBooks(query: String) async {
        guard !query.isEmpty else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.searchResults = []
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openapi.naver.com/v1/search/book.json?query=\(encodedQuery)&display=10&start=1") else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Invalid query"
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(clientID, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        do {
            print("Searching Naver for: \(encodedQuery)")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "Naver API Error: \(httpResponse.statusCode)"
                    }
                    return
                }
            }
            
            let result = try JSONDecoder().decode(NaverBookResult.self, from: data)
            print("Found \(result.items?.count ?? 0) items")
            
            await MainActor.run {
                self.isLoading = false
                if let items = result.items, !items.isEmpty {
                    self.searchResults = items.map { item in
                        // Naver returns titles with HTML tags like <b>swift</b>, strip them
                        let cleanTitle = item.title.replacingOccurrences(of: "<b>", with: "").replacingOccurrences(of: "</b>", with: "")
                        let cleanAuthor = item.author?.replacingOccurrences(of: "<b>", with: "").replacingOccurrences(of: "</b>", with: "") ?? ""
                        
                        return BookInfo(
                            id: item.isbn ?? UUID().uuidString,
                            title: cleanTitle,
                            authors: [cleanAuthor], // Wrapper for compatibility
                            thumbnailURL: item.image
                        )
                    }
                } else {
                    self.errorMessage = "No results found"
                }
            }
        } catch {
            print("Book Search Error: \(error)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Connection failed: \(error.localizedDescription)"
            }
        }
    }
}
