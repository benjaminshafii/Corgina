import Foundation
import AVFoundation
import SwiftUI
import Combine

class VoiceLogManager: NSObject, ObservableObject, @unchecked Sendable {
    nonisolated static let shared = VoiceLogManager()

    enum ActionRecognitionState {
        case idle
        case recognizing
        case executing
        case completed
    }

    enum VoiceError: LocalizedError {
        case timeout
        case notConfigured
        case allActionsFailed
        case processingFailed(String)

        var errorDescription: String? {
            switch self {
            case .timeout: return "Operation timed out"
            case .notConfigured: return "Voice manager not configured"
            case .allActionsFailed: return "All actions failed to execute"
            case .processingFailed(let msg): return msg
            }
        }
    }

    @Published var actionRecognitionState: ActionRecognitionState = .idle
    @Published var refinedTranscription: String?
    @Published var executedActions: [VoiceAction] = []
    @Published var voiceLogs: [VoiceLog] = []
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentPlayingID: UUID?
    @Published var currentCategory: LogCategory = .food
    @Published var isProcessingVoice = false
    @Published var lastTranscription: String?
    @Published var detectedActions: [VoiceAction] = []
    @Published var showActionConfirmation = false

    @Published var onDeviceSpeechManager = OnDeviceSpeechManager()

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var currentRecordingURL: URL?

    private let userDefaultsKey = "SavedVoiceLogs"
    private var logsManager: LogsManager?
    private var supplementManager: SupplementManager?
    private var processingTimeoutTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var isConfigured: Bool {
        logsManager != nil && supplementManager != nil
    }

    override init() {
        super.init()
        loadLogs()
        setupAudioSession()
        setupSpeechObserver()
    }

    private func setupSpeechObserver() {
        // Forward changes from onDeviceSpeechManager to trigger view updates
        onDeviceSpeechManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func configure(logsManager: LogsManager, supplementManager: SupplementManager) {
        print("🔧 VoiceLogManager.configure() called")
        print("🔧 LogsManager: \(logsManager)")
        print("🔧 Current logs count: \(logsManager.logEntries.count)")
        self.logsManager = logsManager
        self.supplementManager = supplementManager
        print("🔧 Configuration complete")
    }
    
    @MainActor
    func clearExecutedActions() {
        executedActions = []
        actionRecognitionState = .idle
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    @MainActor
    func startRecording() {
        guard !isRecording else { return }
        
        print("🎤 Starting recording...")
        
        Task {
            let hasPermission = await onDeviceSpeechManager.requestPermission()
            print("🎤 Speech permission: \(hasPermission)")
            
            guard hasPermission else {
                print("⚠️ Recording cancelled - no permission")
                return
            }
            
            await MainActor.run {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
                self.currentRecordingURL = audioFilename
                
                do {
                    try self.onDeviceSpeechManager.startLiveTranscription(recordingURL: audioFilename)
                    self.isRecording = true
                    print("✅ Live transcription and recording started successfully")
                } catch {
                    print("❌ Failed to start live transcription: \(error)")
                }
            }
        }
    }
    
    @MainActor
    func stopRecording() {
        print("🎤🎤🎤 ============================================")
        print("🎤🎤🎤 STOP RECORDING CALLED")
        print("🎤🎤🎤 ============================================")

        guard isRecording else {
            print("⚠️ stopRecording called but not recording")
            return
        }

        print("🎤 Step 1: Calling onDeviceSpeechManager.stopLiveTranscription()")
        let result = onDeviceSpeechManager.stopLiveTranscription()
        print("🎤 Step 2: Setting isRecording = false")
        isRecording = false
        print("🎤 ✅ isRecording is now: \(isRecording)")

        print("🎤 Step 3: Got recording result")
        print("🎤 Live transcript: '\(result.transcript)'")
        print("🎤 Recording URL: \(result.recordingURL?.path ?? "nil")")

        // Validate we have audio data
        print("🎤 Step 4: Validating recording URL...")
        guard let url = result.recordingURL else {
            print("❌❌❌ ERROR: No recording URL available - ABORTING")
            lastTranscription = "Recording failed. Please try again."
            resetToIdle()
            return
        }
        print("🎤 ✅ Recording URL exists: \(url.path)")

        // Check if file exists
        print("🎤 Step 5: Checking if file exists on disk...")
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌❌❌ ERROR: Recording file doesn't exist at path: \(url.path) - ABORTING")
            lastTranscription = "Recording file not found. Please try again."
            resetToIdle()
            return
        }
        print("🎤 ✅ File exists on disk")

        // Check file size
        print("🎤 Step 6: Checking file size...")
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("🎤 ✅ Recording file size: \(fileSize) bytes")

            if fileSize < 1000 {
                print("⚠️ WARNING: Recording file is very small (\(fileSize) bytes)")
            }
        } catch {
            print("⚠️ WARNING: Could not get file attributes: \(error)")
        }

        // Get file duration
        print("🎤 Step 7: Getting file duration...")
        let asset = AVURLAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        print("🎤 ✅ Recording duration: \(duration) seconds")

        // Create voice log with the audio file
        print("🎤 Step 8: Creating voice log...")
        let voiceLog = VoiceLog(
            duration: duration,
            category: currentCategory,
            fileName: url.lastPathComponent
        )
        voiceLogs.append(voiceLog)
        saveLogs()
        print("🎤 ✅ Voice log created and saved")

        // ⚠️ CRITICAL: Set state to recognizing IMMEDIATELY to prevent drawer from disappearing
        // This must happen BEFORE the async processing starts
        print("🎤🎤🎤 ============================================")
        print("🎤🎤🎤 STEP 9: SETTING STATE TO PREVENT UI FLICKER")
        print("🎤🎤🎤 ============================================")
        print("🎤 BEFORE - isProcessingVoice: \(isProcessingVoice)")
        print("🎤 BEFORE - actionRecognitionState: \(actionRecognitionState)")

        isProcessingVoice = true
        actionRecognitionState = .recognizing

        print("🎤 AFTER - isProcessingVoice: \(isProcessingVoice)")
        print("🎤 AFTER - actionRecognitionState: \(actionRecognitionState)")
        print("🎤 ✅✅✅ State set to .recognizing - UI should stay visible!")

        print("🎤🎤🎤 ============================================")
        print("🎤🎤🎤 STEP 10: Starting OpenAI processing...")
        print("🎤🎤🎤 ============================================")

        // Process with OpenAI
        processRecordedAudio(at: url, for: voiceLog)
        print("🎤 ✅ processRecordedAudio() called (async processing started)")
    }
    
    private func processRecordedAudio(at url: URL, for log: VoiceLog) {
        print("🔄🔄🔄 ============================================")
        print("🔄🔄🔄 processRecordedAudio STARTED")
        print("🔄🔄🔄 URL: \(url.path)")
        print("🔄🔄🔄 ============================================")

        processingTimeoutTask?.cancel()

        print("🔄 Setting up 30-second timeout task...")
        processingTimeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await MainActor.run {
                if self.actionRecognitionState != .completed && self.actionRecognitionState != .idle {
                    print("⚠️⚠️⚠️ Processing timeout - resetting to idle")
                    self.resetToIdle()
                    self.lastTranscription = "Processing timed out. Please try again."
                }
            }
        }
        print("🔄 ✅ Timeout task created")

        print("🔄🔄🔄 ============================================")
        print("🔄🔄🔄 Creating detached Task for async processing")
        print("🔄🔄🔄 ============================================")

        Task.detached(priority: .userInitiated) {
            do {
                print("🔄 🚀 ASYNC TASK STARTED")

                print("📍📍📍 Step 1: Setting state to recognizing (redundant check)")
                await MainActor.run {
                    print("📍 MainActor - isProcessingVoice BEFORE: \(self.isProcessingVoice)")
                    print("📍 MainActor - actionRecognitionState BEFORE: \(self.actionRecognitionState)")
                    self.isProcessingVoice = true
                    self.actionRecognitionState = .recognizing
                    print("📍 MainActor - isProcessingVoice AFTER: \(self.isProcessingVoice)")
                    print("📍 MainActor - actionRecognitionState AFTER: \(self.actionRecognitionState)")
                }
                print("📍 ✅ State confirmed as .recognizing in async task")

                print("📍📍📍 Step 2: Loading audio data from file")
                print("📍 File path: \(url.path)")
                print("📍 File exists: \(FileManager.default.fileExists(atPath: url.path))")

                let audioData = try Data(contentsOf: url)
                print("✅✅✅ Audio data loaded: \(audioData.count) bytes")

                print("📍📍📍 Step 3: Calling OpenAI transcription API")
                print("📍 Starting API call with 15 second timeout...")
                let transcription = try await self.withTimeout(seconds: 15) {
                    try await OpenAIManager.shared.transcribeAudio(audioData: audioData)
                }
                print("✅✅✅ Transcription received: '\(transcription.text)'")

                print("📍📍📍 Step 3b: Saving transcription to state")
                await MainActor.run {
                    print("📍 Saving lastTranscription: '\(transcription.text)'")
                    self.lastTranscription = transcription.text
                    self.refinedTranscription = transcription.text

                    if let index = self.voiceLogs.firstIndex(where: { $0.id == log.id }) {
                        print("📍 Found voice log at index \(index), updating transcription")
                        self.voiceLogs[index].transcription = transcription.text
                        self.saveLogs()
                        print("📍 Voice log saved")
                    } else {
                        print("⚠️ WARNING: Could not find voice log with id \(log.id)")
                    }
                }
                print("✅✅✅ Transcription saved to state")

                print("⏳⏳⏳ Waiting 1.5s before action extraction...")
                try await Task.sleep(nanoseconds: 1_500_000_000)
                print("✅ Wait complete")

                print("📍📍📍 Step 4: Extracting actions from transcription")
                print("📍 Transcription text: '\(transcription.text)'")
                print("📍 Starting action extraction API call with 15 second timeout...")
                let actions = try await self.withTimeout(seconds: 15) {
                    try await OpenAIManager.shared.extractVoiceActions(from: transcription.text)
                }
                print("✅✅✅ Actions extracted: \(actions.count) actions")

                print("📍📍📍 Step 4b: Saving detected actions to state")
                await MainActor.run {
                    print("📱 Detected \(actions.count) actions from voice:")
                    for (index, action) in actions.enumerated() {
                        print("   Action \(index): type=\(action.type), item=\(action.details.item ?? "nil"), confidence=\(action.confidence)")
                    }

                    self.detectedActions = actions
                    self.showActionConfirmation = !actions.isEmpty
                    print("📍 Setting isProcessingVoice = false")
                    self.isProcessingVoice = false
                    print("📍 Setting actionRecognitionState = .executing")
                    self.actionRecognitionState = .executing
                    print("📍 State change complete")
                }
                print("✅✅✅ State set to .executing")

                print("⏳⏳⏳ Waiting 2s before execution...")
                try await Task.sleep(nanoseconds: 2_000_000_000)
                print("✅ Wait complete")

                print("📍📍📍 Step 5: Executing actions")
                await MainActor.run {
                    if !actions.isEmpty {
                        print("📱📱📱 Auto-executing \(actions.count) actions")
                        do {
                            try self.executeVoiceActionsWithErrorHandling(actions)
                            print("✅✅✅ All actions executed successfully")
                            self.executedActions = actions
                            print("📍 Setting actionRecognitionState = .completed")
                            self.actionRecognitionState = .completed
                            print("✅✅✅ State set to .completed")
                        } catch {
                            print("❌❌❌ Action execution failed: \(error)")
                            self.lastTranscription = "Failed to log entries. Please try again."
                            self.actionRecognitionState = .idle
                        }
                    } else {
                        print("⚠️⚠️⚠️ No actions to execute")
                        self.lastTranscription = "No actions detected in your speech. Please try again."
                        self.actionRecognitionState = .completed
                    }
                }

                // Show success state for 4 seconds before auto-dismissing
                print("⏳⏳⏳ Showing success state for 4 seconds...")
                try await Task.sleep(nanoseconds: 4_000_000_000)
                print("✅ Wait complete")

                print("🔄🔄🔄 Auto-dismissing and resetting to idle")
                await MainActor.run {
                    print("🔄 Calling resetToIdle()")
                    self.resetToIdle()
                    print("🔄 Reset complete")
                }

                self.processingTimeoutTask?.cancel()
                print("✅✅✅ PROCESSING COMPLETE - FULL SUCCESS!")
                print("✅✅✅ ============================================")

            } catch {
                print("❌❌❌ ============================================")
                print("❌❌❌ PROCESSING FAILED - CAUGHT ERROR")
                print("❌❌❌ ============================================")
                await MainActor.run {
                    print("❌ Error type: \(type(of: error))")
                    print("❌ Error description: \(error.localizedDescription)")
                    print("❌ Error: \(error)")
                    print("❌ Setting lastTranscription to error message")
                    self.lastTranscription = "Error: \(error.localizedDescription)"
                    print("❌ Setting isProcessingVoice = false")
                    self.isProcessingVoice = false
                    print("❌ Calling resetToIdle()")
                    self.resetToIdle()
                    print("❌ Reset complete")
                }
                self.processingTimeoutTask?.cancel()
                print("❌❌❌ ERROR HANDLER COMPLETE")
                print("❌❌❌ ============================================")
            }
        }
        print("🔄 ✅ Task.detached block created and scheduled")
        print("🔄🔄🔄 ============================================")
        print("🔄🔄🔄 processRecordedAudio FINISHED (task queued)")
        print("🔄🔄🔄 ============================================")
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw VoiceError.timeout
            }
            
            guard let result = try await group.next() else {
                throw VoiceError.timeout
            }
            group.cancelAll()
            return result
        }
    }
    
    private func resetToIdle() {
        print("🔄🔄🔄 ============================================")
        print("🔄🔄🔄 resetToIdle() CALLED")
        print("🔄🔄🔄 ============================================")
        print("🔄 BEFORE - actionRecognitionState: \(actionRecognitionState)")
        print("🔄 BEFORE - isProcessingVoice: \(isProcessingVoice)")
        print("🔄 BEFORE - executedActions.count: \(executedActions.count)")

        actionRecognitionState = .idle
        executedActions = []
        refinedTranscription = nil
        lastTranscription = nil
        isProcessingVoice = false

        print("🔄 AFTER - actionRecognitionState: \(actionRecognitionState)")
        print("🔄 AFTER - isProcessingVoice: \(isProcessingVoice)")
        print("🔄 AFTER - executedActions.count: \(executedActions.count)")
        print("🔄🔄🔄 ============================================")
        print("🔄🔄🔄 resetToIdle() COMPLETE")
        print("🔄🔄🔄 ============================================")
    }
    
    private func executeVoiceActionsWithErrorHandling(_ actions: [VoiceAction]) throws {
        guard let logsManager = logsManager else {
            throw VoiceError.notConfigured
        }
        
        var errors: [Error] = []
        
        for action in actions {
            do {
                try executeAction(action, logsManager: logsManager)
            } catch {
                errors.append(error)
                print("❌ Failed to execute action \(action.type): \(error)")
            }
        }
        
        if !errors.isEmpty && errors.count == actions.count {
            throw VoiceError.allActionsFailed
        }
    }
    
    private func executeAction(_ action: VoiceAction, logsManager: LogsManager) throws {
        switch action.type {
        case .logWater:
            if let amountStr = action.details.amount,
               let amount = Double(amountStr) {
                logsManager.logWater(amount: Int(amount), unit: action.details.unit ?? "oz")
                logsManager.objectWillChange.send()
            } else {
                throw VoiceError.processingFailed("Invalid water amount")
            }
        case .logFood:
            if let foodName = action.details.item {
                print("🍔 Processing food action for: \(foodName)")
                let logId = UUID()
                let logEntry = LogEntry(
                    id: logId,
                    date: Date(),
                    type: .food,
                    source: .voice,
                    notes: "Processing nutrition data...",
                    foodName: foodName,
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fat: 0
                )
                
                logsManager.logEntries.append(logEntry)
                logsManager.saveLogs()
                logsManager.objectWillChange.send()
                
                Task {
                    await AsyncTaskManager.queueFoodMacrosFetch(foodName: foodName, logId: logId)
                }
            } else {
                throw VoiceError.processingFailed("No food name provided")
            }
        case .logVitamin:
            if let vitaminName = action.details.item,
               let supplementManager = supplementManager {
                supplementManager.logIntakeByName(vitaminName, taken: true)
            } else {
                throw VoiceError.processingFailed("Invalid vitamin data")
            }
        case .logSymptom:
            if let symptoms = action.details.symptoms, !symptoms.isEmpty {
                let symptomText = symptoms.joined(separator: ", ")
                let logEntry = LogEntry(
                    id: UUID(),
                    date: Date(),
                    type: .symptom,
                    source: .voice,
                    notes: symptomText,
                    severity: action.details.severity.flatMap { Int($0) }
                )
                
                logsManager.logEntries.append(logEntry)
                logsManager.saveLogs()
                logsManager.objectWillChange.send()
            } else {
                throw VoiceError.processingFailed("No symptoms provided")
            }
        case .logPUQE:
            break
        case .unknown:
            break
        }
    }
    
    @MainActor
    func executeVoiceActions(_ actions: [VoiceAction]) {
        try? executeVoiceActionsWithErrorHandling(actions)
    }
    
    @MainActor
    func deleteVoiceLog(_ log: VoiceLog) {
        voiceLogs.removeAll { $0.id == log.id }
        
        // Delete audio file if it exists
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(log.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        
        saveLogs()
    }
    
    @MainActor
    func stopAudio() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            currentPlayingID = nil
        }
    }
    
    @MainActor
    func playAudio(log: VoiceLog) {
        playRecording(for: log)
    }
    
    func playRecording(for log: VoiceLog) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsPath.appendingPathComponent(log.fileName)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Audio file not found")
            return
        }
        
        if isPlaying && currentPlayingID == log.id {
            // Stop playing
            audioPlayer?.stop()
            isPlaying = false
            currentPlayingID = nil
        } else {
            // Start playing
            do {
                // Switch to playback mode
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                isPlaying = true
                currentPlayingID = log.id
            } catch {
                print("Could not play recording: \(error)")
            }
        }
    }
    
    func saveLogs() {
        if let encoded = try? JSONEncoder().encode(voiceLogs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([VoiceLog].self, from: data) {
            voiceLogs = decoded
        }
    }
    
    func filteredLogs(by category: LogCategory?) -> [VoiceLog] {
        guard let category = category else { return voiceLogs }
        return voiceLogs.filter { $0.category == category }
    }
}

extension VoiceLogManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}

extension VoiceLogManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentPlayingID = nil
        }
        
        // Switch back to playAndRecord for recording capability
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to reset audio session: \(error)")
        }
    }
}