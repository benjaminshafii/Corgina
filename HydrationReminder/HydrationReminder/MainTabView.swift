import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var logsManager: LogsManager
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            LogLedgerView(logsManager: logsManager)
                .tabItem {
                    Label("Logs", systemImage: "list.clipboard")
                }
            
            PUQEScoreView()
                .tabItem {
                    Label("PUQE", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            MoreView()
                .environmentObject(logsManager)
                .environmentObject(notificationManager)
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
        }
    }
}