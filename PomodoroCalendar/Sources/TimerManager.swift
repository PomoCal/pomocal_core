import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var isRunning = false
    @Published var isWorkMode = true // true: Work, false: Break
    @Published var selectedTask: TodoItem?
    
    enum TimerMode {
        case pomodoro
        case stopwatch
    }
    
    @Published var mode: TimerMode = .pomodoro
    @Published var stopwatchSeconds: TimeInterval = 0
    
    // For syncing with Calendar. Passes (Duration, TaskTitle)
    var onWorkSessionCompleted: ((TimeInterval, String?) -> Void)?
    
    private var timer: Timer?
    private var workDuration: TimeInterval = 25 * 60
    private let breakDuration: TimeInterval = 5 * 60
    
    func setWorkDuration(minutes: Int) {
        pauseTimer()
        workDuration = TimeInterval(minutes * 60)
        if mode == .pomodoro && isWorkMode {
            timeRemaining = workDuration
        }
    }
    
    func setMode(_ newMode: TimerMode) {
        pauseTimer()
        mode = newMode
        if newMode == .pomodoro {
            timeRemaining = isWorkMode ? workDuration : breakDuration
        } else {
            stopwatchSeconds = 0
        }
    }
    
    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.mode == .pomodoro {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.completeSession()
                }
            } else {
                // Stopwatch
                self.stopwatchSeconds += 1
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        pauseTimer()
        if mode == .pomodoro {
            timeRemaining = isWorkMode ? workDuration : breakDuration
        } else {
            stopwatchSeconds = 0
        }
    }
    
    func switchMode() {
        guard mode == .pomodoro else { return }
        pauseTimer()
        isWorkMode.toggle()
        timeRemaining = isWorkMode ? workDuration : breakDuration
    }
    
    private func completeSession() {
        pauseTimer()
        
        if isWorkMode {
            // Notify to save to calendar
            let taskTitle = selectedTask?.title ?? "Pomodoro Session"
            onWorkSessionCompleted?(workDuration, taskTitle)
        }
        
        switchMode()
    }
    
    func skipBreak() {
        guard mode == .pomodoro && !isWorkMode else { return }
        // Skip break means we just switch mode back to Work without recording anything
        pauseTimer()
        switchMode() 
    }

    func updateTimeRemaining(_ newTime: TimeInterval) {
        pauseTimer()
        timeRemaining = newTime
        
        // Update workDuration to match this new time so that:
        // 1. Progress bar starts at 1.0 (timeRemaining / workDuration)
        // 2. Completed session records this specific duration
        if mode == .pomodoro && isWorkMode {
            workDuration = newTime
        }
    }
    
    func formattedTime() -> String {
        if mode == .pomodoro {
            let minutes = Int(timeRemaining) / 60
            let seconds = Int(timeRemaining) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            let hours = Int(stopwatchSeconds) / 3600
            let minutes = (Int(stopwatchSeconds) % 3600) / 60
            let seconds = Int(stopwatchSeconds) % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    var progress: Double {
        if mode == .pomodoro {
            let totalTime = isWorkMode ? workDuration : breakDuration
            return timeRemaining / totalTime
        } else {
             // Stopwatch
             return 0.0
        }
    }
}
