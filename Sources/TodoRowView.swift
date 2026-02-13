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
    
    // Local state for focus and hover
    @FocusState private var isFocused: Bool
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .center) {
            // Indentation
            if level > 0 {
                Spacer()
                    .frame(width: CGFloat(level * 24))
            }
            
            // Expand/Collapse Chevron (only if subtasks exist)
            if let subtasks = todo.subtasks, !subtasks.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .frame(width: 16, height: 16)
                    .padding(4)
                    .background(Color.secondary.opacity(isHovering ? 0.1 : 0))
                    .clipShape(Circle())
                    .rotationEffect(.degrees(expandedTasks.contains(todo.id) ? 90 : 0))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if expandedTasks.contains(todo.id) {
                                expandedTasks.remove(todo.id)
                            } else {
                                expandedTasks.insert(todo.id)
                            }
                        }
                    }
            } else {
                Spacer().frame(width: 24) // Placeholder alignment
            }
            
            // Completion Toggle (Animated Checkbox)
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.2)) {
                    onToggleCompletion(todo)
                }
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(todo.isCompleted ? .green : (isHovering ? .primary : .secondary))
                    .scaleEffect(todo.isCompleted ? 1.1 : 1.0)
            }
            .buttonStyle(.plain)
            
            // Task Content
            VStack(alignment: .leading, spacing: 4) {
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
                    .onSubmit { editingTaskId = nil }
                    .onAppear { isFocused = true }
                } else {
                    HStack(alignment: .center, spacing: 8) {
                        Text(todo.title)
                            .font(.body)
                            .fontWeight(todo.isCompleted ? .regular : .medium)
                            .strikethrough(todo.isCompleted)
                            .foregroundColor(todo.isCompleted ? .secondary : .primary)
                        
                        if let category = todo.category {
                            Text(category.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(categoryColor(for: category)))
                        }
                    }
                }
            }
            
            Spacer()
            
            // Right Side Controls (Time & Actions)
            HStack(spacing: 12) {
                // Time Spent Display
                if todo.timeSpent > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatTime(todo.timeSpent))
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.indigo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Focus Button (Visible on Hover or Selected)
                if isTimerSelected {
                    Image(systemName: "timer")
                        .foregroundColor(.indigo)
                        .font(.title3)
                        .scaleEffect(isTimerRunning ? 1.1 : 1.0)
                        .animation(isTimerRunning ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isTimerRunning)
                } else if isHovering {
                    Button(action: { onSelectTask(todo) }) {
                        Image(systemName: "play.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Start Focus Session")
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle()) // Make entire row clickable
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hover
            }
        }
        .onTapGesture(count: 2) { // Double tap to open detail
            if level == 0 && editingTaskId != todo.id {
                taskToEdit = todo
            }
        }
        .contextMenu {
            if level == 0 {
                Button { onAddSubtask(todo) } label: {
                    Label("Add Subtask", systemImage: "plus.squares")
                }
            }
            Button { editingTaskId = todo.id } label: {
                Label("Rename", systemImage: "pencil.line")
            }
            Divider()
            if level == 0 {
                Button { taskToEdit = todo } label: {
                    Label("Edit / Detail", systemImage: "pencil")
                }
            }
            Button(role: .destructive) { onDelete(todo) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        return "\(minutes)min"
    }
}
