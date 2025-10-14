# Health Tracking Framework Design
## Multi-Event Type System for Pregnancy App

**Date:** 2025-10-14
**Status:** Design Phase - DO NOT IMPLEMENT YET
**Purpose:** Framework for logging food, vitamins, symptoms, and other health events

---

## 1. Overview

This document outlines a unified, protocol-based architecture for tracking multiple health event types in the pregnancy tracking app. The system is designed to be extensible, type-safe, and iOS 26-compliant.

### Goals
- ✅ Unified interface for all health tracking events
- ✅ Type-safe data models with shared patterns
- ✅ Consistent UI/UX across different event types
- ✅ Easy to add new event types in the future
- ✅ Seamless voice command integration

---

## 2. Architecture

### 2.1 Protocol-Based Design

```swift
/// Base protocol for all health tracking events
protocol HealthEvent: Identifiable, Codable {
    var id: UUID { get }
    var date: Date { get set }
    var notes: String? { get set }
    var confidence: Double? { get }

    /// Icon name for UI representation
    var icon: String { get }

    /// Color for UI representation
    var color: Color { get }

    /// Category for grouping
    var category: HealthEventCategory { get }

    /// Human-readable summary
    var displaySummary: String { get }
}

enum HealthEventCategory: String, Codable, CaseIterable {
    case nutrition = "Nutrition"
    case supplements = "Supplements"
    case symptoms = "Symptoms"
    case hydration = "Hydration"
    case measurements = "Measurements"
    case medications = "Medications"
    case activities = "Activities"

    var icon: String {
        switch self {
        case .nutrition: return "fork.knife"
        case .supplements: return "pills.fill"
        case .symptoms: return "heart.text.square"
        case .hydration: return "drop.fill"
        case .measurements: return "ruler.fill"
        case .medications: return "cross.case.fill"
        case .activities: return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .nutrition: return .orange
        case .supplements: return .green
        case .symptoms: return .purple
        case .hydration: return .blue
        case .measurements: return .pink
        case .medications: return .red
        case .activities: return .cyan
        }
    }
}
```

---

## 3. Specific Event Types

### 3.1 Food Event (Enhanced from current implementation)

```swift
struct FoodEvent: HealthEvent {
    let id: UUID
    var date: Date
    var notes: String?
    let confidence: Double?

    // Food-specific properties
    var item: String
    var isCompoundMeal: Bool
    var components: [MealComponent]?
    var mealType: MealType?
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var fiber: Double?

    var icon: String { "fork.knife" }
    var color: Color { .orange }
    var category: HealthEventCategory { .nutrition }

    var displaySummary: String {
        if isCompoundMeal, let components = components {
            let componentNames = components.map { $0.name }.joined(separator: ", ")
            return "\(item) (\(componentNames))"
        }
        return item
    }

    struct MealComponent: Codable, Identifiable {
        let id: UUID
        let name: String
        let quantity: String?
        var calories: Int?

        init(id: UUID = UUID(), name: String, quantity: String?, calories: Int? = nil) {
            self.id = id
            self.name = name
            self.quantity = quantity
            self.calories = calories
        }
    }
}
```

### 3.2 Vitamin/Supplement Event

```swift
struct SupplementEvent: HealthEvent {
    let id: UUID
    var date: Date
    var notes: String?
    let confidence: Double?

    // Supplement-specific properties
    var name: String
    var dosage: String
    var unit: String // "mg", "mcg", "IU", etc.
    var frequency: SupplementFrequency
    var isPrenatal: Bool
    var timesPerDay: Int
    var takenAt: [Date] // For tracking individual doses

    var icon: String { isPrenatal ? "pills.circle.fill" : "pills.fill" }
    var color: Color { isPrenatal ? .green : .mint }
    var category: HealthEventCategory { .supplements }

    var displaySummary: String {
        "\(name) - \(dosage)\(unit)"
    }

    enum SupplementFrequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case twiceDaily = "Twice Daily"
        case threeTimesDaily = "3x Daily"
        case weekly = "Weekly"
        case asNeeded = "As Needed"

        var timesPerDay: Int {
            switch self {
            case .daily: return 1
            case .twiceDaily: return 2
            case .threeTimesDaily: return 3
            case .weekly: return 0
            case .asNeeded: return 0
            }
        }
    }
}
```

### 3.3 Symptom Event

```swift
struct SymptomEvent: HealthEvent {
    let id: UUID
    var date: Date
    var notes: String?
    let confidence: Double?

    // Symptom-specific properties
    var type: SymptomType
    var severity: SeverityLevel
    var duration: TimeInterval? // in seconds
    var triggers: [String]? // possible triggers
    var relief: [String]? // what helped

    var icon: String { type.icon }
    var color: Color { severity.color }
    var category: HealthEventCategory { .symptoms }

    var displaySummary: String {
        "\(type.rawValue) - \(severity.rawValue)"
    }

    enum SymptomType: String, Codable, CaseIterable {
        case nausea = "Nausea"
        case vomiting = "Vomiting"
        case headache = "Headache"
        case fatigue = "Fatigue"
        case cramps = "Cramps"
        case backPain = "Back Pain"
        case heartburn = "Heartburn"
        case constipation = "Constipation"
        case swelling = "Swelling"
        case moodSwing = "Mood Changes"
        case other = "Other"

        var icon: String {
            switch self {
            case .nausea: return "waveform.path.ecg"
            case .vomiting: return "exclamationmark.triangle.fill"
            case .headache: return "brain.head.profile"
            case .fatigue: return "bed.double.fill"
            case .cramps: return "bolt.fill"
            case .backPain: return "figure.stand"
            case .heartburn: return "flame.fill"
            case .constipation: return "stomach"
            case .swelling: return "arrow.up.circle.fill"
            case .moodSwing: return "cloud.rain.fill"
            case .other: return "heart.text.square"
            }
        }
    }

    enum SeverityLevel: String, Codable, CaseIterable {
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"

        var color: Color {
            switch self {
            case .mild: return .green
            case .moderate: return .orange
            case .severe: return .red
            }
        }

        var numericValue: Int {
            switch self {
            case .mild: return 1
            case .moderate: return 2
            case .severe: return 3
            }
        }
    }
}
```

### 3.4 Hydration Event (Enhanced from current implementation)

```swift
struct HydrationEvent: HealthEvent {
    let id: UUID
    var date: Date
    var notes: String?
    let confidence: Double?

    // Hydration-specific properties
    var amount: Double // in mL
    var beverage: BeverageType
    var temperature: BeverageTemperature?

    var icon: String { beverage.icon }
    var color: Color { .blue }
    var category: HealthEventCategory { .hydration }

    var displaySummary: String {
        "\(Int(amount))mL \(beverage.rawValue)"
    }

    enum BeverageType: String, Codable, CaseIterable {
        case water = "Water"
        case herbalTea = "Herbal Tea"
        case milk = "Milk"
        case juice = "Juice"
        case smoothie = "Smoothie"
        case other = "Other"

        var icon: String {
            switch self {
            case .water: return "drop.fill"
            case .herbalTea: return "cup.and.saucer.fill"
            case .milk: return "mug.fill"
            case .juice: return "wineglass.fill"
            case .smoothie: return "cup.and.saucer.fill"
            case .other: return "drop.circle.fill"
            }
        }
    }

    enum BeverageTemperature: String, Codable {
        case cold = "Cold"
        case room = "Room Temperature"
        case warm = "Warm"
        case hot = "Hot"
    }
}
```

---

## 4. Unified Event Manager

```swift
class HealthEventManager: ObservableObject {
    @Published var events: [any HealthEvent] = []

    private let userDefaultsKey = "HealthEvents"

    init() {
        loadEvents()
    }

    // MARK: - Event Management

    func addEvent<T: HealthEvent>(_ event: T) {
        events.append(event)
        saveEvents()
    }

    func updateEvent<T: HealthEvent>(_ event: T) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
        }
    }

    func deleteEvent<T: HealthEvent>(_ event: T) {
        events.removeAll { $0.id == event.id }
        saveEvents()
    }

    // MARK: - Filtering

    func events(for category: HealthEventCategory) -> [any HealthEvent] {
        events.filter { $0.category == category }
    }

    func events(on date: Date) -> [any HealthEvent] {
        let calendar = Calendar.current
        return events.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func events(between startDate: Date, and endDate: Date) -> [any HealthEvent] {
        events.filter { $0.date >= startDate && $0.date <= endDate }
    }

    // MARK: - Type-Specific Getters

    func foodEvents() -> [FoodEvent] {
        events.compactMap { $0 as? FoodEvent }
    }

    func supplementEvents() -> [SupplementEvent] {
        events.compactMap { $0 as? SupplementEvent }
    }

    func symptomEvents() -> [SymptomEvent] {
        events.compactMap { $0 as? SymptomEvent }
    }

    func hydrationEvents() -> [HydrationEvent] {
        events.compactMap { $0 as? HydrationEvent }
    }

    // MARK: - Analytics

    func totalCalories(for date: Date) -> Int {
        let foodEvents = foodEvents().filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        return foodEvents.compactMap { $0.calories }.reduce(0, +)
    }

    func totalHydration(for date: Date) -> Double {
        let hydrationEvents = hydrationEvents().filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        return hydrationEvents.map { $0.amount }.reduce(0, +)
    }

    func symptomFrequency(for type: SymptomEvent.SymptomType, days: Int = 7) -> Int {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return symptomEvents().filter {
            $0.type == type && $0.date >= startDate
        }.count
    }

    // MARK: - Persistence

    private func saveEvents() {
        // Implementation would use a proper storage mechanism
        // Could use CoreData, SwiftData, or custom JSON encoding with type info
    }

    private func loadEvents() {
        // Implementation would load from storage
    }
}
```

---

## 5. Voice Command Integration

### 5.1 Enhanced VoiceAction Support

The current `VoiceAction` struct already supports multiple action types. Here's how to integrate with the new framework:

```swift
extension HealthEventManager {
    /// Convert a VoiceAction to the appropriate HealthEvent type
    func createEvent(from action: VoiceAction) -> (any HealthEvent)? {
        switch action.type {
        case .logFood:
            return createFoodEvent(from: action)
        case .logWater:
            return createHydrationEvent(from: action)
        case .logSymptom:
            return createSymptomEvent(from: action)
        case .logVitamin:
            return createSupplementEvent(from: action)
        case .addVitamin:
            return createSupplementSchedule(from: action)
        default:
            return nil
        }
    }

    private func createFoodEvent(from action: VoiceAction) -> FoodEvent? {
        guard let item = action.details.item else { return nil }

        let components: [FoodEvent.MealComponent]? = action.details.components?.map {
            FoodEvent.MealComponent(
                name: $0.name,
                quantity: $0.quantity
            )
        }

        return FoodEvent(
            id: UUID(),
            date: parseDate(from: action.details.timestamp) ?? Date(),
            notes: action.details.notes,
            confidence: action.confidence,
            item: item,
            isCompoundMeal: action.details.isCompoundMeal ?? false,
            components: components,
            mealType: parseMealType(action.details.mealType),
            calories: Int(action.details.calories ?? ""),
            protein: nil, // Would be calculated via estimateFoodMacros
            carbs: nil,
            fat: nil,
            fiber: nil
        )
    }

    private func createHydrationEvent(from action: VoiceAction) -> HydrationEvent? {
        guard let amountStr = action.details.amount else { return nil }
        let amount = Double(amountStr) ?? 250.0 // default to 250mL

        return HydrationEvent(
            id: UUID(),
            date: parseDate(from: action.details.timestamp) ?? Date(),
            notes: action.details.notes,
            confidence: action.confidence,
            amount: amount,
            beverage: .water, // default, could be enhanced
            temperature: nil
        )
    }

    private func createSymptomEvent(from action: VoiceAction) -> SymptomEvent? {
        // Parse symptom details from action
        guard let symptoms = action.details.symptoms,
              let firstSymptom = symptoms.first else { return nil }

        let symptomType = parseSymptomType(firstSymptom)
        let severity = parseSeverity(action.details.severity)

        return SymptomEvent(
            id: UUID(),
            date: parseDate(from: action.details.timestamp) ?? Date(),
            notes: action.details.notes,
            confidence: action.confidence,
            type: symptomType,
            severity: severity,
            duration: nil,
            triggers: nil,
            relief: nil
        )
    }

    private func createSupplementEvent(from action: VoiceAction) -> SupplementEvent? {
        guard let name = action.details.vitaminName else { return nil }

        let dosage = action.details.dosage ?? "1"
        let timesPerDay = action.details.timesPerDay ?? 1

        return SupplementEvent(
            id: UUID(),
            date: parseDate(from: action.details.timestamp) ?? Date(),
            notes: action.details.notes,
            confidence: action.confidence,
            name: name,
            dosage: dosage,
            unit: "tablet", // default, could be enhanced
            frequency: timesPerDay == 1 ? .daily : .twiceDaily,
            isPrenatal: name.lowercased().contains("prenatal"),
            timesPerDay: timesPerDay,
            takenAt: [Date()]
        )
    }

    // Helper methods
    private func parseDate(from timestamp: String?) -> Date? {
        guard let timestamp = timestamp else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timestamp)
    }

    private func parseMealType(_ type: String?) -> FoodEvent.MealType? {
        guard let type = type else { return nil }
        return FoodEvent.MealType(rawValue: type.capitalized)
    }

    private func parseSymptomType(_ symptom: String) -> SymptomEvent.SymptomType {
        let lowercased = symptom.lowercased()
        if lowercased.contains("nausea") || lowercased.contains("nauseous") {
            return .nausea
        } else if lowercased.contains("vomit") || lowercased.contains("puke") {
            return .vomiting
        } else if lowercased.contains("headache") || lowercased.contains("head") {
            return .headache
        }
        // Add more mappings...
        return .other
    }

    private func parseSeverity(_ severity: String?) -> SymptomEvent.SeverityLevel {
        guard let severity = severity?.lowercased() else { return .mild }
        if severity.contains("severe") || severity.contains("bad") {
            return .severe
        } else if severity.contains("moderate") || severity.contains("medium") {
            return .moderate
        }
        return .mild
    }
}
```

---

## 6. UI Components

### 6.1 Unified Event Row (iOS 26 Liquid Glass)

```swift
struct HealthEventRow: View {
    let event: any HealthEvent

    var body: some View {
        HStack(spacing: 12) {
            // Icon with category color
            Image(systemName: event.icon)
                .font(.title3)
                .foregroundStyle(event.color.gradient)
                .frame(width: 44, height: 44)
                .background(
                    event.color.opacity(0.15),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(event.displaySummary)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(event.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(formatTime(event.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let confidence = event.confidence, confidence < 0.8 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
```

### 6.2 Category Filter View

```swift
struct HealthEventFilterView: View {
    @Binding var selectedCategory: HealthEventCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }

                ForEach(HealthEventCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? color.gradient : Color.clear,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
            .foregroundStyle(isSelected ? .white : color)
        }
    }
}
```

---

## 7. Migration Strategy

### Phase 1: Core Framework (Week 1)
1. ✅ Define `HealthEvent` protocol and base types
2. ✅ Implement `FoodEvent` as enhanced version of current food logging
3. ✅ Create `HealthEventManager` with basic CRUD operations
4. ✅ Add persistence layer

### Phase 2: New Event Types (Week 2)
1. Implement `SupplementEvent` with full tracking
2. Implement `SymptomEvent` with severity tracking
3. Enhance `HydrationEvent` from current water logging
4. Update voice command integration

### Phase 3: UI Enhancement (Week 3)
1. Create unified event list view
2. Implement category filtering
3. Add event detail views for each type
4. Create analytics dashboard

### Phase 4: Advanced Features (Week 4+)
1. Add correlations between events (e.g., nausea after certain foods)
2. Implement reminders for supplements
3. Add export functionality
4. Create insights and recommendations

---

## 8. Benefits of This Approach

1. **Type Safety**: Each event type has specific properties while sharing common protocol
2. **Extensibility**: Easy to add new event types without breaking existing code
3. **Unified UI**: Consistent user experience across all event types
4. **Better Analytics**: Can correlate different event types (e.g., nausea vs food)
5. **Voice Integration**: Seamless conversion from voice commands to events
6. **iOS 26 Ready**: Liquid Glass UI components throughout

---

## 9. Implementation Priority

### Must Implement (for food logging fix):
- ✅ Enhanced `FoodEvent` with compound meal support
- ✅ Updated voice command parsing
- ✅ Meal confirmation UI

### Should Implement (high value):
- SymptomEvent (especially for puking/nausea tracking)
- SupplementEvent (vitamin tracking)
- Enhanced HydrationEvent

### Nice to Have:
- Activity tracking
- Medication tracking
- Measurement tracking (weight, BP, etc.)

---

## 10. Next Steps

**DO NOT IMPLEMENT YET - User should review first**

Once approved, the implementation order should be:
1. Migrate current food logging to new `FoodEvent` model
2. Add `SymptomEvent` for puking/nausea tracking
3. Add `SupplementEvent` for vitamin tracking
4. Create unified timeline view
5. Add analytics and insights

---

## Questions for User

1. Should symptoms like "puking" trigger automatic suggestions (e.g., ginger tea, small meals)?
2. Do you want reminders for vitamins/supplements?
3. Should the app track medication separately from supplements?
4. Do you want to track pregnancy symptoms like kicks, contractions, etc.?
5. Should food and symptoms be correlated automatically to identify triggers?

