# iOS 26 Voice Recording UI Best Practices for SwiftUI Apps

**Research Date:** October 14, 2025
**Context:** Hydration/Nutrition Tracking App with Voice Logging Functionality
**Target Platform:** iOS 26+ with Liquid Glass Design System

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [iOS 26 Liquid Glass Design Language](#ios-26-liquid-glass-design-language)
3. [Voice Recording UI Patterns](#voice-recording-ui-patterns)
4. [Visual Feedback Systems](#visual-feedback-systems)
5. [Gesture Patterns and Interactions](#gesture-patterns-and-interactions)
6. [Animation Best Practices](#animation-best-practices)
7. [Accessibility Guidelines](#accessibility-guidelines)
8. [Error State Handling](#error-state-handling)
9. [Audio Enhancements in iOS 26](#audio-enhancements-in-ios-26)
10. [Implementation Guidelines](#implementation-guidelines)
11. [Common Pitfalls and Solutions](#common-pitfalls-and-solutions)
12. [Code Examples](#code-examples)
13. [Resources](#resources)

---

## Executive Summary

### Key Findings

iOS 26 introduces the **Liquid Glass design language**, representing Apple's most significant visual overhaul in years. This research documents best practices for implementing voice recording interfaces that align with iOS 26's design philosophy while maintaining accessibility and usability.

### Critical Recommendations

1. **Adopt Liquid Glass for modals and drawers** - Use `.ultraThinMaterial` with continuous corner radius (28pt recommended)
2. **Implement bottom-sheet drawers** for voice recording instead of full-screen modals
3. **Provide real-time visual feedback** through waveforms, animations, and state indicators
4. **Use tap-to-toggle** pattern (not hold-to-record) for better accessibility
5. **Leverage iOS 26 audio APIs** including high-quality AirPods recording and spatial audio capture
6. **Design for VoiceOver** from the start with proper accessibility labels and dynamic type support
7. **Handle state transitions smoothly** using spring animations with proper dampening
8. **Avoid flickering** by maintaining stable view hierarchies and using `.id()` modifiers strategically

---

## iOS 26 Liquid Glass Design Language

### Overview

Liquid Glass is Apple's new design foundation that combines optical glass qualities with fluidity. Elements appear translucent, reflect/refract underlying content, and dynamically transform to bring focus to user content.

### Core Principles

1. **Translucency and Depth** - UI elements use blur and transparency to create depth
2. **Dynamic Transformation** - Elements morph fluidly based on context and user interaction
3. **Content Primacy** - Navigation and controls recede while content takes center stage
4. **Continuous Corners** - Larger corner radii (16-28pt) with continuous curves

### Material Hierarchy

```swift
// Primary materials for voice UI
.ultraThinMaterial     // Drawer backgrounds, overlays
.thinMaterial          // Secondary surfaces
.regularMaterial       // Emphasized surfaces
```

### Design Tokens for Voice UI

| Element | Corner Radius | Material | Shadow |
|---------|---------------|----------|---------|
| Drawer/Modal | 28pt (continuous) | `.ultraThinMaterial` | Y: -8, Blur: 24, Opacity: 0.15 |
| Action Cards | 12pt | Color opacity 0.06-0.15 | Y: 1, Blur: 3, Opacity: 0.05 |
| Buttons | 12pt | Solid or material | Y: 2, Blur: 4, Opacity: 0.1 |
| Status Pills | 20pt (capsule) | Color opacity 0.15 | None |

### Critical Accessibility Note

**Warning:** Liquid Glass poses readability challenges. Apple's HIG mandates:
- Minimum contrast ratio: **4.5:1** (WCAG AA)
- Text on glass must use `.primary` or `.secondary` semantic colors
- Support "Reduce Transparency" accessibility setting
- Test with Dynamic Type at all sizes

---

## Voice Recording UI Patterns

### iOS 26 Recommended Pattern: Bottom Sheet Drawer

Apple's HIG recommends **bottom sheet drawers** for voice interfaces rather than full-screen modals or floating panels.

#### Advantages

1. **Context Preservation** - Users see underlying content
2. **One-handed Reachability** - Bottom placement accessible with thumb
3. **Fluid Transitions** - Morphs from button to drawer seamlessly
4. **Gesture Friendly** - Can be dismissed with swipe-down
5. **Liquid Glass Native** - Designed for material-based UI

#### Drawer Specifications

```swift
// iOS 26 optimized drawer structure
VStack(spacing: 0) {
    // Drag handle - iOS 26 standard
    Capsule()
        .fill(.tertiary)
        .frame(width: 36, height: 5)
        .padding(.top, 12)
        .padding(.bottom, 8)

    // Content area
    drawerContent
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
```

### Alternative Pattern: Floating Action Button (FAB)

For persistent access, use a floating microphone button that triggers the drawer.

#### FAB Specifications

- **Size:** 56x56pt (standard) or 64x64pt (emphasized)
- **Position:** Bottom-trailing, 20pt from edge, 90pt from bottom (above tab bar)
- **Material:** Solid color or gradient (not glass for tap targets)
- **Icon:** SF Symbol `mic.fill` at 20-24pt
- **States:** Idle, Recording, Processing
- **Shadow:** Prominent (y: 4-8, blur: 12-16)

---

## Visual Feedback Systems

### State-Based Visual Hierarchy

Voice recording has distinct states requiring different visual treatments:

| State | Primary Color | Icon | Background Treatment |
|-------|--------------|------|---------------------|
| **Idle** | `.blue` | `mic.fill` | Solid or gradient |
| **Recording** | `.red` | `waveform` or `stop.fill` | Pulsing animation |
| **Processing** | `.blue` or `.purple` | `sparkles` | Progress indicator |
| **Transcribing** | `.green` | `checkmark` | Subtle animation |
| **Completed** | `.green` | `checkmark.circle.fill` | Success state |
| **Error** | `.orange` or `.red` | `exclamationmark.triangle.fill` | Alert state |

### Audio Level Visualization

iOS 26 introduces enhanced audio visualization capabilities:

#### Real-time Waveform Display

```swift
// Using AVAudioRecorder metering
func updateAudioLevel() {
    audioRecorder?.updateMeters()
    let averagePower = audioRecorder?.averagePower(forChannel: 0) ?? -160
    let normalizedLevel = normalizeSoundLevel(level: averagePower)

    // Update visual indicator
    audioLevel = normalizedLevel
}

func normalizeSoundLevel(level: Float) -> CGFloat {
    // Convert dB (-160 to 0) to 0.0-1.0 range
    let level = max(0.2, CGFloat(level) + 70) / 2
    return CGFloat(level * (40/35))
}
```

#### Waveform Bar Visualization

```swift
struct AudioWaveformView: View {
    let samples: [Float]
    let spacing: CGFloat = 2
    let barWidth: CGFloat = 3

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(Array(samples.enumerated()), id: \.offset) { _, magnitude in
                BarView(
                    value: normalizeSoundLevel(level: magnitude),
                    color: .blue
                )
            }
        }
    }
}

struct BarView: View {
    let value: CGFloat
    var color: Color = .blue

    var body: some View {
        Rectangle()
            .fill(color)
            .cornerRadius(2)
            .frame(width: 3, height: max(4, value))
    }
}
```

### Recording State Animations

#### Pulsing Ring Animation

```swift
@State private var pulseScale: CGFloat = 1.0

// Animated pulsing circles
ZStack {
    Circle()
        .stroke(Color.red.opacity(0.3), lineWidth: 2)
        .scaleEffect(pulseScale)
        .opacity(Double(2 - pulseScale))
        .animation(
            Animation.easeOut(duration: 1.2)
                .repeatForever(autoreverses: false),
            value: pulseScale
        )

    Circle()
        .stroke(Color.red.opacity(0.3), lineWidth: 2)
        .scaleEffect(pulseScale * 0.7)
        .opacity(Double(2 - pulseScale * 0.7))
        .animation(
            Animation.easeOut(duration: 1.2)
                .repeatForever(autoreverses: false)
                .delay(0.3),
            value: pulseScale
        )
}
.onAppear {
    pulseScale = 1.8
}
```

### Live Transcript Display

Show real-time transcription using on-device Speech Recognition:

```swift
if !liveTranscript.isEmpty && isRecording {
    VStack(spacing: 4) {
        HStack(spacing: 4) {
            Image(systemName: "waveform")
                .font(.caption2)
                .foregroundStyle(.blue)
            Text("Listening:")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Text("\"\(liveTranscript)\"")
            .font(.body)
            .foregroundStyle(.primary)
            .italic()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.08))
            )
            .multilineTextAlignment(.leading)
    }
    .transition(.opacity.combined(with: .move(edge: .top)))
}
```

---

## Gesture Patterns and Interactions

### Tap vs Hold Patterns

#### Recommendation: Tap-to-Toggle

**Use tap-to-toggle for iOS 26 voice recording:**

**Advantages:**
- More accessible (no sustained grip required)
- Works with Switch Control and Voice Control
- Supports longer recordings without fatigue
- Clearer state indication (separate start/stop)
- Better for users with motor impairments

**Implementation:**
```swift
Button(action: toggleRecording) {
    ZStack {
        Circle()
            .fill(isRecording ? Color.red : Color.blue)
            .frame(width: 64, height: 64)

        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(.white)
    }
}
.scaleEffect(isRecording ? 1.1 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
```

#### When to Use Hold-to-Record

Hold-to-record is appropriate for:
- Quick voice messages (< 10 seconds)
- Voice memo apps with short snippets
- Walkie-talkie style communication

### Haptic Feedback

iOS 26 emphasizes appropriate haptic feedback for state changes:

```swift
// Start recording
let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
impactFeedback.impactOccurred()

// Stop recording
let impactFeedback = UIImpactFeedbackGenerator(style: .light)
impactFeedback.impactOccurred()

// Error state
let notificationFeedback = UINotificationFeedbackGenerator()
notificationFeedback.notificationOccurred(.error)

// Success state
let notificationFeedback = UINotificationFeedbackGenerator()
notificationFeedback.notificationOccurred(.success)
```

### Drawer Dismissal

Support multiple dismissal methods:

1. **Swipe down** on drag handle
2. **Tap "Done" button** explicitly
3. **Automatic dismissal** after completion (with delay)
4. **Tap outside** (optional, may be disruptive)

```swift
.gesture(
    DragGesture()
        .onEnded { value in
            if value.translation.height > 100 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    dismiss()
                }
            }
        }
)
```

---

## Animation Best Practices

### iOS 26 Spring Animations

Apple's new animation system emphasizes spring-based physics for natural motion:

```swift
// Recommended spring parameters for voice UI
.spring(response: 0.4, dampingFraction: 0.8)  // Standard transitions
.spring(response: 0.3, dampingFraction: 0.6)  // Quick feedback
.spring(response: 0.5, dampingFraction: 0.9)  // Smooth, subtle
```

### State Transition Animations

```swift
// Drawer appearance
.transition(.move(edge: .bottom).combined(with: .opacity))
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldShowDrawer)

// Content state changes
.transition(.asymmetric(
    insertion: .move(edge: .top).combined(with: .opacity),
    removal: .move(edge: .top).combined(with: .opacity)
))

// Scale + opacity for cards
.transition(.scale.combined(with: .opacity))
```

### Symbol Effects (iOS 26)

```swift
// Pulse effect for active state
Image(systemName: "waveform")
    .symbolEffect(.pulse, isActive: isRecording)

// Bounce on appearance
Image(systemName: "checkmark.circle.fill")
    .symbolEffect(.bounce, value: showSuccess)

// Variable color effect
Image(systemName: "mic.fill")
    .symbolEffect(.variableColor, isActive: isRecording)
```

### Performance Considerations

**Anti-pattern - Causes Flickering:**
```swift
// DON'T: Rebuild entire view hierarchy on state changes
if someState {
    CompletelyDifferentView()
} else {
    AnotherCompletelyDifferentView()
}
```

**Best Practice - Stable Hierarchy:**
```swift
// DO: Maintain stable hierarchy, toggle content
VStack {
    // Always present, content changes
    ContentView(state: currentState)
        .id(currentState) // Only when complete rebuild needed
}
```

---

## Accessibility Guidelines

### VoiceOver Support

#### Essential Accessibility Modifiers

```swift
Button(action: toggleRecording) {
    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
}
.accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
.accessibilityHint(isRecording
    ? "Double tap to stop voice recording"
    : "Double tap to begin voice recording")
.accessibilityAddTraits(isRecording ? [.isButton, .startsMediaSession] : .isButton)
```

#### Live Region Announcements

```swift
// Announce state changes to VoiceOver
@State private var accessibilityAnnouncement = ""

func announceToVoiceOver(_ message: String) {
    accessibilityAnnouncement = message
}

// In view
.accessibilityElement(children: .contain)
.accessibilityLabel(accessibilityAnnouncement)
.onChange(of: recordingState) { oldValue, newValue in
    switch newValue {
    case .recording:
        announceToVoiceOver("Recording started")
    case .processing:
        announceToVoiceOver("Processing voice input")
    case .completed:
        announceToVoiceOver("Voice command completed successfully")
    }
}
```

#### Accessibility Traits for States

```swift
// Recording state
.accessibilityAddTraits([.updatesFrequently])

// Processing state
.accessibilityAddTraits([.isStaticText])
.accessibilityLabel("Processing: \(processingStatus)")

// Live transcript
.accessibilityLabel("Live transcript: \(transcript)")
.accessibilityAddTraits([.updatesFrequently])
```

### Dynamic Type Support

```swift
// Use scaled fonts
.font(.body)  // Scales automatically
.font(.headline)
.font(.caption)

// For custom sizes
@ScaledMetric(relativeTo: .body) var customSize: CGFloat = 16

// Layout adjustments
@Environment(\.sizeCategory) var sizeCategory

var isAccessibilitySize: Bool {
    sizeCategory >= .accessibilityMedium
}

// Adjust layout for large text
if isAccessibilitySize {
    VStack { /* Vertical layout */ }
} else {
    HStack { /* Horizontal layout */ }
}
```

### Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion ? .linear(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)
}

// Conditional animations
.animation(reduceMotion ? .none : .spring(), value: someState)
```

### Reduce Transparency

Liquid Glass requires fallback for reduced transparency:

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

var drawerBackground: some ShapeStyle {
    if reduceTransparency {
        return AnyShapeStyle(Color(.systemBackground))
    } else {
        return AnyShapeStyle(.ultraThinMaterial)
    }
}

// Usage
.background(
    RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(drawerBackground)
)
```

### Color Contrast

```swift
// Always use semantic colors
.foregroundStyle(.primary)     // High contrast
.foregroundStyle(.secondary)   // Medium contrast
.foregroundStyle(.tertiary)    // Low contrast (use sparingly)

// Avoid custom colors on glass backgrounds
// If custom colors needed, ensure 4.5:1 ratio minimum
```

---

## Error State Handling

### Error Categories

1. **Configuration Errors** - Missing API key, permissions
2. **Runtime Errors** - Recording failure, network issues
3. **Transcription Errors** - Unclear audio, API failures
4. **Action Recognition Errors** - Ambiguous commands

### Error Presentation Patterns

#### In-Context Banners

```swift
struct ErrorBanner: View {
    let message: String
    let icon: String
    let action: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let action = action {
                Button("Fix") {
                    action()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}
```

#### Drawer Error States

```swift
// Show error in drawer with retry option
VStack(spacing: 16) {
    Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 40))
        .foregroundStyle(.orange)

    Text("Could not process voice input")
        .font(.headline)

    Text(errorMessage)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

    HStack(spacing: 12) {
        Button("Try Again") {
            retryRecording()
        }
        .buttonStyle(.borderedProminent)

        Button("Cancel") {
            dismiss()
        }
        .buttonStyle(.bordered)
    }
}
```

### Permission Handling

```swift
func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async {
            if !granted {
                showPermissionError = true
            }
            completion(granted)
        }
    }
}

// Permission error view
if showPermissionError {
    VStack(spacing: 12) {
        Image(systemName: "mic.slash.fill")
            .font(.system(size: 40))
            .foregroundStyle(.orange)

        Text("Microphone Access Required")
            .font(.headline)

        Text("Please enable microphone access in Settings to use voice commands.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

        Button("Open Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        .buttonStyle(.borderedProminent)
    }
}
```

### API Key Validation

```swift
// Pre-flight check before recording
func validateConfiguration() -> Bool {
    guard hasAPIKey else {
        showError("API Key Required",
                  "Voice features require an OpenAI API key. Add it in Settings.")
        return false
    }

    guard hasMicrophonePermission else {
        requestMicrophonePermission { granted in
            if !granted {
                showError("Microphone Access Denied",
                          "Enable microphone access in Settings.")
            }
        }
        return false
    }

    return true
}
```

### Graceful Degradation

```swift
// Fallback for failed transcription
if let transcription = transcription {
    processTranscription(transcription)
} else {
    // Still create log entry with basic info
    createManualLogEntry(
        notes: "Voice log (transcription failed)",
        timestamp: Date()
    )

    showNotification("Voice logged, but transcription failed. You can edit details later.")
}
```

---

## Audio Enhancements in iOS 26

### High-Quality AirPods Recording

iOS 26 introduces high-quality Bluetooth recording for AirPods:

```swift
// Enable high-quality AirPods recording
let session = AVAudioSession.sharedInstance()
try session.setCategory(
    .record,
    mode: .default,
    options: [.bluetoothHighQualityRecording]  // iOS 26+
)
try session.setActive(true)
```

**Benefits:**
- Professional-grade audio capture via Bluetooth
- LAV microphone-quality performance
- Automatic fallback to standard BluetoothHFP when unavailable
- Content creator media tuning

### Input Device Selection

iOS 26 allows in-app audio device selection:

```swift
import AVKit

class AudioInputManager {
    private let inputPickerInteraction = AVInputPickerInteraction()

    func setupInputPicker(for button: UIButton) {
        // Configure after setting up AudioSession
        inputPickerInteraction.delegate = self
        button.addInteraction(inputPickerInteraction)
    }

    func presentInputPicker() {
        inputPickerInteraction.present()
    }
}

// SwiftUI integration
struct InputPickerButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        let interaction = AVInputPickerInteraction()
        button.addInteraction(interaction)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {}
}
```

### Spatial Audio Capture

For advanced use cases (recording environments, immersive experiences):

```swift
// Configure spatial audio capture
let session = AVAudioSession.sharedInstance()
try session.setCategory(.record, mode: .videoRecording)
try session.setPreferredInputOrientation(.portrait)
try session.setActive(true)

// Check if spatial audio capture is available
if session.availableInputs?.contains(where: {
    $0.supportsSpatialAudio
}) == true {
    // Enable spatial audio recording
}
```

### Audio Level Metering

Real-time audio level monitoring:

```swift
class AudioRecorderManager: NSObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    var meterTimer: Timer?
    @Published var audioLevel: Float = 0.0

    func startRecording() {
        // ... setup recorder ...

        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        // Update meters 30 times per second
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
            self?.updateMeters()
        }
    }

    func updateMeters() {
        audioRecorder?.updateMeters()
        let averagePower = audioRecorder?.averagePower(forChannel: 0) ?? -160
        let peakPower = audioRecorder?.peakPower(forChannel: 0) ?? -160

        audioLevel = averagePower
    }
}
```

---

## Implementation Guidelines

### Recommended Architecture

```
VoiceRecordingModule/
├── Views/
│   ├── VoiceRecordingDrawer.swift       // Main drawer UI
│   ├── FloatingMicButton.swift          // FAB trigger
│   ├── RecordingStateView.swift         // State-specific content
│   └── AudioWaveformView.swift          // Visual feedback
├── Managers/
│   ├── VoiceRecordingManager.swift      // Recording logic
│   ├── AudioSessionManager.swift        // AVAudioSession handling
│   ├── TranscriptionManager.swift       // Speech-to-text
│   └── AudioLevelMonitor.swift          // Metering
└── Models/
    ├── RecordingState.swift             // State enum
    ├── VoiceCommand.swift               // Parsed commands
    └── AudioConfiguration.swift         // Settings
```

### State Management

```swift
enum RecordingState: Equatable {
    case idle
    case recording
    case processing
    case transcribing
    case recognizing
    case executing
    case completed([VoiceAction])
    case error(RecordingError)

    var drawerHeight: CGFloat {
        switch self {
        case .idle: return 0
        case .recording: return 200
        case .processing: return 180
        case .completed: return 320
        case .error: return 240
        default: return 200
        }
    }
}

class VoiceRecordingViewModel: ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var liveTranscript: String = ""
    @Published var audioLevel: CGFloat = 0.0
    @Published var actions: [VoiceAction] = []

    func startRecording() {
        guard validateConfiguration() else { return }
        state = .recording
        // ... start recording logic ...
    }
}
```

### Integration with Dashboard

```swift
struct DashboardView: View {
    @StateObject private var voiceViewModel = VoiceRecordingViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            ScrollView {
                // Dashboard cards
            }

            // Voice drawer overlay
            if voiceViewModel.state != .idle {
                VoiceRecordingDrawer(viewModel: voiceViewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // FAB
            if voiceViewModel.state == .idle {
                FloatingMicButton {
                    voiceViewModel.startRecording()
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: voiceViewModel.state)
    }
}
```

---

## Common Pitfalls and Solutions

### 1. Flickering Drawers/Sheets

**Problem:** Drawer flickers or jumps during state transitions

**Causes:**
- Unstable view hierarchy (SwiftUI recreating views)
- Conditional view building with completely different types
- Multiple competing animations
- State updates during animation

**Solutions:**

```swift
// ❌ BAD: Unstable hierarchy
if isRecording {
    RecordingView()
} else if isProcessing {
    ProcessingView()
} else {
    IdleView()
}

// ✅ GOOD: Stable hierarchy
VStack {
    switch state {
    case .recording:
        recordingContent
    case .processing:
        processingContent
    case .idle:
        idleContent
    }
}
.animation(.spring(), value: state)  // Single animation binding

// ✅ BETTER: Use .id() when complete rebuild needed
ContentView(state: state)
    .id(state.stableIdentifier)
```

### 2. Sheet Presentation Issues

**Problem:** White flash or background flicker when presenting sheets

**Solutions:**

```swift
// Use presentationBackground modifier
.sheet(isPresented: $showSheet) {
    SheetContent()
        .presentationBackground {
            Color(.systemBackground)
                .ignoresSafeArea()
        }
}

// Or use .ultraThinMaterial
.presentationBackground(.ultraThinMaterial)

// Ensure background extends below safe area
ZStack {
    // Main content
}
.background {
    Color(.systemBackground)
        .ignoresSafeArea()
}
```

### 3. Audio Session Conflicts

**Problem:** Recording fails or stops unexpectedly

**Solutions:**

```swift
// Configure session properly
func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()

    do {
        // Set category before activating
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth]
        )

        // Activate session
        try session.setActive(true, options: .notifyOthersOnDeactivation)

    } catch {
        handleAudioSessionError(error)
    }
}

// Handle interruptions
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleAudioSessionInterruption),
    name: AVAudioSession.interruptionNotification,
    object: nil
)
```

### 4. Memory Leaks with Timers

**Problem:** Timer prevents deinitialization

**Solutions:**

```swift
class AudioMonitor {
    private var meterTimer: Timer?

    func startMonitoring() {
        meterTimer = Timer.scheduledTimer(
            withTimeInterval: 0.033,
            repeats: true
        ) { [weak self] _ in  // ← Weak capture
            self?.updateMeters()
        }
    }

    func stopMonitoring() {
        meterTimer?.invalidate()
        meterTimer = nil  // ← Clean up
    }

    deinit {
        stopMonitoring()
    }
}
```

### 5. Main Thread Blocking

**Problem:** UI freezes during transcription or processing

**Solutions:**

```swift
// ❌ BAD: Blocking main thread
func processAudio() {
    let transcription = transcribeAudio()  // Long operation
    updateUI(transcription)
}

// ✅ GOOD: Background processing
func processAudio() async {
    await MainActor.run {
        state = .processing
    }

    // Background work
    let transcription = await Task.detached {
        return transcribeAudio()
    }.value

    await MainActor.run {
        updateUI(transcription)
        state = .completed
    }
}
```

### 6. Accessibility Announcements Interrupting VoiceOver

**Problem:** Too many announcements during recording

**Solutions:**

```swift
// Throttle announcements
private var lastAnnouncementTime: Date?

func announceIfNeeded(_ message: String) {
    guard let lastTime = lastAnnouncementTime,
          Date().timeIntervalSince(lastTime) > 2.0 else {
        return
    }

    UIAccessibility.post(notification: .announcement, argument: message)
    lastAnnouncementTime = Date()
}

// Only announce significant state changes
func updateState(_ newState: RecordingState) {
    let oldState = state
    state = newState

    // Only announce major transitions
    if oldState != newState && shouldAnnounce(oldState, newState) {
        announceStateChange(newState)
    }
}
```

---

## Code Examples

### Complete Drawer Implementation

```swift
struct VoiceRecordingDrawer: View {
    @ObservedObject var viewModel: VoiceRecordingViewModel
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(.tertiary)
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // State-specific content
            drawerContent
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(drawerBackground)
        .padding(.horizontal, 16)
        .padding(.bottom, 90)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var drawerContent: some View {
        switch viewModel.state {
        case .recording:
            RecordingStateView(
                liveTranscript: viewModel.liveTranscript,
                audioLevel: viewModel.audioLevel,
                onStop: viewModel.stopRecording
            )
        case .processing:
            ProcessingStateView()
        case .completed(let actions):
            CompletedStateView(
                actions: actions,
                onDismiss: viewModel.reset,
                onRecordAnother: viewModel.startRecording
            )
        case .error(let error):
            ErrorStateView(
                error: error,
                onRetry: viewModel.retry,
                onDismiss: viewModel.reset
            )
        default:
            EmptyView()
        }
    }

    private var drawerBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(reduceTransparency
                ? AnyShapeStyle(Color(.systemBackground))
                : AnyShapeStyle(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.15), radius: 24, y: -8)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    .blendMode(.overlay)
            )
    }
}
```

### Floating Mic Button with States

```swift
struct FloatingMicButton: View {
    let isRecording: Bool
    let actionState: ActionState
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Pulsing background when recording
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseScale)
                        .opacity(2 - pulseScale)
                }

                // Main button
                Circle()
                    .fill(buttonColor)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

                // Icon
                Image(systemName: buttonIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor, isActive: isRecording)
            }
        }
        .scaleEffect(isRecording ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startPulse()
            } else {
                stopPulse()
            }
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint("Double tap to \(isRecording ? "stop" : "start") voice recording")
    }

    private var buttonColor: Color {
        if isRecording {
            return .red
        } else {
            return .blue
        }
    }

    private var buttonIcon: String {
        switch actionState {
        case .idle:
            return "mic.fill"
        case .recording:
            return "stop.fill"
        case .processing:
            return "waveform"
        default:
            return "mic.fill"
        }
    }

    private func startPulse() {
        withAnimation(
            .easeOut(duration: 1.2)
                .repeatForever(autoreverses: false)
        ) {
            pulseScale = 1.8
        }
    }

    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.0
        }
    }
}
```

### Recording State View with Waveform

```swift
struct RecordingStateView: View {
    let liveTranscript: String
    let audioLevel: CGFloat
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.red)
                        .symbolEffect(.variableColor.iterative.reversing, isActive: true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recording")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Speak naturally")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Stop button
                Button(action: onStop) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .accessibilityLabel("Stop recording")
            }

            // Audio level indicator
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(0..<30, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barColor(for: index, total: 30))
                            .frame(
                                width: (geometry.size.width / 30) - 2,
                                height: barHeight(for: index, level: audioLevel)
                            )
                    }
                }
            }
            .frame(height: 40)

            // Live transcript
            if !liveTranscript.isEmpty {
                Text(liveTranscript)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.red.opacity(0.08))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func barHeight(for index: Int, level: CGFloat) -> CGFloat {
        let normalizedIndex = CGFloat(index) / 30.0
        let distance = abs(normalizedIndex - 0.5) * 2
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 40

        return baseHeight + (maxHeight - baseHeight) * level * (1 - distance)
    }

    private func barColor(for index: Int, total: Int) -> Color {
        let position = Double(index) / Double(total)
        if position < 0.6 {
            return .blue
        } else if position < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}
```

---

## Resources

### Official Apple Documentation

1. **Human Interface Guidelines**
   - https://developer.apple.com/design/human-interface-guidelines/
   - Liquid Glass Design: https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass

2. **WWDC 2025 Sessions**
   - Session 251: "Enhance your app's audio recording capabilities"
   - Session 253: "Enhancing your camera experience with capture controls"
   - Session 319: "Capture cinematic video in your app"

3. **AVFoundation**
   - https://developer.apple.com/documentation/AVFoundation
   - Capturing Spatial Audio: https://developer.apple.com/documentation/AVFoundation/capturing-spatial-audio-in-your-ios-app

4. **Accessibility**
   - https://developer.apple.com/accessibility/
   - VoiceOver Best Practices: https://developer.apple.com/design/human-interface-guidelines/accessibility

### Design Resources

1. **iOS 26 UI Kit (Sketch)**
   - https://www.sketch.com/s/f63aa308-1f82-498c-8019-530f3b846db9/

2. **SF Symbols 7**
   - https://developer.apple.com/sf-symbols/
   - Download: SF Symbols app for macOS

3. **Liquid Glass Design Gallery**
   - https://liquidglassdesign.com/gallery/voice-recorder-2025

### Community Resources

1. **iOS 26 Design Evolution Discussion**
   - https://medium.com/@TheDistance/ios-26-is-coming-what-it-means-for-your-apps-future-988142aa8b27

2. **SwiftUI Animation Examples**
   - https://github.com/Asperi-Demo/4SwiftUI (Animation patterns)
   - https://github.com/jaywcjlove/swiftui-example (Transition examples)

3. **Audio Waveform Libraries**
   - https://github.com/dmrschmidt/DSWaveformImage (Waveform visualization)
   - https://github.com/juraskrlec/jswaveform (SwiftUI waveform)
   - https://github.com/bastienFalcou/SoundWave (Audio visualization)

### Technical Articles

1. **iOS 26 Accessibility Features**
   - AppleVis Podcast: https://www.applevis.com/podcasts/what-s-new-ios-26-accessibility

2. **Liquid Glass UI Implementation**
   - https://letsdev.de/en/blog/iOS-26-in-detail-liquid-glass-UI-between-usability-and-accessibility

3. **SwiftUI Performance Best Practices**
   - https://www.dhiwise.com/blog/design-converter/swiftui-transitions-made-simple-for-intuitive-apps

4. **Error Handling in iOS Apps**
   - https://moldstud.com/articles/p-effective-strategies-for-handling-api-errors-in-your-xcode-app

---

## Conclusion

iOS 26's Liquid Glass design language represents a significant shift toward translucent, fluid interfaces that prioritize content over chrome. For voice recording interfaces, this translates to:

1. **Bottom-drawer patterns** that preserve context and accessibility
2. **Material-based backgrounds** that create depth without obscuring content
3. **Smooth spring animations** that feel natural and responsive
4. **Real-time visual feedback** through waveforms and state indicators
5. **Comprehensive accessibility** including VoiceOver, Dynamic Type, and reduced motion
6. **Robust error handling** with clear user communication
7. **Enhanced audio capabilities** leveraging iOS 26's new APIs

The key to success is balancing the aesthetic appeal of Liquid Glass with the functional requirements of accessibility, performance, and user clarity. Always test with:
- VoiceOver enabled
- Largest Dynamic Type sizes
- Reduce Transparency enabled
- Reduce Motion enabled
- Various device sizes (iPhone SE to Pro Max)

By following these guidelines, your voice recording interface will feel native to iOS 26 while remaining accessible and performant for all users.

---

**Document Version:** 1.0
**Last Updated:** October 14, 2025
**Next Review:** When iOS 27 beta releases
