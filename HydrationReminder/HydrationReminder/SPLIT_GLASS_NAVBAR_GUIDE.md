# Split Glass Navigation Bar - Implementation Guide

## Overview

This guide explains how to use the beautiful **Split Glass Navigation Bar** component for your iOS app. This component implements Apple's Liquid Glass design language with a modern split-section layout.

## What You Get

### Component Files
- **`SplitGlassNavBar.swift`** - Complete implementation with:
  - `SplitGlassNavBar` - Two-section glass navbar (left + right)
  - `CompactGlassNavBar` - Single-section glass navbar
  - `GlassNavButton` - Glass-styled button component
  - `GlassNavTitle` - Title/subtitle component
  - View extensions for easy integration

## Visual Design

### Split Glass NavBar Features
```
┌─────────────────────────────────────────────────┐
│  ╔════════════════╗    ╔══════════════════╗    │
│  ║  Left Content  ║    ║  Right Content   ║    │
│  ║  (Title/Logo)  ║    ║  (Actions/Icons) ║    │
│  ╚════════════════╝    ╚══════════════════╝    │
└─────────────────────────────────────────────────┘
```

**Design Properties:**
- **Material**: `.ultraThinMaterial` (glass effect)
- **Corner Radius**: 16pt (soft, modern)
- **Border**: White 20% opacity strokeBorder
- **Shadow**: Black 10% opacity, 10pt radius, (0, 4) offset
- **Padding**: 16pt horizontal, 12pt vertical
- **Spacing**: 12pt between sections

### Accessibility Support
- **Reduce Transparency**: Automatically falls back to `.secondarySystemBackground`
- **VoiceOver**: All buttons support accessibility labels
- **Dynamic Type**: Text scales with user preferences

## Usage Examples

### 1. Basic Split NavBar with Title and Actions

```swift
import SwiftUI

struct DashboardView: View {
    var body: some View {
        ZStack {
            // Your background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Your content
            ScrollView {
                // ... content here ...
            }
            .splitGlassNavBar {
                // Left: Title
                GlassNavTitle("Dashboard", subtitle: "Today")
            } rightContent: {
                // Right: Action buttons
                HStack(spacing: 12) {
                    GlassNavButton(icon: "bell.fill") {
                        // Handle notifications
                    }
                    GlassNavButton(icon: "gearshape.fill") {
                        // Handle settings
                    }
                }
            }
        }
    }
}
```

### 2. Profile Header with Avatar

```swift
SplitGlassNavBar {
    // Left: Avatar + Name
    HStack(spacing: 12) {
        Circle()
            .fill(.blue.gradient)
            .frame(width: 40, height: 40)
            .overlay(
                Text("BS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            )
        
        GlassNavTitle("Welcome Back", subtitle: "Sunday, Oct 13")
    }
} rightContent: {
    // Right: Multiple actions
    HStack(spacing: 16) {
        // Notification badge example
        ZStack(alignment: .topTrailing) {
            GlassNavButton(icon: "envelope.fill") {
                print("Messages")
            }
            
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .offset(x: 4, y: -4)
        }
        
        GlassNavButton(icon: "magnifyingglass") {
            print("Search")
        }
    }
}
```

### 3. Compact Single-Section NavBar

```swift
CompactGlassNavBar {
    HStack {
        // Back button
        GlassNavButton(icon: "chevron.left", title: "Back") {
            // Navigate back
        }
        
        Spacer()
        
        // Centered title
        GlassNavTitle("Settings")
        
        Spacer()
        
        // Action button
        GlassNavButton(icon: "checkmark") {
            // Save/Done action
        }
    }
}
```

### 4. Using View Extension Modifiers

```swift
// Method 1: Split navbar
ScrollView {
    // Your content
}
.splitGlassNavBar {
    GlassNavTitle("Home")
} rightContent: {
    GlassNavButton(icon: "plus") { }
}

// Method 2: Compact navbar
ScrollView {
    // Your content
}
.compactGlassNavBar {
    HStack {
        GlassNavButton(icon: "chevron.left") { }
        Spacer()
        Text("Details")
        Spacer()
        GlassNavButton(icon: "square.and.arrow.up") { }
    }
}
```

## Component Reference

### SplitGlassNavBar

**Parameters:**
- `leftContent: () -> LeftContent` - Content for left section (typically title/logo)
- `rightContent: () -> RightContent` - Content for right section (typically actions)

**Layout:**
- Two equal-width sections with 12pt spacing
- Each section has independent glass material background
- Automatic safe area handling

### CompactGlassNavBar

**Parameters:**
- `content: () -> Content` - Single content section

**Layout:**
- Full-width single glass container
- Ideal for navigation bars with back button + title + action

### GlassNavButton

**Parameters:**
- `icon: String` - SF Symbol name
- `title: String?` - Optional text label (default: nil)
- `action: () -> Void` - Button tap handler

**Usage:**
```swift
// Icon only
GlassNavButton(icon: "bell.fill") {
    showNotifications()
}

// Icon with label
GlassNavButton(icon: "chevron.left", title: "Back") {
    dismiss()
}
```

### GlassNavTitle

**Parameters:**
- `title: String` - Main title text
- `subtitle: String?` - Optional subtitle (default: nil)

**Usage:**
```swift
// Title only
GlassNavTitle("Dashboard")

// Title with subtitle
GlassNavTitle("Welcome", subtitle: "Good morning")
```

## Integration with Existing Views

### Replace Standard Navigation Bar

**Before:**
```swift
NavigationView {
    ScrollView {
        // content
    }
    .navigationTitle("Dashboard")
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { }) {
                Image(systemName: "gear")
            }
        }
    }
}
```

**After:**
```swift
ZStack {
    ScrollView {
        // content
    }
    .splitGlassNavBar {
        GlassNavTitle("Dashboard")
    } rightContent: {
        GlassNavButton(icon: "gearshape.fill") { }
    }
}
```

### Integrate with MainTabView

Add to your `DashboardView.swift`:

```swift
var body: some View {
    ZStack(alignment: .top) {
        // Existing content
        ScrollView {
            VStack(spacing: 20) {
                // ... your existing cards ...
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        
        // Add glass navbar on top
        VStack {
            SplitGlassNavBar {
                GlassNavTitle("Corgina", subtitle: todaysDate)
            } rightContent: {
                HStack(spacing: 12) {
                    GlassNavButton(icon: "bell.fill") {
                        // Show notifications
                    }
                    GlassNavButton(icon: "gearshape.fill") {
                        // Open settings
                    }
                }
            }
            Spacer()
        }
    }
}
```

## Design Patterns

### Pattern 1: Dashboard Header
```swift
SplitGlassNavBar {
    VStack(alignment: .leading) {
        Text("Good Morning")
            .font(.caption)
            .foregroundStyle(.secondary)
        Text("Dashboard")
            .font(.title2)
            .fontWeight(.bold)
    }
} rightContent: {
    HStack(spacing: 12) {
        GlassNavButton(icon: "plus.circle.fill") { }
        GlassNavButton(icon: "line.3.horizontal.decrease.circle") { }
    }
}
```

### Pattern 2: Search Bar Integration
```swift
SplitGlassNavBar {
    HStack {
        Image(systemName: "magnifyingglass")
            .foregroundStyle(.secondary)
        Text("Search...")
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
} rightContent: {
    GlassNavButton(icon: "mic.fill") { }
}
```

### Pattern 3: Multi-Action Toolbar
```swift
SplitGlassNavBar {
    GlassNavTitle("Messages")
} rightContent: {
    HStack(spacing: 16) {
        GlassNavButton(icon: "square.and.pencil") { }
        GlassNavButton(icon: "line.3.horizontal.decrease") { }
        Menu {
            Button("New Group") { }
            Button("Settings") { }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```

## Best Practices

### 1. Content Alignment
✅ **DO:**
- Align left content to `.leading`
- Align right content to `.trailing`
- Use `Spacer()` in compact navbar for center alignment

❌ **DON'T:**
- Overcrowd either section
- Use very long titles that truncate
- Stack too many action buttons

### 2. Visual Hierarchy
✅ **DO:**
- Use title/subtitle in left section
- Group related actions in right section
- Limit to 2-3 action buttons maximum

❌ **DON'T:**
- Mix unrelated actions together
- Use different visual weights in same section

### 3. Interaction Design
✅ **DO:**
- Provide haptic feedback on button taps
- Use meaningful SF Symbols
- Add accessibility labels

❌ **DON'T:**
- Make buttons too small (< 44pt touch target)
- Use vague icons without context
- Forget VoiceOver support

### 4. Background Compatibility
✅ **DO:**
- Use on gradient backgrounds
- Use on image backgrounds
- Use on solid colors

❌ **DON'T:**
- Use on very busy patterns (glass won't be visible)
- Use when content contrast is too low

## Customization Options

### Adjusting Corner Radius
```swift
// In SplitGlassNavBar.swift, modify:
.clipShape(RoundedRectangle(cornerRadius: 20)) // Change from 16
```

### Adjusting Blur Intensity
```swift
// Replace .ultraThinMaterial with:
.background(.thinMaterial)        // Less blur
.background(.regularMaterial)     // Medium blur
.background(.thickMaterial)       // More blur
```

### Adjusting Border Opacity
```swift
// Modify strokeBorder:
.strokeBorder(.white.opacity(0.3), lineWidth: 1) // More visible
.strokeBorder(.white.opacity(0.1), lineWidth: 1) // Less visible
```

### Adding Tint Color
```swift
.background(
    .ultraThinMaterial
        .blendMode(.overlay)
)
.overlay(
    Color.blue.opacity(0.1) // Add subtle blue tint
)
```

## Troubleshooting

### Issue: Glass effect not visible
**Solution:** Check background - glass needs contrast to be visible.
```swift
// Add gradient background:
ZStack {
    LinearGradient(
        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    .ignoresSafeArea()
    
    // Your view with glass navbar
}
```

### Issue: Text not readable
**Solution:** Increase background opacity or add text shadows.
```swift
Text("Title")
    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
```

### Issue: Buttons too small on larger text sizes
**Solution:** Use `.dynamicTypeSize(.accessibility1)` environment.
```swift
.environment(\.dynamicTypeSize, .xxxLarge)
```

## Performance Considerations

### Material Rendering
- Glass materials are GPU-accelerated
- Minimal performance impact on modern devices
- Automatic fallback for older devices via `reduceTransparency`

### Optimization Tips
1. **Limit nested glass**: Don't apply glass to content inside glass navbar
2. **Use static content**: Avoid constantly changing navbar content
3. **Batch updates**: Update multiple buttons together, not individually

## Migration from Standard NavBar

### Step 1: Remove NavigationView
```swift
// OLD:
NavigationView {
    Content()
        .navigationTitle("Title")
}

// NEW:
ZStack {
    Content()
    .splitGlassNavBar { ... } rightContent: { ... }
}
```

### Step 2: Convert Toolbar Items
```swift
// OLD:
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("Back") { }
    }
}

// NEW:
SplitGlassNavBar {
    GlassNavButton(icon: "chevron.left", title: "Back") { }
} rightContent: { ... }
```

### Step 3: Update Safe Area Handling
```swift
// Ensure content scrolls under glass navbar:
ScrollView {
    // Content
}
.ignoresSafeArea(edges: .top)
.padding(.top, 70) // Height of navbar + spacing
```

## Complete Example: Dashboard Implementation

```swift
import SwiftUI

struct ModernDashboard: View {
    @State private var showNotifications = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.2),
                    Color.purple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Your dashboard cards
                    ForEach(0..<5) { index in
                        CardView(title: "Card \(index)")
                    }
                }
                .padding()
                .padding(.top, 70) // Space for glass navbar
            }
            
            // Glass navigation bar overlay
            VStack {
                SplitGlassNavBar {
                    // Left: Greeting + Title
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Dashboard")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                } rightContent: {
                    // Right: Action buttons
                    HStack(spacing: 12) {
                        // Notifications with badge
                        ZStack(alignment: .topTrailing) {
                            GlassNavButton(icon: "bell.fill") {
                                showNotifications.toggle()
                            }
                            if unreadCount > 0 {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                        
                        // Settings
                        GlassNavButton(icon: "gearshape.fill") {
                            showSettings.toggle()
                        }
                    }
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private var unreadCount: Int {
        // Your notification logic
        3
    }
}

struct CardView: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text("Card content here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

## Summary

The Split Glass Navigation Bar provides:
- ✅ Beautiful Liquid Glass design
- ✅ Flexible two-section or compact layout
- ✅ Full accessibility support
- ✅ Easy integration with existing views
- ✅ Customizable appearance
- ✅ Performance optimized

Use it to create modern, Apple-style navigation bars that elevate your app's visual design!

---

**Implementation Date:** October 13, 2025  
**Based on:** iOS 26 Liquid Glass Design System  
**Compatibility:** iOS 15.0+  
**Framework:** SwiftUI
