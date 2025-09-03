import SwiftUI

struct MoreView: View {
    @EnvironmentObject var logsManager: LogsManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Health Tracking") {
                    NavigationLink(destination: SupplementTrackerView()) {
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundColor(.green)
                                .frame(width: 30)
                            Text("Vitamins & Supplements")
                            Spacer()
                        }
                    }
                    
                    NavigationLink(destination: LogLedgerView(logsManager: logsManager)) {
                        HStack {
                            Image(systemName: "list.clipboard")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Activity Logs")
                            Spacer()
                        }
                    }
                    
                    NavigationLink(destination: VoiceLogsView()) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            Text("Voice Recordings")
                            Spacer()
                        }
                    }
                }
                
                Section {
                    Button(action: { showingSettings = true }) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            Text("Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.green)
                                .frame(width: 30)
                            Text("About")
                            Spacer()
                        }
                    }
                    
                    Link(destination: URL(string: "mailto:support@pregnancytracker.app")!) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("More")
            .listStyle(InsetGroupedListStyle())
            .sheet(isPresented: $showingSettings) {
                SettingsView(notificationManager: notificationManager)
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)
            
            Text("Pregnancy Tracker")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Your comprehensive pregnancy health companion")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("Features:")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 5) {
                    FeatureRow(icon: "drop.fill", text: "Hydration tracking")
                    FeatureRow(icon: "fork.knife", text: "Food & nutrition logging")
                    FeatureRow(icon: "pills.fill", text: "Vitamin reminders")
                    FeatureRow(icon: "mic.fill", text: "Voice commands")
                    FeatureRow(icon: "camera.fill", text: "Photo food analysis")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "PUQE score tracking")
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}