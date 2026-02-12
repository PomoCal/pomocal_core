import Foundation
import EventKit
import Combine

class CalendarManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []
    @Published var hasAccess = false
    
    // Publish changes so TodoManager can react
    let objectWillChange = ObservableObjectPublisher()


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
        
        // Listen for external changes (e.g. user deleting event in Calendar app)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeChanged),
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }
    
    @objc private func storeChanged() {
        print("Calendar store changed. Refreshing events...")
        fetchEvents()
        // Notify observers (like TodoManager) to recalculate time
        DispatchQueue.main.async {
            self.objectWillChange.send()
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

    func savePomodoroEvent(duration: TimeInterval, title: String, taskId: UUID? = nil, note: String? = nil) {
        guard hasAccess else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = Date().addingTimeInterval(-duration)
        event.endDate = Date()
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        if let id = taskId {
            event.url = URL(string: "pomocal://task/\(id.uuidString)")
        }
        
        if let note = note, !note.isEmpty {
            event.notes = note
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Saved Pomodoro event to calendar")
            fetchEvents() // Refresh list
        } catch {
            print("Failed to save event: \(error)")
        }
    }
    
    func deletePomodoroEvents(for title: String, on date: Date, taskId: UUID? = nil) {
        guard hasAccess else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let allEvents = eventStore.events(matching: predicate)
        
        // 1. Try deleting by Task ID (URL)
        var matchingEvents: [EKEvent] = []
        
        if let id = taskId {
            let idString = id.uuidString
            matchingEvents = allEvents.filter { event in
                return event.url?.absoluteString.contains(idString) == true
            }
        }
        
        // 2. Fallback: If no ID matches (legacy events), use Title matching
        if matchingEvents.isEmpty {
            matchingEvents = allEvents.filter { $0.title == title }
        }
        
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
    
    // Calculate total time spent per Task ID for a given date based on actual Calendar events
    // legacyTitles matches Title -> TaskID for events without URL
    func calculateTimeSpent(for date: Date, legacyTitles: [String: UUID] = [:]) -> [UUID: TimeInterval] {
        guard hasAccess else { return [:] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        var timeMap: [UUID: TimeInterval] = [:]
        
        for event in events {
            if let urlString = event.url?.absoluteString,
               urlString.starts(with: "pomocal://task/"),
               let idString = urlString.components(separatedBy: "/").last,
               let uuid = UUID(uuidString: idString) {
                
                let duration = event.endDate.timeIntervalSince(event.startDate)
                timeMap[uuid, default: 0] += duration
            } else if let title = event.title, let uuid = legacyTitles[title] {
                // Legacy fallback: Match by title if no URL
                let duration = event.endDate.timeIntervalSince(event.startDate)
                timeMap[uuid, default: 0] += duration
            }
        }
        
        return timeMap
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
