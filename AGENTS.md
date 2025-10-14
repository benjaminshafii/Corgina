# Agent Guidelines for HydrationReminder iOS Project

## Git Workflow
**IMPORTANT: Commit changes regularly to preserve work and enable easy rollback.**

### When to Commit
- After completing each logical feature or fix
- After completing each TODO item
- Before starting a new major change
- When a component is working and tested

### Commit Message Format
```
<type>: <short description>

<optional longer description>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring without behavior change
- `ui`: UI/UX improvements
- `debug`: Add debugging/logging
- `chore`: Maintenance tasks

### Example Commit Messages
```bash
feat: Add progressive disclosure to voice logging UI

- Implemented 4-state flow (recording, analyzing, executing, completed)
- Added liquid glass material styling
- Removed duplicate voice button
```

```bash
fix: Add comprehensive error handling to voice processing

- Added detailed logging at each processing step
- Improved error messages for users
- Added file validation before processing
```

## Build & Test Commands
- **Build**: Open `HydrationReminder.xcodeproj` in Xcode, select scheme, then Product → Build (⌘B)
- **Run**: Product → Run (⌘R) to build and launch in simulator
- **Test**: No test framework currently configured
- **Single File**: Build individual files via Xcode's build system

## ⚠️ CRITICAL: Xcode Project Management Scripts
**ALWAYS USE THESE SCRIPTS FOR PROJECT FILE ISSUES:**

### Remove Missing File References
When Xcode complains about missing files:
```bash
cd /Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder
ruby remove_missing_file.rb
```
Edit the script to specify which file to remove.

### Fix Duplicate Build Files
When build fails with "duplicate file in Compile Sources":
```bash
cd /Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder
ruby fix_duplicates.rb
```
Automatically finds and removes duplicate references.

### Add Files to Xcode Target
After creating new Swift files:
```bash
cd /Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder
ruby add_to_xcode_target.rb
```
Edit the `files_to_add` array to include new files.


## Code Style

### Language & Framework
- **Language**: Swift (SwiftUI framework)
- **Platform**: iOS app with UserNotifications, Combine, PhotosUI

### Imports
- Group by framework: Foundation/SwiftUI first, then UserNotifications/Combine/PhotosUI
- Order: Standard library → Apple frameworks → Custom files

### Naming Conventions
- Classes/Structs: `PascalCase` (e.g., `NotificationManager`, `LogsManager`)
- Functions/Variables: `camelCase` (e.g., `logFood`, `getTodayLogs`)
- @Published properties: camelCase with descriptive names
- Private functions: prefix with `private func`
- Constants: `camelCase` (e.g., `userDefaultsKey`)

### State Management
- Use `@Published` for ObservableObject properties that drive UI updates
- Use `@StateObject` for manager initialization in views
- Use `@EnvironmentObject` to pass managers between views
- Call `objectWillChange.send()` when manually triggering UI updates

### Persistence
- UserDefaults for simple data with string keys (e.g., "SavedSupplements", "UnifiedLogEntries")
- JSONEncoder/JSONDecoder for Codable types
- Always save after mutations

### Error Handling
- Print statements for debugging (e.g., `print("💊 Found supplement match...")`)
- Emojis in debug logs for quick visual scanning (💾, 📌, 🔍, ⚠️, ✅)
- Use `guard` for early returns, `if let` for optionals
- Async/await with `Task` blocks, handle errors with do-catch

### Closure Capture Semantics
- **ALWAYS use explicit `self.` in closures** when accessing properties or methods
- Swift requires explicit `self` to make capture semantics clear
- Common in: `checkPermission { }`, `UNUserNotificationCenter.current().add { }`, etc.
- Examples:
  - ❌ `content.badge = NSNumber(value: currentBadgeCount + 1)`
  - ✅ `content.badge = NSNumber(value: self.currentBadgeCount + 1)`
  - ❌ `if let lastScheduled = lastScheduledEatingTime`
  - ✅ `if let lastScheduled = self.lastScheduledEatingTime`

### Comments
- Minimal inline comments
- Use `// MARK: -` to organize code sections (e.g., `// MARK: - Quick Logging Methods`)
- Self-documenting function names preferred over comments

## Common Build Errors & Fixes

### 1. Missing Closing Braces
**Error**: `Expected '}' in struct`
**Cause**: Misaligned or missing closing braces in SwiftUI view hierarchies
**Fix**: 
- Check VStack/HStack/ZStack nesting and alignment
- Use Xcode's "Editor → Structure → Balance Brackets" (⌃⌘B)
- Count opening `{` vs closing `}` in the file

### 2. Private Members in Local Scope
**Error**: `Attribute 'private' can only be used in a non-local scope`
**Cause**: Private computed properties/functions declared inside another function or body
**Fix**:
- Move private members to struct/class level (outside body)
- Ensure proper indentation and scope placement

### 3. Async/Await Issues
**Error**: `No 'async' operations occur within 'await' expression`
**Cause**: Using `await` on synchronous functions
**Fix**:
- Remove `await` if function isn't async
- Add `async` keyword to function definition if it should be async

**Error**: `'catch' block is unreachable because no errors are thrown`
**Cause**: Using do-catch without throwing functions
**Fix**:
- Remove try/catch if no throwing operations exist
- Use try/catch only around throwing function calls

### 4. Sendable Concurrency Warnings
**Error**: `Capture of 'self' with non-Sendable type in a '@Sendable' closure`
**Cause**: Swift 6 strict concurrency checking on non-Sendable types
**Fix**:
- Add `@unchecked Sendable` conformance to `@MainActor` classes:
  ```swift
  @MainActor
  class MyManager: ObservableObject, @unchecked Sendable {
  ```
- This is safe for `@MainActor` classes since all access is on main thread

### 5. iOS Version Compatibility
**Error**: `Conformance of 'X' to 'Y' is only available in iOS 18.0 or newer`
**Cause**: Using newer SwiftUI APIs not available in deployment target
**Fix**:
- Remove `.symbolEffect()` modifiers (iOS 18+)
- Remove `.bounce` symbol effects (iOS 18+)
- Check availability with `if #available(iOS 18, *)` if needed

### 6. Orphaned Code Fragments
**Error**: `Expected declaration` or random syntax errors
**Cause**: Leftover code from incomplete edits (missing struct declaration, etc.)
**Fix**:
- Search for code fragments without proper declarations
- Remove or complete partial code blocks
- Check for statements appearing outside proper scope

## Liquid Glass UI Best Practices

Use EXA mcp to find out best practices and implemenations
### TabView Implementation
```swift
// Modern iOS 26 style with floating action button
ZStack(alignment: .bottom) {
    TabView {
        View1().tabItem { Label("Tab1", systemImage: "icon") }
        View2().tabItem { Label("Tab2", systemImage: "icon") }
    }
    
    // Floating action button
    HStack {
        Spacer()
        FloatingMicButton(...)
            .padding(.trailing, 16)
            .padding(.bottom, 8)
    }
}
```

### Material Styles
- Use `.ultraThinMaterial` for glass backgrounds (navigation bars, floating buttons)
- Use `.regularMaterial` for secondary surfaces (cards, panels)
- Apply `.toolbarBackground(.ultraThinMaterial, for: .navigationBar)` for nav bars

### Floating Action Buttons
- **Size**: 56x56pt circular button (matches Apple standards)
- **Icons**: 24pt SF Symbols, icon-only (no text labels)
- **Material**: `.ultraThinMaterial` background with shadow
- **Position**: Bottom-right corner, 16pt from edge, 8pt from tab bar
- **States**: Use different icons for states (mic → stop → checkmark → spinner)

### Content Layering
- Allow content to extend behind translucent bars
- Use `ZStack` to layer floating elements above tab bars
- Avoid solid backgrounds - embrace transparency
- Use shadows subtly: `.shadow(color: .black.opacity(0.15), radius: 6, y: 1)`

## Debugging Tips

### Xcode Build Fails But No Clear Error
1. Clean build folder: Product → Clean Build Folder (⌘⇧K)
2. Close and reopen Xcode
3. Check for orphaned file references (red files in navigator)
4. Run `ruby remove_missing_file.rb` to clean project
5. Run `ruby fix_duplicates.rb` to remove duplicate references

### Type Checking Takes Forever
- Xcode's Swift compiler can hang on complex SwiftUI expressions
- Break long chains into smaller computed properties
- Simplify ternary operators and inline conditionals
- Add explicit type annotations to help compiler

### Runtime Crashes with "Cannot find X in scope"
- File exists but not in Xcode target membership
- Run `ruby add_to_xcode_target.rb` to fix
- Or manually add in Xcode File Inspector → Target Membership
