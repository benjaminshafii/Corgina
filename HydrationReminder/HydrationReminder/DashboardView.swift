import SwiftUI
import PhotosUI

struct DashboardView: View {
    @StateObject private var photoLogManager = PhotoFoodLogManager()
    @StateObject private var voiceLogManager = VoiceLogManager()
    @StateObject private var supplementManager = SupplementManager()
    @StateObject private var puqeManager = PUQEManager()
    @EnvironmentObject var logsManager: LogsManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var showingCamera = false
    @State private var showingPhotoOptions = false
    @State private var showingVoiceRecording = false
    @State private var capturedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingAddNotes = false
    @State private var tempImageData: Data?
    @State private var notes = ""
    @State private var selectedMealType: MealType?
    @State private var selectedDate = Date()
    
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
                    
                    if let summary = supplementManager.todaysSummary {
                        vitaminCard(summary)
                    }
                    
                    if let todaysScore = puqeManager.todaysScore {
                        puqeScoreCard(todaysScore)
                    }
                    
                    hydrationCard
                    
                    foodCard
                    
                    recentActivitySection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $capturedImage)
                .onDisappear {
                    if let image = capturedImage,
                       let data = image.jpegData(compressionQuality: 0.8) {
                        tempImageData = data
                        showingAddNotes = true
                        capturedImage = nil
                    }
                }
        }
        .sheet(isPresented: $showingAddNotes) {
            AddNotesView(
                imageData: $tempImageData,
                notes: $notes,
                mealType: $selectedMealType,
                selectedDate: $selectedDate,
                onSave: savePhotoLog,
                onCancel: {
                    showingAddNotes = false
                    tempImageData = nil
                    notes = ""
                    selectedMealType = nil
                    selectedDate = Date()
                }
            )
        }
        .sheet(isPresented: $showingVoiceRecording) {
            VoiceRecordingView(manager: voiceLogManager)
        }
        .confirmationDialog("Add Food Photo", isPresented: $showingPhotoOptions) {
            Button("Take Photo") {
                showingCamera = true
            }
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Choose from Library")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("How would you like to add a food photo?")
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    tempImageData = data
                    showingAddNotes = true
                    selectedItem = nil
                }
            }
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
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hydration")
                        .font(.headline)
                    Text("\(todaysWaterIntake) glasses today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "drop.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 12) {
                ForEach([4, 8, 12, 16], id: \.self) { ounces in
                    Button(action: {
                        logsManager.logWater(amount: ounces, unit: "oz", source: .manual)
                    }) {
                        Text("\(ounces)oz")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
            }
            
            Button(action: {
                logsManager.logWater(amount: 8, unit: "oz", source: .manual)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Quick Add 8oz")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func vitaminCard(_ summary: SupplementManager.SupplementSummary) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vitamins & Supplements")
                        .font(.headline)
                    Text("\(summary.takenToday)/\(summary.totalSupplements) taken today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: Double(summary.takenToday) / Double(max(summary.totalSupplements, 1)),
                    lineWidth: 4
                )
                .frame(width: 40, height: 40)
            }
            
            if summary.missedToday > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(summary.missedToday) still needed")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
            
            NavigationLink(destination: SupplementTrackerView()) {
                HStack {
                    Image(systemName: "pills.fill")
                    Text("Manage Supplements")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func puqeScoreCard(_ score: PUQEScore) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PUQE Score")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text("\(score.totalScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(score.severity.color)
                        Text("(\(score.severity.rawValue))")
                            .font(.caption)
                            .foregroundColor(score.severity.color)
                    }
                }
                
                Spacer()
                
                if score.severity == .moderate || score.severity == .severe {
                    NavigationLink(destination: PUQEFoodSuggestionsView(puqeScore: score)) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                            Text("Get Suggestions")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                }
            }
            
            NavigationLink(destination: PUQEScoreView()) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Update PUQE Score")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(score.severity.color.opacity(0.2))
                .foregroundColor(score.severity.color)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var foodCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Food Intake")
                        .font(.headline)
                    Text("\(todaysFoodCount) meals today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "fork.knife")
                    .font(.title)
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    showingPhotoOptions = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Add Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingVoiceRecording = true
                }) {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("Voice Note")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            Button(action: {
                logsManager.logFood(notes: "Quick food log", source: .manual)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Quick Log Meal")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
    
    private func savePhotoLog() {
        if let data = tempImageData {
            photoLogManager.addPhotoLog(
                imageData: data,
                notes: notes,
                mealType: selectedMealType,
                date: selectedDate
            )
            
            logsManager.logFood(
                notes: notes.isEmpty ? "Photo logged" : notes,
                source: .manual
            )
            
            showingAddNotes = false
            tempImageData = nil
            notes = ""
            selectedMealType = nil
            selectedDate = Date()
        }
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