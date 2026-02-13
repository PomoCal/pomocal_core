import SwiftUI

// MARK: - Color Utilities

func categoryColor(for category: String) -> Color {
    let hash = abs(category.hashValue)
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .teal, .indigo, .mint]
    return colors[hash % colors.count]
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
