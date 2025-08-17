import SwiftUI

struct ContentView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var eatInterval: Double = 3
    @State private var drinkInterval: Double = 1
    @State private var eatingEnabled = false
    @State private var drinkingEnabled = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "fork.knife")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Eating Reminder")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Every")
                            TextField("Hours", value: $eatInterval, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 70)
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                            Text("hours")
                        }
                        
                        Toggle("Enable Eating Reminders", isOn: $eatingEnabled)
                            .onChange(of: eatingEnabled) { newValue in
                                if newValue {
                                    notificationManager.scheduleEatingNotification(hours: eatInterval)
                                } else {
                                    notificationManager.cancelEatingNotifications()
                                }
                            }
                    }
                    .padding(20)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(15)
                    
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Water Reminder")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Every")
                            TextField("Hours", value: $drinkInterval, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 70)
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                            Text("hours")
                        }
                        
                        Toggle("Enable Water Reminders", isOn: $drinkingEnabled)
                            .onChange(of: drinkingEnabled) { newValue in
                                if newValue {
                                    notificationManager.scheduleDrinkingNotification(hours: drinkInterval)
                                } else {
                                    notificationManager.cancelDrinkingNotifications()
                                }
                            }
                    }
                    .padding(20)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                    
                    Button(action: {
                        eatInterval = max(0.5, eatInterval)
                        drinkInterval = max(0.5, drinkInterval)
                        
                        if eatingEnabled {
                            notificationManager.scheduleEatingNotification(hours: eatInterval)
                        }
                        if drinkingEnabled {
                            notificationManager.scheduleDrinkingNotification(hours: drinkInterval)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Update Intervals")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    VStack(spacing: 15) {
                        Text("Quick Setup")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 15) {
                            Button("Meals: 4h") {
                                eatInterval = 4
                                if eatingEnabled {
                                    notificationManager.scheduleEatingNotification(hours: eatInterval)
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Water: 1h") {
                                drinkInterval = 1
                                if drinkingEnabled {
                                    notificationManager.scheduleDrinkingNotification(hours: drinkInterval)
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Water: 2h") {
                                drinkInterval = 2
                                if drinkingEnabled {
                                    notificationManager.scheduleDrinkingNotification(hours: drinkInterval)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(20)
            }
            .navigationTitle("Health Reminders")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                notificationManager.requestPermission()
            }
        }
    }
}

#Preview {
    ContentView()
}