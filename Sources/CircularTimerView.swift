import SwiftUI

struct CircularTimerView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.1)
                .foregroundColor(Color.primary)
            
            // Progress Ring with Glow and Gradient
            Circle()
                .trim(from: 0.0, to: CGFloat(min(timerManager.progress, 1.0)))
                .stroke(
                    timerManager.isWorkMode ? Color.focusGradient : Color.breakGradient,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(Angle(degrees: 270.0))
                .shadow(color: (timerManager.isWorkMode ? Color.indigo : Color.teal).opacity(0.6), radius: 15, x: 0, y: 0)
                .animation(.linear(duration: 1.0), value: timerManager.progress)
            
            // Time Text & Controls
            VStack(spacing: 10) {
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
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .offset(y: -4)
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
                    // Display Mode
                    Text(timerManager.formattedTime())
                        .font(.system(size: 70, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .animation(.default, value: timerManager.timeRemaining)
                }
                
                Text(timerManager.isWorkMode ? "FOCUS" : "BREAK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(4)
                    .opacity(0.8)
            }
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
