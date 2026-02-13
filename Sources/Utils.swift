import SwiftUI

// MARK: - Color Utilities

func categoryColor(for category: String) -> Color {
    // String.hashValue is not stable across executions. Use a stable hash (DJB2).
    let hash = category.utf8.reduce(5381) {
        ($0 << 5) &+ $0 &+ Int($1)
    }
    let safeHash = abs(hash)
    
    let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, 
        .purple, .pink, .teal, .indigo, .mint,
        .cyan, .brown
    ]
    return colors[safeHash % colors.count]
}

// MARK: - Emoji Utilities

let appEmojis = [
    "📚", "📖", "📝", "💻", "💡", "🎯", "🔥", "🚀", "🎓", "🧠", "💼", "🔬", "🎨", "🎵", "🎹", "🏥",
    "🏃", "🧘", "🏋️", "🚴", "🍎", "🥗", "🍳", "☕", "🍺", "🍷", "🏠", "🛌", "🚿", "🧹", "🧺", "🛒",
    "🚗", "🚌", "✈️", "🗺️", "🏝️", "⛺", "📷", "🎥", "🎬", "🎮", "🎲", "🧩", "🧸", "🐶", "🐱", "🌿",
    "☀️", "🌧️", "❄️", "⚡", "🌈", "⭐", "🌙", "🌊", "🔥", "💧", "💨", "🌍", "🪐", "⚛️", "🦠", "🧬"
]

func randomEmoji(for string: String) -> String {
    let hash = abs(string.hashValue)
    return appEmojis[hash % appEmojis.count]
}
