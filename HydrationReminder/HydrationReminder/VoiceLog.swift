import Foundation

enum LogCategory: String, Codable, CaseIterable {
    case food = "Food"
    case symptoms = "Symptoms"
    
    var icon: String {
        switch self {
        case .food:
            return "fork.knife"
        case .symptoms:
            return "heart.text.square"
        }
    }
    
    var color: String {
        switch self {
        case .food:
            return "orange"
        case .symptoms:
            return "purple"
        }
    }
}

struct VoiceLog: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let category: LogCategory
    let fileName: String
    var transcription: String?
    var tags: [String]
    
    init(id: UUID = UUID(), date: Date = Date(), duration: TimeInterval, category: LogCategory, fileName: String) {
        self.id = id
        self.date = date
        self.duration = duration
        self.category = category
        self.fileName = fileName
        self.transcription = nil
        self.tags = []
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}