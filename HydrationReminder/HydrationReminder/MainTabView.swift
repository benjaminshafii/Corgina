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
            ContentView()
                .environmentObject(notificationManager)
                .environmentObject(logsManager)
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