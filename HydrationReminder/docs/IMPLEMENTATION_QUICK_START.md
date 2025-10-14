# Quick Start: Implementing iOS 26 Calorie Trackers

**Read this first for a rapid implementation overview. For full details, see the main design document.**

---

## What You're Building

### 1. Daily Calorie Tracker Card
- **Replaces:** `nutritionSummaryCard` (lines 471-528 in DashboardView.swift)
- **Features:** Circular progress ring, tap-to-expand, meal breakdown
- **Time:** ~1-2 days for basic implementation

### 2. Weekly Calorie Tracker View
- **Location:** New card on DashboardView OR NavigationLink destination
- **Features:** 7-day bar chart with SwiftUI Charts, interactive bars
- **Time:** ~2-3 days for basic implementation

---

## File Structure

Create these new files:

```
HydrationReminder/
├── Views/
│   └── Nutrition/
│       ├── DailyCalorieTrackerCard.swift        (NEW)
│       ├── WeeklyCalorieTrackerView.swift       (NEW)
│       └── NutritionDataModels.swift            (NEW)
```

---

## Step 1: Add Data Models (5 minutes)

**Create: `NutritionDataModels.swift`**

```swift
import Foundation
import SwiftUI

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

struct DailyCalorieData: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
    let isToday: Bool
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

extension LogEntry {
    var mealCategory: MealCategory {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<18: return .snack
        case 18..<23: return .dinner
        default: return .snack
        }
    }
}
```

---

## Step 2: Extend LogsManager (10 minutes)

**Add to `LogsManager.swift`:**

```swift
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
}
```

---

## Step 3: Create Daily Calorie Card (30-60 minutes)

**Create: `DailyCalorieTrackerCard.swift`**

Copy the complete implementation from the main design document (section "Component 1: Daily Calorie Tracker Card"). The file includes:

- Main card structure with expand/collapse
- Circular progress ring
- Macro pills
- Meal breakdown section
- All supporting views (MacroPill, MealBar)

**Key features:**
- ✅ Liquid Glass with `.glassBackgroundEffect()`
- ✅ Spring animations
- ✅ Tap to expand gesture
- ✅ Haptic feedback
- ✅ Gradient borders and shadows

---

## Step 4: Create Weekly Chart (30-60 minutes)

**Create: `WeeklyCalorieTrackerView.swift`**

Copy the complete implementation from the main design document (section "Component 2: Weekly Calorie Tracker View"). The file includes:

- 7-day bar chart with SwiftUI Charts
- Goal and average lines
- Interactive bar selection
- Day detail sheet
- Legend and formatting

**Key features:**
- ✅ SwiftUI Charts with BarMark
- ✅ Color-coded bars (green/orange/red)
- ✅ Tap to see details
- ✅ Liquid Glass styling
- ✅ Axis customization

---

## Step 5: Integrate into DashboardView (5 minutes)

### Option A: Replace Nutrition Card

In `DashboardView.swift`, **line 273**, replace:

```swift
// OLD
nutritionSummaryCard

// NEW
DailyCalorieTrackerCard()
    .environmentObject(logsManager)
```

Then **delete** the old `nutritionSummaryCard` computed property (lines 471-528).

### Option B: Add Weekly Chart

**After** the Daily Calorie Card, add:

```swift
WeeklyCalorieTrackerView()
    .environmentObject(logsManager)
```

---

## Step 6: Test (15 minutes)

### Checklist:
- [ ] Daily card shows correct calorie total
- [ ] Tap to expand works smoothly
- [ ] Meal breakdown calculates correctly
- [ ] Weekly chart shows last 7 days
- [ ] Bar colors are correct (green/orange/red)
- [ ] Tapping bars opens detail sheet
- [ ] Dark mode looks good
- [ ] No console errors

### Sample Data for Testing:

```swift
// Add some test food logs
logsManager.logFood(
    notes: "Breakfast - oatmeal",
    source: .manual,
    foodName: "Oatmeal with berries",
    calories: 350,
    protein: 12,
    carbs: 58,
    fat: 8
)

logsManager.logFood(
    notes: "Lunch - salad",
    source: .manual,
    foodName: "Chicken salad",
    calories: 450,
    protein: 35,
    carbs: 30,
    fat: 18
)
```

---

## Common Issues & Fixes

### Issue: "Type 'LogsManager' has no member 'getLogsForDateRange'"
**Fix:** Add the LogsManager extension from Step 2

### Issue: Glass effect not showing
**Fix:** Make sure you're running on iOS 26+ simulator/device

### Issue: Weekly chart is empty
**Fix:** Ensure you have food logs with calorie data from the past 7 days

### Issue: Animation is stuttering
**Fix:** Check that you're not doing heavy calculations on the main thread

---

## Customization Options

### Change Daily Calorie Goal

In `DailyCalorieTrackerCard.swift`:

```swift
private let dailyCalorieGoal = 2000  // Change this value
```

**Better approach:** Make it user-configurable with @AppStorage:

```swift
@AppStorage("dailyCalorieGoal") private var dailyCalorieGoal = 2000
```

### Adjust Colors

```swift
// In DailyCalorieTrackerCard.swift
.foregroundStyle(.orange)  // Change to your brand color

// In WeeklyCalorieTrackerView.swift
private func barColor(for data: DailyCalorieData) -> Color {
    // Customize color logic here
}
```

### Change Week Range

```swift
// In WeeklyCalorieTrackerView.swift
for dayOffset in (0..<14).reversed() {  // Show 14 days instead of 7
    // ...
}
```

---

## Next Steps

1. ✅ **Basic implementation** (Steps 1-6 above)
2. **Polish animations** - Fine-tune spring physics
3. **Add empty states** - Handle no data gracefully
4. **Implement caching** - Optimize performance
5. **Add accessibility** - VoiceOver labels and Dynamic Type
6. **User testing** - Get feedback from pregnancy nutrition users

---

## Need Help?

- **Main design document:** See `ios26-calorie-tracker-liquid-glass-design-2025-10-14.md` for complete details
- **iOS 26 specifics:** Review WWDC25 sessions on Liquid Glass
- **SwiftUI Charts:** Check Apple's Charts documentation
- **Data issues:** Verify LogsManager and PhotoFoodLogManager are working correctly

---

## Timeline Estimate

| Phase | Time | Tasks |
|-------|------|-------|
| Setup | 30 min | Data models, LogsManager extensions |
| Daily Card | 2-3 hours | Full implementation with animations |
| Weekly Chart | 2-3 hours | SwiftUI Charts setup and styling |
| Integration | 30 min | Add to DashboardView |
| Testing | 1 hour | Functional and visual testing |
| **Total** | **6-8 hours** | For basic working implementation |

Add 2-4 more hours for polish, accessibility, and edge cases.

---

**Quick wins:**
- Start with just the Daily Card (skip weekly for now)
- Use placeholder meal breakdown initially
- Test with mock data before using real logs
- Deploy to TestFlight early for feedback

**Pro tips:**
- Copy code exactly from design doc first, then customize
- Test on real device for best Liquid Glass preview
- Use Xcode Previews for rapid iteration
- Keep spring animation values consistent across components

Good luck! 🚀
