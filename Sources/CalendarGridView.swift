import SwiftUI
import AppKit

struct CalendarDay: Identifiable {
    let id: String
    let date: Date?
    let isCurrentMonth: Bool
}

struct CalendarGridView: View {
    @EnvironmentObject var todoManager: TodoManager
    @State private var monthOffset = 0
    
    // Grid configuration
    let daysInWeek = 7
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
// ...

    private var currentMonthDate: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
    
    private var daysInMonth: [CalendarDay] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentMonthDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonthDate)) else {
            return []
        }
        
        // Calculate padding for first week
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let paddingDays = firstWeekday - 1 // Sunday is 1
        
        var days: [CalendarDay] = []
        
        // Add padding
        for i in 0..<paddingDays {
            days.append(CalendarDay(id: "pad-\(i)", date: nil, isCurrentMonth: false))
        }
        
        // Add days
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                let id = calendar.startOfDay(for: date).description 
                days.append(CalendarDay(id: id, date: date, isCurrentMonth: true))
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack {
            // Header: Month/Year and navigation
            HStack {
                Button(action: { monthOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthFormatter.string(from: currentMonthDate))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { monthOffset += 1 }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            // Weekday Headers
            LazyVGrid(columns: columns) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
            
            // Days Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysInMonth) { day in
                    if let date = day.date {
                        DayCell(date: date, 
                                isSelected: Calendar.current.isDate(date, inSameDayAs: todoManager.selectedDate))
                            .onTapGesture {
                                todoManager.selectedDate = date
                            }
                    } else {
                        Text("") // Empty cell
                            .frame(height: 40)
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .frame(minWidth: 320)

    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.accentColor)
                    .opacity(0.2)
            }
            
            Text("\(Calendar.current.component(.day, from: date))")
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .accentColor : .primary)
                .frame(width: 30, height: 30)
                .overlay(
                    Calendar.current.isDateInToday(date) ? 
                        Circle().stroke(Color.red, lineWidth: 1) : nil
                )
        }
        .frame(height: 40)
    }
}
