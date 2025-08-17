import SwiftUI

struct VoiceLogRow: View {
    let log: VoiceLog
    @ObservedObject var manager: VoiceLogManager
    
    var isPlaying: Bool {
        manager.isPlaying && manager.currentPlayingID == log.id
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: log.category.icon)
                .font(.title2)
                .foregroundColor(Color(log.category.color))
                .frame(width: 40)
            
            // Log Info
            VStack(alignment: .leading, spacing: 4) {
                Text(log.category.rawValue)
                    .font(.headline)
                
                HStack {
                    Text(log.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(log.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let transcription = log.transcription {
                    Text(transcription)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Play/Pause Button
            Button(action: {
                if isPlaying {
                    manager.stopAudio()
                } else {
                    manager.playAudio(log: log)
                }
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
}