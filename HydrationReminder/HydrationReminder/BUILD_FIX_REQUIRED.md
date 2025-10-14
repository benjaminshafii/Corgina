# Build Fix Required - AboutView.swift Not in Target

## Issue
`AboutView.swift` exists in the project but is not added to the Xcode build target, causing this error:

```
/Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder/MoreView.swift:82:49 
Cannot find 'AboutView' in scope
```

## ⚡ AUTOMATED FIX (30 seconds - RECOMMENDED)

**Yes, this CAN be automated!** Use the Ruby script:

```bash
# Install xcodeproj gem (one-time)
gem install xcodeproj

# Run the automated script
cd /Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder
ruby add_to_xcode_target.rb
```

The script will:
- ✅ Find AboutView.swift and DataBackupManager.swift
- ✅ Add them to the HydrationReminder target
- ✅ Save the project file
- ✅ You can then build in Xcode (⌘B)

**Script Location:** `add_to_xcode_target.rb` (in project directory)

---

## Manual Fix Steps (2 minutes)

### Option 1: Add to Target in Xcode (Recommended)
1. Open `HydrationReminder.xcodeproj` in Xcode
2. Select `AboutView.swift` in the Project Navigator (left sidebar)
3. Open the File Inspector (right sidebar, first tab)
4. Under "Target Membership", check the box for "HydrationReminder"
5. Build (⌘B) to verify it compiles

### Option 2: Re-add the File
1. Open Xcode
2. Right-click `AboutView.swift` in Project Navigator
3. Select "Delete" → "Remove Reference" (don't move to trash!)
4. Right-click on the project folder
5. Select "Add Files to HydrationReminder..."
6. Select `AboutView.swift`
7. **IMPORTANT:** Check "Add to targets: HydrationReminder"
8. Click "Add"
9. Build (⌘B) to verify

### Option 3: Check All New Files
If you have other new files from the reliability fixes, check them too:
- `DataBackupManager.swift` (if it exists)
- Any other new files created recently

## Verification
After fixing, run in Xcode:
```
Product → Clean Build Folder (⌘⇧K)
Product → Build (⌘B)
```

Should see: **Build Succeeded**

## Why This Happened
When AI creates new files, they need to be manually added to the Xcode target. The file exists in the filesystem but Xcode doesn't know to compile it.

## Related Files
- `AboutView.swift` - The missing file (exists but not in target)
- `MoreView.swift:82` - Where it's being used
- `DisclaimerView.swift` - Related view (check if this also needs target membership)
