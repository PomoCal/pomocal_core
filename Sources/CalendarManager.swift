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
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil) // nil means all calendars
        print("Fetching events for \(date) from all calendars.")
        let loadedEvents = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async {
            self.events = loadedEvents.sorted { $0.startDate < $1.startDate }
        }
    }

    func getOrCreatePomoCalCalendar() -> EKCalendar? {
        let kPomoCalID = "PomoCalCalendarID"
        
        // 1. Try to get via saved Identifier
        if let savedID = UserDefaults.standard.string(forKey: kPomoCalID),
           let calendar = eventStore.calendar(withIdentifier: savedID) {
            return calendar
        }
        
        // 2. Check if it already exists by Title (fallback)
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == "PomoCal" }) {
            // Save ID for next time
            UserDefaults.standard.set(existing.calendarIdentifier, forKey: kPomoCalID)
            return existing
        }
        
        // 3. Create new
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = "📆 PomoCal"
        
        // Set Source (Prefer iCloud, then Local)
        let sources = eventStore.sources
        if let iCloud = sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" }) {
            newCalendar.source = iCloud
        } else if let local = sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = local
        } else {
             newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
        }
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            print("Created PomoCal calendar.")
            // Save ID
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: kPomoCalID)
            return newCalendar
        } catch {
            print("Failed to create PomoCal calendar: \(error)")
            return nil
        }
    }

    func savePomodoroEvent(duration: TimeInterval, title: String, bookTitle: String? = nil, taskId: UUID? = nil, note: String? = nil) {
        guard hasAccess else { return }
        
        let event = EKEvent(eventStore: eventStore)
        
        // Title Format: [Book Name] Task Title
        // If no book name: Task Title
        if let book = bookTitle, !book.isEmpty {
            event.title = "[\(book)] \(title)"
        } else {
            event.title = title
        }
        
        event.startDate = Date().addingTimeInterval(-duration)
        event.endDate = Date()
        
        // Use Dedicated Calendar
        if let pomoCalendar = getOrCreatePomoCalCalendar() {
             event.calendar = pomoCalendar
        } else {
             event.calendar = eventStore.defaultCalendarForNewEvents
        }
        
        if let id = taskId {
            event.url = URL(string: "pomocal://task/\(id.uuidString)")
        }
        
        if let note = note, !note.isEmpty {
            event.notes = note
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Saved Pomodoro event to PomoCal calendar")
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
