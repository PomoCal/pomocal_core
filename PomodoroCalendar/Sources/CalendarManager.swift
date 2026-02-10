import Foundation
import EventKit
import Combine

class CalendarManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []
    @Published var hasAccess = false

    func requestAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.hasAccess = granted
                    if granted {
                        self.fetchEvents()
                    } else {
                        print("Access denied: \(String(describing: error))")
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.hasAccess = granted
                    if granted {
                        self.fetchEvents()
                    } else {
                        print("Access denied: \(String(describing: error))")
                    }
                }
            }
        }
    }
    
    init() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        if status == .notDetermined {
            print("Calendar access not determined. Requesting access...")
            requestAccess()
        }
        
        if #available(macOS 14.0, *) {
            self.hasAccess = (status == .authorized || status == .fullAccess)
        } else {
            self.hasAccess = (status == .authorized)
        }
        
        if self.hasAccess {
            fetchEvents()
        }
    }

    func fetchEvents(for date: Date = Date()) {
        guard hasAccess else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let loadedEvents = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async {
            self.events = loadedEvents.sorted { $0.startDate < $1.startDate }
        }
    }

    func savePomodoroEvent(duration: TimeInterval, title: String) {
        guard hasAccess else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = Date().addingTimeInterval(-duration)
        event.endDate = Date()
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Saved Pomodoro event to calendar")
            fetchEvents() // Refresh list
        } catch {
            print("Failed to save event: \(error)")
        }
    }
    
    func deletePomodoroEvents(for title: String, on date: Date) {
        guard hasAccess else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let matchingEvents = eventStore.events(matching: predicate).filter { $0.title == title }
        
        for event in matchingEvents {
            do {
                try eventStore.remove(event, span: .thisEvent)
                print("Deleted calendar event: \(title)")
            } catch {
                print("Failed to delete event: \(error)")
            }
        }
        
        fetchEvents() // Refresh
    }
    func deleteEvents(matching title: String) {
        guard hasAccess, !title.isEmpty else { return }
        
        let calendar = Calendar.current
        // Search range: +/- 2 years
        let startDate = calendar.date(byAdding: .year, value: -2, to: Date())!
        let endDate = calendar.date(byAdding: .year, value: 2, to: Date())!
        
        print("Searching for events with title '\(title)' from \(startDate) to \(endDate)")
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let matchingEvents = eventStore.events(matching: predicate).filter { $0.title == title }
        
        print("Found \(matchingEvents.count) events.")
        
        for event in matchingEvents {
            do {
                try eventStore.remove(event, span: .thisEvent)
                print("Deleted: \(event.title ?? "")")
            } catch {
                print("Failed to delete event: \(error)")
            }
        }
        
        fetchEvents()
    }
    
    func deleteEvent(_ event: EKEvent) {
        guard hasAccess else { return }
        do {
            try eventStore.remove(event, span: .thisEvent)
            print("Deleted event: \(event.title ?? "")")
            fetchEvents() // Refresh manually or rely on notification? Best to fetch.
        } catch {
            print("Failed to delete event: \(error)")
        }
    }
}
