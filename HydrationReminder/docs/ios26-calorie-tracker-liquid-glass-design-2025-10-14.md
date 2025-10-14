# iOS 26 Liquid Glass Design: Daily & Weekly Calorie Tracker Components

**Research Date:** October 14, 2025
**iOS Version:** iOS 26
**Design System:** Liquid Glass
**App:** Corgina - Pregnancy Nutrition Tracker
**Target Platform:** iPhone (iOS 26+)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [iOS 26 Liquid Glass Fundamentals](#ios-26-liquid-glass-fundamentals)
3. [Component 1: Daily Calorie Tracker Card](#component-1-daily-calorie-tracker-card)
4. [Component 2: Weekly Calorie Tracker View](#component-2-weekly-calorie-tracker-view)
5. [Data Architecture & Integration](#data-architecture--integration)
6. [Implementation Roadmap](#implementation-roadmap)
7. [Performance & Accessibility](#performance--accessibility)
8. [Resources & References](#resources--references)

---

## Executive Summary

This document provides iOS 26-specific implementation guidance for two nutrition tracking components using Apple's new **Liquid Glass** design language. Based on extensive research of WWDC 2025 sessions, official documentation, and real-world implementations, these recommendations focus on:

- **Modern visual design** using translucent materials, depth, and fluid animations
- **Enhanced interactivity** with spring physics and adaptive components
- **Seamless integration** with existing DashboardView architecture
- **iOS 26-exclusive features** like `.glassEffect()`, adaptive materials, and dynamic transformations

### Key Findings

1. **Liquid Glass is NOT just visual polish** - it's a fundamental shift in how UI elements behave and respond to context
2. **Content-first philosophy** - UI should recede when focus is needed, expand when interaction is required
3. **Optical qualities over physical metaphors** - emphasize translucency, refraction, and light interaction
4. **Spring-based animations** - all interactions should feel fluid and natural, not mechanical
5. **Adaptive materials** - components should respond to background content, lighting, and user interaction

### Component Overview

| Component | Purpose | Location | Key Features |
|-----------|---------|----------|--------------|
| Daily Calorie Tracker Card | Show today's calorie intake vs. goal with expandable meal breakdown | Replace/enhance `nutritionSummaryCard` (lines 471-528) | Circular progress ring, tap-to-expand, meal breakdown, liquid glass material |
| Weekly Calorie Tracker View | 7-day bar chart showing calorie trends | New card on DashboardView OR NavigationLink destination | SwiftUI Charts integration, interactive bars, average indicators, over/under highlighting |

---

## iOS 26 Liquid Glass Fundamentals

### What is Liquid Glass?

Liquid Glass is Apple's new **cross-platform design language** introduced at WWDC 2025. Unlike previous visual updates, it represents a paradigm shift in how interfaces behave and respond to user interaction.

**Core Principles (from WWDC25-219):**

1. **Dynamics** - UI elements transform fluidly based on context and interaction
2. **Adaptivity** - Materials respond to content beneath them, lighting conditions, and user preferences
3. **Clarity** - Content takes center stage; UI recedes when not needed
4. **Deference** - Controls morph and adapt rather than remain static
5. **Depth** - Visual layers create spatial hierarchy without overwhelming content

### Key Properties

```swift
// Liquid Glass exhibits these optical qualities:
// - Real-time refraction of underlying content
// - Dynamic blur based on motion and context
// - Reflection of ambient light
// - Translucency that adapts to background
// - Fluid morphing between states
```

### iOS 26-Specific APIs

**Primary Modifiers:**

```swift
// Apply glass effect to any view
.glassEffect()

// Apply glass with specific shape
.glassBackgroundEffect(
    in: .rect(cornerRadius: 20),
    displayMode: .adaptive
)

// Glass effect with ID for morphing animations
.glassEffectID("uniqueID", in: namespace)

// Union multiple glass elements
.glassEffectUnion(id: "groupID", namespace: namespace)

// Container for multiple glass elements
GlassEffectContainer(spacing: 20.0) {
    // Child views
}
```

**DO NOT use** (these are iOS 18/pre-26 APIs):
- `.background(.regularMaterial)` - too opaque for Liquid Glass
- `.background(.ultraThinMaterial)` without `.glassEffect()` - lacks interactive qualities
- Static corner radius without adaptive morphing

### Visual Specifications

**Typography (SF Pro):**
- Large titles: `.system(.largeTitle, design: .rounded)` - 34pt, weight: .bold
- Headlines: `.headline` - 17pt, weight: .semibold
- Body: `.body` - 17pt, weight: .regular
- Captions: `.caption` or `.caption2` - 12pt/11pt, weight: .regular
- Numbers: `.system(size: X, design: .rounded)` - use rounded design for data

**Color Palette (Health/Nutrition):**
- Calories: `.orange` with `.opacity(0.9)`
- Protein: `.red` with `.opacity(0.8)`
- Carbs: `.blue` with `.opacity(0.8)`
- Fat: `.green` with `.opacity(0.8)`
- Fiber: `.brown` with `.opacity(0.8)`
- Success/Goal Met: `.green`
- Warning/Over Goal: `.orange`
- Critical: `.red`

**Spacing Standards:**
- Card padding: 20pt (external), 16-20pt (internal)
- Stack spacing: 12-16pt (related items), 20-24pt (sections)
- Button height: 44-50pt (minimum touch target)
- Corner radius: 16-20pt (cards), 12pt (buttons), 8-10pt (small elements)

**Shadow & Depth:**
```swift
// Subtle elevation for cards
.shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)

// Interactive elements (pressed state)
.shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
```

### Animation Principles

**Spring Physics (iOS 26 Standard):**

```swift
// Standard spring - most interactions
.animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)

// Bouncy spring - playful interactions (food logging)
.animation(.spring(response: 0.5, dampingFraction: 0.6), value: value)

// Snappy spring - quick feedback
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)

// Smooth spring - charts and data visualization
.animation(.spring(response: 0.6, dampingFraction: 0.85), value: chartData)
```

**Keyframe Animations (for complex sequences):**

```swift
.keyframeAnimator(initialValue: 1.0, trigger: didUpdate) { view, scale in
    view.visualEffect { content, _ in
        content.scaleEffect(scale)
    }
} keyframes: { _ in
    SpringKeyframe(0.95, duration: 0.2, spring: .snappy)
    SpringKeyframe(1.0, duration: 0.2, spring: .bouncy)
}
```

---

## Component 1: Daily Calorie Tracker Card

### Design Overview

The Daily Calorie Tracker replaces the existing `nutritionSummaryCard` (lines 471-528) with a modern, interactive iOS 26 Liquid Glass component. It displays:

- **Collapsed state:** Circular progress ring showing calorie intake vs. goal
- **Expanded state:** Meal-by-meal breakdown (breakfast, lunch, dinner, snacks)
- **Macro summary:** Protein, carbs, fat in compact pills below main display
- **Interactive elements:** Tap to expand/collapse with fluid animations

### Visual Design Specifications

**Layout Structure:**

```
┌─────────────────────────────────────┐
│  🔥 Today's Calories      2000 cal  │  ← Header (always visible)
│                                     │
│         ╭───────╮                   │
│        │ 1,847 │  92%              │  ← Progress Ring + Percentage
│         ╰───────╯                   │
│                                     │
│  ⚫ Protein  ⚫ Carbs  ⚫ Fat        │  ← Macro Pills
│                                     │
│  ─────────────────────────────      │  ← Tap to expand divider
│                                     │
│  [Expanded content when tapped]     │
└─────────────────────────────────────┘
```

**Collapsed State (default):**
- Height: ~200pt
- Shows: Circular progress, total calories, goal, macros
- Glass material with subtle shadow
- Tap anywhere to expand

**Expanded State:**
- Height: ~400pt
- Shows: All of above + meal breakdown with bar indicators
- Morphs smoothly using `.matchedGeometryEffect()`
- Tap header or dismiss button to collapse

### SwiftUI Implementation

#### 1. Main Card Structure

```swift
struct DailyCalorieTrackerCard: View {
    @EnvironmentObject var logsManager: LogsManager
    @StateObject private var photoLogManager = PhotoFoodLogManager()

    // State
    @State private var isExpanded = false
    @Namespace private var glassNamespace

    // Constants
    private let dailyCalorieGoal = 2000 // TODO: Make user-configurable
    private let cardCornerRadius: CGFloat = 20

    // Computed properties
    private var todaysNutrition: NutritionData {
        calculateTodaysNutrition()
    }

    private var calorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        return min(Double(todaysNutrition.calories) / Double(dailyCalorieGoal), 1.2)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header - always visible
            headerSection

            // Main content area
            mainContentSection
                .frame(height: isExpanded ? 380 : 200)

            // Expanded meal breakdown
            if isExpanded {
                mealBreakdownSection
                    .transition(.asymmetric(
                        insertion: .push(from: .bottom).combined(with: .opacity),
                        removal: .push(from: .top).combined(with: .opacity)
                    ))
            }
        }
        .glassBackgroundEffect(
            in: .rect(cornerRadius: cardCornerRadius),
            displayMode: .adaptive
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: .black.opacity(isExpanded ? 0.1 : 0.05),
            radius: isExpanded ? 12 : 8,
            x: 0,
            y: isExpanded ? 6 : 3
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isExpanded)
        .contentShape(Rectangle())
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            isExpanded.toggle()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, isActive: todaysNutrition.calories > 0)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Calories")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(todaysNutrition.calories) of \(dailyCalorieGoal) cal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Expand/collapse indicator
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
        }
        .padding(20)
        .background(
            .ultraThinMaterial,
            in: .rect(
                topLeadingRadius: cardCornerRadius,
                topTrailingRadius: cardCornerRadius
            )
        )
    }

    // MARK: - Main Content Section

    private var mainContentSection: some View {
        VStack(spacing: 20) {
            // Circular progress ring
            circularProgressRing

            // Macro pills
            if !isExpanded {
                macroPillsView
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    private var circularProgressRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    .orange.opacity(0.15),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 140, height: 140)

            // Progress ring
            Circle()
                .trim(from: 0, to: calorieProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .orange,
                            calorieProgress > 1.0 ? .red : .orange.opacity(0.7)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270 * calorieProgress - 90)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: calorieProgress)

            // Center content
            VStack(spacing: 4) {
                Text("\(todaysNutrition.calories)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, calorieProgress > 1.0 ? .red : .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("\(Int(calorieProgress * 100))%")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .contentTransition(.numericText(value: Double(todaysNutrition.calories)))
        }
    }

    private var macroPillsView: some View {
        HStack(spacing: 8) {
            MacroPill(
                label: "Protein",
                value: Int(todaysNutrition.protein),
                unit: "g",
                color: .red,
                icon: "p.circle.fill"
            )

            MacroPill(
                label: "Carbs",
                value: Int(todaysNutrition.carbs),
                unit: "g",
                color: .blue,
                icon: "c.circle.fill"
            )

            MacroPill(
                label: "Fat",
                value: Int(todaysNutrition.fat),
                unit: "g",
                color: .green,
                icon: "f.circle.fill"
            )
        }
    }

    // MARK: - Meal Breakdown Section

    private var mealBreakdownSection: some View {
        VStack(spacing: 16) {
            // Section divider
            HStack {
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(height: 1)

                Text("Breakdown")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, 20)

            // Meal bars
            VStack(spacing: 12) {
                MealBar(
                    mealType: "Breakfast",
                    calories: mealBreakdown.breakfast,
                    icon: "sunrise.fill",
                    color: .yellow,
                    maxCalories: dailyCalorieGoal
                )

                MealBar(
                    mealType: "Lunch",
                    calories: mealBreakdown.lunch,
                    icon: "sun.max.fill",
                    color: .orange,
                    maxCalories: dailyCalorieGoal
                )

                MealBar(
                    mealType: "Dinner",
                    calories: mealBreakdown.dinner,
                    icon: "moon.stars.fill",
                    color: .indigo,
                    maxCalories: dailyCalorieGoal
                )

                MealBar(
                    mealType: "Snacks",
                    calories: mealBreakdown.snacks,
                    icon: "leaf.fill",
                    color: .green,
                    maxCalories: dailyCalorieGoal
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Data Calculation

    private func calculateTodaysNutrition() -> NutritionData {
        var totalCalories = 0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0

        // From photo logs
        let todaysPhotos = photoLogManager.getLogsForToday()
        for photo in todaysPhotos {
            if let analysis = photo.aiAnalysis {
                totalCalories += analysis.totalCalories ?? 0
                totalProtein += analysis.totalProtein ?? 0
                totalCarbs += analysis.totalCarbs ?? 0
                totalFat += analysis.totalFat ?? 0
            }
        }

        // From manual/voice logs
        let todaysLogs = logsManager.getTodayLogs()
        for log in todaysLogs where log.type == .food {
            totalCalories += log.calories ?? 0
            totalProtein += Double(log.protein ?? 0)
            totalCarbs += Double(log.carbs ?? 0)
            totalFat += Double(log.fat ?? 0)
        }

        return NutritionData(
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat
        )
    }

    private var mealBreakdown: MealBreakdown {
        // TODO: Implement meal categorization based on LogEntry.date time
        // For now, distribute evenly as placeholder
        let total = todaysNutrition.calories
        return MealBreakdown(
            breakfast: Int(Double(total) * 0.25),
            lunch: Int(Double(total) * 0.35),
            dinner: Int(Double(total) * 0.30),
            snacks: Int(Double(total) * 0.10)
        )
    }
}

// MARK: - Supporting Views

struct MacroPill: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            VStack(spacing: 2) {
                Text("\(value)\(unit)")
                    .font(.caption.weight(.semibold))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
        )
    }
}

struct MealBar: View {
    let mealType: String
    let calories: Int
    let icon: String
    let color: Color
    let maxCalories: Int

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        guard maxCalories > 0 else { return 0 }
        return min(Double(calories) / Double(maxCalories), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)

                    Text(mealType)
                        .font(.subheadline.weight(.medium))
                }

                Spacer()

                Text("\(calories) cal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 8)

                    // Foreground
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Data Models

struct NutritionData {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct MealBreakdown {
    let breakfast: Int
    let lunch: Int
    let dinner: Int
    let snacks: Int
}
```

#### 2. Integration into DashboardView

**Replace existing `nutritionSummaryCard` (line 273):**

```swift
// In DashboardView.swift, line 273
// Replace this:
// nutritionSummaryCard

// With this:
DailyCalorieTrackerCard()
    .environmentObject(logsManager)
```

**Remove old `nutritionSummaryCard` computed property (lines 471-528)**

---

## Component 2: Weekly Calorie Tracker View

### Design Overview

The Weekly Calorie Tracker provides a 7-day visualization of calorie intake using SwiftUI Charts. It displays:

- **Bar chart** showing daily calorie intake for the past 7 days
- **Goal line** indicating target calorie intake
- **Average indicator** showing mean intake for the week
- **Interactive bars** - tap to see detailed breakdown for that day
- **Color coding** - green (under goal), orange (at goal), red (over goal)

### Visual Design Specifications

**Layout Structure:**

```
┌─────────────────────────────────────┐
│  Weekly Calorie Trends              │  ← Title
│  Average: 1,847 cal                 │  ← Subtitle
│                                     │
│      ╷                              │
│  2k  ┼─────────────────── Goal      │  ← Goal line
│      │     █                        │
│      │     █     █                  │
│  1k  │ █   █ █   █   █              │  ← Bar chart
│      │ █   █ █   █   █   █          │
│   0  └─────────────────────         │
│      Mon Tue Wed Thu Fri Sat Sun    │  ← X-axis labels
│                                     │
│  [Tap a bar to see details]         │
└─────────────────────────────────────┘
```

### SwiftUI Charts Implementation

#### 1. Weekly Chart View

```swift
import Charts

struct WeeklyCalorieTrackerView: View {
    @EnvironmentObject var logsManager: LogsManager
    @StateObject private var photoLogManager = PhotoFoodLogManager()

    // State
    @State private var selectedDay: Date?
    @State private var showingDetailSheet = false

    // Constants
    private let dailyCalorieGoal = 2000
    private let cardCornerRadius: CGFloat = 20

    // Computed properties
    private var weeklyData: [DailyCalorieData] {
        calculateWeeklyData()
    }

    private var averageCalories: Int {
        guard !weeklyData.isEmpty else { return 0 }
        let total = weeklyData.reduce(0) { $0 + $1.calories }
        return total / weeklyData.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Chart
            chartSection

            // Legend
            legendSection
        }
        .glassBackgroundEffect(
            in: .rect(cornerRadius: cardCornerRadius),
            displayMode: .adaptive
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .sheet(isPresented: $showingDetailSheet) {
            if let selectedDay = selectedDay {
                DayDetailSheet(
                    date: selectedDay,
                    data: weeklyData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) })
                )
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Calorie Trends")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text("Average:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(averageCalories) cal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(averageColor)
                    }
                }

                Spacer()

                // Week range
                Text(weekRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(20)
        .background(
            .ultraThinMaterial,
            in: .rect(
                topLeadingRadius: cardCornerRadius,
                topTrailingRadius: cardCornerRadius
            )
        )
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(spacing: 16) {
            // Chart
            Chart {
                // Bar marks for daily calories
                ForEach(weeklyData) { data in
                    BarMark(
                        x: .value("Day", data.date, unit: .day),
                        y: .value("Calories", data.calories)
                    )
                    .foregroundStyle(barColor(for: data))
                    .cornerRadius(8)
                    .annotation(position: .top, alignment: .center) {
                        if data.calories > 0 {
                            Text("\(data.calories)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .opacity(selectedDay == data.date ? 1 : 0.7)
                        }
                    }
                }

                // Goal line
                RuleMark(y: .value("Goal", dailyCalorieGoal))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(.orange.opacity(0.6))
                    .annotation(position: .trailing, alignment: .center) {
                        Text("Goal")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.orange.opacity(0.15))
                            )
                    }

                // Average line
                RuleMark(y: .value("Average", averageCalories))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .foregroundStyle(.blue.opacity(0.5))
                    .annotation(position: .leading, alignment: .center) {
                        Text("Avg")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.blue.opacity(0.15))
                            )
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            VStack(spacing: 2) {
                                Text(dayOfWeekFormatter.string(from: date))
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(
                                        Calendar.current.isDateInToday(date) ? .orange : .secondary
                                    )
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.2))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let calories = value.as(Int.self) {
                            Text("\(calories / 1000)k")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.secondary.opacity(0.1))
                }
            }
            .chartYScale(domain: 0...(dailyCalorieGoal + 500))
            .frame(height: 220)
            .chartAngleSelection(value: $selectedDay)
            .onChange(of: selectedDay) { oldValue, newValue in
                if newValue != nil {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingDetailSheet = true
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Legend Section

    private var legendSection: some View {
        HStack(spacing: 20) {
            LegendItem(color: .green, label: "Under Goal")
            LegendItem(color: .orange, label: "At Goal")
            LegendItem(color: .red, label: "Over Goal")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Helper Methods

    private func barColor(for data: DailyCalorieData) -> Color {
        let ratio = Double(data.calories) / Double(dailyCalorieGoal)

        if ratio < 0.9 {
            return .green.opacity(0.8)
        } else if ratio <= 1.1 {
            return .orange.opacity(0.8)
        } else {
            return .red.opacity(0.8)
        }
    }

    private var averageColor: Color {
        let ratio = Double(averageCalories) / Double(dailyCalorieGoal)

        if ratio < 0.9 {
            return .green
        } else if ratio <= 1.1 {
            return .orange
        } else {
            return .red
        }
    }

    private var weekRangeText: String {
        guard let first = weeklyData.first?.date,
              let last = weeklyData.last?.date else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }

    private var dayOfWeekFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }

    // MARK: - Data Calculation

    private func calculateWeeklyData() -> [DailyCalorieData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get last 7 days
        var data: [DailyCalorieData] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            // Calculate calories for this day
            var totalCalories = 0

            // From photo logs
            let photosForDay = photoLogManager.logs.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            for photo in photosForDay {
                if let analysis = photo.aiAnalysis {
                    totalCalories += analysis.totalCalories ?? 0
                }
            }

            // From manual/voice logs
            let logsForDay = logsManager.logEntries.filter {
                $0.type == .food && calendar.isDate($0.date, inSameDayAs: date)
            }
            for log in logsForDay {
                totalCalories += log.calories ?? 0
            }

            data.append(DailyCalorieData(
                date: date,
                calories: totalCalories,
                isToday: calendar.isDateInToday(date)
            ))
        }

        return data
    }
}

// MARK: - Supporting Views

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.8))
                .frame(width: 8, height: 8)

            Text(label)
        }
    }
}

struct DayDetailSheet: View {
    let date: Date
    let data: DailyCalorieData?
    @Environment(\.dismiss) var dismiss

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Date header
                VStack(spacing: 8) {
                    Text(dateFormatter.string(from: date))
                        .font(.title2.weight(.semibold))

                    if let data = data {
                        HStack(spacing: 4) {
                            Text("\(data.calories)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)

                            Text("cal")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 24)

                // TODO: Add meal breakdown, macros, food list
                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding()
            .navigationTitle("Daily Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Data Models

struct DailyCalorieData: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
    let isToday: Bool
}
```

#### 2. Integration Options

**Option A: Add as Card on DashboardView**

```swift
// In DashboardView.swift, after DailyCalorieTrackerCard():
WeeklyCalorieTrackerView()
    .environmentObject(logsManager)
```

**Option B: Add as NavigationLink Destination**

```swift
// In DashboardView.swift, add to DailyCalorieTrackerCard header:
NavigationLink(destination: WeeklyCalorieTrackerView()) {
    HStack(spacing: 4) {
        Image(systemName: "chart.bar.fill")
            .font(.caption)
        Text("Weekly Trends")
            .font(.caption)
    }
    .foregroundStyle(.blue)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(
        Capsule()
            .fill(.blue.opacity(0.1))
    )
}
```

---

## Data Architecture & Integration

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Data Sources                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────┐       ┌──────────────────┐       │
│  │   LogsManager    │       │ PhotoFoodLog     │       │
│  │                  │       │    Manager       │       │
│  │ • LogEntry[]     │       │                  │       │
│  │ • foodName       │       │ • PhotoLog[]     │       │
│  │ • calories       │       │ • aiAnalysis     │       │
│  │ • protein        │       │ • totalCalories  │       │
│  │ • carbs          │       │ • macros         │       │
│  │ • fat            │       │                  │       │
│  │ • date           │       │                  │       │
│  └──────────────────┘       └──────────────────┘       │
│           │                          │                  │
│           └──────────┬───────────────┘                  │
│                      │                                  │
└──────────────────────┼──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│              Calorie Tracker Components                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  DailyCalorieTrackerCard                                │
│  • calculateTodaysNutrition()                           │
│  • Sum calories from both sources                       │
│  • Calculate macros                                     │
│  • Determine meal breakdown                             │
│                                                          │
│  WeeklyCalorieTrackerView                               │
│  • calculateWeeklyData()                                │
│  • Group by date (last 7 days)                          │
│  • Sum daily totals                                     │
│  • Calculate average                                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Data Requirements

#### From LogsManager

**Existing data already available:**

```swift
// Get today's food logs
logsManager.getTodayLogs()
    .filter { $0.type == .food }
    .map { log in
        (
            calories: log.calories ?? 0,
            protein: log.protein ?? 0,
            carbs: log.carbs ?? 0,
            fat: log.fat ?? 0,
            date: log.date
        )
    }
```

**New method needed for weekly data:**

```swift
// Add to LogsManager.swift:
func getLogsForDateRange(start: Date, end: Date) -> [LogEntry] {
    let calendar = Calendar.current
    return logEntries.filter { entry in
        entry.date >= start && entry.date <= end
    }
}

func getFoodLogsGroupedByDay(days: Int = 7) -> [Date: [LogEntry]] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let startDate = calendar.date(byAdding: .day, value: -days, to: today)!

    let foodLogs = logEntries.filter {
        $0.type == .food && $0.date >= startDate
    }

    return Dictionary(grouping: foodLogs) { entry in
        calendar.startOfDay(for: entry.date)
    }
}
```

#### From PhotoFoodLogManager

**Existing data structure (assumed):**

```swift
struct PhotoFoodLog {
    let id: UUID
    let date: Date
    let imageData: Data
    let aiAnalysis: FoodAnalysis?
    let notes: String?
    let mealType: MealType?
}

struct FoodAnalysis {
    let totalCalories: Int?
    let totalProtein: Double?
    let totalCarbs: Double?
    let totalFat: Double?
    let totalFiber: Double?
    let items: [FoodItem]
}
```

**Data access:**

```swift
// Get today's photo logs
photoLogManager.getLogsForToday()
    .compactMap { $0.aiAnalysis }
    .map { analysis in
        (
            calories: analysis.totalCalories ?? 0,
            protein: analysis.totalProtein ?? 0,
            carbs: analysis.totalCarbs ?? 0,
            fat: analysis.totalFat ?? 0
        )
    }
```

### Computed Properties

Both components require these computed properties:

```swift
// Unified nutrition data for today
private var todaysNutrition: NutritionData {
    calculateTodaysNutrition()
}

private func calculateTodaysNutrition() -> NutritionData {
    var totalCalories = 0
    var totalProtein = 0.0
    var totalCarbs = 0.0
    var totalFat = 0.0

    // Aggregate from both sources
    let todaysPhotos = photoLogManager.getLogsForToday()
    for photo in todaysPhotos {
        if let analysis = photo.aiAnalysis {
            totalCalories += analysis.totalCalories ?? 0
            totalProtein += analysis.totalProtein ?? 0
            totalCarbs += analysis.totalCarbs ?? 0
            totalFat += analysis.totalFat ?? 0
        }
    }

    let todaysLogs = logsManager.getTodayLogs()
    for log in todaysLogs where log.type == .food {
        totalCalories += log.calories ?? 0
        totalProtein += Double(log.protein ?? 0)
        totalCarbs += Double(log.carbs ?? 0)
        totalFat += Double(log.fat ?? 0)
    }

    return NutritionData(
        calories: totalCalories,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat
    )
}
```

### Meal Categorization Logic

**Add to LogEntry extension:**

```swift
extension LogEntry {
    var mealCategory: MealCategory {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 5..<11:
            return .breakfast
        case 11..<15:
            return .lunch
        case 15..<18:
            return .snack
        case 18..<23:
            return .dinner
        default:
            return .snack
        }
    }
}

enum MealCategory: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snacks"

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .breakfast: return .yellow
        case .lunch: return .orange
        case .dinner: return .indigo
        case .snack: return .green
        }
    }
}
```

---

## Implementation Roadmap

### Phase 1: Core Setup (Week 1)

**Day 1-2: Data Layer**
- [ ] Add new methods to LogsManager
  - `getLogsForDateRange(start:end:)`
  - `getFoodLogsGroupedByDay(days:)`
- [ ] Add LogEntry extension with `mealCategory`
- [ ] Create data models: `NutritionData`, `MealBreakdown`, `DailyCalorieData`
- [ ] Test data aggregation logic

**Day 3-4: Daily Calorie Tracker Card**
- [ ] Create `DailyCalorieTrackerCard.swift`
- [ ] Implement collapsed state with circular progress
- [ ] Implement macro pills view
- [ ] Add liquid glass effects and shadows
- [ ] Test with sample data

**Day 5-7: Expandable Interaction**
- [ ] Implement expand/collapse animation
- [ ] Add meal breakdown section
- [ ] Create `MealBar` component
- [ ] Wire up tap gestures and haptic feedback
- [ ] Test spring animations and transitions

### Phase 2: Weekly Chart (Week 2)

**Day 1-2: Chart Foundation**
- [ ] Create `WeeklyCalorieTrackerView.swift`
- [ ] Implement weekly data calculation
- [ ] Set up SwiftUI Charts with BarMark
- [ ] Add goal and average RuleMarks

**Day 3-4: Chart Styling**
- [ ] Apply liquid glass background
- [ ] Style axes and labels
- [ ] Implement color coding (green/orange/red)
- [ ] Add annotations and legend

**Day 5-7: Interactivity**
- [ ] Implement bar selection with `.chartAngleSelection()`
- [ ] Create `DayDetailSheet` for drill-down
- [ ] Add haptic feedback
- [ ] Wire up navigation from daily card

### Phase 3: Integration & Polish (Week 3)

**Day 1-2: DashboardView Integration**
- [ ] Replace old `nutritionSummaryCard` with `DailyCalorieTrackerCard`
- [ ] Add `WeeklyCalorieTrackerView` to dashboard
- [ ] Test environment object passing
- [ ] Verify data flows correctly

**Day 3-4: Refinement**
- [ ] Optimize performance (lazy loading, caching)
- [ ] Add loading states and empty states
- [ ] Implement error handling
- [ ] Test on various screen sizes

**Day 5-7: Accessibility & Testing**
- [ ] Add VoiceOver labels and hints
- [ ] Test with Dynamic Type sizes
- [ ] Verify color contrast ratios
- [ ] User acceptance testing

### Phase 4: Advanced Features (Week 4+)

**Optional Enhancements:**
- [ ] User-configurable calorie goal
- [ ] Custom meal time ranges
- [ ] Export weekly chart as image
- [ ] Push notifications for goal achievements
- [ ] HealthKit integration for calorie burn
- [ ] Pregnancy-specific calorie recommendations

---

## Performance & Accessibility

### Performance Considerations

**1. Data Caching**

```swift
class CalorieDataCache: ObservableObject {
    @Published var todaysNutrition: NutritionData?
    @Published var weeklyData: [DailyCalorieData]?

    private var lastUpdate: Date?
    private let cacheTimeout: TimeInterval = 60 // 1 minute

    func invalidate() {
        todaysNutrition = nil
        weeklyData = nil
        lastUpdate = nil
    }

    func needsUpdate() -> Bool {
        guard let lastUpdate = lastUpdate else { return true }
        return Date().timeIntervalSince(lastUpdate) > cacheTimeout
    }
}
```

**2. Lazy Data Loading**

```swift
// In DailyCalorieTrackerCard
@State private var nutritionData: NutritionData?

var body: some View {
    // UI code
}
.task {
    if nutritionData == nil {
        nutritionData = await calculateNutritionInBackground()
    }
}

private func calculateNutritionInBackground() async -> NutritionData {
    await Task.detached(priority: .userInitiated) {
        // Heavy calculation
        let data = calculateTodaysNutrition()
        return data
    }.value
}
```

**3. Chart Optimization**

```swift
// Limit chart data points
private var weeklyDataOptimized: [DailyCalorieData] {
    weeklyData.filter { $0.calories > 0 } // Only show days with data
}

// Use `.chartYScale(domain:)` to prevent unnecessary redraws
.chartYScale(domain: 0...(dailyCalorieGoal + 500))
```

### Accessibility Implementation

**1. VoiceOver Support**

```swift
// Daily Calorie Tracker Card
.accessibilityLabel("Daily calorie tracker")
.accessibilityValue("\(todaysNutrition.calories) calories consumed out of \(dailyCalorieGoal) calorie goal, \(Int(calorieProgress * 100)) percent complete")
.accessibilityHint(isExpanded ? "Double tap to collapse meal breakdown" : "Double tap to see meal breakdown")

// Circular progress ring
.accessibilityElement(children: .combine)
.accessibilityLabel("Calorie progress")
.accessibilityValue("\(todaysNutrition.calories) of \(dailyCalorieGoal) calories, \(Int(calorieProgress * 100)) percent")

// Macro pills
MacroPill(...)
    .accessibilityLabel("\(label): \(value) \(unit)")

// Meal bars
MealBar(...)
    .accessibilityLabel("\(mealType): \(calories) calories, \(Int(progress * 100)) percent of daily goal")
```

**2. Dynamic Type Support**

```swift
// Use scalable fonts
Text("Today's Calories")
    .font(.headline)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Limit scaling

// Adjust layout for large text
@Environment(\.dynamicTypeSize) var dynamicTypeSize

var useCompactLayout: Bool {
    dynamicTypeSize >= .xLarge
}

// Conditional stacks
Group {
    if useCompactLayout {
        VStack { macroContent }
    } else {
        HStack { macroContent }
    }
}
```

**3. Reduced Motion**

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Conditional animations
.animation(
    reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.5, dampingFraction: 0.7),
    value: isExpanded
)

// Alternative to complex animations
if reduceMotion {
    // Show immediate state change
} else {
    // Show animated transition
    .transition(.asymmetric(...))
}
```

**4. Color Contrast**

```swift
// Ensure minimum 4.5:1 contrast ratio for text
// Use `.foregroundStyle()` instead of `.foregroundColor()` for adaptive colors

// Test contrast in both light and dark modes
.foregroundStyle(.primary) // Adapts to color scheme
.foregroundStyle(.secondary) // Adapts with proper contrast

// For custom colors, provide variants
extension Color {
    static var calorieOrange: Color {
        Color("CalorieOrange") // Define in Assets with light/dark variants
    }
}
```

**5. Reduced Transparency**

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

// Conditional materials
.background(
    reduceTransparency
        ? Color(.systemBackground)
        : .ultraThinMaterial
)

// Alternative to glass effects
if reduceTransparency {
    // Use solid colors
    .background(Color(.secondarySystemBackground))
} else {
    // Use liquid glass
    .glassBackgroundEffect(...)
}
```

### Testing Checklist

**Functional Testing:**
- [ ] Data aggregates correctly from LogsManager and PhotoFoodLogManager
- [ ] Circular progress ring shows accurate percentage
- [ ] Expand/collapse animation works smoothly
- [ ] Meal breakdown calculates correctly based on time
- [ ] Weekly chart displays last 7 days
- [ ] Bar selection opens detail sheet
- [ ] Goal and average lines render correctly
- [ ] Empty states display when no data

**Visual Testing:**
- [ ] Liquid glass effect renders properly
- [ ] Colors are vibrant but not overwhelming
- [ ] Shadows provide appropriate depth
- [ ] Typography is readable at all sizes
- [ ] Layout adapts to different screen sizes (SE, 14 Pro, 14 Pro Max)
- [ ] Dark mode looks good
- [ ] Tinted app icons don't clash with UI

**Accessibility Testing:**
- [ ] VoiceOver reads all elements correctly
- [ ] All interactive elements have proper labels and hints
- [ ] Dynamic Type scales appropriately up to xxxLarge
- [ ] Reduced Motion disables complex animations
- [ ] Reduced Transparency replaces glass with solid colors
- [ ] Color contrast meets WCAG AA standards
- [ ] Haptic feedback works on supported devices

**Performance Testing:**
- [ ] No lag when scrolling dashboard
- [ ] Chart renders within 100ms
- [ ] Expand animation is smooth (60fps)
- [ ] No memory leaks after repeated use
- [ ] Data calculation doesn't block main thread

---

## Resources & References

### Official Apple Resources

**WWDC 2025 Sessions:**
- [Meet Liquid Glass (WWDC25-219)](https://developer.apple.com/videos/play/wwdc2025/219/) - Design principles and optical properties
- [Build a SwiftUI app with the new design (WWDC25-323)](https://developer.apple.com/videos/play/wwdc2025/323/) - Implementation patterns
- [Get to know the new design system (WWDC25-356)](https://developer.apple.com/videos/play/wwdc2025/356/) - Visual design and structure

**Documentation:**
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [Human Interface Guidelines: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [SwiftUI Charts Documentation](https://developer.apple.com/documentation/Charts)

### Community Resources

**Articles & Guides:**
- [iOS 26 — Liquid Glass Design (Medium)](https://medium.com/codex/liquid-glass-design-5e57f5faddc3) - Comprehensive overview
- [Designing custom UI with Liquid Glass on iOS 26 (Donny Wals)](https://www.donnywals.com/designing-custom-ui-with-liquid-glass-on-ios-26/) - Practical patterns
- [Apple Liquid Glass: The UX Evolution (Supercharge Design)](https://supercharge.design/blog/apple-liquid-glass-the-ux-evolution-of-adaptive-interfaces) - Strategic insights
- [Exploring a new visual language: Liquid Glass (Create with Swift)](https://createwithswift.com/exploring-a-new-visual-language-liquid-glass) - Technical deep dive

**Code Examples:**
- [Liquid Glass UI Toolkit](https://glassui.dev) - Reference implementations
- [SwiftGlass Library](https://github.com/1998code/SwiftGlass) - Custom glass effects
- [Swift Charts Examples](https://developer.apple.com/documentation/Charts) - Official samples

### Design Inspiration

**Apps with Excellent Liquid Glass Implementation:**
- Widgetsmith 8
- Dark Noise
- Overcast
- Pedometer++ 7
- Carrot Weather
- CardioBot (Health tracking reference)

### Calorie Tracking References

**Health Tracking Patterns:**
- Apple Health app - Nutrition section
- MyFitnessPal - Daily diary and charts
- Lose It! - Circular progress design
- Noom - Meal categorization

### SwiftUI Charts Resources

**Tutorials:**
- [Mastering SwiftUI Charts (Medium)](https://elamir.medium.com/mastering-swiftui-charts-a-comprehensive-guide-with-swift-charts-e9a39619b40f)
- [Bar Chart creation using Swift Charts (SwiftLee)](https://www.avanderlee.com/swift-charts/bar-chart-creation-using-swift-charts/)
- [Practical Data Visualization with SwiftUI Charts (Medium)](https://medium.com/data-science-collective/practical-data-visualization-with-swiftui-charts-patterns-and-pitfalls-f2abe4251c84)

**WWDC Sessions:**
- [Explore pie charts and interactivity in Swift Charts (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10037/)
- [Swift Charts: Vectorized and function plots (WWDC24)](https://developer.apple.com/videos/play/wwdc2024/10155/)

---

## Migration Notes

### From Existing UI to Liquid Glass

**Current Implementation (lines 471-528):**
- Uses `.background(Color(.secondarySystemBackground))`
- Static corner radius with `.clipShape(RoundedRectangle(cornerRadius: 16))`
- Basic shadow `.shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)`
- No interactive materials or depth

**New Implementation:**
- Uses `.glassBackgroundEffect()` with adaptive display mode
- Dynamic materials that respond to content
- Enhanced depth with gradient borders
- Interactive animations with spring physics
- Expandable states with fluid transitions

### Breaking Changes

**None.** The new components are drop-in replacements that:
- Use the same data sources (LogsManager, PhotoFoodLogManager)
- Maintain the same API surface
- Require no changes to existing log entry structure
- Work with existing EnvironmentObjects

### Recommended Additions to LogsManager

```swift
// Add these methods to LogsManager.swift for optimal performance:

extension LogsManager {
    func getLogsForDateRange(start: Date, end: Date) -> [LogEntry] {
        let calendar = Calendar.current
        return logEntries.filter { entry in
            entry.date >= start && entry.date <= end
        }
    }

    func getFoodLogsGroupedByDay(days: Int = 7) -> [Date: [LogEntry]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return [:]
        }

        let foodLogs = logEntries.filter {
            $0.type == .food && $0.date >= startDate
        }

        return Dictionary(grouping: foodLogs) { entry in
            calendar.startOfDay(for: entry.date)
        }
    }

    func getTodayCalorieTotal() -> Int {
        logsForToday()
            .filter { $0.type == .food }
            .compactMap { $0.calories }
            .reduce(0, +)
    }
}
```

---

## Conclusion

This document provides comprehensive guidance for implementing iOS 26 Liquid Glass calorie tracking components. Key takeaways:

1. **Liquid Glass is transformative** - not just visual polish, but a new interaction paradigm
2. **Content-first design** - UI should enhance, not overwhelm, the user's data
3. **SwiftUI Charts is powerful** - native framework provides excellent performance and accessibility
4. **Spring animations are essential** - all interactions should feel fluid and natural
5. **Accessibility is built-in** - use semantic modifiers and test with assistive technologies

### Next Steps

1. **Review this document** with the development team
2. **Set up dev environment** with iOS 26 SDK and Xcode 26
3. **Start with Phase 1** - data layer and daily tracker card
4. **Iterate based on feedback** - test with real users and pregnancy nutrition experts
5. **Monitor iOS 26 adoption** - adjust implementation as community best practices evolve

### Questions or Issues?

Refer to:
- WWDC 2025 session videos for design philosophy
- Apple Developer Forums for technical questions
- Human Interface Guidelines for design decisions
- SwiftUI Charts documentation for chart-specific issues

---

**Document Version:** 1.0
**Last Updated:** October 14, 2025
**Author:** iOS 26 UI Research Specialist (Claude)
**Target iOS Version:** iOS 26+ (Fall 2025)
