import SwiftUI

struct CategoryManagerView: View {
    @EnvironmentObject var todoManager: TodoManager
    @EnvironmentObject var calendarManager: CalendarManager
    @Environment(\.dismiss) var dismiss
    
    @State private var editingCategory: String?
    @State private var newName: String = ""
    @State private var eventTitleToDelete: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Manage Categories")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            List {
                ForEach(todoManager.savedCategories, id: \.self) { category in
                    HStack {
                        if editingCategory == category {
                            TextField("Category Name", text: $newName, onCommit: {
                                commitRename(oldName: category)
                            })
                            .textFieldStyle(.roundedBorder)
                            
                            Button(action: { commitRename(oldName: category) }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { cancelEdit() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(category)
                            Spacer()
                            
                            // Edit Button
                            Button(action: { startEditing(category) }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                            
                            // Delete Button
                            Button(action: { todoManager.deleteCategory(category) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Troubleshooting Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Delete Events by Title (Troubleshooting)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                HStack {
                    TextField("Title (e.g., 2장 공부하기)", text: $eventTitleToDelete)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Delete") {
                        calendarManager.deleteEvents(matching: eventTitleToDelete)
                        eventTitleToDelete = ""
                    }
                    .disabled(eventTitleToDelete.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .frame(width: 350, height: 450)
    }
    
    private func startEditing(_ category: String) {
        editingCategory = category
        newName = category
    }
    
    private func commitRename(oldName: String) {
        todoManager.renameCategory(from: oldName, to: newName)
        editingCategory = nil
        newName = ""
    }
    
    private func cancelEdit() {
        editingCategory = nil
        newName = ""
    }
}
