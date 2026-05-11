import SwiftUI

// MARK: - Color Utilities

func stableHash(for string: String) -> Int {
    let hash = string.utf8.reduce(5381) {
        ($0 << 5) &+ $0 &+ Int($1)
    }
    return hash == Int.min ? Int.max : abs(hash)
}

func categoryColor(for category: String) -> Color {
    let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, 
        .purple, .pink, .teal, .indigo, .mint,
        .cyan, .brown
    ]
    return colors[stableHash(for: category) % colors.count]
}

// MARK: - Emoji Utilities

let appEmojis = [
    "📚", "📖", "📝", "💻", "💡", "🎯", "🔥", "🚀", "🎓", "🧠", "💼", "🔬", "🎨", "🎵", "🎹", "🏥",
    "🏃", "🧘", "🏋️", "🚴", "🍎", "🥗", "🍳", "☕", "🍺", "🍷", "🏠", "🛌", "🚿", "🧹", "🧺", "🛒",
    "🚗", "🚌", "✈️", "🗺️", "🏝️", "⛺", "📷", "🎥", "🎬", "🎮", "🎲", "🧩", "🧸", "🐶", "🐱", "🌿",
    "☀️", "🌧️", "❄️", "⚡", "🌈", "⭐", "🌙", "🌊", "🔥", "💧", "💨", "🌍", "🪐", "⚛️", "🦠", "🧬"
]

func randomEmoji(for string: String) -> String {
    appEmojis[stableHash(for: string) % appEmojis.count]
}
