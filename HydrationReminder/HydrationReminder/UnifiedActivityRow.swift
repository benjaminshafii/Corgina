import SwiftUI

struct UnifiedActivityRow: View {
    let activity: UnifiedActivityEntry
    let isCompact: Bool
    let logsManager: LogsManager?
    let voiceLogManager: VoiceLogManager
    @State private var showingTimeEdit = false
    @State private var editableDate: Date
    
    init(activity: UnifiedActivityEntry, isCompact: Bool = false, logsManager: LogsManager? = nil, voiceLogManager: VoiceLogManager = VoiceLogManager.shared) {
        self.activity = activity
        self.isCompact = isCompact
        self.logsManager = logsManager
        self.voiceLogManager = voiceLogManager
        self._editableDate = State(initialValue: activity.date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: activity.category.icon)
                .font(.system(size: isCompact ? 16 : 20))
                .foregroundColor(Color(activity.category.color))
                .frame(width: isCompact ? 28 : 36, height: isCompact ? 28 : 36)
                .background(Color(activity.category.color).opacity(0.1))
                .cornerRadius(8)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(activity.title)
                        .font(isCompact ? .subheadline : .body)
                        .fontWeight(.medium)
                    
                    if activity.source == .voice {
                        Image(systemName: "mic.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        editableDate = activity.date
                        showingTimeEdit = true
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(formatTime(activity.date))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let subtitle = activity.subtitle, !isCompact {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Show nutrition info for food items
                if activity.category == .food, let nutrition = activity.nutrition {
                    HStack(spacing: 8) {
                        if let calories = nutrition.calories {
                            Label("\(calories)", systemImage: "flame.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        if let protein = nutrition.protein {
                            Text("\(Int(protein))g P")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        if let carbs = nutrition.carbs {
                            Text("\(Int(carbs))g C")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        if let fat = nutrition.fat {
                            Text("\(Int(fat))g F")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .padding(.vertical, isCompact ? 8 : 10)
        .padding(.horizontal, isCompact ? 12 : 16)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .sheet(isPresented: $showingTimeEdit) {
            TimeEditSheet(date: $editableDate)
                .onDisappear {
                    // Update the appropriate log when sheet is dismissed
                    if editableDate != activity.date {
                        updateActivityTime()
                    }
                }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: date)
    }
    
    private func updateActivityTime() {
        // Update the appropriate log based on the original entry type
        if let logEntry = activity.originalEntry as? LogEntry, let logsManager = logsManager {
            logsManager.updateLogTime(logEntry, newDate: editableDate)
        } else if let voiceLog = activity.originalEntry as? VoiceLog {
            if let index = voiceLogManager.voiceLogs.firstIndex(where: { $0.id == voiceLog.id }) {
                voiceLogManager.voiceLogs[index].date = editableDate
                voiceLogManager.saveLogs()
            }
        }
        // PhotoFoodLog time editing can be added similarly if needed
    }
}