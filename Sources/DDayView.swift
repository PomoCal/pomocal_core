import SwiftUI

struct DDayView: View {
    @ObservedObject var manager: DDayManager
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
                                    .font(.system(size: 24, weight: .bold, design: .rounded)) // Larger font
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
                                    manager.deleteDDay(dDay)
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
        }
        .sheet(item: $dDayToEdit) { dDay in
            DDayEditView(manager: manager, dDayToEdit: dDay)
        }
    }
    
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
    var dDayToEdit: DDay?
    
    @State private var title: String = ""
    @State private var date: Date = Date()
    
    var body: some View {
        VStack(spacing: 20) {
            Text(dDayToEdit == nil ? "Add D-Day" : "Edit D-Day")
                .font(.headline)
            
            TextField("Title (e.g. Exam)", text: $title)
                .textFieldStyle(.roundedBorder)
            
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Save") {
                    if let dDay = dDayToEdit {
                        manager.updateDDay(dDay, title: title, date: date)
                    } else {
                        manager.addDDay(title: title, date: date)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            if let dDay = dDayToEdit {
                title = dDay.title
                date = dDay.date
            }
        }
    }
}
