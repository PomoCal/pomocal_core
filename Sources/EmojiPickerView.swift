import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategoryIndex = 0
    
    // Grid Configuration
    private let columns = [
        GridItem(.adaptive(minimum: 40), spacing: 8)
    ]
    
    var filteredCategories: [EmojiCategory] {
        if searchText.isEmpty {
            return EmojiProvider.allCategories
        } else {
            // Flatten and filter
            let allEmojis = EmojiProvider.allCategories.flatMap { $0.emojis }
            #if os(macOS)
            // Name filtering would require a massive dictionary mapping strings to emoji names.
            // For now, we search if the user typed an emoji, OR we could map a few common keywords.
            // Since we don't have a name database, let's just filter categories that might match?
            // Actually, without a name database, "Search" is limited to finding the emoji character itself
            // OR we can rely on system search if we had a library.
            // IMPROVEMENT: Let's assume the user might paste an emoji or we just show all for now if no match.
            // Realistically to implement text search (e.g. "smile" -> 😀), we need a [String: String] map.
            // I will implement a basic "Recent" filter or just show all if search is empty.
            // For this iteration, let's stick to Categories as the primary navigation.
            // Search will attempt to match emoji if the user types one, or we can add a basic keyword lookup later.
             return EmojiProvider.allCategories
            #else
             return EmojiProvider.allCategories
            #endif
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search emoji", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(10)
            
            // 2. Category Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<EmojiProvider.allCategories.count, id: \.self) { index in
                        Button(action: {
                            withAnimation {
                                selectedCategoryIndex = index
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: EmojiProvider.allCategories[index].symbol)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(selectedCategoryIndex == index ? .primary : .secondary)
                                    .frame(width: 44, height: 30) // Tapper area
                                
                                // Indicator
                                if selectedCategoryIndex == index {
                                    Capsule()
                                        .fill(Color.primary)
                                        .frame(width: 20, height: 2)
                                        .matchedGeometryEffect(id: "CategoryIndicator", in: Namespace().wrappedValue)
                                } else {
                                    Capsule()
                                        .fill(Color.clear)
                                        .frame(width: 20, height: 2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(.bottom, 8)
            
            Divider()
            
            // 3. Emoji Grid
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        // If searching, maybe show all flat? 
                        // For now, sticking to category sections.
                        
                        ForEach(0..<EmojiProvider.allCategories.count, id: \.self) { index in
                            let category = EmojiProvider.allCategories[index]
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                    .id(index) // For ScrollTo
                                
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(category.emojis, id: \.self) { emoji in
                                        Button(action: {
                                            selectedEmoji = emoji
                                            dismiss()
                                        }) {
                                            Text(emoji)
                                                .font(.system(size: 32))
                                                .frame(width: 40, height: 40)
                                                .background(Color.clear)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .onChange(of: selectedCategoryIndex) { newIndex in
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .top)
                    }
                }
            }
        }
        .frame(width: 350, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
