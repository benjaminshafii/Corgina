# Voice UI Implementation Recommendations

**For:** Hydration/Nutrition Tracking App (Corgina)
**Date:** October 14, 2025
**Based on:** iOS 26 Best Practices Research

---

## Quick Assessment of Current Implementation

### What You're Doing Well ✅

1. **Bottom Drawer Pattern** - Your `MainTabView` uses the recommended bottom drawer approach
2. **Liquid Glass Materials** - Using `.ultraThinMaterial` with proper corner radius (28pt)
3. **State-Based UI** - Clear visual distinction between recording, processing, and completed states
4. **Floating Action Button** - Proper placement and sizing
5. **Spring Animations** - Using recommended spring parameters (0.4 response, 0.8 dampening)
6. **Live Transcript Display** - Showing on-device transcription during recording
7. **Haptic Feedback** - Providing tactile feedback on state changes

### Areas for Enhancement 🔧

#### 1. Flickering Issue (Mentioned in Git History)

**Likely Cause:** The drawer is recreating its view hierarchy on state changes.

**Current Code (MainTabView.swift, line 186-196):**
```swift
Group {
    if voiceLogManager.isRecording {
        recordingStateView
    } else if voiceLogManager.actionRecognitionState == .recognizing {
        analyzingStateView
    } // ...
}
```

**Recommendation:**
```swift
// Use switch instead of if-else chain for more stable hierarchy
switch (voiceLogManager.isRecording, voiceLogManager.actionRecognitionState) {
case (true, _):
    recordingStateView
        .id("recording")  // Stable identity
case (false, .recognizing):
    analyzingStateView
        .id("recognizing")
// ...
}
```

#### 2. Audio Waveform Visualization

**Current:** You have on-device transcript display but no visual audio level feedback.

**Recommendation:** Add real-time waveform in `RecordingStateView`:

```swift
// Add to VoiceLogManager
@Published var audioLevel: CGFloat = 0.0
private var meterTimer: Timer?

func startMetering() {
    audioRecorder?.isMeteringEnabled = true
    meterTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
        self?.updateMeters()
    }
}

func updateMeters() {
    audioRecorder?.updateMeters()
    let avgPower = audioRecorder?.averagePower(forChannel: 0) ?? -160
    audioLevel = normalizePower(avgPower)
}

private func normalizePower(_ power: Float) -> CGFloat {
    max(0, (CGFloat(power) + 70) / 70)  // -70dB to 0dB → 0.0 to 1.0
}
```

Then in `recordingStateView`:
```swift
// Add visual indicator
HStack(spacing: 2) {
    ForEach(0..<30, id: \.self) { index in
        RoundedRectangle(cornerRadius: 2)
            .fill(audioLevel > CGFloat(index) / 30 ? Color.red : Color.red.opacity(0.2))
            .frame(width: 4, height: barHeight(for: index))
    }
}
.frame(height: 40)
```

#### 3. Accessibility Enhancements

**Current:** Basic accessibility but room for improvement.

**Add to FloatingMicButton:**
```swift
// In MainTabView floating mic button
.accessibilityLabel(voiceLogManager.isRecording ? "Stop recording" : "Start voice command")
.accessibilityHint(voiceLogManager.isRecording
    ? "Double tap to stop recording"
    : "Double tap to record a voice command for logging food or water")
.accessibilityAddTraits(voiceLogManager.isRecording ? [.isButton, .startsMediaSession] : .isButton)
```

**Add live region announcements:**
```swift
// In VoiceLogManager
func announceStateChange(_ newState: ActionRecognitionState) {
    let message: String
    switch newState {
    case .idle:
        message = "Voice command ready"
    case .recognizing:
        message = "Analyzing your voice command"
    case .executing:
        message = "Creating log entries"
    case .completed:
        message = "Successfully logged \(executedActions.count) items"
    }

    UIAccessibility.post(notification: .announcement, argument: message)
}
```

#### 4. Error State Improvements

**Current:** You have basic error handling but could be more user-friendly.

**Enhance API Key Error Banner:**
```swift
// Current banner is good, but add action
struct APIKeyErrorBanner: View {
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void  // NEW

    var body: some View {
        HStack(spacing: 12) {
            // ... existing content ...

            VStack(spacing: 8) {
                Button("Open Settings") {
                    onOpenSettings()
                }
                .buttonStyle(.borderedProminent)

                Button("Dismiss") {
                    onDismiss()
                }
                .font(.caption)
            }
        }
        // ... existing styling ...
    }
}
```

#### 5. Reduce Transparency Support

**Add to drawer background:**
```swift
// In MainTabView, add environment variable
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

// Update voiceFlowDrawer background
.background(
    RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(reduceTransparency
            ? AnyShapeStyle(Color(.systemBackground))
            : AnyShapeStyle(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.15), radius: 24, y: -8)
)
```

---

## Priority Implementation Checklist

### High Priority (Address Flickering & Core UX)

- [ ] **Fix drawer flickering** - Stabilize view hierarchy with switch statement and .id() modifiers
- [ ] **Add audio level visualization** - Implement real-time waveform bars
- [ ] **Enhance accessibility labels** - Add descriptive labels and hints to all interactive elements
- [ ] **Support Reduce Transparency** - Provide solid background fallback

### Medium Priority (Polish & Features)

- [ ] **Improve error messaging** - More specific error messages with recovery actions
- [ ] **Add VoiceOver announcements** - Live state change announcements
- [ ] **Optimize animations** - Ensure smooth 60fps during state transitions
- [ ] **Add haptic variety** - Different patterns for success vs error vs recording

### Low Priority (Nice to Have)

- [ ] **Waveform polish** - Add color gradients (blue→orange→red based on level)
- [ ] **Sound effects** - Subtle audio cues for state changes (optional)
- [ ] **Recording timer** - Show elapsed time during recording
- [ ] **Transcript history** - Show previous transcriptions in drawer

---

## Specific Code Changes

### File: `MainTabView.swift`

#### Change 1: Fix Flickering (Lines 186-196)
```swift
// BEFORE (current)
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

// AFTER (recommended)
ZStack {
    switch drawerContentType {
    case .recording:
        recordingStateView
    case .analyzing:
        analyzingStateView
    case .executing:
        executingStateView
    case .completed:
        completedStateView
    }
}
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: drawerContentType)

private var drawerContentType: DrawerContentType {
    if voiceLogManager.isRecording {
        return .recording
    } else if voiceLogManager.actionRecognitionState == .recognizing {
        return .analyzing
    } else if voiceLogManager.actionRecognitionState == .executing {
        return .executing
    } else {
        return .completed
    }
}

enum DrawerContentType {
    case recording, analyzing, executing, completed
}
```

#### Change 2: Add Audio Visualization to Recording State (Lines 215-256)

Add after line 241 (after "Tap stop when finished"):
```swift
// Audio level visualization
GeometryReader { geometry in
    HStack(spacing: 2) {
        ForEach(0..<30, id: \.self) { index in
            RoundedRectangle(cornerRadius: 2)
                .fill(barColor(for: index, voiceLogManager.audioLevel))
                .frame(
                    width: (geometry.size.width / 30) - 2,
                    height: barHeight(for: index, voiceLogManager.audioLevel)
                )
        }
    }
}
.frame(height: 32)
.padding(.vertical, 8)

private func barHeight(for index: Int, level: CGFloat) -> CGFloat {
    let normalizedIndex = CGFloat(index) / 30.0
    let distance = abs(normalizedIndex - 0.5) * 2
    return 4 + (28 * level * (1 - distance))
}

private func barColor(for index: Int, _ level: CGFloat) -> Color {
    let active = CGFloat(index) / 30.0 < level
    return active ? .red : .red.opacity(0.15)
}
```

### File: `VoiceLogManager.swift`

#### Add Audio Metering Properties
```swift
// Add to VoiceLogManager class
@Published var audioLevel: CGFloat = 0.0
private var meterTimer: Timer?

func startRecording() {
    // ... existing setup ...

    audioRecorder?.isMeteringEnabled = true

    // Start metering
    startAudioLevelMonitoring()
}

func stopRecording() {
    stopAudioLevelMonitoring()
    // ... existing logic ...
}

private func startAudioLevelMonitoring() {
    meterTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
        self?.updateAudioLevel()
    }
}

private func stopAudioLevelMonitoring() {
    meterTimer?.invalidate()
    meterTimer = nil
    audioLevel = 0.0
}

private func updateAudioLevel() {
    guard let recorder = audioRecorder else { return }

    recorder.updateMeters()
    let avgPower = recorder.averagePower(forChannel: 0)

    // Normalize -160dB to 0dB → 0.0 to 1.0
    let normalized = max(0, min(1, (avgPower + 70) / 70))

    // Smooth the transition
    DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.audioLevel = self.audioLevel * 0.7 + CGFloat(normalized) * 0.3
    }
}
```

---

## Testing Checklist

### Visual Testing
- [ ] Test with Reduce Transparency ON
- [ ] Test with all Dynamic Type sizes (especially accessibility sizes)
- [ ] Test in Light and Dark mode
- [ ] Test on iPhone SE (small screen)
- [ ] Test on iPhone 16 Pro Max (large screen)

### Accessibility Testing
- [ ] VoiceOver - Navigate entire voice flow
- [ ] VoiceOver - Verify all state changes are announced
- [ ] VoiceOver - Ensure transcript is readable
- [ ] Voice Control - Can trigger recording hands-free
- [ ] Switch Control - Can operate all controls
- [ ] Reduce Motion - Animations are minimal/disabled

### Functional Testing
- [ ] Start recording → Stop → Verify no flicker
- [ ] Recording → Processing → Completed flow
- [ ] Error handling (no API key, no permission, etc.)
- [ ] Background audio interruption (phone call during recording)
- [ ] Multiple quick taps (verify no duplicate recordings)
- [ ] Very quiet audio input
- [ ] Very loud audio input

---

## Performance Metrics

Target frame rates:
- **Idle → Recording transition:** 60fps
- **During recording with waveform:** 30-60fps (acceptable)
- **Processing → Completed:** 60fps

Memory:
- **Voice recording session:** < 50MB additional memory
- **No memory leaks** after 10 recording cycles

---

## Next Steps

1. **Immediate (This Week)**
   - Fix flickering issue with stable view hierarchy
   - Add Reduce Transparency support
   - Improve accessibility labels

2. **Short Term (Next Sprint)**
   - Implement audio level visualization
   - Add VoiceOver state announcements
   - Enhance error messaging with actions

3. **Future Enhancements**
   - iOS 26 AirPods high-quality recording
   - Input device selection UI
   - Recording timer
   - Waveform color gradients

---

## Additional Resources

See the full best practices document:
`/Users/benjaminshafii/preg-app/docs/ios26-voice-recording-ui-best-practices-2025-10-14.md`

For specific code examples and in-depth explanations of:
- Liquid Glass design patterns
- Advanced animations
- Complete accessibility implementation
- Error handling strategies
- iOS 26 audio API usage

---

**Document Version:** 1.0
**Last Updated:** October 14, 2025
**Author:** iOS 26 UI Research Specialist
