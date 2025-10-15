# iOS 26 Compact Pill UI: Loading Indicators and Dynamic Height Best Practices

**Research Date:** October 14, 2025
**Component:** VoiceCompactPill (Liquid Glass Design)
**Issues Addressed:**
1. Double loading spinner overlay when pausing
2. Text overflow truncation instead of vertical pill growth

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Root Cause Analysis: Double Spinner Issue](#root-cause-analysis-double-spinner-issue)
3. [iOS 26 Best Practices: Loading Indicators](#ios-26-best-practices-loading-indicators)
4. [iOS 26 Best Practices: Dynamic Height Pills](#ios-26-best-practices-dynamic-height-pills)
5. [Implementation Recommendations](#implementation-recommendations)
6. [Code Fixes](#code-fixes)
7. [iOS 26 Liquid Glass Design Principles](#ios-26-liquid-glass-design-principles)
8. [Resources](#resources)

---

## Executive Summary

**Key Findings:**
- The double spinner issue is caused by **non-mutually-exclusive state conditions** in the `trailingContent` ViewBuilder
- Both `.recognizing` and `.executing` states show identical ProgressViews without proper state transitions
- Current implementation uses `.lineLimit(1)` which truncates text instead of allowing vertical growth
- iOS 26 Liquid Glass design emphasizes **dynamic adaptivity** - UI should fluidly morph based on content needs

**Critical Recommendations:**
1. Use mutually exclusive state handling or combine similar loading states
2. Remove `.lineLimit(1)` constraint on subtitle text
3. Add `.fixedSize(horizontal: false, vertical: true)` to allow vertical expansion
4. Consider using a single, persistent ProgressView with state-aware styling
5. Leverage iOS 26's dynamic toolbar/navigation patterns that expand based on content

---

## Root Cause Analysis: Double Spinner Issue

### Current Implementation Problem

Located in `/Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder/VoiceCompactPill.swift` (lines 72-88):

```swift
@ViewBuilder
private var trailingContent: some View {
    if voiceLogManager.actionRecognitionState == .recognizing {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
            .scaleEffect(0.9)
    } else if voiceLogManager.actionRecognitionState == .executing {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
            .scaleEffect(0.9)
    } else if voiceLogManager.actionRecognitionState == .completed {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.green)
    }
}
```

### Why Double Spinners Occur

**State Transition Flow Analysis:**

From `VoiceLogManager.swift` line 150-252 (`stopRecording()` function):
1. User clicks pause while recording
2. `isRecording = false` (line 163)
3. **State immediately set to `.recognizing`** (line 213)
4. Async task begins processing
5. State transitions through: `.recognizing` → `.executing` → `.completed`

**The Problem:**
- When transitioning from `.recognizing` to `.executing`, SwiftUI may briefly render **both** ProgressViews due to:
  - Animation timing overlaps
  - View identity not being properly managed
  - No explicit removal of previous view before adding new one
  - Both conditions rendering identical views (same ProgressView style)

### Research-Backed Explanation

From **Stack Overflow** (SwiftUI ProgressView in List can only be displayed once):
> Multiple ProgressView instances can overlay if view identity is not properly managed. The solution is to use `.id(UUID())` or ensure mutually exclusive state conditions.

**Key Issue:** The `@ViewBuilder` is rendering two separate ProgressView instances that are visually identical but have different view identities. During state transitions, both may briefly exist in the view hierarchy.

---

## iOS 26 Best Practices: Loading Indicators

### 1. Single, Persistent Loading View Pattern

**Best Practice:** Use a single ProgressView that adapts styling based on state, rather than creating new instances per state.

```swift
// RECOMMENDED: Single view with state-driven styling
@ViewBuilder
private var trailingContent: some View {
    switch voiceLogManager.actionRecognitionState {
    case .recognizing, .executing:
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
            .scaleEffect(0.9)
            .id("loading-indicator") // Stable identity
    case .completed:
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.green)
            .transition(.scale.combined(with: .opacity))
    case .idle:
        EmptyView()
    }
}
```

**Why this works:**
- Combines `.recognizing` and `.executing` into a single loading state
- Uses `switch` statement for truly mutually exclusive conditions
- Provides stable view identity with `.id()` modifier
- Prevents multiple ProgressView instances from existing simultaneously

### 2. iOS 26 Loading State Transitions

**Apple's WWDC 2025 Session 219 - "Meet Liquid Glass":**
> "Liquid Glass components should dynamically transform to help bring greater focus to your content. Transitions between states should be fluid and seamless, avoiding abrupt changes that disrupt the user experience."

**Implementation Pattern:**
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: actionRecognitionState)
```

### 3. Prevent Duplicate ProgressView Rendering

**Technique 1: Explicit View Identity**
```swift
ProgressView()
    .id(UUID()) // Forces SwiftUI to treat each render as unique
```

**Technique 2: State Consolidation** (Recommended)
```swift
var isProcessing: Bool {
    voiceLogManager.actionRecognitionState == .recognizing ||
    voiceLogManager.actionRecognitionState == .executing
}

if isProcessing {
    ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
}
```

---

## iOS 26 Best Practices: Dynamic Height Pills

### Current Text Overflow Issue

Located in `VoiceCompactPill.swift` lines 19-24:

```swift
if let subtitle = statusSubtitle {
    Text(subtitle)
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(1)  // ❌ PROBLEM: Truncates text
}
```

**Issue:** `.lineLimit(1)` forces text truncation with ellipsis ("...") instead of allowing the pill to grow vertically.

### iOS 26 Dynamic Adaptivity Principle

**From Apple's iOS 26 Feature Documentation:**
> "**Dynamic tools & navigation**: Liquid Glass toolbars and navigation across apps like Mail, Notes, Messages and more bring more focus to your content, and **fluidly morph as you need access to more tools** or move through different views of your app."

**Key Principle:** iOS 26 UI components should **expand and contract** based on content requirements, not impose fixed constraints.

### Research-Backed Solutions

#### Solution 1: Remove Line Limit + Fixed Size (Recommended)

From **"The magic of fixed size modifier in SwiftUI"** (swiftwithmajid.com):
> "The `fixedSize(horizontal: false, vertical: true)` modifier tells SwiftUI to respect the view's ideal size in the vertical axis while allowing horizontal flexibility."

```swift
if let subtitle = statusSubtitle {
    Text(subtitle)
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(nil) // Allow unlimited lines
        .fixedSize(horizontal: false, vertical: true) // Expand vertically
}
```

**Why this works:**
- Removes artificial line limit
- Allows text to wrap naturally across multiple lines
- Pill height automatically adjusts to accommodate content
- Maintains horizontal constraints (pill doesn't expand width)

#### Solution 2: Conditional Line Limit with Dynamic Height

For cases where you want to limit extremely long text:

```swift
if let subtitle = statusSubtitle {
    Text(subtitle)
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(3) // Max 3 lines instead of 1
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
}
```

#### Solution 3: GeometryReader-Based Dynamic Height (Advanced)

From **"Dynamic Adjustment of Bottom Sheet Height in SwiftUI Based on Content inside"**:

```swift
@State private var contentHeight: CGFloat = 0

var body: some View {
    HStack(spacing: 12) {
        // ... existing content ...
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
        GeometryReader { geometry in
            Color.clear
                .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    )
    .onPreferenceChange(HeightPreferenceKey.self) { height in
        contentHeight = height
    }
    // ... rest of styling
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

**Note:** This is overkill for a simple pill component. Use Solution 1 instead.

### iOS 26 Liquid Glass Material Considerations

**ultraThinMaterial with Dynamic Height:**
- `.ultraThinMaterial` adapts to any size container
- No special considerations needed for height changes
- Shadow and border overlays automatically adjust to new frame
- **Important:** Use `.continuous` corner radius style (already implemented) for fluid Liquid Glass aesthetic

```swift
.background(
    RoundedRectangle(cornerRadius: 20, style: .continuous) // ✅ Correct
        .fill(.ultraThinMaterial)
        // ... shadows and overlays
)
```

---

## Implementation Recommendations

### Priority 1: Fix Double Spinner Issue

**Action:** Consolidate `.recognizing` and `.executing` states into a single loading indicator.

**Rationale:**
- Both states perform the same visual function: "processing in progress"
- Users don't need to distinguish between AI analysis and action execution
- Eliminates possibility of overlapping ProgressViews
- Simplifies state management

### Priority 2: Enable Vertical Text Growth

**Action:** Remove `.lineLimit(1)` and add `.fixedSize(horizontal: false, vertical: true)`

**Rationale:**
- Aligns with iOS 26's dynamic adaptivity principles
- Prevents loss of important transcription/status information
- Improves accessibility (users can read full content)
- Maintains visual consistency with Liquid Glass design language

### Priority 3: Smooth Transitions

**Action:** Add explicit transitions for state changes

```swift
.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .opacity
))
.animation(.spring(response: 0.35, dampingFraction: 0.75), value: actionRecognitionState)
```

**Rationale:**
- iOS 26 emphasizes fluid, delightful interactions
- Prevents jarring UI updates
- Matches system-wide animation standards

---

## Code Fixes

### Fix 1: Consolidated Loading State (Required)

**File:** `/Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder/VoiceCompactPill.swift`

**Replace lines 72-88 with:**

```swift
@ViewBuilder
private var trailingContent: some View {
    switch voiceLogManager.actionRecognitionState {
    case .recognizing, .executing:
        // Combined loading state - prevents duplicate spinners
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
            .scaleEffect(0.9)
            .id("processing-indicator") // Stable identity
            .transition(.scale.combined(with: .opacity))
    case .completed:
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.green)
            .transition(.scale.combined(with: .opacity))
    case .idle:
        EmptyView()
    }
}
```

**Changes:**
1. Replaced `if-else` chain with `switch` for mutually exclusive conditions
2. Combined `.recognizing` and `.executing` into single case
3. Added `.id("processing-indicator")` for stable view identity
4. Added smooth `.transition()` effects
5. Explicitly handled `.idle` state

---

### Fix 2: Dynamic Height for Text (Required)

**File:** `/Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder/VoiceCompactPill.swift`

**Replace lines 19-24 with:**

```swift
if let subtitle = statusSubtitle {
    Text(subtitle)
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(nil) // Allow unlimited lines
        .fixedSize(horizontal: false, vertical: true) // Grow vertically
        .multilineTextAlignment(.leading)
}
```

**Changes:**
1. Changed `.lineLimit(1)` to `.lineLimit(nil)` - removes truncation
2. Added `.fixedSize(horizontal: false, vertical: true)` - enables vertical growth
3. Added `.multilineTextAlignment(.leading)` - ensures left alignment for multi-line text

**Alternative (if you want max 3 lines):**
```swift
.lineLimit(3) // Instead of nil
```

---

### Fix 3: Add Animation to State Changes (Recommended)

**File:** `/Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder/VoiceCompactPill.swift`

**Add to the end of the `body` view (after line 55):**

```swift
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: voiceLogManager.actionRecognitionState)
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: statusSubtitle)
```

**Full context:**
```swift
var body: some View {
    HStack(spacing: 12) {
        // ... existing content ...
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
        // ... existing background ...
    )
    .overlay(
        // ... existing overlay ...
    )
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: voiceLogManager.actionRecognitionState)
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: statusSubtitle)
}
```

**Changes:**
1. Animates state transitions smoothly
2. Animates height changes when subtitle text changes
3. Uses iOS 26-appropriate spring animation parameters

---

### Optional Enhancement: Dynamic Padding

For extra polish, adjust vertical padding based on content:

```swift
.padding(.vertical, statusSubtitle != nil ? 12 : 10)
```

This creates slightly more compact pills when there's no subtitle.

---

## iOS 26 Liquid Glass Design Principles

### Core Principles (from WWDC 2025 Session 219)

1. **Dynamics**: Liquid Glass components react to movement and interaction in real-time
2. **Adaptivity**: UI fluidly morphs based on content and context needs
3. **Transparency**: Components allow underlying content to show through
4. **Fluidity**: Transitions are smooth and spring-based, never abrupt

### Application to Compact Pills

**Your VoiceCompactPill already follows these principles:**
- ✅ Uses `.ultraThinMaterial` for transparency
- ✅ Dynamic status icon and colors based on state
- ✅ Continuous corner radius for fluid aesthetic
- ✅ Shadow with color opacity for depth

**Improvements from this guide:**
- ✅ Now adapts height based on content (Adaptivity)
- ✅ Smooth transitions between states (Fluidity)
- ✅ Single, morphing loading indicator (Dynamics)

### Material Usage Guidelines

**From Apple's HIG - Materials:**
> "Use ultraThin material for floating UI elements that need to maintain legibility over dynamic backgrounds while minimizing visual weight."

**Your implementation is correct:**
```swift
.fill(.ultraThinMaterial)
```

**For dynamic height changes**, no material adjustments needed - materials automatically adapt to container size.

---

## Additional Considerations

### Performance

**Dynamic height recalculations:**
- SwiftUI efficiently handles text measurement
- No manual calculation needed with `.fixedSize()` modifier
- Layout system automatically reflows content

**Animation performance:**
- Spring animations are GPU-accelerated
- `.ultraThinMaterial` is optimized for real-time rendering
- No performance concerns with these changes

### Accessibility

**Benefits of removing line limit:**
1. **VoiceOver**: Full transcript is available to screen readers
2. **Dynamic Type**: Text can grow without truncation when users increase font size
3. **Readability**: Users with cognitive disabilities can read complete information

**Add accessibility label for status:**
```swift
.accessibilityLabel("\(statusTitle). \(statusSubtitle ?? "")")
```

### Edge Cases

**Very long transcriptions:**
If transcriptions can be extremely long (100+ characters), consider:

```swift
.lineLimit(5) // Reasonable max instead of unlimited
```

Or add a "Show more" interaction pattern.

**Rapid state changes:**
The consolidated loading state prevents UI flicker during rapid `.recognizing` → `.executing` transitions.

---

## Testing Recommendations

### Test Case 1: Double Spinner Fix
1. Start voice recording
2. Speak a command
3. Stop recording (pause)
4. **Expected:** Single spinner visible during processing
5. **Previous behavior:** Brief moment where two spinners overlaid

### Test Case 2: Text Overflow
1. Record a long voice command (20+ words)
2. Stop recording
3. **Expected:** Pill expands vertically to show full transcription
4. **Previous behavior:** Text truncated with "..."

### Test Case 3: Height Animation
1. Start with short command
2. Record longer command
3. **Expected:** Smooth height transition between states
4. **Previous behavior:** Abrupt height changes or truncation

### Test Case 4: Accessibility
1. Enable VoiceOver
2. Navigate to pill during processing
3. **Expected:** Full status and transcription announced
4. Test with Dynamic Type enabled (Settings → Display → Text Size)

---

## Migration Path

### Step-by-Step Implementation

**Phase 1: Fix Double Spinner (Immediate)**
1. Apply Fix 1 (Consolidated Loading State)
2. Test voice recording → processing flow
3. Verify no visual glitches during state transitions

**Phase 2: Enable Dynamic Height (Immediate)**
1. Apply Fix 2 (Dynamic Text Height)
2. Test with various transcription lengths
3. Verify pill height adapts smoothly

**Phase 3: Polish Animations (Low Priority)**
1. Apply Fix 3 (State Change Animations)
2. Fine-tune spring parameters if needed
3. Test on different device sizes

### Rollback Plan

If issues arise:
- Fix 1: Revert to original if-else chain (no functional impact)
- Fix 2: Restore `.lineLimit(1)` (loses dynamic height but prevents layout issues)
- Fix 3: Remove animation modifiers (no functional impact)

---

## Resources

### Apple Documentation
- [WWDC 2025 Session 219: Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [iOS 26 New Features PDF](https://www.apple.com/os/pdf/All_New_Features_iOS_26_Sept_2025.pdf)
- [Human Interface Guidelines: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)

### Community Resources
- [SwiftUI: The magic of fixed size modifier](https://swiftwithmajid.com/2020/04/29/the-magic-of-fixed-size-modifier-in-swiftui/)
- [Stack Overflow: SwiftUI ProgressView in List can only be displayed once](https://stackoverflow.com/questions/75570322/swiftui-progressview-in-list-can-only-be-displayed-once)
- [Dynamic Bottom Sheet Height Based on Content](https://www.svpdigitalstudio.com/blog/dynamic-bottom-sheet-height-based-on-content-inside)
- [iOS 26: Liquid Glass UI between design and accessibility](https://letsdev.de/en/blog/iOS-26-in-detail-liquid-glass-UI-between-usability-and-accessibility)

### Design Articles
- [MacRumors: iOS 26 Liquid Glass Redesign Guide](https://www.macrumors.com/guide/ios-26-liquid-glass/)
- [Medium: Liquid Glass in iOS 26 - The Next Evolution of Modern UI Design](https://medium.com/@gauravkumarjaipur/liquid-glass-in-ios-26-the-next-evolution-of-modern-ui-design-ce54985eb9d1)
- [Designing custom UI with Liquid Glass on iOS 26](https://www.donnywals.com/designing-custom-ui-with-liquid-glass-on-ios-26/)

---

## Summary of Changes

### Required Changes
1. **Consolidate loading states** - Fixes double spinner issue
2. **Remove line limit** - Enables vertical text growth
3. **Add fixedSize modifier** - Allows dynamic height adaptation

### Recommended Changes
1. **Add state animations** - Improves visual fluidity
2. **Add accessibility labels** - Improves VoiceOver experience
3. **Test with Dynamic Type** - Ensures accessibility compliance

### Impact Assessment
- **Visual Impact**: Moderate - pill will expand vertically with content
- **Functional Impact**: High - fixes double spinner bug, shows complete information
- **Performance Impact**: Negligible - SwiftUI handles layout efficiently
- **Accessibility Impact**: High positive - better VoiceOver support, Dynamic Type compatibility

---

**Document Version:** 1.0
**Last Updated:** October 14, 2025
**Next Review:** After iOS 26 official release (Spring 2026)
