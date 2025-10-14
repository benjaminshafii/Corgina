import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var logsManager: LogsManager
    @State private var showingDisclaimer = !UserDefaults.standard.bool(forKey: "hasAcceptedDisclaimer")
    @StateObject private var voiceLogManager = VoiceLogManager.shared
    @StateObject private var openAIManager = OpenAIManager.shared
    @StateObject private var supplementManager = SupplementManager()
    @State private var showAPIKeyError = false

    var body: some View {
        mainView
            .overlay(alignment: .top) {
                if showAPIKeyError {
                    APIKeyErrorBanner(onDismiss: {
                        showAPIKeyError = false
                    })
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 50)
                }
            }
            .fullScreenCover(isPresented: $showingDisclaimer) {
                DisclaimerView(isPresented: $showingDisclaimer)
            }
            .onAppear {
                voiceLogManager.configure(logsManager: logsManager, supplementManager: supplementManager)
            }
    }
    
    @ViewBuilder
    private var mainView: some View {
        ZStack(alignment: .bottom) {
            tabView
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                Spacer()
                    .allowsHitTesting(false)

                let shouldShowDrawer = voiceLogManager.isRecording ||
                   voiceLogManager.actionRecognitionState == .recognizing ||
                   voiceLogManager.actionRecognitionState == .executing ||
                   voiceLogManager.isProcessingVoice ||
                   (voiceLogManager.actionRecognitionState == .completed && !voiceLogManager.executedActions.isEmpty)

                let _ = print("🎨 UI DRAWER EVALUATION:")
                let _ = print("🎨 isRecording: \(voiceLogManager.isRecording)")
                let _ = print("🎨 actionRecognitionState: \(voiceLogManager.actionRecognitionState)")
                let _ = print("🎨 isProcessingVoice: \(voiceLogManager.isProcessingVoice)")
                let _ = print("🎨 executedActions.count: \(voiceLogManager.executedActions.count)")
                let _ = print("🎨 shouldShowDrawer: \(shouldShowDrawer)")

                if shouldShowDrawer {
                    voiceFlowDrawer
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: voiceLogManager.isRecording)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: voiceLogManager.actionRecognitionState)
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingMicButton(
                isRecording: voiceLogManager.isRecording,
                actionState: voiceLogManager.actionRecognitionState,
                onTap: handleVoiceTap
            )
            .padding(.trailing, 16)
            .padding(.bottom, 100)
        }
    }
    
    private var tabView: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            LogLedgerView(logsManager: logsManager)
                .tabItem {
                    Label("Logs", systemImage: "list.clipboard")
                }

            PUQEScoreView()
                .tabItem {
                    Label("PUQE", systemImage: "chart.line.uptrend.xyaxis")
                }

            MoreView()
                .environmentObject(logsManager)
                .environmentObject(notificationManager)
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
        }
        .tint(.blue)
    }
    


    private func handleVoiceTap() {
        print("🎯🎯🎯 ============================================")
        print("🎯🎯🎯 handleVoiceTap() CALLED")
        print("🎯🎯🎯 ============================================")
        print("🎯 Current state - isRecording: \(voiceLogManager.isRecording)")
        print("🎯 Current state - actionRecognitionState: \(voiceLogManager.actionRecognitionState)")

        if !openAIManager.hasAPIKey {
            print("🎯 ❌ No API key - showing error banner")
            withAnimation(.spring(response: 0.3)) {
                showAPIKeyError = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    showAPIKeyError = false
                }
            }
            return
        }

        if voiceLogManager.isRecording {
            print("🎯 Currently recording - calling stopRecording()")
            voiceLogManager.stopRecording()
            print("🎯 stopRecording() returned")
        } else {
            print("🎯 Not recording - calling startRecording()")
            voiceLogManager.startRecording()
            print("🎯 startRecording() returned")
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: voiceLogManager.isRecording ? .medium : .light)
        impactFeedback.impactOccurred()
        print("🎯 Haptic feedback triggered")
        print("🎯🎯🎯 ============================================")
        print("🎯🎯🎯 handleVoiceTap() COMPLETE")
        print("🎯🎯🎯 ============================================")
    }
    
    private func getActionSummary(_ action: VoiceAction) -> String {
        var summary = ""
        
        switch action.type {
        case .logFood:
            summary = "Added \(action.details.item ?? "food")"
            if let mealType = action.details.mealType {
                summary += " for \(mealType)"
            }
        case .logWater:
            if let amount = action.details.amount, let unit = action.details.unit {
                summary = "Logged \(amount) \(unit) of water"
            } else {
                summary = "Logged water"
            }
        case .logVitamin:
            summary = "Took \(action.details.vitaminName ?? action.details.item ?? "supplement")"
        case .logSymptom:
            if let symptoms = action.details.symptoms {
                summary = "Logged: \(symptoms.joined(separator: ", "))"
            } else {
                summary = "Logged symptoms"
            }
        case .logPUQE:
            summary = "Updated PUQE score"
        case .unknown:
            summary = "Unknown action"
        }
        
        return summary
    }
    
    private var voiceFlowDrawer: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(.tertiary)
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Content based on state
            Group {
                if voiceLogManager.isRecording {
                    recordingStateView
                } else if voiceLogManager.actionRecognitionState == .recognizing {
                    analyzingStateView
                } else if voiceLogManager.actionRecognitionState == .executing {
                    executingStateView
                } else if voiceLogManager.actionRecognitionState == .completed {
                    completedStateView
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, y: -5)
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
    }

    // MARK: - State 1: Recording (Live Transcription)
    private var recordingStateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Circle()
                        .stroke(.red.opacity(0.4), lineWidth: 2)
                        .frame(width: 54, height: 54)
                        .scaleEffect(voiceLogManager.isRecording ? 1.2 : 1.0)
                        .opacity(voiceLogManager.isRecording ? 0 : 0.8)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: voiceLogManager.isRecording)

                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recording")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Speak naturally")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Live transcript bubble
            if !voiceLogManager.onDeviceSpeechManager.liveTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Transcript")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(voiceLogManager.onDeviceSpeechManager.liveTranscript)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.easeInOut(duration: 0.2), value: voiceLogManager.onDeviceSpeechManager.liveTranscript)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.red.opacity(0.08))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - State 2: Analyzing (On-device → OpenAI refinement)
    private var analyzingStateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.15))
                        .frame(width: 44, height: 44)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Analyzing")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Refining with AI...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Show on-device transcript dimmed
            if !voiceLogManager.onDeviceSpeechManager.liveTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("On-Device")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(voiceLogManager.onDeviceSpeechManager.liveTranscript)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .opacity(0.6)
                        .lineLimit(3)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.secondary.opacity(0.08))
                )
            }

            // Progress indicators
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(.blue.opacity(0.3))
                        .frame(height: 4)
                        .overlay(
                            GeometryReader { geo in
                                Capsule()
                                    .fill(.blue)
                                    .frame(width: index == 0 ? geo.size.width : (index == 1 ? geo.size.width * 0.6 : 0))
                            }
                        )
                }
            }
        }
    }

    // MARK: - State 3: Executing (Refined transcript + creating logs)
    private var executingStateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Understood")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Creating logs...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Refined transcript from OpenAI
            if let transcript = voiceLogManager.lastTranscription, !transcript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refined")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text("\"\(transcript)\"")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.green.opacity(0.08))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Creating logs indicator
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))

                Text("Creating log entries...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - State 4: Completed (Show logged actions)
    private var completedStateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with dismiss button
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Successfully Logged")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(voiceLogManager.executedActions.count) item\(voiceLogManager.executedActions.count == 1 ? "" : "s") added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        voiceLogManager.clearExecutedActions()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Action cards
            VStack(spacing: 12) {
                ForEach(Array(voiceLogManager.executedActions.enumerated()), id: \.offset) { index, action in
                    CompactActionCard(action: action)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity)
                                .animation(.spring().delay(Double(index) * 0.08)),
                            removal: .opacity
                        ))
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                // Log Another button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        voiceLogManager.clearExecutedActions()
                        // Small delay to let drawer disappear, then start new recording
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            voiceLogManager.startRecording()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Log Another")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // Done button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        voiceLogManager.clearExecutedActions()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Done")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Compact Action Card Component
struct CompactActionCard: View {
    let action: VoiceAction

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: actionIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(actionColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(actionColor.opacity(0.15)))

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(actionTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let detail = actionDetail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(actionColor.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(actionColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var actionIcon: String {
        switch action.type {
        case .logFood: return "fork.knife"
        case .logWater: return "drop.fill"
        case .logVitamin: return "pills.fill"
        case .addVitamin: return "plus.circle.fill"
        case .logSymptom: return "heart.text.square"
        case .logPUQE: return "chart.line.uptrend.xyaxis"
        case .unknown: return "questionmark.circle"
        }
    }

    private var actionColor: Color {
        switch action.type {
        case .logFood: return .orange
        case .logWater: return .blue
        case .logVitamin: return .green
        case .addVitamin: return .mint
        case .logSymptom: return .purple
        case .logPUQE: return .pink
        case .unknown: return .gray
        }
    }

    private var actionTitle: String {
        switch action.type {
        case .logFood:
            return action.details.item ?? "Food"
        case .logWater:
            if let amount = action.details.amount, let unit = action.details.unit {
                return "\(amount) \(unit) water"
            }
            return "Water"
        case .logVitamin:
            return action.details.vitaminName ?? action.details.item ?? "Supplement"
        case .addVitamin:
            return action.details.vitaminName ?? "New Supplement"
        case .logSymptom:
            return "Symptoms logged"
        case .logPUQE:
            return "PUQE Score"
        case .unknown:
            return "Unknown"
        }
    }

    private var actionDetail: String? {
        switch action.type {
        case .logFood:
            if let mealType = action.details.mealType {
                return mealType.capitalized
            }
            return nil
        case .addVitamin:
            if let frequency = action.details.frequency {
                return "Added - \(frequency.capitalized)"
            }
            return "Added to supplements"
        case .logSymptom:
            if let symptoms = action.details.symptoms {
                return symptoms.joined(separator: ", ")
            }
            return nil
        default:
            return nil
        }
    }
}
