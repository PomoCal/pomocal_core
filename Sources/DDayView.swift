import SwiftUI

struct DDayView: View {
    @ObservedObject var manager: DDayManager
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var showingAddSheet = false
    @State private var dDayToEdit: DDay?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("D-Day")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingAddSheet = true }) {
                    Label("D-Day", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    if manager.dDays.isEmpty {
                        Text("No D-Days")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(manager.dDays) { dDay in
                            let days = manager.daysRemaining(to: dDay.date)
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dDay.title)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    Text(formatDate(dDay.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(formatDDay(days))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(colorForDDay(days))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                            .contextMenu {
                                Button("Edit") {
                                    dDayToEdit = dDay
                                }
                                Button("Delete", role: .destructive) {
                                    manager.deleteDDay(dDay, calendarManager: calendarManager)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showingAddSheet) {
            DDayEditView(manager: manager)
                .environmentObject(calendarManager)
        }
        .sheet(item: $dDayToEdit) { dDay in
            DDayEditView(manager: manager, dDayToEdit: dDay)
                .environmentObject(calendarManager)
        }
    }
    
    // ... (Helpers remain same)
    
    private func formatDDay(_ days: Int) -> String {
        if days == 0 { return "D-Day" }
        if days > 0 { return "D-\(days)" }
        return "D+\(abs(days))"
    }
    
    private func colorForDDay(_ days: Int) -> Color {
        // 0 to 7 days (Upcoming Week): Red
        if days >= 0 && days <= 7 { return .red }
        // 8 to 14 days (Upcoming 2 Weeks): Green
        if days > 7 && days <= 14 { return .green }
        // Otherwise: Default
        return .primary
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}

struct DDayEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager: DDayManager
    @EnvironmentObject var calendarManager: CalendarManager
    var dDayToEdit: DDay?
    
    @State private var title: String = ""
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDay: Int = Calendar.current.component(.day, from: Date())
    
    var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear...currentYear + 10)
    }
    
    var months: [Int] { Array(1...12) }
    
    var days: [Int] {
        let range = Calendar.current.range(of: .day, in: .month, for: dateFromSelection()) ?? 1..<32
        return Array(range)
    }
    
    private func dateFromSelection() -> Date {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay // This might be invalid temporarily if month changes, defaulting safe
        // Logic check: if day > range, clamp it?
        // Basic check handled by picker reconstruction, but safer to clamp logic:
        let calendar = Calendar.current
        var safeDay = selectedDay
        if let range = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth))!) {
            if safeDay > range.count { safeDay = range.count }
        }
        components.day = safeDay
        return calendar.date(from: components) ?? Date()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(dDayToEdit == nil ? "Add D-Day" : "Edit D-Day")
                .font(.headline)
            
            TextField("Title (e.g. Exam)", text: $title)
                .textFieldStyle(.roundedBorder)
            
            // Custom Wheel Picker (HStack of Menus)
            HStack(spacing: 12) {
                // Year
                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(format: "%d", year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                // Month
                Picker("Month", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { month in
                        Text(String(format: "%d월", month)).tag(month)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                // Day
                Picker("Day", selection: $selectedDay) {
                    ForEach(days, id: \.self) { day in
                        Text(String(format: "%d일", day)).tag(day)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Save") {
                    let date = dateFromSelection()
                    if let dDay = dDayToEdit {
                        manager.updateDDay(dDay, title: title, date: date, calendarManager: calendarManager)
                    } else {
                        manager.addDDay(title: title, date: date, calendarManager: calendarManager)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 350)
        .onAppear {
            if let dDay = dDayToEdit {
                title = dDay.title
                let components = Calendar.current.dateComponents([.year, .month, .day], from: dDay.date)
                selectedYear = components.year ?? selectedYear
                selectedMonth = components.month ?? selectedMonth
                selectedDay = components.day ?? selectedDay
            }
        }
    }
}
