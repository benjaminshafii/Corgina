import SwiftUI
import UserNotifications

@main
struct PlanyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let notificationManager = NotificationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Update badge count when notification arrives
        let userInfo = notification.request.content.userInfo
        if let type = userInfo["type"] as? String {
            if type == "eating" {
                notificationManager.incrementEatingBadge()
            } else if type == "drinking" {
                notificationManager.incrementDrinkingBadge()
            }
        }
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification actions
        switch response.actionIdentifier {
        case "LOG_EATING":
            notificationManager.logEating()
        case "LOG_DRINKING":
            notificationManager.logDrinking()
        default:
            break
        }
        completionHandler()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Check and reset daily badge when app becomes active
        notificationManager.checkAndResetDailyBadge()
    }
}