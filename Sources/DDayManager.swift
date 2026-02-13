import SwiftUI

struct DDay: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    
    init(id: UUID = UUID(), title: String, date: Date) {
        self.id = id
        self.title = title
        self.date = date
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
    
    func addDDay(title: String, date: Date) {
        let newDDay = DDay(title: title, date: date)
        dDays.append(newDDay)
        dDays.sort { $0.date < $1.date }
    }
    
    func updateDDay(_ dDay: DDay, title: String, date: Date) {
        if let index = dDays.firstIndex(where: { $0.id == dDay.id }) {
            dDays[index].title = title
            dDays[index].date = date
            dDays.sort { $0.date < $1.date }
        }
    }
    
    func deleteDDay(_ dDay: DDay) {
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
