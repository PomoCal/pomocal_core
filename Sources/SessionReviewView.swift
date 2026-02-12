import SwiftUI

struct SessionReviewView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    @State private var rating: Int = 0
    @State private var note: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Session Complete!")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            if let task = timerManager.selectedTask {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Star Rating
            VStack(spacing: 8) {
                Text("How was your focus?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= rating ? "star.fill" : "star")
                            .font(.title)
                            .foregroundColor(index <= rating ? .yellow : .gray.opacity(0.3))
                            .onTapGesture {
                                rating = index
                            }
                    }
                }
            }
            
            // Note
            VStack(alignment: .leading, spacing: 8) {
                Text("Session Note")
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
                    .frame(height: 100)
            }
            
            Spacer()
            
            Button(action: {
                timerManager.finalizeSession(rating: rating, note: note)
                dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(rating > 0 ? Color.indigo : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(rating == 0) // Require rating? Or optional. Let's make it optional but encourage it.
                                   // Actually, let's allow 0 rating (skipped) or default to 3? 
                                   // Let's allow Done even if 0, treating 0 as "No Rating".
            .disabled(false) 
        }
        .padding(30)
        .frame(width: 400, height: 450)
        .onAppear {
            self.note = timerManager.currentNote
        }
    }
}
