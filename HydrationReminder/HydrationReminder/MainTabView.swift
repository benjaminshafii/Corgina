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
            
            ContentView()
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
            
            PhotoFoodLogView()
                .tabItem {
                    Label("Food", systemImage: "camera.fill")
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