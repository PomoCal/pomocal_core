import SwiftUI

struct DDay: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    var eventIdentifier: String? // Linked Calendar Event ID
    
    init(id: UUID = UUID(), title: String, date: Date, eventIdentifier: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.eventIdentifier = eventIdentifier
    }
}

class DDayManager: ObservableObject {
    @Published var dDays: [DDay] = [] {
        didSet {
            save()
        }
    }
    
    private let storageKey = "SavedDDays"
    
    init() {
        load()
    }
    
    func addDDay(title: String, date: Date, calendarManager: CalendarManager) {
        let newId = UUID()
        // Save to Calendar First
        let eventId = calendarManager.saveDDayEventReturningId(title: title, date: date, dDayId: newId)
        
        let newDDay = DDay(id: newId, title: title, date: date, eventIdentifier: eventId)
        dDays.append(newDDay)
        dDays.sort { $0.date < $1.date }
    }
    
    func updateDDay(_ dDay: DDay, title: String, date: Date, calendarManager: CalendarManager) {
        if let index = dDays.firstIndex(where: { $0.id == dDay.id }) {
            // Delete old event if exists
            if let oldId = dDays[index].eventIdentifier {
                calendarManager.deleteEvent(identifier: oldId)
            }
            
            // Create new event to reflect changes (simplest way to update date/title)
            let newId = calendarManager.saveDDayEventReturningId(title: title, date: date, dDayId: dDay.id)
            
            dDays[index].title = title
            dDays[index].date = date
            dDays[index].eventIdentifier = newId
            dDays.sort { $0.date < $1.date }
        }
    }
    
    func deleteDDay(_ dDay: DDay, calendarManager: CalendarManager) {
        if let eventId = dDay.eventIdentifier {
            calendarManager.deleteEvent(identifier: eventId)
        }
        dDays.removeAll { $0.id == dDay.id }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(dDays) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DDay].self, from: data) {
            dDays = decoded.sorted { $0.date < $1.date }
        }
    }
    
    // Helper to calculate days remaining
    func daysRemaining(to date: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: date)
        
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget)
        return components.day ?? 0
    }
}
