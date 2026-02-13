import SwiftUI

struct DDayView: View {
    @ObservedObject var manager: DDayManager
    @State private var showingAddSheet = false
    @State private var dDayToEdit: DDay?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("D-DAY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            if manager.dDays.isEmpty {
                Text("No D-Days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(manager.dDays) { dDay in
                    let days = manager.daysRemaining(to: dDay.date)
                    HStack {
                        VStack(alignment: .leading) {
                            Text(dDay.title)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(formatDate(dDay.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(formatDDay(days))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(colorForDDay(days))
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal)
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
        .padding(.bottom)
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
        if days == 0 { return .red }
        if days > 0 && days <= 7 { return .orange }
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
