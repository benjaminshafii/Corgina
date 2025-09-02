import SwiftUI
import PhotosUI

struct DashboardView: View {
    @StateObject private var photoLogManager = PhotoFoodLogManager()
    @StateObject private var voiceLogManager = VoiceLogManager()
    @EnvironmentObject var logsManager: LogsManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var showingPhotoOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showingVoiceRecording = false
    @State private var showingFoodLog = false
    
    private var todaysDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var todaysNutrition: (calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        let todaysPhotos = photoLogManager.getLogsForToday()
        var totalCalories = 0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0
        var totalFiber = 0.0
        
        for photo in todaysPhotos {
            if let analysis = photo.aiAnalysis {
                totalCalories += analysis.totalCalories ?? 0
                totalProtein += analysis.totalProtein ?? 0
                totalCarbs += analysis.totalCarbs ?? 0
                totalFat += analysis.totalFat ?? 0
                totalFiber += analysis.totalFiber ?? 0
            }
        }
        
        return (totalCalories, totalProtein, totalCarbs, totalFat, totalFiber)
    }
    
    private var todaysWaterIntake: Int {
        logsManager.getTodayWaterCount()
    }
    
    private var todaysFoodCount: Int {
        logsManager.getTodayFoodCount()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    
                    nutritionSummaryCard
                    
                    hydrationCard
                    
                    quickActionsSection
                    
                    recentActivitySection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $capturedImage)
                .onDisappear {
                    if capturedImage != nil {
                        showingFoodLog = true
                    }
                }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Select Photo")
            }
            .onDisappear {
                if selectedItem != nil {
                    showingFoodLog = true
                }
            }
        }
        .sheet(isPresented: $showingVoiceRecording) {
            VoiceRecordingView(manager: voiceLogManager)
        }
        .sheet(isPresented: $showingFoodLog) {
            NavigationView {
                PhotoFoodLogView()
            }
        }
        .confirmationDialog("Add Food Photo", isPresented: $showingPhotoOptions) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingPhotoPicker = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("How would you like to add a food photo?")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Good \(getTimeOfDay())!")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(todaysDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var nutritionSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Today's Nutrition")
                    .font(.headline)
                Spacer()
                if todaysNutrition.calories > 0 {
                    Text("\(todaysNutrition.calories) cal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            if todaysNutrition.calories > 0 {
                HStack(spacing: 20) {
                    MacroView(
                        label: "Protein",
                        value: Int(todaysNutrition.protein),
                        unit: "g",
                        color: .red
                    )
                    
                    MacroView(
                        label: "Carbs",
                        value: Int(todaysNutrition.carbs),
                        unit: "g",
                        color: .blue
                    )
                    
                    MacroView(
                        label: "Fat",
                        value: Int(todaysNutrition.fat),
                        unit: "g",
                        color: .green
                    )
                    
                    MacroView(
                        label: "Fiber",
                        value: Int(todaysNutrition.fiber),
                        unit: "g",
                        color: .brown
                    )
                }
            } else {
                Text("No food logged yet today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var hydrationCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text("Hydration")
                        .font(.headline)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("\(todaysWaterIntake)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Water logs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack(alignment: .leading) {
                        Text("\(todaysFoodCount)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Food logs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                logsManager.logWater(amount: 8, unit: "oz", source: .manual)
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    icon: "camera.fill",
                    title: "Food Photo",
                    color: .purple,
                    action: {
                        showingPhotoOptions = true
                    }
                )
                
                QuickActionButton(
                    icon: "mic.fill",
                    title: "Voice Note",
                    color: .orange,
                    action: {
                        showingVoiceRecording = true
                    }
                )
                
                QuickActionButton(
                    icon: "drop.fill",
                    title: "Log Water",
                    color: .blue,
                    action: {
                        logsManager.logWater(amount: 8, unit: "oz", source: .manual)
                    }
                )
                
                QuickActionButton(
                    icon: "fork.knife",
                    title: "Log Food",
                    color: .green,
                    action: {
                        logsManager.logFood(notes: "Meal", source: .manual)
                    }
                )
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recentActivityHeader
            recentActivityContent
        }
    }
    
    private var recentActivityHeader: some View {
        HStack {
            Text("Recent Activity")
                .font(.headline)
            Spacer()
            NavigationLink(destination: LogLedgerView(logsManager: logsManager)) {
                Text("See All")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var recentActivityContent: some View {
        Group {
            if logsManager.getTodayLogs().isEmpty {
                Text("No activity yet today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(logsManager.getTodayLogs().prefix(5)) { log in
                        RecentActivityRow(log: log, formatTime: formatTime)
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        default:
            return "Evening"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RecentActivityRow: View {
    let log: LogEntry
    let formatTime: (Date) -> String
    
    var body: some View {
        HStack {
            Image(systemName: log.type == .water ? "drop.fill" : "fork.knife")
                .foregroundColor(log.type == .water ? .blue : .orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.type == .water ? "Water" : "Food")
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let notes = log.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(formatTime(log.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct MacroView: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(12)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VoiceRecordingView: View {
    @ObservedObject var manager: VoiceLogManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.orange)
                
                Text("Voice Recording")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Tap to start recording")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    let nm = NotificationManager()
    return DashboardView()
        .environmentObject(LogsManager(notificationManager: nm))
        .environmentObject(nm)
}