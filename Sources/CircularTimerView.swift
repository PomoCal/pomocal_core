import SwiftUI

struct CircularTimerView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Time Display / Editor
            if !timerManager.isRunning && timerManager.mode == .pomodoro {
                // Time Editor Mode
                HStack(spacing: 5) {
                    // Minutes
                    TimeComponentEditor(
                        value: Binding(
                            get: { Int(timerManager.timeRemaining) / 60 },
                            set: { minute in
                                let seconds = Int(timerManager.timeRemaining) % 60
                                let newTotal = TimeInterval(minute * 60 + seconds)
                                timerManager.updateTimeRemaining(newTotal)
                            }
                        ),
                        range: 0...99,
                        step: 1
                    )
                    
                    Text(":")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .offset(y: -8)
                        .foregroundColor(.secondary)
                    
                    // Seconds
                    TimeComponentEditor(
                        value: Binding(
                            get: { Int(timerManager.timeRemaining) % 60 },
                            set: { second in
                                let minutes = Int(timerManager.timeRemaining) / 60
                                let newTotal = TimeInterval(minutes * 60 + second)
                                timerManager.updateTimeRemaining(newTotal)
                            }
                        ),
                        range: 0...59,
                        step: 10
                    )
                }
            } else {
                // Display Mode (Running or Break)
                FlipClockView(
                    seconds: Int(timerManager.timeRemaining),
                    showHours: false,
                    fontSize: 100,
                    color: .primary
                )
            }
            
            Text(timerManager.isWorkMode ? "FOCUS" : "BREAK")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(6)
                .opacity(0.8)
        }
        .padding(40)
    }
}

// Helper Component for Time Editing
struct TimeComponentEditor: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                var newValue = value + step
                if newValue > range.upperBound { newValue = range.lowerBound } // Wrap around
                value = newValue
            }) {
                Image(systemName: "chevron.up")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1.0 : 0.0) // Show on hover
            
            TextField("", text: Binding(
                get: { String(format: "%02d", value) },
                set: { newValue in
                    if let intValue = Int(newValue) {
                         // Allow typing, clamp on commit or processing if needed, 
                         // but for live update let's clamp immediately
                         if intValue >= range.lowerBound && intValue <= range.upperBound {
                             value = intValue
                         } else if intValue > range.upperBound {
                             value = range.upperBound
                         }
                    }
                }
            ))
            .font(.system(size: 60, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .frame(width: 80, height: 70)

            Button(action: {
                var newValue = value - step
                if newValue < range.lowerBound { newValue = range.upperBound } // Wrap around
                value = newValue
            }) {
                Image(systemName: "chevron.down")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1.0 : 0.0)
        }
        .contentShape(Rectangle())
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hover
            }
        }
    }
}
