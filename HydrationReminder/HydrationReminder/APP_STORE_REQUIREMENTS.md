# Corgina - App Store Submission Requirements Checklist

**Last Updated:** October 12, 2025  
**Target Launch:** US Only  
**Current Status:** Pre-submission

---

## ⚠️ CRITICAL REQUIREMENTS

### 1. Privacy Policy URL - **REQUIRED** ❌
**Status:** Missing  
**Priority:** Critical  
**Deadline:** Before submission

**What's Needed:**
- Host a publicly accessible privacy policy on a website
- URL must be valid and accessible without login
- Must describe all data collection practices

**How to Fix:**
1. Create a privacy policy document covering:
   - What data is collected (voice recordings, photos, food logs, health data, OpenAI API usage)
   - How data is stored (locally on device, UserDefaults)
   - Third-party services (OpenAI API)
   - User rights and data deletion
   - Contact information

2. Host options:
   - GitHub Pages (free): Create `privacy.html` in a public repo
   - Simple hosting service: Netlify, Vercel (free tier)
   - Your own domain

3. Add URL to App Store Connect under App Privacy section

**Resources:**
- [Privacy Policy Generator for Apps](https://app-privacy-policy-generator.firebaseapp.com/)
- [Apple Privacy Requirements](https://developer.apple.com/app-store/app-privacy-details/)

---

### 2. App Privacy Nutrition Labels - **REQUIRED** ❌
**Status:** Not configured  
**Priority:** Critical  
**Deadline:** Before submission

**What's Needed:**
Complete the App Privacy questionnaire in App Store Connect detailing:

**Data Collection:**
- ✅ Health & Fitness (food logs, hydration, pregnancy tracking, PUQE scores)
- ✅ Photos (meal photos)
- ✅ Audio Data (voice recordings)
- ✅ User Content (voice logs, notes, journal entries)
- ✅ Identifiers (device ID for local storage only)

**Third-Party Data:**
- ✅ OpenAI API (voice transcription, food suggestions)
- Data sent: voice recordings, text logs
- Data usage: transcription and analysis only
- Not used for tracking

**Data Practices:**
- Data linked to user: Yes (stored locally on device)
- Used to track user: No
- Collected data: Health info, photos, audio
- Data storage: Local only (UserDefaults, device storage)
- No cloud sync unless user enables iCloud

**How to Fix:**
1. Log into App Store Connect
2. Navigate to your app → App Information → App Privacy
3. Answer all questions accurately
4. Review and submit responses

**Resources:**
- [App Privacy Details Guide](https://developer.apple.com/app-store/app-privacy-details/)
- Takes 15-30 minutes to complete

---

### 3. App Display Name - **NEEDS UPDATE** ⚠️
**Status:** Still shows "Plany"  
**Priority:** High  
**Current:** Info.plist shows `CFBundleDisplayName = Plany`

**How to Fix:**
```xml
<!-- In Info.plist, change: -->
<key>CFBundleDisplayName</key>
<string>Corgina</string>
```

---

### 4. App Store Screenshots - **REQUIRED** ❌
**Status:** Not created  
**Priority:** Critical  

**Requirements:**
- iPhone 6.7" display (1290 x 2796 pixels) - Required
- iPhone 6.5" display (1242 x 2688 pixels) - Required
- iPad Pro 12.9" (2048 x 2732 pixels) - Optional but recommended
- Minimum 3 screenshots, maximum 10 per device size

**Content Guidelines:**
- Show actual app functionality
- No placeholder content
- Must match final app appearance
- Can include text overlays explaining features

**Key Screens to Capture:**
1. Dashboard view with pregnancy tracking
2. Food/hydration logging
3. Voice log feature
4. PUQE score tracking
5. Photo food log
6. Supplements tracker

**How to Fix:**
1. Run app in simulator at required sizes
2. Use Simulator → File → New Screenshot (⌘S)
3. Or use actual device screenshots
4. Edit if needed to add text/highlights
5. Upload to App Store Connect

---

### 5. App Description & Keywords - **REQUIRED** ❌
**Status:** Not created  
**Priority:** High

**What's Needed:**

**App Name:** Corgina (30 characters max)

**Subtitle:** (30 characters max)
Example: "Pregnancy Wellness Tracker"

**Description:** (4000 characters max)
Focus on:
- Pregnancy health tracking
- Food and hydration logging
- Voice logging capabilities
- PUQE score tracking
- Supplement management
- Photo food diary
- NOT a medical device disclaimer

**Keywords:** (100 characters max, comma-separated)
Examples: pregnancy,tracker,food,wellness,health,journal,supplements

**Promotional Text:** (170 characters, updatable without new version)

---

### 6. Medical Disclaimer - **CRITICAL** ❌
**Status:** Missing  
**Priority:** Critical - FDA Compliance

**Why This Matters:**
Your app tracks pregnancy health data. To avoid FDA regulation as a medical device, you MUST:

**Required Disclaimers:**

1. **In-App (First Launch):**
```
"Corgina is a wellness tracker and is not intended to diagnose, 
treat, cure, or prevent any disease or medical condition. 
Always consult your healthcare provider for medical advice."
```

2. **App Store Description:**
Add to the end of description:
```
IMPORTANT: This app is for informational and tracking purposes 
only and is not a substitute for professional medical advice. 
Consult your doctor for medical guidance.
```

3. **In the App (Settings or About):**
Add a disclaimer screen accessible from settings

**How to Fix:**
1. Add disclaimer to `ContentView.swift` on first launch
2. Store flag in UserDefaults to show only once
3. Add to App Store description
4. Add to app settings/about section

**Why:**
- Apps providing general wellness tracking (not diagnosis/treatment) are exempt from FDA regulation
- Clear disclaimers demonstrate this intent
- Protects from medical device classification

**Resources:**
- [FDA Mobile Medical Apps Guidance](https://www.fda.gov/medical-devices/digital-health-center-excellence/device-software-functions-including-mobile-medical-applications)

---

### 7. Support URL - **REQUIRED** ❌
**Status:** Missing  
**Priority:** High

**What's Needed:**
- Publicly accessible support page
- Must include contact information
- Can be email or contact form

**Options:**
1. Simple GitHub Pages site with email contact
2. Email address: support@yourdomain.com
3. Contact form on website

**How to Fix:**
1. Create simple support page (can use same hosting as privacy policy)
2. Include:
   - Contact email
   - Brief FAQ
   - How to report issues
3. Add URL to App Store Connect

---

### 8. Marketing URL - **OPTIONAL** ✅
**Status:** Not required for launch  
**Priority:** Low

Can add later if you create a marketing website.

---

### 9. Age Rating - **REQUIRED** ⚠️
**Status:** Needs configuration  
**Priority:** High

**Recommended Rating:** 12+ (Infrequent/Mild Medical/Treatment Information)

**Questionnaire Responses:**
- Made for Kids: No
- Medical/Treatment Information: Infrequent/Mild (pregnancy tracking)
- Unrestricted Web Access: No
- Gambling: No
- Contests: No

**How to Fix:**
Complete age rating questionnaire in App Store Connect

---

### 10. App Category - **REQUIRED** ⚠️
**Status:** Needs selection  
**Priority:** Medium

**Primary Category:** Health & Fitness  
**Secondary Category:** Medical (optional)

---

### 11. Export Compliance - **REQUIRED** ⚠️
**Status:** Needs declaration  
**Priority:** Medium

**Your App Uses Encryption:** YES (HTTPS for OpenAI API)

**Exempt:** YES (Standard encryption only, no proprietary algorithms)

**How to Answer:**
- Uses encryption: Yes
- Uses only standard encryption: Yes
- Qualifies for exemption: Yes
- No export documentation needed

---

## 🔧 TECHNICAL REQUIREMENTS

### 12. TestFlight Testing - **RECOMMENDED** ✅
**Status:** In progress  
**Priority:** High

**Best Practice:**
- Test with at least 5-10 users before public launch
- Get feedback on:
  - Usability
  - Bug discovery
  - Feature requests
  - Pregnancy-specific use cases

---

### 13. App Icon - **COMPLETED** ✅
**Status:** Fixed (removed alpha channel)  
**Priority:** Critical

**✅ Fixed:** All icons now RGB without transparency

---

### 14. Bundle Identifier - **COMPLETED** ✅
**Status:** `com.benjaminshafii.corgina`  
**Priority:** Critical

---

### 15. Minimum iOS Version - **REVIEW** ⚠️
**Status:** Currently set to iOS 17.0  
**Priority:** Low

**Recommendation:** iOS 17.0 is good (covers 90%+ of users)

---

### 16. App Crashes & Bugs - **REQUIRED** ❌
**Status:** Needs thorough testing  
**Priority:** Critical

**Before Submission:**
- Test all major features
- Test on multiple device sizes
- Test with/without permissions granted
- Test voice recording
- Test photo capture
- Test OpenAI API failures
- Test offline mode

**Critical Test Cases:**
1. First launch experience
2. Notification permissions
3. Camera/microphone permissions
4. Voice recording and transcription
5. Photo selection and capture
6. Food logging
7. Supplement tracking
8. PUQE score calculation
9. Background app refresh
10. Data persistence after app restart

---

## 📱 METADATA CHECKLIST

### App Store Connect Setup
- [ ] App Name: Corgina
- [ ] Subtitle (30 chars)
- [ ] Description (4000 chars)
- [ ] Keywords (100 chars)
- [ ] Screenshots (3+ per device size)
- [ ] App Icon (1024x1024)
- [ ] Privacy Policy URL
- [ ] Support URL
- [ ] Privacy Nutrition Labels completed
- [ ] Age Rating questionnaire
- [ ] Export Compliance
- [ ] App Category selected
- [ ] Pricing (Free)
- [ ] Availability: US only

---

## 🚨 LEGAL & COMPLIANCE

### 17. Terms of Service - **OPTIONAL** ✅
**Status:** Not required but recommended  
**Priority:** Low-Medium

Consider adding if you plan to:
- Add user accounts in future
- Collect any user data beyond local storage
- Add premium features

---

### 18. Copyright Notice - **REQUIRED** ⚠️
**Status:** Needs to be added  
**Priority:** Low

**How to Fix:**
Add to App Store Connect:
```
© 2025 [Your Name/Company]. All rights reserved.
```

---

## 📋 PRE-SUBMISSION CHECKLIST

**Complete Before Submitting:**

### Required (Cannot submit without):
- [ ] Privacy Policy URL hosted and accessible
- [ ] Privacy Nutrition Labels completed in App Store Connect
- [ ] Support URL or contact email
- [ ] App screenshots (3+ per required device size)
- [ ] App description, subtitle, keywords
- [ ] Medical disclaimer in app and description
- [ ] Age rating completed
- [ ] Export compliance declaration
- [ ] Display name updated to "Corgina"
- [ ] Thorough testing completed
- [ ] No critical bugs or crashes

### Recommended (Should have):
- [ ] TestFlight beta testing completed
- [ ] User feedback incorporated
- [ ] Terms of Service (if collecting data)
- [ ] In-app disclaimer shown on first launch
- [ ] Help/FAQ section in app

### Optional (Nice to have):
- [ ] Marketing website
- [ ] App preview video
- [ ] Secondary app category
- [ ] Promotional text

---

## 🎯 ESTIMATED TIMELINE

**Minimum Time to Launch:** 3-5 days

1. **Day 1:** Create privacy policy & support page (2-3 hours)
2. **Day 2:** Complete Privacy Nutrition Labels (1 hour)
3. **Day 2-3:** Create screenshots and metadata (3-4 hours)
4. **Day 3:** Update app with medical disclaimer (1 hour)
5. **Day 3-4:** Thorough testing (4-6 hours)
6. **Day 4:** Fix critical bugs found in testing
7. **Day 5:** Submit to App Store
8. **Day 5-7:** Apple review process (24-48 hours typically)

---

## 📞 NEXT STEPS

1. **Immediate (Today):**
   - Create and host privacy policy
   - Create support page/email
   - Update app display name in Info.plist

2. **Within 24 Hours:**
   - Complete Privacy Nutrition Labels in App Store Connect
   - Add medical disclaimer to app
   - Create app screenshots

3. **Within 48 Hours:**
   - Write app description and metadata
   - Complete age rating questionnaire
   - Conduct thorough testing

4. **Within 72 Hours:**
   - Fix any critical bugs
   - Build and upload to App Store Connect
   - Submit for review

---

## 🔗 USEFUL RESOURCES

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy Nutrition Labels](https://developer.apple.com/app-store/app-privacy-details/)
- [FDA Mobile Medical Apps](https://www.fda.gov/medical-devices/digital-health-center-excellence/device-software-functions-including-mobile-medical-applications)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

**Document Version:** 1.0  
**Created:** October 12, 2025  
**For:** Corgina iOS App
