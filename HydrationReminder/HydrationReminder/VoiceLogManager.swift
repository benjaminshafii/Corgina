import Foundation
import AVFoundation
import SwiftUI

class VoiceLogManager: NSObject, ObservableObject {
    @Published var voiceLogs: [VoiceLog] = []
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentPlayingID: UUID?
    @Published var recordingTime: TimeInterval = 0
    @Published var currentCategory: LogCategory = .food
    @Published var isProcessingVoice = false
    @Published var lastTranscription: String?
    @Published var detectedActions: [VoiceAction] = []
    @Published var showActionConfirmation = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var currentRecordingURL: URL?
    
    private let userDefaultsKey = "SavedVoiceLogs"
    private let openAIManager = OpenAIManager.shared
    private var logsManager: LogsManager?
    private var supplementManager: SupplementManager?
    
    override init() {
        super.init()
        loadLogs()
        setupAudioSession()
    }
    
    func configure(logsManager: LogsManager, supplementManager: SupplementManager) {
        print("🔧 VoiceLogManager.configure() called")
        print("🔧 LogsManager: \(logsManager)")
        print("🔧 Current logs count: \(logsManager.logEntries.count)")
        self.logsManager = logsManager
        self.supplementManager = supplementManager
        print("🔧 Configuration complete")
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
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
        currentRecordingURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingStartTime = Date()
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingTime = Date().timeIntervalSince(startTime)
            }
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        let duration = recordingTime
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingTime = 0
        
        // Process the recorded audio
        if let url = currentRecordingURL {
            // Create voice log with the audio file
            let voiceLog = VoiceLog(
                duration: duration,
                category: currentCategory,
                fileName: url.lastPathComponent
            )
            voiceLogs.append(voiceLog)
            saveLogs()
            
            // Process with OpenAI
            processRecordedAudio(at: url, for: voiceLog)
        }
    }
    
    private func processRecordedAudio(at url: URL, for log: VoiceLog) {
        Task {
            do {
                isProcessingVoice = true
                
                // Read audio data
                let audioData = try Data(contentsOf: url)
                
                // Transcribe audio
                let transcription = try await openAIManager.transcribeAudio(audioData: audioData)
                
                await MainActor.run {
                    self.lastTranscription = transcription.text
                    
                    // Update the log with transcription
                    if let index = self.voiceLogs.firstIndex(where: { $0.id == log.id }) {
                        self.voiceLogs[index].transcription = transcription.text
                        self.saveLogs()
                    }
                }
                
                // Extract actions from transcription
                let actions = try await openAIManager.extractVoiceActions(from: transcription.text)
                
                await MainActor.run {
                    print("📱 Detected \(actions.count) actions from voice")
                    for (index, action) in actions.enumerated() {
                        print("📱 Action \(index): type=\(action.type), item=\(action.details.item ?? "nil"), confidence=\(action.confidence)")
                    }
                    
                    self.detectedActions = actions
                    self.showActionConfirmation = !actions.isEmpty
                    self.isProcessingVoice = false
                    
                    // Don't auto-execute here - let VoiceCommandSheet handle it
                    // This prevents double execution
                    // if !actions.isEmpty {
                    //     print("📱 Auto-executing \(actions.count) actions")
                    //     self.executeVoiceActions(actions)
                    // }
                }
                
            } catch {
                await MainActor.run {
                    print("Processing failed: \(error)")
                    self.lastTranscription = "Failed to process audio"
                    self.isProcessingVoice = false
                }
            }
        }
    }
    
    func executeVoiceActions(_ actions: [VoiceAction]) {
        guard let logsManager = logsManager else {
            print("❌ CRITICAL: LogsManager not configured in VoiceLogManager!")
            print("❌ This means voice actions will not be logged!")
            print("❌ Make sure to call voiceLogManager.configure() with shared managers")
            return
        }
        
        print("✅ ExecuteVoiceActions: LogsManager is configured, processing \(actions.count) actions")
        
        for action in actions {
            switch action.type {
            case .logWater:
                if let amountStr = action.details.amount,
                   let amount = Double(amountStr) {
                    logsManager.logWater(amount: Int(amount), unit: action.details.unit ?? "oz")
                    // Immediate UI update for water
                    logsManager.objectWillChange.send()
                }
            case .logFood:
                if let foodName = action.details.item {
                    print("🍔 VoiceLogManager: Processing food action for: \(foodName)")
                    print("🍔 LogsManager configured: \(logsManager != nil)")
                    print("🍔 Current log count before: \(logsManager.logEntries.count)")
                    
                    // Create log entry immediately with placeholder data
                    let logId = UUID()
                    let logEntry = LogEntry(
                        id: logId,
                        date: Date(),
                        type: .food,
                        source: .voice,
                        notes: "Processing nutrition data...",
                        foodName: foodName,
                        calories: 0,  // Placeholder
                        protein: 0,   // Placeholder
                        carbs: 0,     // Placeholder
                        fat: 0        // Placeholder
                    )
                    
                    // Add to logs immediately
                    logsManager.logEntries.append(logEntry)
                    logsManager.saveLogs()
                    logsManager.objectWillChange.send()
                    
                    print("🍔 Log count after append: \(logsManager.logEntries.count)")
                    print("🍔 Today's logs count: \(logsManager.getTodayLogs().count)")
                    print("🍔 Today's food count: \(logsManager.getTodayFoodCount())")
                    
                    // Queue async task for macro fetching
                    Task {
                        await AsyncTaskManager.queueFoodMacrosFetch(foodName: foodName, logId: logId)
                    }
                } else {
                    print("⚠️ VoiceLogManager: Food action has no item name")
                }
            case .logVitamin:
                if let vitaminName = action.details.item,
                   let supplementManager = supplementManager {
                    // Mark supplement as taken by name
                    supplementManager.logIntakeByName(vitaminName, taken: true)
                }
            case .logSymptom:
                // Log symptoms
                if let symptoms = action.details.symptoms, !symptoms.isEmpty {
                    let symptomText = symptoms.joined(separator: ", ")
                    print("📝 Logging symptoms: \(symptomText)")
                    
                    // Create symptom log entry
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
                    
                    print("📝 Symptom logged successfully")
                } else {
                    print("⚠️ No symptoms found in action details")
                }
            case .logPUQE:
                // Handle PUQE logging if needed
                break
            case .unknown:
                break
            }
        }
    }
    
    func deleteVoiceLog(_ log: VoiceLog) {
        voiceLogs.removeAll { $0.id == log.id }
        
        // Delete audio file if it exists
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(log.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        
        saveLogs()
    }
    
    func stopAudio() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            currentPlayingID = nil
        }
    }
    
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
    
    private func saveLogs() {
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
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}

extension VoiceLogManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentPlayingID = nil
        
        // Switch back to playAndRecord for recording capability
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to reset audio session: \(error)")
        }
    }
}