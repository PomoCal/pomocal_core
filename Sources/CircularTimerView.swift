import SwiftUI

struct CircularTimerView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // Ambient Glow
            if timerManager.mode == .pomodoro {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                timerManager.isWorkMode ? Color.red.opacity(0.2) : Color.teal.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 350
                        )
                    )
                    .frame(width: 700, height: 700)
                    .blur(radius: 50)
                    .animation(.easeInOut(duration: 2.0), value: timerManager.isWorkMode)
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 30) {
                // Time Display / Editor
                if !timerManager.isRunning && timerManager.mode == .pomodoro {
                    // Time Editor Mode
                    HStack(spacing: 10) {
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
                
                // Status Text
                Text(timerManager.isWorkMode ? "FOCUS" : "BREAK")
                    .font(.appTitle)
                    .fontWeight(.bold)
                    .foregroundColor(timerManager.isWorkMode ? .primary : .secondary)
                    .tracking(6)
                    .opacity(0.8)
                    .animation(.easeInOut, value: timerManager.isWorkMode)
            }
            .padding(40)
        }
    }
}

// Helper Component for Time Editing
struct TimeComponentEditor: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    
    var body: some View {
        VStack(spacing: 4) {
            // Up Button
            Button(action: {
                var newValue = value + step
                if newValue > range.upperBound { newValue = range.lowerBound }
                value = newValue
            }) {
                Image(systemName: "chevron.up")
                    .font(.title2.bold()) // Increased size for better clicking
                    .foregroundColor(.secondary)
                    .frame(height: 20) // Taller hit area
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Card Input
            ZStack {
                // Background Card
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                // Sidebar / Split Line (Optional - keeping valid structure)
                 VStack {
                    Spacer()
                    Divider().background(Color.black.opacity(0.1))
                    Spacer()
                }
                
                // TextField
                TextField("", text: Binding(
                    get: { String(format: "%02d", value) },
                    set: { newValue in
                        if let intValue = Int(newValue) {
                             if intValue >= range.lowerBound && intValue <= range.upperBound {
                                 value = intValue
                             } else if intValue > range.upperBound {
                                 value = range.upperBound // Clamp
                             }
                        }
                    }
                ))
                .font(.system(size: 80, weight: .bold, design: .monospaced)) // Resize to 80
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .foregroundColor(.black)
            }
            .frame(width: 176, height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // Down Button
            Button(action: {
                var newValue = value - step
                if newValue < range.lowerBound { newValue = range.upperBound }
                value = newValue
            }) {
                Image(systemName: "chevron.down")
                    .font(.title2.bold()) // Increased size
                    .foregroundColor(.secondary)
                    .frame(height: 20) // Taller hit area
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}
