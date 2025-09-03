import Foundation
import SwiftUI
import UserNotifications

class SupplementManager: ObservableObject {
    @Published var supplements: [Supplement] = []
    @Published var todaysSummary: SupplementSummary?
    
    private let userDefaultsKey = "SavedSupplements"
    private let notificationManager: NotificationManager
    
    struct SupplementSummary {
        let totalSupplements: Int
        let takenToday: Int
        let missedToday: Int
        let upcomingReminders: [Date]
        let complianceRate: Double
    }
    
    init(notificationManager: NotificationManager? = nil) {
        self.notificationManager = notificationManager ?? NotificationManager()
        loadSupplements()
        updateTodaysSummary()
        scheduleReminders()
    }
    
    func addSupplement(_ supplement: Supplement) {
        supplements.append(supplement)
        saveSupplements()
        scheduleReminders()
        updateTodaysSummary()
    }
    
    func updateSupplement(_ supplement: Supplement) {
        if let index = supplements.firstIndex(where: { $0.id == supplement.id }) {
            supplements[index] = supplement
            saveSupplements()
            scheduleReminders()
            updateTodaysSummary()
        }
    }
    
    func deleteSupplement(_ supplement: Supplement) {
        supplements.removeAll { $0.id == supplement.id }
        saveSupplements()
        cancelReminders(for: supplement)
        updateTodaysSummary()
    }
    
    func logIntake(supplementId: UUID, taken: Bool = true, notes: String? = nil) {
        guard let index = supplements.firstIndex(where: { $0.id == supplementId }) else { return }
        
        let record = Supplement.IntakeRecord(taken: taken, notes: notes)
        supplements[index].intakeHistory.append(record)
        saveSupplements()
        updateTodaysSummary()
        
        if taken && supplements[index].isEssential {
            NotificationCenter.default.post(
                name: Notification.Name("EssentialSupplementTaken"),
                object: nil,
                userInfo: ["supplement": supplements[index]]
            )
        }
    }
    
    func logIntakeByName(_ name: String, taken: Bool = true) {
        guard let supplement = supplements.first(where: { 
            $0.name.lowercased().contains(name.lowercased()) 
        }) else { return }
        
        logIntake(supplementId: supplement.id, taken: taken)
    }
    
    func getTodaysIntake() -> [(supplement: Supplement, taken: Bool, timesNeeded: Int)] {
        var result: [(Supplement, Bool, Int)] = []
        
        for supplement in supplements {
            let timesNeeded = supplement.frequency.timesPerDay
            let timesTaken = supplement.todaysTaken()
            let taken = timesNeeded > 0 ? timesTaken >= timesNeeded : timesTaken > 0
            result.append((supplement, taken, timesNeeded))
        }
        
        return result
    }
    
    func getMissedSupplements() -> [Supplement] {
        supplements.filter { supplement in
            let needed = supplement.frequency.timesPerDay
            let taken = supplement.todaysTaken()
            return supplement.shouldTakeToday() && taken < needed
        }
    }
    
    func getUpcomingReminders() -> [(Supplement, Date)] {
        var reminders: [(Supplement, Date)] = []
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        
        for supplement in supplements where supplement.remindersEnabled {
            for reminderTime in supplement.reminderTimes {
                if reminderTime > now && reminderTime <= endOfDay {
                    reminders.append((supplement, reminderTime))
                }
            }
        }
        
        return reminders.sorted { $0.1 < $1.1 }
    }
    
    private func updateTodaysSummary() {
        let intake = getTodaysIntake()
        let taken = intake.filter { $0.taken }.count
        let total = intake.count
        let missed = intake.filter { !$0.taken && $0.supplement.shouldTakeToday() }.count
        
        let overallCompliance = supplements.isEmpty ? 0.0 : 
            supplements.map { $0.complianceRate(days: 7) }.reduce(0, +) / Double(supplements.count)
        
        todaysSummary = SupplementSummary(
            totalSupplements: total,
            takenToday: taken,
            missedToday: missed,
            upcomingReminders: getUpcomingReminders().map { $0.1 },
            complianceRate: overallCompliance
        )
    }
    
    private func scheduleReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for supplement in supplements where supplement.remindersEnabled {
            for reminderTime in supplement.reminderTimes {
                scheduleReminder(for: supplement, at: reminderTime)
            }
        }
    }
    
    private func scheduleReminder(for supplement: Supplement, at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for \(supplement.name)"
        content.body = "Remember to take your \(supplement.dosage) of \(supplement.name)"
        content.sound = .default
        content.categoryIdentifier = "SUPPLEMENT_REMINDER"
        content.userInfo = ["supplementId": supplement.id.uuidString]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "supplement_\(supplement.id.uuidString)_\(time.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling supplement reminder: \(error)")
            }
        }
    }
    
    private func cancelReminders(for supplement: Supplement) {
        let identifierPrefix = "supplement_\(supplement.id.uuidString)"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(identifierPrefix) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    func addFromTemplate(_ templateName: String) {
        if let template = PregnancySupplements.commonSupplements.first(where: { 
            $0.name.lowercased() == templateName.lowercased() 
        }) {
            var newSupplement = template
            newSupplement = Supplement(
                name: template.name,
                dosage: template.dosage,
                frequency: template.frequency,
                reminderTimes: [Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!],
                remindersEnabled: true,
                notes: template.notes,
                isEssential: template.isEssential
            )
            addSupplement(newSupplement)
        }
    }
    
    func checkInteractions(_ supplement: Supplement) -> [String] {
        var warnings: [String] = []
        
        if supplement.name.contains("Iron") {
            if supplements.contains(where: { $0.name.contains("Calcium") }) {
                warnings.append("Iron and Calcium can interfere with each other's absorption. Take at different times.")
            }
        }
        
        if supplement.name.contains("Vitamin D") {
            if supplements.contains(where: { $0.name.contains("Magnesium") }) {
                warnings.append("Vitamin D and Magnesium work well together for better absorption.")
            }
        }
        
        return warnings
    }
    
    private func saveSupplements() {
        if let encoded = try? JSONEncoder().encode(supplements) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadSupplements() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Supplement].self, from: data) {
            supplements = decoded
        }
    }
}