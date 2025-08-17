import SwiftUI

struct MainTabView: View {
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var logsManager: LogsManager
    
    init() {
        let notificationManager = NotificationManager()
        _notificationManager = StateObject(wrappedValue: notificationManager)
        _logsManager = StateObject(wrappedValue: LogsManager(notificationManager: notificationManager))
    }
    
    var body: some View {
        TabView {
            ContentView(logsManager: logsManager)
                .environmentObject(notificationManager)
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
            
            LogLedgerView(logsManager: logsManager)
                .tabItem {
                    Label("Logs", systemImage: "list.clipboard")
                }
            
            VoiceLogsView()
                .environmentObject(logsManager)
                .tabItem {
                    Label("Voice", systemImage: "mic.fill")
                }
        }
    }
}