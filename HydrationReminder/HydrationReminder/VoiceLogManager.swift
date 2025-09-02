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
    private let logsManager: LogsManager
    private let supplementManager: SupplementManager
    
    override init() {
        self.logsManager = LogsManager(notificationManager: NotificationManager.shared)
        self.supplementManager = SupplementManager(notificationManager: NotificationManager.shared)
        super.init()
        loadLogs()
        setupAudioSession()
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
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(true)
            
            let fileName = "voicelog_\(UUID().uuidString)_\(Date().timeIntervalSince1970).m4a"
            let audioURL = getDocumentsDirectory().appendingPathComponent(fileName)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingStartTime = Date()
            recordingTime = 0
            
            // Start timer to update recording time
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let startTime = self.recordingStartTime {
                    self.recordingTime = Date().timeIntervalSince(startTime)
                }
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        let duration = recordingTime
        
        if let recorder = audioRecorder {
            let fileName = recorder.url.lastPathComponent
            currentRecordingURL = recorder.url
            
            let voiceLog = VoiceLog(
                duration: duration,
                category: currentCategory,
                fileName: fileName
            )
            
            voiceLogs.insert(voiceLog, at: 0)
            saveLogs()
            
            // Process voice for actions if OpenAI API is available
            if openAIManager.hasAPIKey {
                processVoiceForActions(audioURL: recorder.url)
            }
            
            // Post notification that a voice log was created
            NotificationCenter.default.post(
                name: Notification.Name("VoiceLogCreated"),
                object: nil,
                userInfo: ["voiceLog": voiceLog]
            )
        }
        
        isRecording = false
        recordingTime = 0
        audioRecorder = nil
    }
    
    private func processVoiceForActions(audioURL: URL) {
        Task { @MainActor in
            isProcessingVoice = true
            
            do {
                let audioData = try Data(contentsOf: audioURL)
                let actions = try await openAIManager.transcribeAndExtractActions(audioData: audioData)
                
                self.lastTranscription = openAIManager.lastTranscription
                self.detectedActions = actions
                
                if !actions.isEmpty {
                    self.showActionConfirmation = true
                    // Auto-execute high confidence actions
                    for action in actions where action.confidence > 0.8 {
                        executeAction(action)
                    }
                }
            } catch {
                print("Error processing voice: \(error)")
            }
            
            isProcessingVoice = false
        }
    }
    
    func executeAction(_ action: VoiceAction) {
        switch action.type {
        case .logWater:
            if let amountStr = action.details.amount,
               let amount = Int(amountStr) {
                logsManager.logWater(amount: amount, unit: action.details.unit ?? "oz", source: .voice)
                showToast("Logged \(amount) \(action.details.unit ?? "oz") of water")
            }
            
        case .logFood:
            if let foodItem = action.details.item {
                logsManager.logFood(notes: foodItem, source: .voice)
                showToast("Logged food: \(foodItem)")
            }
            
        case .logVitamin:
            if let vitaminName = action.details.vitaminName {
                supplementManager.logIntakeByName(vitaminName)
                showToast("Logged vitamin: \(vitaminName)")
            }
            
        case .logSymptom:
            if let symptoms = action.details.symptoms {
                let severity = parseSeverity(action.details.severity)
                for symptom in symptoms {
                    logsManager.logSymptom(notes: symptom, severity: severity, source: .voice)
                }
                showToast("Logged symptoms: \(symptoms.joined(separator: ", "))")
            }
            
        case .logPUQE:
            // Handle PUQE logging
            if let notes = action.details.notes {
                NotificationCenter.default.post(
                    name: Notification.Name("LogPUQEFromVoice"),
                    object: nil,
                    userInfo: ["notes": notes]
                )
                showToast("PUQE score recorded")
            }
            
        case .unknown:
            print("Unknown action type")
        }
    }
    
    private func parseSeverity(_ severityStr: String?) -> Int {
        guard let severity = severityStr?.lowercased() else { return 3 }
        
        switch severity {
        case "mild", "light", "slight": return 2
        case "moderate", "medium": return 3
        case "severe", "heavy", "bad": return 4
        default: return 3
        }
    }
    
    private func showToast(_ message: String) {
        NotificationCenter.default.post(
            name: Notification.Name("ShowToast"),
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    func playAudio(log: VoiceLog) {
        stopAudio()
        
        let audioURL = getDocumentsDirectory().appendingPathComponent(log.fileName)
        
        do {
            // Switch to playback mode for louder volume
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0  // Set maximum volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            currentPlayingID = log.id
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
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
    
    func deleteLog(_ log: VoiceLog) {
        // Stop playing if this log is currently playing
        if currentPlayingID == log.id {
            stopAudio()
        }
        
        // Delete the audio file
        let audioURL = getDocumentsDirectory().appendingPathComponent(log.fileName)
        try? FileManager.default.removeItem(at: audioURL)
        
        // Remove from array
        voiceLogs.removeAll { $0.id == log.id }
        saveLogs()
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        // Create VoiceLogs subdirectory if it doesn't exist
        let voiceLogsDirectory = documentsDirectory.appendingPathComponent("VoiceLogs")
        if !FileManager.default.fileExists(atPath: voiceLogsDirectory.path) {
            try? FileManager.default.createDirectory(at: voiceLogsDirectory, withIntermediateDirectories: true)
        }
        
        return voiceLogsDirectory
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