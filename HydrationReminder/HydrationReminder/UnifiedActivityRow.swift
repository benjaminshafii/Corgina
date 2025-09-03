import SwiftUI

struct UnifiedActivityRow: View {
    let activity: UnifiedActivityEntry
    let isCompact: Bool
    
    init(activity: UnifiedActivityEntry, isCompact: Bool = false) {
        self.activity = activity
        self.isCompact = isCompact
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
                    
                    Text(formatTime(activity.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
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
}