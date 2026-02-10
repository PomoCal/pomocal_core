import Foundation
import EventKit

let store = EKEventStore()
let semaphore = DispatchSemaphore(value: 0)

print("Requesting Calendar Access...")

if #available(macOS 14.0, *) {
    store.requestFullAccessToEvents { granted, error in
        if granted {
            deleteEvents()
        } else {
            print("Access denied: \(String(describing: error))")
            semaphore.signal()
        }
    }
} else {
    store.requestAccess(to: .event) { granted, error in
        if granted {
            deleteEvents()
        } else {
            print("Access denied: \(String(describing: error))")
            semaphore.signal()
        }
    }
}

func deleteEvents() {
    let calendar = Calendar.current
    // Search in a wide range (e.g., last year to next year)
    let startDate = calendar.date(byAdding: .year, value: -1, to: Date())!
    let endDate = calendar.date(byAdding: .year, value: 1, to: Date())!
    
    let targetTitle = "2장 공부하기"
    print("Searching for events with title: '\(targetTitle)'...")
    
    let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
    let events = store.events(matching: predicate)
    
    let matchingEvents = events.filter { $0.title == targetTitle }
    
    if matchingEvents.isEmpty {
        print("No events found with that title.")
    } else {
        print("Found \(matchingEvents.count) events.")
        for event in matchingEvents {
            do {
                try store.remove(event, span: .thisEvent)
                print("Deleted: \(event.title ?? "") on \(event.startDate!)")
            } catch {
                print("Failed to delete event: \(error)")
            }
        }
        print("Deletion complete.")
    }
    semaphore.signal()
}

semaphore.wait()
