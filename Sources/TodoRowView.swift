import SwiftUI
import EventKit

struct TodoRowView: View {
    let todo: TodoItem
    let level: Int
    @Binding var expandedTasks: Set<UUID>
    @Binding var selectedTask: TodoItem?
    @Binding var taskToEdit: TodoItem?
    @Binding var editingTaskId: UUID?
    
    // Actions
    var onToggleCompletion: (TodoItem) -> Void
    var onUpdate: (TodoItem) -> Void
    var onAddSubtask: (TodoItem) -> Void
    var onDelete: (TodoItem) -> Void
    var onSelectTask: (TodoItem) -> Void
    
    // Timer State for visual feedback
    var isTimerRunning: Bool
    var isTimerSelected: Bool
    
    // Local state for focus
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            // Indentation
            if level > 0 {
                Spacer()
                    .frame(width: CGFloat(level * 20))
            }
            
            // Expand/Collapse Chevron (only if subtasks exist)
            if let subtasks = todo.subtasks, !subtasks.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(expandedTasks.contains(todo.id) ? 90 : 0))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            if expandedTasks.contains(todo.id) {
                                expandedTasks.remove(todo.id)
                            } else {
                                expandedTasks.insert(todo.id)
                            }
                        }
                    }
                    .padding(.top, 6)
            } else {
                Spacer()
                    .frame(width: 12) // Placeholder alignment
            }
            
            // Completion Toggle
            Button(action: { onToggleCompletion(todo) }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                if editingTaskId == todo.id {
                    TextField("Task Title", text: Binding(
                        get: { todo.title },
                        set: { newValue in
                            var updated = todo
                            updated.title = newValue
                            onUpdate(updated)
                        }
                    ))
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isFocused)
                    .onSubmit {
                        editingTaskId = nil
                    }
                    .onAppear {
                        isFocused = true
                    }
                } else {
                    Text(todo.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(todo.isCompleted)
                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                }
                
                if let category = todo.category {
                    Text(category.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Time Spent Display
            if todo.timeSpent > 0 {
                Text(formatTime(todo.timeSpent))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Focus Button
            if isTimerSelected {
                Image(systemName: "timer")
                    .foregroundColor(.indigo)
                    .font(.title3)
            } else {
                Button(action: { onSelectTask(todo) }) {
                    Image(systemName: "play.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .contentShape(Rectangle()) // Make entire row clickable
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .onTapGesture(count: 2) { // Double tap to open detail
            if level == 0 && editingTaskId != todo.id {
                taskToEdit = todo
            }
        }
        .contextMenu {
            if level == 0 {
                Button {
                    onAddSubtask(todo)
                } label: {
                    Label("Add Subtask", systemImage: "plus.squares")
                }
            }
            
            Button {
                editingTaskId = todo.id
            } label: {
                Label("Rename", systemImage: "pencil.line")
            }
            
            Divider()
            
            if level == 0 {
                Button {
                    taskToEdit = todo
                } label: {
                    Label("Edit / Detail", systemImage: "pencil")
                }
            }
            
            Button(role: .destructive) {
                onDelete(todo)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        return "\(minutes)min"
    }
}
