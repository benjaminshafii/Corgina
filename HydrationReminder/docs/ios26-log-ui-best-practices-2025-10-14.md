# iOS 26 Log Management UI/UX Best Practices
## Top 0.1% Design Patterns for Food/Hydration Tracking Apps

**Research Date:** October 14, 2025
**Target Platform:** iOS 26 with Liquid Glass Design Language
**Research Focus:** Log list interfaces, activity feeds, heterogeneous data display

---

## Executive Summary

This document synthesizes cutting-edge iOS 26 UI/UX patterns for building world-class log management interfaces. Based on extensive research of Apple's Health app, Fitness+, and the latest iOS 26 design guidelines, this guide provides actionable recommendations for displaying heterogeneous log types (food, water, vitamins, symptoms) in a unified, native-feeling interface.

**Key Findings:**
1. **Liquid Glass is for chrome, not content** - Apply glass effects to toolbars, navigation, and floating elements, NOT to log entries themselves
2. **Swipe actions are the primary interaction pattern** - Context menus are secondary
3. **Inline editing beats modal sheets** for timestamp adjustments
4. **Sectioned lists with clear visual hierarchy** work best for heterogeneous data
5. **Compact macro displays use horizontal layouts** with visual emphasis on primary metrics

---

## Table of Contents

1. [List View Architecture](#1-list-view-architecture)
2. [Liquid Glass Integration](#2-liquid-glass-integration)
3. [Delete Interaction Patterns](#3-delete-interaction-patterns)
4. [Edit Interaction Patterns](#4-edit-interaction-patterns)
5. [Timestamp Editing UI](#5-timestamp-editing-ui)
6. [Heterogeneous Data Display](#6-heterogeneous-data-display)
7. [Recent Activity Patterns](#7-recent-activity-patterns)
8. [Macro Display Strategies](#8-macro-display-strategies)
9. [SwiftUI Implementation Patterns](#9-swiftui-implementation-patterns)
10. [Accessibility & Performance](#10-accessibility--performance)

---

## 1. List View Architecture

### Recommended Approach: Native SwiftUI List

**Primary Choice:** Use native `List` with `.listStyle(.insetGrouped)` for iOS 26
- Automatic Liquid Glass integration with system chrome
- Native scroll performance and rubber-banding
- Built-in separator management
- System-standard swipe actions

```swift
List {
    ForEach(groupedLogs) { section in
        Section {
            ForEach(section.items) { log in
                LogRowView(log: log)
            }
        } header: {
            SectionHeaderView(date: section.date)
        }
    }
}
.listStyle(.insetGrouped)
.scrollContentBackground(.hidden) // iOS 26: Allow custom backgrounds
.background(Color(.systemGroupedBackground))
```

### When to Use LazyVStack Instead

Consider `ScrollView` + `LazyVStack` only if you need:
- Custom scroll indicators
- Non-standard cell animations
- Precise scroll position control

**Trade-offs:**
- LazyVStack requires manual separator implementation
- No automatic swipe action support
- More complex state management
- Less native feel on iOS 26

**Verdict:** Use native `List` unless you have specific customization requirements that can't be achieved with list modifiers.

---

## 2. Liquid Glass Integration

### Core Principle: Glass for Chrome, Not Content

**Liquid Glass is a translucent material for UI chrome** - not for content cells. Based on Apple's design language:

> "Liquid Glass forms the foundation of the new design. It reflects and refracts what's underneath it in real time, while dynamically transforming to help bring greater focus to your content."

### DO Apply Liquid Glass To:
✅ **Floating action buttons**
```swift
Button(action: addLog) {
    Label("Add", systemImage: "plus")
        .bold()
        .labelStyle(.iconOnly)
        .padding()
}
.glassEffect(.regular.interactive())
.padding([.bottom, .trailing], 12)
```

✅ **Toolbars and navigation bars**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("Edit") { }
            .buttonStyle(.glass)
    }
}
```

✅ **Bottom sheets and overlays**
```swift
.sheet(isPresented: $showingEditor) {
    LogEditorView()
        .presentationBackground(.thinMaterial)
}
```

### DON'T Apply Liquid Glass To:
❌ **List rows/cells** - This creates visual clutter and reduces readability
❌ **Primary content** - Keep content opaque for maximum clarity
❌ **Text-heavy views** - Glass reduces contrast and legibility

### Proper List Background Styling

```swift
List {
    // Log entries WITHOUT glass effect
    ForEach(logs) { log in
        LogRowView(log: log)
            .listRowBackground(Color(.systemBackground)) // Solid color
    }
}
.scrollContentBackground(.hidden)
.background(Color(.systemGroupedBackground))
```

### iOS 26 Glass Effect API

```swift
// Regular glass effect
.glassEffect(.regular, in: .rect(cornerRadius: 16))

// Interactive glass (responds to touch)
.glassEffect(.regular.interactive())

// Tinted glass
.glassEffect(.regular.tint(.purple.opacity(0.8)))

// Grouped glass effects
.glassEffectUnion(id: "group1", namespace: glassNamespace)
```

**Performance Note:** Liquid Glass uses GPU-accelerated blur with automatic fallbacks on older devices.

---

## 3. Delete Interaction Patterns

### Primary Pattern: Swipe-to-Delete (Trailing Edge)

iOS 26 prioritizes swipe actions over edit mode. The Health app uses this pattern consistently:

```swift
ForEach(logs) { log in
    LogRowView(log: log)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteLog(log)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
}
```

**Key Features:**
- `allowsFullSwipe: true` - Enables swipe-all-the-way-to-delete
- `role: .destructive` - Automatic red color, no manual tinting needed
- System icon with text label for clarity

### Multi-Action Swipe Pattern

For logs with multiple actions (Health app pattern):

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: false) {
    Button(role: .destructive) {
        deleteLog(log)
    } label: {
        Label("Delete", systemImage: "trash")
    }

    Button {
        showEditor(for: log)
    } label: {
        Label("Edit", systemImage: "pencil")
    }
    .tint(.blue)
}
```

**UX Guidelines:**
- Order: Most destructive action (delete) appears first (rightmost)
- Limit to 2-3 actions maximum
- Use system colors for familiarity

### Secondary Pattern: Context Menu (Long Press)

Use context menus for **additional, less common actions**:

```swift
.contextMenu {
    Button {
        duplicateLog(log)
    } label: {
        Label("Duplicate", systemImage: "doc.on.doc")
    }

    Button {
        shareLog(log)
    } label: {
        Label("Share", systemImage: "square.and.arrow.up")
    }

    Divider()

    Button(role: .destructive) {
        deleteLog(log)
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

**When to Use Context Menu:**
- Actions beyond edit/delete (share, duplicate, pin)
- Platform-specific functionality (iPad multi-window)
- Discovery of advanced features

### Confirmation Pattern for Destructive Actions

**iOS 26 In-Place Alerts** - Alerts now expand from the button that initiates them:

```swift
@State private var showingDeleteAlert = false
@State private var logToDelete: LogEntry?

.swipeActions(edge: .trailing) {
    Button(role: .destructive) {
        logToDelete = log
        showingDeleteAlert = true
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
.alert("Delete Log Entry?", isPresented: $showingDeleteAlert) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        if let log = logToDelete {
            deleteLog(log)
        }
    }
} message: {
    Text("This action cannot be undone.")
}
```

**Best Practice:** Use confirmations for:
- Bulk delete operations
- Logs with significant data (food with multiple items)
- Irreversible actions

---

## 4. Edit Interaction Patterns

### Pattern Hierarchy (Least to Most Disruptive)

1. **Inline Editing** (Best for simple edits)
2. **Tap-to-Expand** (Good for moderate complexity)
3. **Navigation Push** (For complex multi-field editing)
4. **Sheet Presentation** (For create-new workflows)

### 1. Inline Editing (Preferred for Timestamps)

Best for single-field edits without leaving context:

```swift
struct LogRowView: View {
    @Binding var log: LogEntry
    @State private var isEditingTimestamp = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(log.title)
                    .font(.headline)

                if isEditingTimestamp {
                    DatePicker("Time",
                              selection: $log.timestamp,
                              displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                } else {
                    Text(log.timestamp, style: .time)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                            withAnimation {
                                isEditingTimestamp = true
                            }
                        }
                }
            }
        }
    }
}
```

### 2. Tap-to-Expand Pattern (Detail Disclosure)

Health app uses this for workout details:

```swift
struct ExpandableLogRow: View {
    let log: LogEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Collapsed view
            HStack {
                Text(log.title)
                    .font(.headline)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    MacroDisplayView(macros: log.macros)

                    Button {
                        // Edit action
                    } label: {
                        Label("Edit Entry", systemImage: "pencil")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
    }
}
```

### 3. Navigation Push Pattern (Complex Editing)

For multi-field editing with validation:

```swift
NavigationStack {
    List(logs) { log in
        NavigationLink {
            LogEditorView(log: log)
        } label: {
            LogRowView(log: log)
        }
    }
}
```

**Use when:**
- Editing 5+ fields
- Complex validation logic
- Multi-step workflows
- Photo/media attachment

### 4. Sheet Presentation Pattern (Create New)

iOS 26 enhances sheets with matchGeometry transitions:

```swift
@State private var showingNewLog = false
@Namespace private var animation

Button {
    withAnimation {
        showingNewLog = true
    }
} label: {
    Label("Add", systemImage: "plus")
}
.glassEffect(.regular.interactive())
.sheet(isPresented: $showingNewLog) {
    NewLogView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
}
```

**iOS 26 Sheet Features:**
- `.presentationBackgroundInteraction()` - Interact with content behind sheet
- Smooth Liquid Glass integration
- Improved drag-to-dismiss physics

---

## 5. Timestamp Editing UI

### Pattern Analysis: Inline vs. Modal

**Research Finding:** Apple Health uses **inline DatePicker** for timestamp adjustments, not modal sheets.

### Recommended: Inline DatePicker

```swift
struct TimestampEditRow: View {
    @Binding var timestamp: Date
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Time")
                    .foregroundStyle(.secondary)
                Spacer()

                if isEditing {
                    Button("Done") {
                        withAnimation {
                            isEditing = false
                        }
                    }
                    .font(.subheadline)
                } else {
                    Button {
                        withAnimation {
                            isEditing = true
                        }
                    } label: {
                        Text(timestamp, style: .time)
                            .foregroundStyle(.primary)
                    }
                }
            }

            if isEditing {
                DatePicker("",
                          selection: $timestamp,
                          displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}
```

### iOS 26 DatePicker Styles

```swift
// Compact style (tappable, opens popover)
.datePickerStyle(.compact)

// Graphical calendar view (inline)
.datePickerStyle(.graphical)

// Wheel picker (time selection)
.datePickerStyle(.wheel)
```

**UX Guidelines:**
- Use `.graphical` for date + time selection
- Use `.compact` for space-constrained views
- Use `.wheel` for time-only adjustments

### Quick Timestamp Adjustments

Add common presets for faster editing:

```swift
struct QuickTimestampAdjust: View {
    @Binding var timestamp: Date

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickButton(title: "Now") {
                    timestamp = Date()
                }
                QuickButton(title: "-15min") {
                    timestamp = timestamp.addingTimeInterval(-15 * 60)
                }
                QuickButton(title: "-1hr") {
                    timestamp = timestamp.addingTimeInterval(-3600)
                }
                QuickButton(title: "Morning") {
                    timestamp = Calendar.current.date(
                        bySettingHour: 8, minute: 0, second: 0,
                        of: timestamp
                    ) ?? timestamp
                }
            }
            .padding(.horizontal)
        }
    }

    private func QuickButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
    }
}
```

---

## 6. Heterogeneous Data Display

### Challenge: Unified List with Different Log Types

Your app needs to display:
- Food logs (with macros)
- Water logs (volume)
- Vitamin logs (type, dosage)
- Symptom logs (severity, notes)
- PUQE scores (numerical)

### Solution 1: Enum-Based Row Rendering (Recommended)

```swift
enum LogType: Identifiable {
    case food(FoodLog)
    case water(WaterLog)
    case vitamin(VitaminLog)
    case symptom(SymptomLog)
    case puqe(PUQELog)

    var id: UUID {
        switch self {
        case .food(let log): return log.id
        case .water(let log): return log.id
        case .vitamin(let log): return log.id
        case .symptom(let log): return log.id
        case .puqe(let log): return log.id
        }
    }

    var timestamp: Date {
        switch self {
        case .food(let log): return log.timestamp
        case .water(let log): return log.timestamp
        case .vitamin(let log): return log.timestamp
        case .symptom(let log): return log.timestamp
        case .puqe(let log): return log.timestamp
        }
    }
}

struct UnifiedLogRow: View {
    let logType: LogType

    var body: some View {
        switch logType {
        case .food(let log):
            FoodLogRow(log: log)
        case .water(let log):
            WaterLogRow(log: log)
        case .vitamin(let log):
            VitaminLogRow(log: log)
        case .symptom(let log):
            SymptomLogRow(log: log)
        case .puqe(let log):
            PUQELogRow(log: log)
        }
    }
}
```

### Solution 2: Protocol-Based Abstraction

```swift
protocol LogEntry: Identifiable {
    var id: UUID { get }
    var timestamp: Date { get }
    var title: String { get }
    var iconName: String { get }
    var iconColor: Color { get }
}

extension FoodLog: LogEntry {
    var title: String { description }
    var iconName: String { "fork.knife" }
    var iconColor: Color { .orange }
}

extension WaterLog: LogEntry {
    var title: String { "\(Int(amount))ml Water" }
    var iconName: String { "drop.fill" }
    var iconColor: Color { .blue }
}

// Generic row with specialized content
struct GenericLogRow<Content: View>: View {
    let entry: any LogEntry
    let content: () -> Content

    var body: some View {
        HStack(spacing: 12) {
            // Consistent icon
            Image(systemName: entry.iconName)
                .font(.title2)
                .foregroundStyle(entry.iconColor)
                .frame(width: 40, height: 40)
                .background(entry.iconColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.headline)

                Text(entry.timestamp, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                content()
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
```

### Visual Hierarchy for Different Log Types

**Icon + Color System:**

```swift
struct LogTypeStyle {
    let icon: String
    let color: Color

    static let food = LogTypeStyle(icon: "fork.knife", color: .orange)
    static let water = LogTypeStyle(icon: "drop.fill", color: .blue)
    static let vitamin = LogTypeStyle(icon: "pills.fill", color: .green)
    static let symptom = LogTypeStyle(icon: "heart.text.square", color: .red)
    static let puqe = LogTypeStyle(icon: "chart.bar.fill", color: .purple)
}
```

### Grouping Strategy

Group by date with type diversity within sections:

```swift
struct GroupedLogs {
    let date: Date
    let logs: [LogType]

    var dateString: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

// In your view
List {
    ForEach(groupedLogs) { group in
        Section {
            ForEach(group.logs) { log in
                UnifiedLogRow(logType: log)
            }
        } header: {
            Text(group.dateString)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}
```

---

## 7. Recent Activity Patterns

### Health App "Recent Activity" Analysis

The iOS 26 Health app uses a **timeline-based feed** with:
1. Chronological ordering (newest first)
2. Date section headers
3. Compact card design
4. Swipe actions on every item
5. "Show All" navigation for full history

### Recommended Implementation

```swift
struct RecentActivityView: View {
    @StateObject private var viewModel: LogsViewModel
    let maxRecentItems = 10

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.recentLogs.prefix(maxRecentItems)) { log in
                        RecentActivityRow(log: log)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.delete(log)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text("Recent Activity")
                            .font(.headline)
                        Spacer()
                        if viewModel.recentLogs.count > maxRecentItems {
                            NavigationLink("Show All") {
                                AllLogsView()
                            }
                            .font(.subheadline)
                        }
                    }
                }

                // Today's Summary Section
                Section {
                    TodaySummaryCard(
                        calories: viewModel.todayCalories,
                        water: viewModel.todayWater,
                        vitamins: viewModel.todayVitamins
                    )
                } header: {
                    Text("Today's Summary")
                        .font(.headline)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showAddLog = true
                    } label: {
                        Label("Add", systemName: "plus")
                    }
                }
            }
        }
    }
}
```

### Recent Activity Row Design

Compact, scannable design:

```swift
struct RecentActivityRow: View {
    let log: LogType

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            LogTypeIcon(log: log)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.title)
                        .font(.body)
                        .lineLimit(1)

                    Spacer()

                    Text(log.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Type-specific preview
                LogPreview(log: log)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LogTypeIcon: View {
    let log: LogType

    var body: some View {
        Image(systemName: log.iconName)
            .font(.body)
            .foregroundStyle(log.color)
            .frame(width: 32, height: 32)
            .background(log.color.opacity(0.15))
            .clipShape(Circle())
    }
}
```

### Timeline Visualization

For a more visual timeline (advanced):

```swift
struct TimelineActivityView: View {
    let logs: [LogType]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(logs) { log in
                    HStack(alignment: .top, spacing: 12) {
                        // Timeline connector
                        VStack(spacing: 0) {
                            Circle()
                                .fill(log.color)
                                .frame(width: 12, height: 12)

                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 2)
                        }

                        // Log card
                        LogCard(log: log)
                            .padding(.bottom, 16)
                    }
                }
            }
            .padding()
        }
    }
}
```

---

## 8. Macro Display Strategies

### Research Finding: Horizontal Compact Layouts

Top food tracking apps (MyFitnessPal, Lose It!, Cronometer) use **horizontal pill-style layouts** for macro displays in list rows.

### Pattern 1: Horizontal Pills (Recommended for List Rows)

```swift
struct CompactMacroDisplay: View {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double

    var body: some View {
        HStack(spacing: 8) {
            MacroPill(value: "\(calories)", label: "cal", color: .orange)
            MacroPill(value: "\(Int(protein))g", label: "P", color: .blue)
            MacroPill(value: "\(Int(carbs))g", label: "C", color: .green)
            MacroPill(value: "\(Int(fat))g", label: "F", color: .purple)
        }
    }
}

struct MacroPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}
```

**Usage in Row:**
```swift
struct FoodLogRow: View {
    let log: FoodLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(log.description)
                .font(.headline)

            CompactMacroDisplay(
                calories: log.calories,
                protein: log.protein,
                carbs: log.carbs,
                fat: log.fat
            )
        }
        .padding(.vertical, 4)
    }
}
```

### Pattern 2: Grid Layout (For Detail Views)

```swift
struct DetailedMacroGrid: View {
    let macros: Macros

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MacroCard(
                title: "Protein",
                value: macros.protein,
                unit: "g",
                color: .blue,
                icon: "figure.strengthtraining.traditional"
            )
            MacroCard(
                title: "Carbs",
                value: macros.carbs,
                unit: "g",
                color: .green,
                icon: "leaf.fill"
            )
            MacroCard(
                title: "Fat",
                value: macros.fat,
                unit: "g",
                color: .purple,
                icon: "drop.fill"
            )
        }
    }
}

struct MacroCard: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text("\(Int(value))")
                .font(.title2)
                .fontWeight(.bold)

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

### Pattern 3: Progress Bar Style (For Goals)

```swift
struct MacroProgressView: View {
    let macro: String
    let current: Double
    let goal: Double
    let color: Color

    var progress: Double {
        min(current / goal, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(macro)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(current))g / \(Int(goal))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
        }
    }
}
```

### Calorie Emphasis Pattern

Make calories the visual anchor:

```swift
struct CalorieEmphasizedMacroDisplay: View {
    let macros: Macros

    var body: some View {
        HStack(spacing: 12) {
            // Large calorie display
            VStack(spacing: 2) {
                Text("\(macros.calories)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)

                Text("cal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Compact macro pills
            HStack(spacing: 6) {
                SmallMacroPill(value: macros.protein, label: "P", color: .blue)
                SmallMacroPill(value: macros.carbs, label: "C", color: .green)
                SmallMacroPill(value: macros.fat, label: "F", color: .purple)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
```

---

## 9. SwiftUI Implementation Patterns

### Complete Example: Log List with All Patterns

```swift
import SwiftUI

// MARK: - Main View
struct LogsListView: View {
    @StateObject private var viewModel = LogsViewModel()
    @State private var showingAddLog = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Main list
                List {
                    ForEach(viewModel.groupedLogs) { group in
                        Section {
                            ForEach(group.logs) { log in
                                LogRowView(log: log)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            viewModel.delete(log)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            viewModel.showEditor(for: log)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                    .contextMenu {
                                        Button {
                                            viewModel.duplicate(log)
                                        } label: {
                                            Label("Duplicate", systemImage: "doc.on.doc")
                                        }

                                        Button {
                                            viewModel.share(log)
                                        } label: {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }
                                    }
                            }
                        } header: {
                            Text(group.dateString)
                                .font(.headline)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))

                // Floating action button (Liquid Glass)
                Button {
                    showingAddLog = true
                } label: {
                    Label("Add Log", systemImage: "plus")
                        .bold()
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                }
                .glassEffect(.regular.tint(.blue).interactive())
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                .padding([.bottom, .trailing], 20)
            }
            .navigationTitle("Activity Log")
            .sheet(isPresented: $showingAddLog) {
                AddLogView()
            }
        }
    }
}

// MARK: - Row View
struct LogRowView: View {
    let log: LogEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Type icon
                Image(systemName: log.iconName)
                    .font(.title3)
                    .foregroundStyle(log.color)
                    .frame(width: 36, height: 36)
                    .background(log.color.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(log.title)
                        .font(.headline)

                    Text(log.timestamp, style: .time)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if log.hasDetails {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if log.hasDetails {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
            }

            // Expanded details
            if isExpanded {
                log.detailView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Model
@MainActor
class LogsViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var groupedLogs: [GroupedLogs] = []

    func delete(_ log: LogEntry) {
        withAnimation {
            logs.removeAll { $0.id == log.id }
            updateGroupedLogs()
        }
    }

    func showEditor(for log: LogEntry) {
        // Navigate to editor
    }

    func duplicate(_ log: LogEntry) {
        // Duplicate logic
    }

    func share(_ log: LogEntry) {
        // Share sheet
    }

    private func updateGroupedLogs() {
        let grouped = Dictionary(grouping: logs) { log in
            Calendar.current.startOfDay(for: log.timestamp)
        }

        groupedLogs = grouped.map { date, logs in
            GroupedLogs(date: date, logs: logs.sorted { $0.timestamp > $1.timestamp })
        }
        .sorted { $0.date > $1.date }
    }
}
```

### Performance Optimizations

```swift
// 1. Use @StateObject for view models
@StateObject private var viewModel = LogsViewModel()

// 2. Lazy loading with ForEach identifiers
ForEach(logs, id: \.id) { log in
    LogRowView(log: log)
}

// 3. Equatable conformance to prevent unnecessary redraws
struct LogEntry: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let title: String

    static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// 4. Use .id() modifier to force view refresh when needed
List {
    // content
}
.id(viewModel.refreshID)
```

---

## 10. Accessibility & Performance

### VoiceOver Support

```swift
struct AccessibleLogRow: View {
    let log: LogEntry

    var body: some View {
        LogRowView(log: log)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(log.type), \(log.title)")
            .accessibilityValue(log.accessibilityDescription)
            .accessibilityHint("Double tap to expand details")
            .accessibilityAction(named: "Delete") {
                // Delete action
            }
    }
}
```

### Dynamic Type Support

```swift
struct ScalableLogRow: View {
    @Environment(\.dynamicTypeSize) var typeSize

    var body: some View {
        HStack(spacing: typeSize >= .xxxLarge ? 16 : 12) {
            // Content that adapts to text size
        }
    }
}
```

### Color Contrast (Liquid Glass Considerations)

```swift
// Ensure sufficient contrast on glass backgrounds
Text("Content")
    .foregroundStyle(.primary) // Automatically adapts to light/dark mode
    .glassEffect(.regular.tint(.blue.opacity(0.7))) // Lower opacity for readability
```

### Performance Best Practices

1. **Use LazyVStack only when needed** - Native List is more performant
2. **Limit glass effects** - GPU-intensive, use sparingly
3. **Batch updates** - Use `withAnimation` for grouped changes
4. **Identifiable conformance** - Ensures efficient diffing
5. **Avoid nested ForEach** - Flatten data structures when possible

---

## Conclusion

### Key Takeaways

1. **List Architecture**: Use native `List` with `.insetGrouped` style for automatic iOS 26 integration
2. **Liquid Glass**: Apply ONLY to chrome (toolbars, floating buttons, overlays), NOT content cells
3. **Delete Pattern**: Swipe-to-delete (trailing edge) as primary, context menu as secondary
4. **Edit Pattern**: Inline editing for simple fields, tap-to-expand for details, navigation for complex edits
5. **Timestamp UI**: Inline DatePicker with graphical style, supplemented with quick presets
6. **Heterogeneous Display**: Enum-based row rendering with consistent icon system
7. **Macro Display**: Horizontal pill layout for list rows, grid layout for detail views
8. **Recent Activity**: Timeline feed with "Show All" navigation, limited to 10 recent items

### Implementation Priority

**Phase 1 - Core Patterns (Week 1)**
- [ ] Implement grouped List with section headers
- [ ] Add swipe-to-delete actions
- [ ] Create enum-based row rendering for different log types
- [ ] Add compact macro display for food logs

**Phase 2 - Interactions (Week 2)**
- [ ] Implement tap-to-expand for log details
- [ ] Add inline timestamp editing
- [ ] Create context menus for secondary actions
- [ ] Add floating action button with Liquid Glass

**Phase 3 - Polish (Week 3)**
- [ ] Implement recent activity feed with "Show All"
- [ ] Add empty state views
- [ ] Implement undo/redo for deletions
- [ ] Add animations and transitions
- [ ] Accessibility audit and fixes

### Additional Resources

- [Apple HIG - Lists and Tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables)
- [WWDC 2025 - What's New in SwiftUI](https://developer.apple.com/videos/play/wwdc2025/)
- [iOS 26 Design Resources](https://developer.apple.com/design/resources/)
- [Liquid Glass Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/materials)

---

**Document Version:** 1.0
**Last Updated:** October 14, 2025
**Next Review:** When iOS 27 beta releases
