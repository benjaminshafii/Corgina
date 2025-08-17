import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification permission granted")
            } else if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleEatingNotification(hours: Double) {
        cancelEatingNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Eat! 🍽️"
        content.body = "It's been \(formatHours(hours)). Time for a healthy meal!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "EATING_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: hours * 3600, repeats: true)
        
        let request = UNNotificationRequest(identifier: "eating_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling eating notification: \(error)")
            } else {
                print("Eating notification scheduled for every \(hours) hours")
            }
        }
    }
    
    func scheduleDrinkingNotification(hours: Double) {
        cancelDrinkingNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "Hydration Time! 💧"
        content.body = "It's been \(formatHours(hours)). Time to drink some water!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "DRINKING_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: hours * 3600, repeats: true)
        
        let request = UNNotificationRequest(identifier: "drinking_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling drinking notification: \(error)")
            } else {
                print("Drinking notification scheduled for every \(hours) hours")
            }
        }
    }
    
    func cancelEatingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["eating_reminder"])
        print("Eating notifications cancelled")
    }
    
    func cancelDrinkingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["drinking_reminder"])
        print("Drinking notifications cancelled")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All notifications cancelled")
    }
    
    private func formatHours(_ hours: Double) -> String {
        if hours == 1.0 {
            return "1 hour"
        } else if hours < 1.0 {
            let minutes = Int(hours * 60)
            return "\(minutes) minutes"
        } else if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(hours)) hours"
        } else {
            return String(format: "%.1f hours", hours)
        }
    }
}