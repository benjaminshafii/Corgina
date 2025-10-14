import Foundation
import Speech
import AVFoundation

@MainActor
class OnDeviceSpeechManager: NSObject, ObservableObject, @unchecked Sendable {
    @Published var liveTranscript: String = ""
    @Published var isTranscribing = false
    @Published var error: Error?
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    nonisolated override init() {
        super.init()
        Task { @MainActor in
            self.setupAudioEngine()
        }
    }
    
    private func setupAudioEngine() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
        }
    }
    
    func requestPermission() async -> Bool {
        let speechStatus = await SFSpeechRecognizer.requestAuthorization()
        let micStatus = await AVAudioApplication.requestRecordPermission()
        return speechStatus == .authorized && micStatus
    }
    
    func startLiveTranscription(recordingURL: URL) throws {
        guard !isTranscribing else { return }
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("❌ Speech recognizer not available")
            throw SpeechError.recognizerUnavailable
        }
        
        self.recordingURL = recordingURL
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Failed to create recognition request")
            throw SpeechError.requestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false  // Allow network if on-device fails
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        print("🎤 Recording format: \(recordingFormat)")
        
        // Create audio file to save recording - use CAF format for PCM compatibility
        let tempURL = recordingURL.deletingPathExtension().appendingPathExtension("caf")
        do {
            // Use CAF format which supports PCM directly
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: recordingFormat.sampleRate,
                AVNumberOfChannelsKey: recordingFormat.channelCount,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]
            
            audioFile = try AVAudioFile(forWriting: tempURL, settings: settings)
            print("🎤 Audio file created at: \(tempURL)")
        } catch {
            print("❌ Failed to create audio file: \(error)")
            throw SpeechError.audioEngineFailed
        }
        
        print("🎤 Setting up recognition task...")
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcript = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.liveTranscript = transcript
                    print("🎤 Live transcript updated: '\(transcript)'")
                }
            }

            if let error = error {
                print("❌ Speech recognition error: \(error)")
                DispatchQueue.main.async {
                    self.error = error
                }
            }

            if error != nil || result?.isFinal == true {
                print("🎤 Recognition finished (final: \(result?.isFinal ?? false))")
            }
        }
        
        print("🎤 Installing audio tap...")
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // Send to speech recognizer
            self.recognitionRequest?.append(buffer)
            
            // Write to audio file
            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                print("❌ Error writing audio buffer: \(error)")
            }
        }
        
        print("🎤 Starting audio engine...")
        audioEngine.prepare()
        try audioEngine.start()
        
        isTranscribing = true
        liveTranscript = ""
        print("✅ Live transcription started successfully")
    }
    
    func stopLiveTranscription() -> (transcript: String, recordingURL: URL?) {
        let finalTranscript = liveTranscript
        let url = recordingURL
        stopAudioEngine()
        isTranscribing = false

        // Close audio file
        audioFile = nil
        recordingURL = nil

        // Keep transcript visible for a moment, then clear after delay to avoid jarring transition
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            self.liveTranscript = ""
        }

        print("🎤 Live transcription stopped, file saved at: \(url?.path ?? "nil")")
        return (finalTranscript, url)
    }
    
    private func stopAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    enum SpeechError: LocalizedError {
        case recognizerUnavailable
        case requestFailed
        case audioEngineFailed
        
        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                return "Speech recognizer is not available"
            case .requestFailed:
                return "Failed to create recognition request"
            case .audioEngineFailed:
                return "Audio engine failed to start"
            }
        }
    }
}

extension AVAudioApplication {
    static func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

extension SFSpeechRecognizer {
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
