import SwiftUI

struct SettingsView: View {
    @ObservedObject var notificationManager: NotificationManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingResetConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Test Notifications")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("Send test notifications to verify everything is working")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            notificationManager.checkPermissionAndSendTest(type: "eating") { status in
                                if status == .denied {
                                    alertMessage = "Notifications are disabled! Go to Settings > Notifications > Health Tracker and enable them."
                                    showingAlert = true
                                } else if status == .notDetermined {
                                    notificationManager.requestPermission()
                                    alertMessage = "Please allow notifications and try again."
                                    showingAlert = true
                                } else {
                                    alertMessage = "Test eating notification sent! Minimize the app and check in 5 seconds."
                                    showingAlert = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "fork.knife")
                                Text("Test Eating")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            notificationManager.checkPermissionAndSendTest(type: "water") { status in
                                if status == .denied {
                                    alertMessage = "Notifications are disabled! Go to Settings > Notifications > Health Tracker and enable them."
                                    showingAlert = true
                                } else if status == .notDetermined {
                                    notificationManager.requestPermission()
                                    alertMessage = "Please allow notifications and try again."
                                    showingAlert = true
                                } else {
                                    alertMessage = "Test water notification sent! Minimize the app and check in 5 seconds."
                                    showingAlert = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "drop.fill")
                                Text("Test Water")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quiet Hours")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("Notifications won't be sent during these hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Quiet Starts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Picker("End Hour", selection: $notificationManager.endHour) {
                                    ForEach(0..<24) { hour in
                                        Text(formatHour(hour)).tag(hour)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Quiet Ends")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Picker("Start Hour", selection: $notificationManager.startHour) {
                                    ForEach(0..<24) { hour in
                                        Text(formatHour(hour)).tag(hour)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Quiet time: \(formatHour(notificationManager.endHour)) - \(formatHour(notificationManager.startHour))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Daily Reset")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("Clear all logs and start fresh for a new day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "sunrise.fill")
                            Text("Reset for New Day")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.indigo)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .confirmationDialog("Reset Daily Logs", isPresented: $showingResetConfirmation) {
                        Button("Reset All Logs", role: .destructive) {
                            notificationManager.resetForNextDay()
                            alertMessage = "All logs cleared! Starting fresh for the new day."
                            showingAlert = true
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will clear all eating and drinking logs for today. Notifications will be rescheduled from your start hour.")
                    }
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Troubleshooting")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notifications must be enabled in Settings", systemImage: "1.circle.fill")
                            .font(.caption)
                        Label("App must be in background to see notifications", systemImage: "2.circle.fill")
                            .font(.caption)
                        Label("Check that Focus/DND mode is off", systemImage: "3.circle.fill")
                            .font(.caption)
                        Label("Make sure phone is not on silent", systemImage: "4.circle.fill")
                            .font(.caption)
                    }
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open App Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(10)
                }
                
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Notification", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

#Preview {
    SettingsView(notificationManager: NotificationManager())
}