import SwiftUI
import AppKit

struct FlipClockView: View {
    let seconds: Int
    let showHours: Bool
    var fontSize: CGFloat = 60
    var color: Color = .primary
    
    var hours: Int { seconds / 3600 }
    var minutes: Int { (seconds % 3600) / 60 }
    var secs: Int { seconds % 60 }
    
    var body: some View {
        HStack(spacing: 8) {
            if showHours {
                FlipSection(value: hours, fontSize: fontSize, color: color)
                Separator(fontSize: fontSize)
            }
            FlipSection(value: minutes, fontSize: fontSize, color: color)
            Separator(fontSize: fontSize)
            FlipSection(value: secs, fontSize: fontSize, color: color)
        }
        .padding(12)
        .background(Color.black.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Components

private struct Separator: View {
    let fontSize: CGFloat
    var body: some View {
        Text(":")
            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
            .foregroundColor(.secondary.opacity(0.5))
            .offset(y: -fontSize * 0.05)
    }
}

private struct FlipSection: View {
    let value: Int
    let fontSize: CGFloat
    let color: Color
    
    var tens: Int { value / 10 }
    var ones: Int { value % 10 }
    
    var body: some View {
        HStack(spacing: 2) {
            FlipDigit(value: tens, fontSize: fontSize, color: color)
            FlipDigit(value: ones, fontSize: fontSize, color: color)
        }
    }
}

private struct FlipDigit: View {
    let value: Int
    let fontSize: CGFloat
    let color: Color
    
    @State private var currentValue: Int
    @State private var nextValue: Int
    @State private var rotation: Double = 0 // 0 to -180
    
    init(value: Int, fontSize: CGFloat, color: Color) {
        self.value = value
        self.fontSize = fontSize
        self.color = color
        self._currentValue = State(initialValue: value)
        self._nextValue = State(initialValue: value)
    }
    
    var body: some View {
        ZStack {
            // Static Background Layer
            VStack(spacing: 0) {
                // Top: Top Half of Next Value (Revealed when flap falls)
                HalfDigit(value: nextValue, fontSize: fontSize, color: color, type: .top)
                
                // Bottom: Bottom Half of Current Value (Covered when flap falls)
                HalfDigit(value: currentValue, fontSize: fontSize, color: color, type: .bottom)
            }
            
            // Animating Flap Layer
            // It sits on top of the Top Static Half and rotates down to cover Bottom Static Half.
            VStack(spacing: 0) {
                Flipper(current: currentValue, next: nextValue, fontSize: fontSize, color: color, rotation: rotation)
                // Spacer to fill the bottom half space so ZStack alignment works if needed, 
                // but since Flipper behaves as a Top Half anchored at bottom, we align Top.
                Spacer().frame(height: fontSize * 0.5)
            }
        }
        .onChange(of: value) { newValue in
            guard newValue != currentValue else { return }
            nextValue = newValue
            withAnimation(.easeInOut(duration: 0.6)) {
                rotation = -180
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                currentValue = nextValue
                rotation = 0
            }
        }
    }
}

private struct Flipper: View {
    let current: Int
    let next: Int
    let fontSize: CGFloat
    let color: Color
    let rotation: Double // 0 to -180
    
    var body: some View {
        ZStack {
            if rotation > -90 {
                // Front Side: Top Half of Current Value
                HalfDigit(value: current, fontSize: fontSize, color: color, type: .top)
            } else {
                // Back Side: Bottom Half of Next Value
                // Rotated 180 on X so it appears upright when the flipper is at -180.
                HalfDigit(value: next, fontSize: fontSize, color: color, type: .bottom)
                    .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
            }
        }
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 1, y: 0, z: 0),
            anchor: .bottom,
            perspective: 0.5
        )
        // No offset needed if we structure layout correctly.
        // It is a TopHalf view.
    }
}

private struct HalfDigit: View {
    let value: Int
    let fontSize: CGFloat
    let color: Color
    let type: HalfType
    
    enum HalfType { case top, bottom }
    
    var cardWidth: CGFloat { fontSize * 0.7 }
    var cardHeight: CGFloat { fontSize * 1.0 }
    var halfHeight: CGFloat { cardHeight * 0.5 }
    var cornerRadius: CGFloat = 6
    
    var body: some View {
        // We create a view of size (cardWidth x halfHeight)
        // that shows either the top or bottom half of the digit.
        
        ZStack {
            // Background Card
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(NSColor.controlBackgroundColor))
            
            // Text
            Text("\(value)")
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                // Offset the text to show the correct half
                .offset(y: type == .top ? halfHeight * 0.5 : -halfHeight * 0.5)
        }
        .frame(width: cardWidth, height: halfHeight)
        .clipped() // Clip content to the half-height frame
        .overlay(
            // Border / Stroke
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        // Divider line simulation
        .overlay(
            VStack {
                if type == .top {
                    Spacer()
                    Divider().background(Color.black.opacity(0.3))
                } else {
                    Divider().background(Color.black.opacity(0.3))
                    Spacer()
                }
            }
        )
    }
}
