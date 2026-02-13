import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var isRunning = false
    @Published var isWorkMode = true // true: Work, false: Break
    @Published var selectedTask: TodoItem?
    @Published var currentNote: String = "" // New: Note for the current session

    
    enum TimerMode {
        case pomodoro
        case stopwatch
    }
    
    @Published var mode: TimerMode = .pomodoro
    @Published var stopwatchSeconds: TimeInterval = 0
    
    @Published var showReviewSheet = false
    
    // For syncing with Calendar. Passes (Duration, TaskTitle, BookTitle, TaskID, Note, Rating)
    var onWorkSessionCompleted: ((TimeInterval, String?, String?, UUID?, String?, Int?) -> Void)?

    
    private var timer: Timer?
    private var workDuration: TimeInterval = 25 * 60
    private let breakDuration: TimeInterval = 5 * 60
    
    // ... existing setWorkDuration ...
    
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
            // Show Review Sheet
            // We do NOT call onWorkSessionCompleted here yet.
            // We wait for user to review.
            showReviewSheet = true
            
            // Clean up note if any was typed during session (it will be passed to finalize)
        } else {
            // Break is over, just switch back to work
            switchMode()
        }
    }
    
    func finishStopwatch() {
        guard mode == .stopwatch else { return }
        pauseTimer()
        if stopwatchSeconds > 0 {
            showReviewSheet = true
        }
    }
    
    func finalizeSession(rating: Int, note: String) {
        // Now we save
        let taskTitle = selectedTask?.title ?? (mode == .pomodoro ? "Pomodoro Session" : "Stopwatch Session")
        let bookTitle = selectedTask?.book?.title
        
        let duration = mode == .pomodoro ? workDuration : stopwatchSeconds
        
        // Use the note from the review, which might be the one typed during session + edits
        onWorkSessionCompleted?(duration, taskTitle, bookTitle, selectedTask?.id, note, rating)
        
        // Clear temp
        currentNote = ""
        showReviewSheet = false
        
        // Mode Specific Cleanup
        if mode == .pomodoro {
            switchMode() // Switch to Break/Work
        } else {
            stopwatchSeconds = 0 // Reset Stopwatch
        }
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
