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
            // Drawer that appears during processing
            if shouldShowDrawer {
                voiceFlowDrawer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Floating mic button - visible when idle or recording
            if !shouldHideButton {
                FloatingMicButton(
                    isRecording: voiceLogManager.isRecording,
                    actionState: voiceLogManager.actionRecognitionState,
                    onTap: handleVoiceTap
                )
                .padding(.trailing, 20)
                .padding(.bottom, 90)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldShowDrawer)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldHideButton)
    }

    private var shouldShowDrawer: Bool {
        voiceLogManager.isRecording ||
        voiceLogManager.actionRecognitionState == .recognizing ||
        voiceLogManager.actionRecognitionState == .executing ||
        voiceLogManager.isProcessingVoice ||
        (voiceLogManager.actionRecognitionState == .completed && !voiceLogManager.executedActions.isEmpty)
    }

    private var shouldHideButton: Bool {
        // Hide button when drawer is showing (during processing states)
        voiceLogManager.actionRecognitionState == .recognizing ||
        voiceLogManager.actionRecognitionState == .executing ||
        (voiceLogManager.actionRecognitionState == .completed && !voiceLogManager.executedActions.isEmpty)
    }

    private var tabView: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                DashboardView()
            }

            Tab("Logs", systemImage: "list.clipboard") {
                LogLedgerView(logsManager: logsManager)
            }

            Tab("PUQE", systemImage: "chart.line.uptrend.xyaxis") {
                PUQEScoreView()
            }

            Tab("More", systemImage: "ellipsis.circle") {
                MoreView()
                    .environmentObject(logsManager)
                    .environmentObject(notificationManager)
            }
        }
        .tint(.blue)
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
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
        case .addVitamin:
            summary = "Added \(action.details.vitaminName ?? "supplement") to tracker"
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
}

// MARK: - Voice Flow Drawer (iOS 26 Liquid Glass)
extension MainTabView {
    private var voiceFlowDrawer: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
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
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 24, y: -8)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                        .blendMode(.overlay)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 90)
    }

    // Recording state
    private var recordingStateView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recording")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Tap stop when finished")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Live transcript
            if !voiceLogManager.onDeviceSpeechManager.liveTranscript.isEmpty {
                Text(voiceLogManager.onDeviceSpeechManager.liveTranscript)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.red.opacity(0.08))
                    )
            }
        }
    }

    // Analyzing state
    private var analyzingStateView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Analyzing")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Processing with AI...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if !voiceLogManager.onDeviceSpeechManager.liveTranscript.isEmpty {
                Text(voiceLogManager.onDeviceSpeechManager.liveTranscript)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .opacity(0.6)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.secondary.opacity(0.08))
                    )
            }

            // Progress animation
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(.blue.opacity(0.3))
                        .frame(height: 4)
                }
            }
        }
    }

    // Executing state
    private var executingStateView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.green)
                }

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

            if let transcript = voiceLogManager.lastTranscription, !transcript.isEmpty {
                Text("\"\(transcript)\"")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.green.opacity(0.08))
                    )
            }

            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                Text("Creating log entries...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // Completed state
    private var completedStateView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
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
            }

            // Action cards
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(voiceLogManager.executedActions.enumerated()), id: \.offset) { _, action in
                        CompactActionCard(action: action)
                    }
                }
            }
            .frame(maxHeight: 200)

            // Action buttons
            HStack(spacing: 12) {
                // Log Another button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        voiceLogManager.clearExecutedActions()
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
