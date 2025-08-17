import SwiftUI

struct LogEntryRow: View {
    let entry: LogEntry
    let showRelated: Bool
    let relatedLogs: [LogEntry]
    
    init(entry: LogEntry, showRelated: Bool = true, relatedLogs: [LogEntry] = []) {
        self.entry = entry
        self.showRelated = showRelated
        self.relatedLogs = relatedLogs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Time
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 55, alignment: .trailing)
                
                // Icon
                Image(systemName: entry.type.icon)
                    .font(.title3)
                    .foregroundColor(Color(entry.type.color))
                    .frame(width: 25)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.type.rawValue)
                            .font(.headline)
                        
                        if entry.source == .voice {
                            Image(systemName: "mic.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if entry.type == .puke && !relatedLogs.isEmpty {
                            Text("• Related to meal")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if let notes = entry.notes {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 12) {
                        if let amount = entry.amount {
                            Label(amount, systemImage: "drop.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        if let severity = entry.severityText {
                            Label(severity, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(severityColor(entry.severity ?? 3))
                        }
                        
                        Text(entry.timeSince)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Show related logs if any
            if showRelated && !relatedLogs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(relatedLogs) { related in
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: related.type.icon)
                                .font(.caption)
                                .foregroundColor(Color(related.type.color))
                            
                            Text("\(related.type.rawValue) - \(related.timeSince)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 92)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 1, 2: return .yellow
        case 3: return .orange
        case 4, 5: return .red
        default: return .gray
        }
    }
}