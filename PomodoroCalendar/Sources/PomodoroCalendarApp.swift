import SwiftUI

@main
struct PomodoroCalendarApp: App {
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var timerManager = TimerManager()
    @StateObject private var todoManager = TodoManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarManager)
                .environmentObject(timerManager)
                .environmentObject(todoManager)
                .onAppear {
                    calendarManager.requestAccess()
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
