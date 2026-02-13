import SwiftUI

extension Color {
    // Primary Backgrounds
    static let appBackground = Color("AppBackground")
    static let sidebarBackground = Color.softWhite
    static let cardBackground = Color("CardBackground")
    
    // Premium Palette
    static let deepNavy = Color(red: 0.05, green: 0.08, blue: 0.12)
    static let softWhite = Color(red: 251/255, green: 247/255, blue: 236/255) // #FBF7EC
    static let glassBackground = Material.regular
    
    // Gradients
    static let oceanicGradient = LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sunsetGradient = LinearGradient(
        gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.pink.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let focusGradient = AngularGradient(
        gradient: Gradient(colors: [.indigo, .purple, .blue, .indigo]),
        center: .center
    )
    
    static let breakGradient = AngularGradient(
        gradient: Gradient(colors: [.mint, .teal, .green, .mint]),
        center: .center
    )
}

extension View {
    func glassEffect() -> some View {
        self.background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
