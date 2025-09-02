import Foundation
import SwiftUI

class LogsManager: ObservableObject {
    @Published var logEntries: [LogEntry] = []
    @Published var todaysSummary: DailySummary?
    
    private let userDefaultsKey = "UnifiedLogEntries"
    private let notificationManager: NotificationManager
    
    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
        loadLogs()
        updateTodaysSummary()
    }
    
    // MARK: - Quick Logging Methods
    
    func logFood(notes: String? = nil, source: LogSource = .manual) {
        let entry = LogEntry(
            type: .food,
            source: source,
            notes: notes
        )
        addLog(entry)
        
        // Also update notification manager if from reminder
        if source == .reminder || source == .manual {
            notificationManager.logEating()
        }
    }
    
    func logWater(amount: Int? = nil, unit: String? = nil, notes: String? = nil, source: LogSource = .manual) {
        let amountText = amount != nil && unit != nil ? "\(amount!) \(unit!)" : nil
        let entry = LogEntry(
            type: .water,
            source: source,
            notes: notes,
            amount: amountText
        )
        addLog(entry)
        
        // Also update notification manager if from reminder
        if source == .reminder || source == .manual {
            notificationManager.logDrinking()
        }
    }
    
    func logDrink(amount: String? = nil, notes: String? = nil, source: LogSource = .manual) {
        let entry = LogEntry(
            type: .drink,
            source: source,
            notes: notes,
            amount: amount
        )
        addLog(entry)
        
        // Also update notification manager if from reminder
        if source == .reminder || source == .manual {
            notificationManager.logDrinking()
        }
    }
    
    func logPuke(severity: Int = 3, notes: String? = nil, relatedToLastMeal: Bool = false) {
        var relatedIds: [UUID] = []
        
        // If related to last meal, find the most recent food log
        if relatedToLastMeal {
            if let lastFoodLog = logEntries
                .filter({ $0.type == .food })
                .sorted(by: { $0.date > $1.date })
                .first {
                relatedIds.append(lastFoodLog.id)
            }
        }
        
        let entry = LogEntry(
            type: .puke,
            source: .quick,
            notes: notes,
            relatedLogIds: relatedIds,
            severity: severity
        )
        addLog(entry)
        
        // Send alert if multiple pukes in short time
        checkPukeFrequency()
    }
    
    func logSymptom(notes: String, severity: Int = 3, source: LogSource = .manual) {
        let entry = LogEntry(
            type: .symptom,
            source: source,
            notes: notes,
            severity: severity
        )
        addLog(entry)
    }
    
    // MARK: - Voice Log Integration
    
    func addVoiceLog(_ voiceLog: VoiceLog, type: LogType, notes: String? = nil) {
        let entry = LogEntry(
            type: type,
            source: .voice,
            notes: notes ?? "Voice log: \(voiceLog.formattedDuration)",
            voiceLogId: voiceLog.id
        )
        addLog(entry)
    }
    
    // MARK: - Data Management
    
    private func addLog(_ entry: LogEntry) {
        logEntries.insert(entry, at: 0)
        saveLogs()
        updateTodaysSummary()
    }
    
    func deleteLog(_ entry: LogEntry) {
        logEntries.removeAll { $0.id == entry.id }
        saveLogs()
        updateTodaysSummary()
    }
    
    func getRelatedLogs(for entry: LogEntry) -> [LogEntry] {
        return logEntries.filter { entry.relatedLogIds.contains($0.id) }
    }
    
    // MARK: - Filtering
    
    func filteredLogs(by type: LogType? = nil, date: Date? = nil) -> [LogEntry] {
        var filtered = logEntries
        
        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }
        
        if let date = date {
            let calendar = Calendar.current
            filtered = filtered.filter { 
                calendar.isDate($0.date, inSameDayAs: date)
            }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    func logsForToday() -> [LogEntry] {
        return filteredLogs(date: Date())
    }
    
    func logsForLastHours(_ hours: Int) -> [LogEntry] {
        let cutoffDate = Date().addingTimeInterval(-Double(hours * 3600))
        return logEntries.filter { $0.date >= cutoffDate }
    }
    
    func getTodayLogs() -> [LogEntry] {
        return logsForToday()
    }
    
    func getTodayWaterCount() -> Int {
        return logsForToday().filter { $0.type == .water || $0.type == .drink }.count
    }
    
    func getTodayFoodCount() -> Int {
        return logsForToday().filter { $0.type == .food }.count
    }
    
    // MARK: - Analytics
    
    private func updateTodaysSummary() {
        let todaysLogs = logsForToday()
        
        let foodCount = todaysLogs.filter { $0.type == .food }.count
        let drinkCount = todaysLogs.filter { $0.type == .drink }.count
        let pukeCount = todaysLogs.filter { $0.type == .puke }.count
        let symptomCount = todaysLogs.filter { $0.type == .symptom }.count
        
        // Calculate kept down percentage
        var keptDownPercentage: Double?
        if foodCount > 0 {
            let mealsKeptDown = foodCount - pukeCount
            keptDownPercentage = Double(max(0, mealsKeptDown)) / Double(foodCount) * 100
        }
        
        todaysSummary = DailySummary(
            date: Date(),
            foodCount: foodCount,
            drinkCount: drinkCount,
            pukeCount: pukeCount,
            symptomCount: symptomCount,
            totalFluidIntake: calculateTotalFluid(from: todaysLogs),
            keptDownPercentage: keptDownPercentage
        )
    }
    
    private func calculateTotalFluid(from logs: [LogEntry]) -> String? {
        let drinkLogs = logs.filter { $0.type == .drink }
        if drinkLogs.isEmpty { return nil }
        
        // Simple count for now, could parse amounts later
        return "\(drinkLogs.count) drinks"
    }
    
    private func checkPukeFrequency() {
        let recentPukes = logsForLastHours(3).filter { $0.type == .puke }
        if recentPukes.count >= 3 {
            // Could trigger an alert or notification
            print("Warning: \(recentPukes.count) vomiting episodes in last 3 hours")
        }
    }
    
    func getMostCommonSymptomTime() -> String? {
        let symptoms = logEntries.filter { $0.type == .symptom || $0.type == .puke }
        guard !symptoms.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let hourCounts = symptoms.reduce(into: [Int: Int]()) { counts, log in
            let hour = calendar.component(.hour, from: log.date)
            counts[hour, default: 0] += 1
        }
        
        if let mostCommonHour = hourCounts.max(by: { $0.value < $1.value })?.key {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            var components = DateComponents()
            components.hour = mostCommonHour
            if let date = calendar.date(from: components) {
                return formatter.string(from: date)
            }
        }
        
        return nil
    }
    
    // MARK: - Persistence
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logEntries) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) {
            logEntries = decoded
        }
    }
    
    // MARK: - Export
    
    func exportLogsAsText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        var export = "Health Logs Export\n"
        export += "Generated: \(Date())\n\n"
        
        let groupedByDate = Dictionary(grouping: logEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        
        for date in groupedByDate.keys.sorted(by: >) {
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .none
            export += "\n--- \(dateFormatter.string(from: date)) ---\n"
            
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            
            if let logs = groupedByDate[date] {
                for log in logs.sorted(by: { $0.date > $1.date }) {
                    export += "\(dateFormatter.string(from: log.date)) - \(log.type.rawValue)"
                    if let notes = log.notes {
                        export += ": \(notes)"
                    }
                    if let severity = log.severityText {
                        export += " (\(severity))"
                    }
                    if let amount = log.amount {
                        export += " - \(amount)"
                    }
                    export += "\n"
                }
            }
        }
        
        return export
    }
}