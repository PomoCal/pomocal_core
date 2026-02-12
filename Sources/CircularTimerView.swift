import SwiftUI

struct CircularTimerView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.1)
                .foregroundColor(Color.primary)
            
            // Progress Ring
            Circle()
                .trim(from: 0.0, to: CGFloat(min(timerManager.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .foregroundColor(timerManager.isWorkMode ? Color.indigo : Color.mint)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear(duration: 1.0), value: timerManager.progress)
            
            // Time Text & Controls
            VStack(spacing: 10) {
                if !timerManager.isRunning && timerManager.mode == .pomodoro {
                    // Time Editor Mode
                    HStack(spacing: 5) {
                        // Minutes
                        VStack(spacing: 5) {
                            Button(action: { adjustTime(minutes: 1) }) {
                                Image(systemName: "chevron.up")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            
                            TextField("", text: Binding(
                                get: { String(format: "%02d", Int(timerManager.timeRemaining) / 60) },
                                set: { newValue in
                                    if let minutes = Int(newValue), minutes >= 0 {
                                        let seconds = Int(timerManager.timeRemaining) % 60
                                        let newTotal = TimeInterval(minutes * 60 + seconds)
                                        timerManager.updateTimeRemaining(newTotal)
                                    }
                                }
                            ))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .frame(width: 80)
                            .minimumScaleFactor(0.5)
                            
                            Button(action: { adjustTime(minutes: -1) }) {
                                Image(systemName: "chevron.down")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text(":")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .offset(y: -5)
                        
                        // Seconds
                        VStack(spacing: 5) {
                            Button(action: { adjustTime(seconds: 10) }) {
                                Image(systemName: "chevron.up")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            
                            TextField("", text: Binding(
                                get: { String(format: "%02d", Int(timerManager.timeRemaining) % 60) },
                                set: { newValue in
                                    if let seconds = Int(newValue), seconds >= 0 && seconds < 60 {
                                        let minutes = Int(timerManager.timeRemaining) / 60
                                        let newTotal = TimeInterval(minutes * 60 + seconds)
                                        timerManager.updateTimeRemaining(newTotal)
                                    }
                                }
                            ))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .frame(width: 80)
                            .minimumScaleFactor(0.5)
                            
                            Button(action: { adjustTime(seconds: -10) }) {
                                Image(systemName: "chevron.down")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    // Display Mode
                    Text(timerManager.formattedTime())
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Text(timerManager.isWorkMode ? "FOCUS" : "BREAK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(2)
                

            }
        }
        .padding(40)
    }
    
    private func adjustTime(minutes: Int = 0, seconds: Int = 0) {
        let currentMinutes = Int(timerManager.timeRemaining) / 60
        let currentSeconds = Int(timerManager.timeRemaining) % 60
        
        var newMinutes = currentMinutes + minutes
        var newSeconds = currentSeconds + seconds
        
        // Handle overflow/underflow for seconds
        if newSeconds >= 60 {
            newSeconds -= 60
            newMinutes += 1
        } else if newSeconds < 0 {
            newSeconds += 60
            newMinutes -= 1
        }
        
        // Clamp and update
        if newMinutes < 0 { newMinutes = 0; newSeconds = 0 }
        
        let newTotal = TimeInterval(newMinutes * 60 + newSeconds)
        timerManager.updateTimeRemaining(newTotal)
    }
}
