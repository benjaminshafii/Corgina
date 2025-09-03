import SwiftUI
import AVFoundation

struct VoiceCommandSheet: View {
    @ObservedObject var voiceLogManager: VoiceLogManager
    @StateObject private var openAIManager = OpenAIManager.shared
    @State private var isListening = false
    @State private var animationScale: CGFloat = 1.0
    @State private var showExamples = false
    @State private var timer: Timer?
    @State private var errorMessage: String?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Microphone Button
                ZStack {
                    // Animated circles when recording
                    if isListening {
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            .scaleEffect(animationScale)
                            .opacity(Double(2 - animationScale))
                            .animation(
                                Animation.easeOut(duration: 1)
                                    .repeatForever(autoreverses: false),
                                value: animationScale
                            )
                        
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            .scaleEffect(animationScale * 0.8)
                            .opacity(Double(2 - animationScale * 0.8))
                            .animation(
                                Animation.easeOut(duration: 1)
                                    .repeatForever(autoreverses: false)
                                    .delay(0.2),
                                value: animationScale
                            )
                    }
                    
                    Button(action: toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(isListening ? Color.red : Color.blue)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: isListening ? "stop.fill" : "mic.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(isListening ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isListening)
                }
                .frame(height: 150)
                
                // Status Text
                VStack(spacing: 8) {
                    if isListening {
                        Text("Listening...")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(formatTime(voiceLogManager.recordingTime))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else if voiceLogManager.isProcessingVoice {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing...")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("Tap to start voice command")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Transcription Display - Always show if available
                if let transcript = voiceLogManager.lastTranscription, !transcript.isEmpty, !isListening {
                    VStack(spacing: 4) {
                        Text("You said:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\"\(transcript)\"")
                            .font(.body)
                            .foregroundColor(.primary)
                            .italic()
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }
                
                // Error or API Key Warning
                if !openAIManager.hasAPIKey && !isListening {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        Text("OpenAI API Key Required")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Voice transcription requires an OpenAI API key. Please add it in Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            // Close sheet and open settings
                            onDismiss()
                        }) {
                            Text("Go to Settings")
                                .font(.caption)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Detected Actions
                if !voiceLogManager.detectedActions.isEmpty && !isListening {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected Actions:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(voiceLogManager.detectedActions, id: \.type) { action in
                            HStack {
                                Image(systemName: iconForAction(action.type))
                                    .foregroundColor(colorForAction(action.type))
                                
                                Text(descriptionForAction(action))
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                if action.confidence > 0.8 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Example Commands
                Button(action: { showExamples.toggle() }) {
                    HStack {
                        Image(systemName: showExamples ? "chevron.up" : "chevron.down")
                        Text("Example Commands")
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal)
                }
                
                if showExamples {
                    VStack(alignment: .leading, spacing: 6) {
                        ExampleRow(icon: "drop.fill", text: "I drank 16 ounces of water")
                        ExampleRow(icon: "fork.knife", text: "I had eggs and toast for breakfast")
                        ExampleRow(icon: "pills.fill", text: "I took my prenatal vitamin")
                        ExampleRow(icon: "heart.text.square", text: "I'm feeling nauseous")
                        ExampleRow(icon: "face.sad", text: "I threw up after lunch")
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Voice Command")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    if isListening {
                        stopRecording()
                    }
                    onDismiss()
                }
            )
        }
        .onAppear {
            if voiceLogManager.isRecording {
                isListening = true
                startAnimations()
            }
        }
        .onDisappear {
            if isListening {
                stopRecording()
            }
        }
        .onReceive(voiceLogManager.$detectedActions) { actions in
            if !actions.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onDismiss()
                }
            }
        }
    }
    
    private func toggleRecording() {
        if isListening {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Clear previous transcription and actions
        voiceLogManager.lastTranscription = nil
        voiceLogManager.detectedActions = []
        
        voiceLogManager.requestMicrophonePermission { granted in
            if granted {
                voiceLogManager.startRecording()
                isListening = true
                startAnimations()
            }
        }
    }
    
    private func stopRecording() {
        voiceLogManager.stopRecording()
        isListening = false
        stopAnimations()
    }
    
    private func startAnimations() {
        animationScale = 1.5
    }
    
    private func stopAnimations() {
        animationScale = 1.0
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func iconForAction(_ type: VoiceAction.ActionType) -> String {
        switch type {
        case .logWater: return "drop.fill"
        case .logFood: return "fork.knife"
        case .logVitamin: return "pills.fill"
        case .logSymptom: return "heart.text.square"
        case .logPUQE: return "chart.line.uptrend.xyaxis"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private func colorForAction(_ type: VoiceAction.ActionType) -> Color {
        switch type {
        case .logWater: return .blue
        case .logFood: return .orange
        case .logVitamin: return .purple
        case .logSymptom: return .red
        case .logPUQE: return .pink
        case .unknown: return .gray
        }
    }
    
    private func descriptionForAction(_ action: VoiceAction) -> String {
        switch action.type {
        case .logWater:
            if let amount = action.details.amount, let unit = action.details.unit {
                return "Log \(amount) \(unit) of water"
            }
            return "Log water intake"
        case .logFood:
            return "Log food: \(action.details.item ?? "meal")"
        case .logVitamin:
            return "Log vitamin: \(action.details.vitaminName ?? "supplement")"
        case .logSymptom:
            if let symptoms = action.details.symptoms {
                return "Log symptoms: \(symptoms.joined(separator: ", "))"
            }
            return "Log symptom"
        case .logPUQE:
            return "Record PUQE score"
        case .unknown:
            return "Unknown command"
        }
    }
}

struct ExampleRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text("\"\(text)\"")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
            Spacer()
        }
    }
}