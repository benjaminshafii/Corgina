import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @ObservedObject var logsManager: LogsManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSettings = false
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    func timeSinceString(from date: Date?) -> String {
        guard let date = date else { return "Not logged today" }
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m ago"
        } else {
            return "\(minutes)m ago"
                            }
                        }
                        .padding(.horizontal)
                        
                        // Puke Log Button - Emergency Action
                        Button(action: {
                            logsManager.logPuke(
                                severity: 3,
                                notes: "Logged from main screen",
                                relatedToLastMeal: true
                            )
                            alertMessage = "Episode logged. Take care of yourself! 💙"
                            showingAlert = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Quick Log: Vomiting")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Tap to log episode (relates to last meal)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(spacing: 20) {
                        Text("Log Your Intake")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                logsManager.logFood(source: .manual)
                                alertMessage = "Meal logged! Next reminder in \(Int(notificationManager.eatingInterval)) hours"
                                showingAlert = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "fork.knife.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.orange)
                                    
                                    Text("Log Meal")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(timeSinceString(from: notificationManager.lastEatingTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(15)
                            }
                            
                            Button(action: {
                                logsManager.logDrink(source: .manual)
                                alertMessage = "Water intake logged! Next reminder in \(Int(notificationManager.drinkingInterval)) hours"
                                showingAlert = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "drop.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.blue)
                                    
                                    Text("Log Water")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(timeSinceString(from: notificationManager.lastDrinkingTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    VStack(spacing: 20) {
                        Text("Next Reminders")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            if notificationManager.eatingEnabled, let nextTime = notificationManager.nextEatingNotification {
                                VStack(spacing: 8) {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.orange)
                                    Text("Meal")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text(nextTime, formatter: timeFormatter)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            if notificationManager.drinkingEnabled, let nextTime = notificationManager.nextDrinkingNotification {
                                VStack(spacing: 8) {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.blue)
                                    Text("Water")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text(nextTime, formatter: timeFormatter)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        
                        if !notificationManager.eatingEnabled && !notificationManager.drinkingEnabled {
                            Text("No reminders active")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.purple)
                            Text("Start Hour: \(notificationManager.startHour):00")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $notificationManager.startHour) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .accentColor(.purple)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    VStack(spacing: 15) {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.orange)
                                Text("Meal Interval")
                                Spacer()
                                HStack {
                                    TextField("", value: $notificationManager.eatingInterval, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 50)
                                        .multilineTextAlignment(.center)
                                        .keyboardType(.decimalPad)
                                    Text("hours")
                                        .font(.subheadline)
                                }
                            }
                            
                            Toggle("Enable Reminders", isOn: Binding(
                                get: { notificationManager.eatingEnabled },
                                set: { newValue in
                                    if newValue {
                                        notificationManager.checkPermission { status in
                                            if status == .authorized || status == .provisional {
                                                notificationManager.enableEatingReminders()
                                            } else if status == .denied {
                                                alertMessage = "Please enable notifications in Settings"
                                                showingAlert = true
                                            } else {
                                                notificationManager.requestPermission()
                                                alertMessage = "Please allow notifications"
                                                showingAlert = true
                                            }
                                        }
                                    } else {
                                        notificationManager.disableEatingReminders()
                                    }
                                }
                            ))
                            .tint(.orange)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(12)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.blue)
                                Text("Water Interval")
                                Spacer()
                                HStack {
                                    TextField("", value: $notificationManager.drinkingInterval, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 50)
                                        .multilineTextAlignment(.center)
                                        .keyboardType(.decimalPad)
                                    Text("hours")
                                        .font(.subheadline)
                                }
                            }
                            
                            Toggle("Enable Reminders", isOn: Binding(
                                get: { notificationManager.drinkingEnabled },
                                set: { newValue in
                                    if newValue {
                                        notificationManager.checkPermission { status in
                                            if status == .authorized || status == .provisional {
                                                notificationManager.enableDrinkingReminders()
                                            } else if status == .denied {
                                                alertMessage = "Please enable notifications in Settings"
                                                showingAlert = true
                                            } else {
                                                notificationManager.requestPermission()
                                                alertMessage = "Please allow notifications"
                                                showingAlert = true
                                            }
                                        }
                                    } else {
                                        notificationManager.disableDrinkingReminders()
                                    }
                                }
                            ))
                            .tint(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    HStack(spacing: 15) {
                        Button("Quick: 4h Meals") {
                            notificationManager.eatingInterval = 4
                            if notificationManager.eatingEnabled {
                                notificationManager.rescheduleAllNotifications()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Quick: 1h Water") {
                            notificationManager.drinkingInterval = 1
                            if notificationManager.drinkingEnabled {
                                notificationManager.rescheduleAllNotifications()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Quick: 2h Water") {
                            notificationManager.drinkingInterval = 2
                            if notificationManager.drinkingEnabled {
                                notificationManager.rescheduleAllNotifications()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(20)
            }
            .navigationTitle("Health Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                notificationManager.requestPermission()
                // Clear badge when app opens if user has viewed pending logs
                if notificationManager.currentBadgeCount > 0 {
                    UNUserNotificationCenter.current().setBadgeCount(0)
                }
            }
            .alert("", isPresented: $showingAlert) {
                if alertMessage.contains("Settings") {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } else {
                    Button("OK", role: .cancel) { }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(notificationManager: notificationManager)
            }
        }
    }
}

#Preview {
    ContentView()
}