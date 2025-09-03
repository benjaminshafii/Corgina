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
    @State private var showVoiceSheet = false
    @State private var voiceActionConfirmation = false
    @State private var lastVoiceActions: [VoiceAction] = []
    @State private var isRecordingInline = false
    @State private var showTranscriptionToast = false
    @State private var transcriptionText = ""
    @State private var showActionToast = false
    @State private var actionText = ""
    
    private var todaysDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var todaysNutrition: (calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        // Combine nutrition from all sources
        var totalCalories = 0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0
        var totalFiber = 0.0
        
        // Add from photo logs
        let todaysPhotos = photoLogManager.getLogsForToday()
        for photo in todaysPhotos {
            if let analysis = photo.aiAnalysis {
                totalCalories += analysis.totalCalories ?? 0
                totalProtein += analysis.totalProtein ?? 0
                totalCarbs += analysis.totalCarbs ?? 0
                totalFat += analysis.totalFat ?? 0
                totalFiber += analysis.totalFiber ?? 0
            }
        }
        
        // Add from voice/manual logs with macros
        let todaysLogs = logsManager.getTodayLogs()
        for log in todaysLogs where log.type == .food {
            totalCalories += log.calories ?? 0
            totalProtein += Double(log.protein ?? 0)
            totalCarbs += Double(log.carbs ?? 0)
            totalFat += Double(log.fat ?? 0)
        }
        
        return (totalCalories, totalProtein, totalCarbs, totalFat, totalFiber)
    }
    
    private var todaysWaterIntake: Int {
        logsManager.getTodayWaterCount()
    }
    
    private var todaysFoodCount: Int {
        logsManager.getTodayFoodCount() + photoLogManager.getLogsForToday().count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        if voiceLogManager.isProcessingVoice {
                            voiceProcessingCard
                        }
                        
                        if !lastVoiceActions.isEmpty && voiceActionConfirmation {
                            voiceActionsCard
                        }
                        
                        hydrationCard
                        
                        foodCard
                        
                        nutritionSummaryCard
                        
                        if let summary = supplementManager.todaysSummary {
                            vitaminCard(summary)
                        }
                        
                        if let todaysScore = puqeManager.todaysScore {
                            puqeScoreCard(todaysScore)
                        }
                        
                        recentActivitySection
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
                .background(Color(.systemGroupedBackground))
                
                // Floating Voice Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        voiceActionButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 90)
                    }
                }
                
                // Toast overlays
                if showTranscriptionToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.white)
                            Text(transcriptionText)
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .padding(.bottom, 180)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(), value: showTranscriptionToast)
                }
                
                if showActionToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(actionText)
                                .foregroundColor(.white)
                                .lineLimit(3)
                        }
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .padding(.bottom, 180)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(), value: showActionToast)
                }
            }
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
        .sheet(isPresented: $showVoiceSheet) {
            VoiceCommandSheet(voiceLogManager: voiceLogManager, onDismiss: {
                showVoiceSheet = false
                if !voiceLogManager.detectedActions.isEmpty {
                    lastVoiceActions = voiceLogManager.detectedActions
                    voiceActionConfirmation = true
                    // Force refresh of logs
                    logsManager.objectWillChange.send()
                }
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("VoiceLogCreated"))) { _ in
            // Force UI refresh when voice log is created
            logsManager.objectWillChange.send()
        }
        .onAppear {
            // Configure VoiceLogManager with shared managers
            voiceLogManager.configure(logsManager: logsManager, supplementManager: supplementManager)
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
                    Text("\(todaysWaterIntake * 237) ml today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "drop.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 12) {
                ForEach([125, 250, 375, 500], id: \.self) { ml in
                    Button(action: {
                        logsManager.logWater(amount: ml, unit: "ml", source: .manual)
                    }) {
                        Text("\(ml)ml")
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
                logsManager.logWater(amount: 250, unit: "ml", source: .manual)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Quick Add 250ml")
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
                        LogEntryRow(entry: log, showRelated: false)
                    }
                }
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
    
    // MARK: - Voice UI Components
    
    private var voiceActionButton: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: isRecordingInline ? [Color.red, Color.orange] : [Color.blue, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 60, height: 60)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            Image(systemName: isRecordingInline ? "stop.fill" : "mic.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            if isRecordingInline {
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 3)
                    .frame(width: 70, height: 70)
                    .scaleEffect(isRecordingInline ? 1.2 : 1.0)
                    .opacity(isRecordingInline ? 0 : 1)
                    .animation(.easeOut(duration: 0.5).repeatForever(autoreverses: false), value: isRecordingInline)
            }
        }
        .scaleEffect(isRecordingInline ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRecordingInline)
        .onLongPressGesture(minimumDuration: 0.2, maximumDistance: .infinity) {
            // Long press started - start recording
            startInlineRecording()
        } onPressingChanged: { isPressing in
            if !isPressing && isRecordingInline {
                // Released - stop recording
                stopInlineRecording()
            }
        }
    }
    
    private var voiceProcessingCard: some View {
        VStack(spacing: 12) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Processing voice command...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if let transcript = voiceLogManager.lastTranscription {
                Text("\"\(transcript)\"")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var voiceActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Actions Completed")
                    .font(.headline)
                Spacer()
                Button(action: {
                    voiceActionConfirmation = false
                    lastVoiceActions = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            ForEach(lastVoiceActions, id: \.type) { action in
                HStack {
                    Image(systemName: actionIcon(for: action.type))
                        .foregroundColor(actionColor(for: action.type))
                        .frame(width: 20)
                    
                    Text(actionDescription(for: action))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if action.confidence > 0.8 {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    voiceActionConfirmation = false
                }
            }
        }
    }
    
    private func actionIcon(for type: VoiceAction.ActionType) -> String {
        switch type {
        case .logWater: return "drop.fill"
        case .logFood: return "fork.knife"
        case .logVitamin: return "pills.fill"
        case .logSymptom: return "heart.text.square"
        case .logPUQE: return "chart.line.uptrend.xyaxis"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private func actionColor(for type: VoiceAction.ActionType) -> Color {
        switch type {
        case .logWater: return .blue
        case .logFood: return .orange
        case .logVitamin: return .purple
        case .logSymptom: return .red
        case .logPUQE: return .pink
        case .unknown: return .gray
        }
    }
    
    private func actionDescription(for action: VoiceAction) -> String {
        switch action.type {
        case .logWater:
            if let amount = action.details.amount, let unit = action.details.unit {
                return "Logged \(amount) \(unit) of water"
            }
            return "Logged water intake"
        case .logFood:
            return "Logged: \(action.details.item ?? "food")"
        case .logVitamin:
            return "Logged: \(action.details.vitaminName ?? "vitamin")"
        case .logSymptom:
            return "Logged symptom: \(action.details.symptoms?.joined(separator: ", ") ?? "symptom")"
        case .logPUQE:
            return "Logged PUQE score"
        case .unknown:
            return "Unknown action"
        }
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
    
    // MARK: - Inline Voice Recording
    
    private func startInlineRecording() {
        isRecordingInline = true
        voiceLogManager.startRecording()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func stopInlineRecording() {
        isRecordingInline = false
        voiceLogManager.stopRecording()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show "Processing..." toast immediately
        transcriptionText = "Processing your voice command..."
        showTranscriptionToast = true
        
        // Monitor the processing completion
        Task {
            // Wait for transcription first
            var transcriptionAttempts = 0
            while transcriptionAttempts < 60 { // Max 6 seconds for transcription
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                if let transcription = voiceLogManager.lastTranscription {
                    await MainActor.run {
                        transcriptionText = transcription
                        showTranscriptionToast = true
                    }
                    
                    // Now wait for actions to be detected and executed
                    var actionAttempts = 0
                    while actionAttempts < 30 { // Max 3 more seconds for actions
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        
                        // Check if processing is complete
                        if !voiceLogManager.isProcessingVoice {
                            await MainActor.run {
                                // Hide transcription toast
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showTranscriptionToast = false
                                }
                                
                                // Show action results
                                if !voiceLogManager.detectedActions.isEmpty {
                                    // Actions were already executed by VoiceLogManager
                                    // Just show confirmation
                                    var actionSummary = ""
                                    for action in voiceLogManager.detectedActions {
                                        switch action.type {
                                        case .logFood:
                                            if let foodName = action.details.item {
                                                actionSummary += "✓ Added \(foodName) to food log\n"
                                            }
                                        case .logWater:
                                            if let amount = action.details.amount, let unit = action.details.unit {
                                                actionSummary += "✓ Logged \(amount)\(unit) of water\n"
                                            }
                                        case .logVitamin:
                                            if let vitaminName = action.details.item ?? action.details.vitaminName {
                                                actionSummary += "✓ Marked \(vitaminName) as taken\n"
                                            }
                                        case .logSymptom:
                                            if let symptoms = action.details.symptoms {
                                                actionSummary += "✓ Logged symptoms: \(symptoms.joined(separator: ", "))\n"
                                            }
                                        case .logPUQE:
                                            actionSummary += "✓ Logged PUQE score\n"
                                        case .unknown:
                                            actionSummary += "Unknown action\n"
                                        }
                                    }
                                    
                                    actionText = actionSummary.trimmingCharacters(in: .whitespacesAndNewlines)
                                    showActionToast = true
                                    
                                    // Clear actions and hide toast after showing
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        showActionToast = false
                                        voiceLogManager.detectedActions = []
                                        voiceLogManager.lastTranscription = nil
                                    }
                                } else {
                                    // No actions detected
                                    actionText = "No actions detected from your command"
                                    showActionToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showActionToast = false
                                    }
                                }
                            }
                            return
                        }
                        actionAttempts += 1
                    }
                    
                    // If we got transcription but timed out waiting for actions
                    await MainActor.run {
                        showTranscriptionToast = false
                        actionText = "Processing timed out"
                        showActionToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showActionToast = false
                        }
                    }
                    return
                }
                transcriptionAttempts += 1
            }
            
            // If we timed out on transcription
            await MainActor.run {
                transcriptionText = "Failed to process voice command"
                showTranscriptionToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showTranscriptionToast = false
                }
            }
        }
    }
    
    private func processDetectedActions() {
        let actions = voiceLogManager.detectedActions
        if actions.isEmpty { return }
        
        // Create action summary text
        var actionSummary = ""
        for action in actions {
            switch action.type {
            case .logFood:
                if let foodName = action.details.item {
                    actionSummary += "Adding \(foodName) to food log\n"
                }
            case .logWater:
                if let amount = action.details.amount, let unit = action.details.unit {
                    actionSummary += "Logging \(amount)\(unit) of water\n"
                }
            case .logVitamin:
                if let vitaminName = action.details.item {
                    actionSummary += "Marking \(vitaminName) as taken\n"
                }
            case .logSymptom:
                if let symptoms = action.details.symptoms {
                    actionSummary += "Logging symptoms: \(symptoms.joined(separator: ", "))\n"
                }
            case .logPUQE:
                actionSummary += "Logging PUQE score\n"
            case .unknown:
                actionSummary += "Unknown action\n"
            }
        }
        
        actionText = actionSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        showActionToast = true
        
        // Execute actions
        voiceLogManager.executeVoiceActions(actions)
        
        // Update UI
        lastVoiceActions = actions
        voiceActionConfirmation = false // Don't show confirmation card since we're using toasts
        
        // Hide action toast after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showActionToast = false
            voiceLogManager.detectedActions = []
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