import SwiftUI

struct TimeEditSheet: View {
    @Binding var date: Date
    @Environment(\.dismiss) var dismiss
    @State private var tempDate: Date
    
    let quickPresets: [(String, TimeInterval)] = [
        ("Now", 0),
        ("15 min ago", -900),
        ("30 min ago", -1800),
        ("1 hour ago", -3600),
        ("2 hours ago", -7200),
        ("3 hours ago", -10800)
    ]
    
    init(date: Binding<Date>) {
        self._date = date
        self._tempDate = State(initialValue: date.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Title
            HStack {
                Text("Edit Time")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    date = tempDate
                    dismiss()
                }
                .font(.body.bold())
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Quick Presets
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Select")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(quickPresets, id: \.0) { preset in
                            QuickTimeButton(
                                title: preset.0,
                                action: {
                                    tempDate = Date().addingTimeInterval(preset.1)
                                    hapticFeedback()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Custom Time Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                DatePicker(
                    "Time",
                    selection: $tempDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding(.horizontal, 10)
                .onChange(of: tempDate) {
                    hapticFeedback()
                }
            }
            
            // Preview
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text(formatPreview(tempDate))
                    .font(.subheadline)
                Spacer()
                if abs(tempDate.timeIntervalSince(Date())) < 60 {
                    Text("Current time")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text(relativeTime(from: tempDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Spacer(minLength: 0)
        }
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.hidden)
    }
    
    private func formatPreview(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    private func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let absInterval = abs(interval)
        
        if absInterval < 3600 {
            let minutes = Int(absInterval / 60)
            return interval > 0 ? "\(minutes) min ago" : "in \(minutes) min"
        } else if absInterval < 86400 {
            let hours = Int(absInterval / 3600)
            return interval > 0 ? "\(hours) hour\(hours == 1 ? "" : "s") ago" : "in \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let days = Int(absInterval / 86400)
            return interval > 0 ? "\(days) day\(days == 1 ? "" : "s") ago" : "in \(days) day\(days == 1 ? "" : "s")"
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

struct QuickTimeButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(20)
        }
    }
}