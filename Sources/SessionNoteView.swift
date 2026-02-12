import SwiftUI

struct SessionNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var note: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Note")
                .font(.headline)
            
            Text("Write down your thoughts, ideas, or what you learned during this session.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextEditor(text: $note)
                .font(.body)
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
