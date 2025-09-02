import SwiftUI

struct MainTabView: View {
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var logsManager: LogsManager
    
    init() {
        let nm = NotificationManager()
        _notificationManager = StateObject(wrappedValue: nm)
        _logsManager = StateObject(wrappedValue: LogsManager(notificationManager: nm))
    }
    
    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(notificationManager)
                .environmentObject(logsManager)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            ContentView()
                .environmentObject(notificationManager)
                .environmentObject(logsManager)
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
            
            PhotoFoodLogView()
                .environmentObject(logsManager)
                .tabItem {
                    Label("Food", systemImage: "camera.fill")
                }
            
            LogLedgerView(logsManager: logsManager)
                .tabItem {
                    Label("Logs", systemImage: "list.clipboard")
                }
            
            PUQEScoreView()
                .tabItem {
                    Label("PUQE", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
    }
}