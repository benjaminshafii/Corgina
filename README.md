# Health Reminders - iOS App

A simple iOS app that sends notifications to remind you to eat and drink water at regular intervals.

## Features

- 🍽️ **Eating Reminders**: Set custom intervals for meal reminders
- 💧 **Water Reminders**: Set custom intervals for hydration reminders
- ⏰ **Customizable Timing**: Set any interval from 30 minutes to multiple hours
- 📱 **Native iOS Notifications**: Works even when the app is closed
- 🎨 **Clean UI**: Simple and intuitive interface
- ⚡ **Quick Setup Buttons**: Preset intervals for common schedules

## Installation on iPhone 15 Pro Max (iOS 18)

### Method 1: Using Xcode (Recommended)

1. **Install Xcode**:
   - Download Xcode from the Mac App Store
   - Requires macOS Monterey 12.5 or later

2. **Open the Project**:
   ```bash
   open HydrationReminder/HydrationReminder.xcodeproj
   ```

3. **Configure Signing**:
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Select your Apple ID team
   - Change Bundle Identifier to something unique (e.g., `com.yourname.hydrationreminder`)

4. **Connect iPhone**:
   - Connect iPhone 15 Pro Max via USB
   - Trust the computer if prompted
   - Enable Developer Mode: Settings > Privacy & Security > Developer Mode

5. **Install App**:
   - Select your iPhone from the device list in Xcode
   - Click the "Run" button (▶️)
   - Trust the developer certificate on iPhone: Settings > General > VPN & Device Management

### Method 2: Using TestFlight (If you have Apple Developer Account)

1. Archive the app in Xcode
2. Upload to App Store Connect
3. Add your wife as a tester
4. She can install via TestFlight app

### Method 3: Sideloading with AltStore (Free Alternative)

1. **Install AltStore** on your computer and iPhone
2. **Build IPA**:
   ```bash
   cd HydrationReminder
   xcodebuild -scheme HydrationReminder -destination generic/platform=iOS archive -archivePath HydrationReminder.xcarchive
   xcodebuild -exportArchive -archivePath HydrationReminder.xcarchive -exportPath . -exportOptionsPlist ExportOptions.plist
   ```
3. **Install via AltStore** on the iPhone

## Usage

1. **First Launch**: The app will request notification permissions - tap "Allow"
2. **Set Eating Reminders**: Toggle on and set hours between meal reminders
3. **Set Water Reminders**: Toggle on and set hours between hydration reminders
4. **Quick Setup**: Use preset buttons for common schedules
5. **Update Anytime**: Change intervals and tap "Update Intervals"

## Technical Details

- **Platform**: iOS 17.0+
- **Framework**: SwiftUI
- **Notifications**: UserNotifications framework
- **Architecture**: MVVM pattern
- **Persistence**: Notification scheduling persists across app launches

## Project Structure

```
HydrationReminder/
├── HydrationReminderApp.swift    # Main app entry point
├── ContentView.swift             # Main UI
├── NotificationManager.swift     # Notification logic
├── Info.plist                   # App configuration
└── Assets.xcassets/             # App icons and assets
```

## Troubleshooting

- **Notifications not working**: Check Settings > Notifications > Health Reminders
- **App won't install**: Ensure iPhone is in Developer Mode
- **Build errors**: Check Bundle Identifier is unique and team is selected

## License

Free to use and modify.