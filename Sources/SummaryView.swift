import SwiftUI
import Charts

struct SummaryView: View {
    @EnvironmentObject var todoManager: TodoManager
    @State private var weeklyHistory: [TodoManager.DailyFocus] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Study Session Summary")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            if todoManager.todosForSelectedDate.isEmpty {
                 emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 30) {
                        totalTimeCard
                        weeklyChartSection
                        chartSection
                        taskListSection
                    }
                    .padding(.bottom)
                }
            }
        }
    .background(Color(NSColor.windowBackgroundColor))
    .onAppear { startWeeklyLoad() }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.3))
            Text("No activity recorded for this day.")
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private var totalTimeCard: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Total Study Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatTotalTime())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.indigo)
            }
            Spacer()
            Image(systemName: "hourglass")
                .font(.largeTitle)
                .foregroundColor(.indigo.opacity(0.2))
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func startWeeklyLoad() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = todoManager.getWeeklyFocusHistory()
            DispatchQueue.main.async {
                self.weeklyHistory = data
            }
        }
    }
    
    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Focus")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(weeklyHistory) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Hours", item.seconds / 3600)
                )
                .foregroundStyle(Color.indigo.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(), centered: true)
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            if todoManager.todosForSelectedDate.filter({ $0.timeSpent > 0 }).isEmpty {
                Text("No data to display")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                HStack(spacing: 40) {
                    // Pie Chart
                    PieChart(data: calculateCategoryData())
                        .frame(width: 200, height: 200)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(calculateCategoryData(), id: \.key) { category, time in
                            HStack {
                                Circle()
                                    .fill(color(for: category))
                                    .frame(width: 10, height: 10)
                                Text(category)
                                    .font(.caption)
                                Spacer()
                                Text(formatTime(time))
                                    .font(.caption2)
                                    .bold()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
    }
    
    // ... existing tasks list code ...

    // Helper to generate consistent colors
    private func color(for category: String) -> Color {
        // Simple hash-based color generation or predefined map
        let colors: [Color] = [.indigo, .purple, .blue, .cyan, .mint, .teal, .pink, .orange]
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
    
    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Task Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(todoManager.todosForSelectedDate.filter { $0.timeSpent > 0 }) { todo in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(todo.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text(formatTime(todo.timeSpent))
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .frame(width: geometry.size.width, height: 8)
                                .foregroundColor(Color.secondary.opacity(0.1))
                            
                            Capsule()
                                .frame(width: calculateWidth(total: totalTimeForDay(), current: todo.timeSpent, width: geometry.size.width), height: 8)
                                .foregroundColor(.indigo)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
            }
        }
    }
    
    // Derived Data for Chart
    private func calculateCategoryData() -> [(key: String, value: TimeInterval)] {
        var dict: [String: TimeInterval] = [:]
        for todo in todoManager.todosForSelectedDate {
            if todo.timeSpent > 0 {
                let cat = todo.category ?? "Uncategorized"
                dict[cat, default: 0] += todo.timeSpent
            }
        }
        return dict.sorted { $0.value > $1.value }
    }
    
    private func totalTimeForDay() -> TimeInterval {
        return todoManager.todosForSelectedDate.reduce(0) { $0 + $1.timeSpent }
    }
    
    private func formatTotalTime() -> String {
        let total = totalTimeForDay()
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        let seconds = Int(total) % 60
        return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        if hours > 0 {
             return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else {
             return String(format: "%02dm %02ds", minutes, seconds)
        }
    }
    
    private func calculateWidth(total: TimeInterval, current: TimeInterval, width: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(current / total) * width
    }
}

// MARK: - Custom Pie Chart
struct PieChart: View {
    let data: [(key: String, value: TimeInterval)]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let radius = min(width, height) / 2
            let center = CGPoint(x: width / 2, y: height / 2)
            
            let total = data.reduce(0) { $0 + $1.value }
            
            ZStack {
                ForEach(data, id: \.key) { item in
                    let angle = Angle(degrees: (item.value / total) * 360)
                    let start = startAngle(for: item, in: data, total: total)
                    let end = start + angle
                    
                    Path { path in
                        path.move(to: center)
                        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                    }
                    .fill(color(for: item.key))
                }
                
                // Donut Hole
                // CircularTimerView uses: lineWidth: 20
                // Here we want the "ring" to be about 20-25 thick.
                // If radius is the outer radius, inner radius should be radius - 20.
                Circle()
                    .fill(Color(NSColor.windowBackgroundColor))
                    .frame(width: (radius - 20) * 2, height: (radius - 20) * 2)
                
                // Total Text in Center
                VStack {
                    Text("Total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatTotalTime(total))
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
    }
    
    private func startAngle(for currentItem: (key: String, value: TimeInterval), in allData: [(key: String, value: TimeInterval)], total: TimeInterval) -> Angle {
        var angle = Angle(degrees: -90)
        for item in allData {
            if item.key == currentItem.key { break }
            angle += Angle(degrees: (item.value / total) * 360)
        }
        return angle
    }
    
    private func color(for category: String) -> Color {
        let colors: [Color] = [.indigo, .purple, .blue, .cyan, .mint, .teal, .pink, .orange]
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
    
    private func formatTotalTime(_ total: TimeInterval) -> String {
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%02dm", minutes)
        }
    }
}
