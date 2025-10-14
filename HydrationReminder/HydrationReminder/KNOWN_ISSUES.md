# Corgina - Known Issues & Reliability Concerns

**Last Updated:** October 12, 2025  
**Version:** 1.0  
**Priority Levels:** 🔴 Critical | 🟡 High | 🟢 Medium | 🔵 Low

---

## 🔴 CRITICAL ISSUES

### 1. TestFlight Public Link Not Working
**Issue:** "Testers cannot join public link until this group has an approved build"

**Impact:** 
- Cannot invite beta testers
- No one can test the app before App Store submission
- Blocks pre-launch feedback loop

**Root Cause:**
- No approved build uploaded to TestFlight yet
- Need to complete first successful App Store Connect upload and processing

**Fix Required:**
1. Complete App Store Connect setup (privacy labels, metadata)
2. Build and upload first archive using `./build_testflight.sh`
3. Wait for build to process (5-10 minutes)
4. Submit build for TestFlight beta review
5. Once approved, public link becomes active

**Status:** ❌ Blocking  
**Workaround:** None - must complete submission steps  
**Estimated Fix Time:** 2-4 hours (includes all submission prep)

---

## 🔴 DATA PERSISTENCE ISSUES

### 2. No Backup or Recovery System
**Issue:** All data stored in UserDefaults with no cloud backup

**Impact:**
- App deletion = permanent data loss
- Device replacement = all logs lost
- No way to recover from corruption

**Location:** 
- `LogsManager.swift:265-280`
- `VoiceLogManager.swift:587-598`
- `SupplementManager.swift:279-290`

**Fix Required:**
- Add CloudKit backup option
- Implement export/import functionality
- Add data integrity checks on load

**Status:** 🚨 High Priority  
**Estimated Fix Time:** 8-12 hours

### 3. Silent Data Save Failures
**Issue:** All save operations use `try?` which swallows errors

**Impact:**
- Users don't know when data fails to save
- Silent data loss
- No way to debug save failures

**Examples:**
```swift
// LogsManager.swift:268
if let encoded = try? JSONEncoder().encode(logEntries) {
    UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
}
// If encoding fails, no error shown to user

// SupplementManager.swift:280
if let encoded = try? JSONEncoder().encode(supplements) {
    UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
}
```

**Fix Required:**
- Replace `try?` with proper `do-catch`
- Show user alerts on save failures
- Add retry logic
- Log errors for debugging

**Status:** 🟡 High Priority  
**Estimated Fix Time:** 4-6 hours

### 4. No Data Migration Strategy
**Issue:** No versioning or migration system for data model changes

**Impact:**
- App updates that change data structure will break existing data
- Users will lose all logs on update
- No backward compatibility

**Fix Required:**
- Add version numbers to saved data
- Implement migration system
- Add data validation on load
- Test migration paths before releases

**Status:** 🟡 High Priority  
**Estimated Fix Time:** 6-8 hours

---

## 🟡 STATE MANAGEMENT ISSUES

### 5. VoiceLogManager Configuration Failure
**Issue:** `configure()` method must be called or voice actions silently fail

**Location:** `VoiceLogManager.swift:64-71, 341-345`

**Impact:**
- Voice recordings work but actions don't execute
- No error shown to user
- Silent failures are confusing

**Example:**
```swift
guard let logsManager = logsManager else {
    print("❌ CRITICAL: LogsManager not configured!")
    return  // Silent failure - no user notification
}
```

**Fix Required:**
- Make configuration required in init
- Show user error if not configured
- Add runtime checks
- Fail loudly instead of silently

**Status:** 🟡 High Priority  
**Estimated Fix Time:** 2-3 hours

### 6. Race Conditions in Managers
**Issue:** Multiple managers can modify shared state simultaneously without locks

**Impact:**
- Potential data corruption
- Lost updates
- Inconsistent state

**Locations:**
- `LogsManager` + `VoiceLogManager` both modify log entries
- `NotificationManager` badge counts can desync
- Multiple async operations without serialization

**Fix Required:**
- Add serial dispatch queues for data access
- Use actor pattern (Swift 5.5+)
- Implement thread-safe wrappers
- Add state consistency checks

**Status:** 🟡 High Priority  
**Estimated Fix Time:** 8-10 hours

### 7. No State Recovery After Crashes
**Issue:** App crash loses all unsaved changes

**Impact:**
- In-progress voice recordings lost
- Partially entered data lost
- User frustration

**Fix Required:**
- Auto-save drafts periodically
- Recover in-progress recordings
- Show recovery UI on launch after crash
- Save state to disk more frequently

**Status:** 🟢 Medium Priority  
**Estimated Fix Time:** 6-8 hours

---

## 🟡 ERROR HANDLING ISSUES

### 8. Generic Error Messages
**Issue:** Users see vague errors like "Failed to process audio"

**Location:** `VoiceLogManager.swift:322-333`

**Impact:**
- Users don't know how to fix issues
- Support burden increases
- Poor user experience

**Example:**
```swift
self.lastTranscription = "Failed to process audio. Please try again."
// No details about what went wrong
```

**Fix Required:**
- Provide specific error messages
- Add troubleshooting tips
- Include error codes for support
- Different messages for different failures

**Status:** 🟢 Medium Priority  
**Estimated Fix Time:** 4-6 hours

### 9. No Retry Logic for Network Failures
**Issue:** OpenAI API calls fail immediately on network errors

**Location:** `OpenAIManager.swift` (all API methods)

**Impact:**
- Temporary network issues cause permanent failures
- Users must manually retry
- Poor offline experience

**Fix Required:**
- Add exponential backoff retry
- Queue failed requests
- Show retry UI to users
- Cache results when possible

**Status:** 🟢 Medium Priority  
**Estimated Fix Time:** 6-8 hours

### 10. No Request Cancellation
**Issue:** Long-running API operations cannot be cancelled

**Impact:**
- Users stuck waiting
- Wasted API quota
- Poor UX

**Fix Required:**
- Add cancel buttons to loading states
- Implement URLSessionTask cancellation
- Clean up resources on cancel
- Save partial results

**Status:** 🔵 Low Priority  
**Estimated Fix Time:** 3-4 hours

---

## 🟡 API RELIABILITY ISSUES

### 11. No Rate Limiting
**Issue:** No protection against rapid API calls

**Location:** `OpenAIManager.swift`

**Impact:**
- Potential API quota exhaustion
- Rate limit errors from OpenAI
- Unexpected costs

**Fix Required:**
- Implement request queue with delays
- Add rate limiting (e.g., 10 requests/minute)
- Cache results when appropriate
- Show queue status to users

**Status:** 🟢 Medium Priority  
**Estimated Fix Time:** 4-6 hours

### 12. No Timeout Handling
**Issue:** Network requests can hang indefinitely

**Impact:**
- App appears frozen
- Users force-quit
- Poor experience on slow networks

**Fix Required:**
- Add timeouts to all URLRequests (30-60 seconds)
- Show timeout errors clearly
- Add retry option
- Test on slow networks

**Status:** 🟢 Medium Priority  
**Estimated Fix Time:** 2-3 hours

### 13. No Offline Mode
**Issue:** All AI features require network connectivity

**Impact:**
- App partially unusable without internet
- Travel/airplane mode issues
- Rural area usability

**Fix Required:**
- Allow basic logging without AI
- Queue AI requests for later
- Cache common results
- Graceful degradation

**Status:** 🔵 Low Priority  
**Estimated Fix Time:** 10-12 hours

---

## 🟢 NOTIFICATION SYSTEM ISSUES

### 14. No Delivery Verification
**Issue:** Notifications scheduled but never verified they were delivered

**Location:** `NotificationManager.swift:300-310, 351-361`

**Impact:**
- Silent notification failures
- Users miss reminders
- No way to debug issues

**Fix Required:**
- Check notification permissions before scheduling
- Verify notifications were added successfully
- Log delivery status
- Alert user if notifications disabled

**Status:** 🟢 Medium Priority  
**Estimated Fix Time:** 3-4 hours

### 15. Badge Count Drift
**Issue:** Badge counts can become out of sync with actual state

**Location:** `NotificationManager.swift:564-582`

**Impact:**
- Incorrect badge numbers
- User confusion
- No way to reset

**Fix Required:**
- Verify badge counts on app launch
- Add manual reset option
- Audit badge logic
- Add consistency checks

**Status:** 🔵 Low Priority  
**Estimated Fix Time:** 2-3 hours

### 16. Weak Duplicate Prevention
**Issue:** Only 60-second window to prevent duplicate notifications

**Location:** `NotificationManager.swift:293-298, 344-349`

**Impact:**
- Duplicate notifications possible
- User annoyance
- Badge count inflation

**Fix Required:**
- Use better unique identifiers
- Track all scheduled notifications
- Check for duplicates more broadly
- Add notification ID management

**Status:** 🔵 Low Priority  
**Estimated Fix Time:** 3-4 hours

---

## 🔵 RESOURCE MANAGEMENT ISSUES

### 17. Audio File Orphaning
**Issue:** Voice recording files may remain after log deletion

**Location:** `VoiceLogManager.swift:523-532`

**Impact:**
- Disk space waste
- Privacy concern (orphaned voice files)
- Storage growth over time

**Fix Required:**
- Verify file deletion
- Add cleanup routine on app launch
- Track all audio files
- Add storage management UI

**Status:** 🔵 Low Priority  
**Estimated Fix Time:** 3-4 hours

### 18. No Storage Quota Management
**Issue:** No limits on data storage or cleanup of old data

**Impact:**
- Unbounded storage growth
- App slowdown with large datasets
- Potential storage exhaustion

**Fix Required:**
- Add auto-cleanup of old logs (e.g., >1 year)
- Show storage usage in settings
- Add manual cleanup option
- Warn when storage high

**Status:** 🔵 Low Priority  
**Estimated Fix Time:** 4-6 hours

---

## 🔵 TESTING & DEBUGGING ISSUES

### 19. Insufficient Logging
**Issue:** Many operations have no logging or only print statements

**Impact:**
- Hard to debug production issues
- No crash diagnostics
- Can't reproduce bugs

**Fix Required:**
- Add structured logging framework
- Log all critical operations
- Add analytics/crash reporting (e.g., Firebase)
- Create debug logs export

**Status:** 🔵 Low Priority  
**Estimated Fix Time:** 8-10 hours

### 20. No Unit Tests
**Issue:** Zero test coverage

**Impact:**
- Regression risks
- Hard to refactor safely
- Unknown edge case behavior

**Fix Required:**
- Add XCTest framework
- Test critical paths (data save/load, voice actions)
- Add UI tests for main flows
- Set up CI/CD

**Status:** 🔵 Low Priority  
**Estimated Fix Time:** 20-30 hours

---

## 📊 PRIORITY SUMMARY

| Priority | Count | Total Hours |
|----------|-------|-------------|
| 🔴 Critical | 1 | 2-4 hours |
| 🟡 High | 6 | 38-49 hours |
| 🟢 Medium | 7 | 34-45 hours |
| 🔵 Low | 6 | 43-57 hours |
| **TOTAL** | **20** | **117-155 hours** |

---

## 🎯 RECOMMENDED FIX ORDER

### Phase 1: Pre-Launch (Must Do)
1. **TestFlight Public Link** (Issue #1) - 2-4 hours
   - Complete App Store Connect setup
   - Upload first build
   - Enable beta testing

### Phase 2: Post-Launch Critical (Week 1-2)
2. **Silent Save Failures** (Issue #3) - 4-6 hours
3. **VoiceLogManager Configuration** (Issue #5) - 2-3 hours
4. **Generic Error Messages** (Issue #8) - 4-6 hours

### Phase 3: Stability (Month 1-2)
5. **No Backup System** (Issue #2) - 8-12 hours
6. **Data Migration** (Issue #4) - 6-8 hours
7. **Race Conditions** (Issue #6) - 8-10 hours
8. **API Retry Logic** (Issue #9) - 6-8 hours

### Phase 4: Polish (Month 2-3)
9. **Rate Limiting** (Issue #11) - 4-6 hours
10. **Notification Verification** (Issue #14) - 3-4 hours
11. **State Recovery** (Issue #7) - 6-8 hours
12. **Timeout Handling** (Issue #12) - 2-3 hours

### Phase 5: Long-term (Month 3+)
- Offline mode
- Storage management
- Comprehensive logging
- Unit test coverage

---

## 🆘 WORKAROUNDS FOR USERS

### Until Fixed:
1. **Data Loss Prevention:**
   - Use "Export Logs" feature regularly
   - Take screenshots of important data
   - Don't delete app until export

2. **Voice Recording Issues:**
   - Keep recordings under 2 minutes
   - Close other apps before recording
   - Restart app if actions don't execute

3. **Notification Issues:**
   - Check Settings > Notifications > Corgina
   - Toggle reminders off/on if not working
   - Restart app to reset notification state

4. **API Errors:**
   - Wait 30 seconds and retry
   - Check internet connection
   - Verify OpenAI API key in settings

---

## 📝 NOTES FOR DEVELOPERS

### Code Quality
- Many `// TODO:` comments scattered throughout
- Inconsistent error handling patterns
- Heavy reliance on print statements vs proper logging
- No dependency injection (tight coupling)

### Architecture Concerns
- Managers are singletons but not thread-safe
- No clear separation of concerns (networking + business logic mixed)
- UserDefaults used as database (not scalable)
- No repository pattern for data access

### Testing
- Zero automated tests
- Manual testing only
- No CI/CD pipeline
- No test data generators

---

## 🔗 RELATED DOCUMENTS

- `FINAL_TODO.md` - Submission checklist
- `APP_STORE_REQUIREMENTS.md` - App Store compliance
- `PRIVACY_POLICY.md` - Privacy policy
- `README_SUBMISSION.md` - Quick submission guide

---

**Questions or want to prioritize fixes?** Update this document with decisions and timelines.
