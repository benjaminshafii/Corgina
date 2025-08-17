import SwiftUI
import AVFoundation

struct VoiceLogsView: View {
    @StateObject private var voiceLogManager = VoiceLogManager()
    @EnvironmentObject var logsManager: LogsManager
    @State private var selectedFilter: LogCategory? = nil
    @State private var showingMicrophoneAlert = false
    @State private var microphonePermissionDenied = false
    
    var filteredLogs: [VoiceLog] {
        voiceLogManager.filteredLogs(by: selectedFilter)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Recording Section
                VStack(spacing: 16) {
                    // Category Selector
                    VStack(spacing: 8) {
                        Text("Select Category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(LogCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    voiceLogManager.currentCategory = category
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: category.icon)
                                            .font(.title3)
                                        Text(category.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(voiceLogManager.currentCategory == category ? .semibold : .regular)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(voiceLogManager.currentCategory == category ?
                                                  Color(category.color).opacity(0.15) :
                                                  Color.gray.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(voiceLogManager.currentCategory == category ?
                                                   Color(category.color) :
                                                   Color.gray.opacity(0.3),
                                                   lineWidth: voiceLogManager.currentCategory == category ? 2 : 1)
                                    )
                                    .foregroundColor(
                                        voiceLogManager.currentCategory == category ?
                                        Color(category.color) :
                                        .primary
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Record Button and Timer
                    HStack(spacing: 30) {
                        // Timer Display
                        Text(formatTime(voiceLogManager.recordingTime))
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundColor(voiceLogManager.isRecording ? .red : .secondary)
                            .frame(width: 100)
                        
                        // Record Button
                        Button(action: {
                            handleRecordButtonTap()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(voiceLogManager.isRecording ? Color.red : Color.blue)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: voiceLogManager.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                        .scaleEffect(voiceLogManager.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: voiceLogManager.isRecording)
                        
                        // Spacer for balance
                        Color.clear
                            .frame(width: 100)
                    }
                    
                    // Recording indicator
                    if voiceLogManager.isRecording {
                        HStack(spacing: 8) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .foregroundColor(.red)
                                .symbolEffect(.pulse)
                            Text("Recording \(voiceLogManager.currentCategory.rawValue)...")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(20)
                    } else {
                        Text("Tap record to log \(voiceLogManager.currentCategory.rawValue.lowercased())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 20)
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                
                // Filter Section
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(nil as LogCategory?)
                    ForEach(LogCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category as LogCategory?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Logs List
                if filteredLogs.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "mic.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No voice logs yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the record button to create your first log")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(filteredLogs) { log in
                            VoiceLogRow(log: log, manager: voiceLogManager)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            voiceLogManager.deleteLog(log)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Voice Logs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !filteredLogs.isEmpty {
                        Text("\(filteredLogs.count) log\(filteredLogs.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("VoiceLogCreated"))) { notification in
            if let voiceLog = notification.userInfo?["voiceLog"] as? VoiceLog {
                // Add to unified logs based on category
                let logType: LogType = voiceLog.category == .food ? .food : .symptom
                logsManager.addVoiceLog(voiceLog, type: logType)
            }
        }
        .alert("Microphone Permission Required", isPresented: $showingMicrophoneAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone access in Settings to record voice logs.")
        }
    }
    
    private func handleRecordButtonTap() {
        if voiceLogManager.isRecording {
            voiceLogManager.stopRecording()
        } else {
            voiceLogManager.requestMicrophonePermission { granted in
                if granted {
                    voiceLogManager.startRecording()
                } else {
                    showingMicrophoneAlert = true
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}