# Corgina - Final Tasks Before App Store Submission

**Status:** Ready for final steps  
**Estimated Time to Complete:** 2-4 hours  
**Priority:** Complete before submission

---

## ✅ COMPLETED CODE CHANGES

All code changes have been completed:

1. ✅ **App Display Name** - Updated to "Corgina" in Info.plist
2. ✅ **Medical Disclaimer** - Full-screen disclaimer on first launch (DisclaimerView.swift)
3. ✅ **About & Settings Screen** - Complete with support, privacy, disclaimer, data deletion (AboutView.swift)
4. ✅ **Data Deletion** - Users can delete all data from settings
5. ✅ **Bundle Identifier** - Changed to `com.benjaminshafii.corgina`
6. ✅ **Project Name** - Updated to Corgina throughout
7. ✅ **App Icon** - Fixed (removed alpha channel)
8. ✅ **Privacy Policy** - Full content generated (PRIVACY_POLICY.md)
9. ✅ **Support Page** - HTML page generated (SUPPORT.html)
10. ✅ **App Store Metadata** - Complete description, keywords, etc. (APP_STORE_METADATA.md)

---

## 🚨 CRITICAL - MUST DO BEFORE SUBMISSION

### 1. Host Privacy Policy & Support Page (30 minutes)

**Option A: GitHub Pages (Recommended - Free)**

```bash
# Create a new public GitHub repo called 'corgina-privacy'
# Upload these files:
# - privacy.html (convert PRIVACY_POLICY.md to HTML or use as-is)
# - support.html (already created as SUPPORT.html)

# Enable GitHub Pages in repo settings
# Your URLs will be:
# https://[your-github-username].github.io/corgina-privacy/privacy.html
# https://[your-github-username].github.io/corgina-privacy/support.html
```

**Option B: Netlify/Vercel (Free)**
1. Sign up for Netlify or Vercel
2. Drag and drop the HTML files
3. Get your URLs

**Option C: Your Own Domain**
1. Upload to your website
2. Create URLs like https://corgina.app/privacy and https://corgina.app/support

**Files to Upload:**
- `PRIVACY_POLICY.md` (convert to privacy.html or use a Markdown viewer)
- `SUPPORT.html` (ready to use as-is)

**After hosting, update these files:**
```swift
// In AboutView.swift line 33 & 43:
Link(destination: URL(string: "https://YOUR-ACTUAL-URL/privacy.html")!)
Link(destination: URL(string: "https://YOUR-ACTUAL-URL/support.html")!)
```

---

### 2. Create App Screenshots (45-60 minutes)

**Required Screenshots:**
- iPhone 6.7" (1290 x 2796) - Need at least 3
- iPhone 6.5" (1242 x 2688) - Need at least 3

**How to Create:**

```bash
# Option 1: Use Simulator
1. Open Xcode
2. Run app in iPhone 15 Pro Max (for 6.7")
3. Navigate to each screen
4. Press Cmd+S to save screenshot
5. Repeat for iPhone 14 Pro Max (for 6.5")

# Option 2: Use Real Device
1. Run app on your iPhone
2. Navigate to screens
3. Take screenshots (Side button + Volume Up)
4. AirDrop to Mac
```

**Screens to Capture:**
1. Dashboard (main screen)
2. Food logging interface
3. Voice recording screen
4. PUQE score tracker
5. Photo food log
6. Supplements tracker

**Optional:** Add text overlays using Preview, Photoshop, or Figma:
- "Track Your Pregnancy Journey"
- "Easy Food & Hydration Logging"
- "Voice-Powered Logging"
- etc.

---

### 3. Complete App Store Connect Setup (30-45 minutes)

**In App Store Connect (appstoreconnect.apple.com):**

#### A. App Information
- [ ] App Name: "Corgina"
- [ ] Subtitle: "Pregnancy Wellness Tracker"
- [ ] Primary Category: Health & Fitness
- [ ] Secondary Category: Medical (optional)

#### B. Pricing & Availability
- [ ] Price: Free
- [ ] Availability: United States only

#### C. App Privacy
**This is REQUIRED and takes 15-30 minutes**

Navigate to App Privacy section and answer:

**1. Does your app collect data?**
- Yes

**2. Data Types Collected:**
- ✅ Health & Fitness
  - Purpose: App Functionality
  - Linked to user: No
  - Used for tracking: No
  
- ✅ Photos
  - Purpose: App Functionality
  - Linked to user: No
  - Used for tracking: No
  
- ✅ Audio Data
  - Purpose: App Functionality, Third-Party Services
  - Linked to user: No
  - Used for tracking: No
  
- ✅ User Content
  - Purpose: App Functionality
  - Linked to user: No
  - Used for tracking: No

**3. Third-Party Disclosure:**
- OpenAI (for voice transcription and image analysis)
- Data sent: Voice recordings, Photos, Text
- Purpose: Transcription and Analysis only

#### D. Privacy Policy URL
- [ ] Enter: https://[YOUR-URL]/privacy.html

#### E. Support URL  
- [ ] Enter: https://[YOUR-URL]/support.html

#### F. Age Rating
- [ ] Complete questionnaire
- [ ] Answer: 12+ (Infrequent/Mild Medical Information)
- [ ] Made for Kids: No

#### G. App Description
- [ ] Copy from APP_STORE_METADATA.md
- [ ] Paste into description field
- [ ] Review and adjust if needed (4000 char limit)

#### H. Keywords
- [ ] Copy from APP_STORE_METADATA.md:
  `pregnancy,tracker,food,wellness,health,journal,PUQE,nausea,nutrition,hydration,vitamins,prenatal`

#### I. Screenshots
- [ ] Upload iPhone 6.7" screenshots (3 minimum)
- [ ] Upload iPhone 6.5" screenshots (3 minimum)
- [ ] Arrange in best order

#### J. App Icon
- [ ] Should auto-populate from your build
- [ ] Verify it shows correctly (1024x1024, no transparency)

#### K. Copyright
- [ ] Enter: "© 2025 [Your Name]. All rights reserved."

#### L. Export Compliance
- [ ] Does your app use encryption? Yes
- [ ] Uses only standard encryption? Yes
- [ ] Qualifies for exemption? Yes
- [ ] No documentation needed

---

### 4. Test the App Thoroughly (30 minutes)

**Critical Test Checklist:**

- [ ] App launches without crashing
- [ ] Disclaimer shows on first launch
- [ ] Can accept disclaimer and continue
- [ ] Dashboard loads properly
- [ ] Can log food (text entry)
- [ ] Can log hydration
- [ ] Voice recording works (grant microphone permission)
- [ ] Photo capture works (grant camera permission)
- [ ] PUQE score calculator works
- [ ] Supplement tracker opens
- [ ] Can add/edit/delete supplements
- [ ] About & Settings screen opens
- [ ] Privacy policy links work (after hosting)
- [ ] Support email link works
- [ ] Data deletion works
- [ ] Notifications permission request works
- [ ] All tabs navigate properly

**Test on Multiple Devices (if possible):**
- [ ] iPhone (different sizes)
- [ ] iPad (optional but good)

---

### 5. Build and Upload to App Store Connect (15 minutes)

```bash
# Make sure you've updated the URLs in AboutView.swift first!

# Run the build script:
cd /Users/benjaminshafii/preg-app/HydrationReminder/HydrationReminder
./build_testflight.sh
```

**If build succeeds:**
- Build will automatically upload to App Store Connect
- Wait 5-10 minutes for processing
- Check App Store Connect for the build

**If build fails:**
- Check error messages
- Most common issues:
  - Code signing (check provisioning profiles)
  - Missing files (check Xcode project)
  - Bundle ID mismatch

---

### 6. Submit for Review (5 minutes)

**In App Store Connect:**

1. Go to your app → Version → Build
2. Select the uploaded build
3. Review all information one final time
4. Click "Submit for Review"
5. Answer review questions:
   - Does your app use the Advertising Identifier? **No**
   - Does your app contain, display, or access third-party content? **Yes** (OpenAI)
   - Does your app use encryption? **Yes** (Standard HTTPS only)

6. Add Review Notes:
   ```
   Testing Instructions:
   - Grant microphone and camera permissions when prompted
   - Accept disclaimer on first launch
   - Voice and photo features use OpenAI API
   - All data stored locally on device
   - Medical disclaimer shown prominently
   ```

7. Click "Submit"

---

## 📧 EMAIL SETUP (Optional but Recommended)

Set up support@corgina.app or use personal email:

**Option 1: Gmail Alias**
- Use your Gmail with + addressing
- Example: youremail+corgina@gmail.com
- Free and easy

**Option 2: Custom Domain Email**
- If you have corgina.app domain
- Set up email forwarding
- Professional but costs ~$5-10/month

---

## 📋 PRE-SUBMISSION CHECKLIST

**Before clicking "Submit for Review":**

- [ ] Privacy Policy hosted and accessible
- [ ] Support page hosted and accessible  
- [ ] URLs updated in AboutView.swift
- [ ] App rebuilt with correct URLs
- [ ] Privacy Nutrition Labels completed in App Store Connect
- [ ] 3+ screenshots uploaded per required size
- [ ] App description entered
- [ ] Keywords entered
- [ ] Age rating completed
- [ ] Export compliance answered
- [ ] App tested thoroughly on device
- [ ] No crashes or major bugs
- [ ] Build uploaded to App Store Connect
- [ ] Build processing completed
- [ ] All metadata reviewed

---

## ⏱️ TIMELINE AFTER SUBMISSION

**Typical App Store Review Process:**

- **Day 1**: Submission → "Waiting for Review"
- **Day 2-3**: "In Review" (24-48 hours typically)
- **Day 3-4**: 
  - ✅ "Ready for Sale" (approved!) 
  - ❌ "Rejected" (see rejection reason, fix, resubmit)

**If Rejected:**
- Don't panic! ~40% of first submissions get rejected
- Read rejection reason carefully
- Fix the issue
- Respond in Resolution Center or resubmit
- Usually quick turnaround on resubmissions

---

## 🎉 AFTER APPROVAL

**When app is "Ready for Sale":**

1. **Test on App Store:**
   - Search for "Corgina"
   - Download and test
   - Verify everything works

2. **Set Up TestFlight (Optional):**
   - Add beta testers
   - Get early feedback
   - Test updates before releasing

3. **Plan Updates:**
   - Monitor crash reports
   - Read user reviews
   - Plan feature improvements

4. **Marketing:**
   - Share on social media
   - Tell friends and family
   - Post in pregnancy communities (Reddit, Facebook groups)

---

## 🆘 IF YOU GET STUCK

**Common Issues & Solutions:**

**"Privacy Policy URL not accessible"**
- Make sure GitHub Pages is enabled
- URL must be publicly accessible (no login)
- Test URL in incognito/private browser

**"Screenshot size incorrect"**
- Use exact simulator sizes
- iPhone 15 Pro Max = 6.7" (1290 x 2796)
- iPhone 14 Pro Max = 6.5" (1242 x 2688)

**"App crashes on launch"**
- Check DisclaimerView integration
- Test in Xcode simulator first
- Check crash logs in Xcode

**"Build failed"**
- Check code signing in Xcode
- Verify team selection
- Check provisioning profiles
- Try Archive again (Product → Archive)

**"Rejected for medical claims"**
- Emphasize wellness tracking, not medical diagnosis
- Disclaimers must be prominent
- Cannot claim to treat/diagnose diseases

---

## 📞 NEED HELP?

**Resources:**
- App Store Connect Help: https://developer.apple.com/help/app-store-connect/
- Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Privacy Labels Guide: https://developer.apple.com/app-store/app-privacy-details/

**If you get completely stuck:**
- Post in r/iOSProgramming on Reddit
- Apple Developer Forums
- Stack Overflow

---

## 🎯 SUCCESS CRITERIA

**You're ready to submit when:**
- ✅ All checkboxes above are checked
- ✅ App runs without crashes
- ✅ Privacy & Support URLs work
- ✅ Screenshots look good
- ✅ Metadata is complete and accurate
- ✅ Build is uploaded and processed
- ✅ You've tested on a real device (if possible)

---

**Good luck with your submission! 🚀**

**Estimated Total Time:** 2-4 hours for all remaining tasks

**Files to Reference:**
- `PRIVACY_POLICY.md` - Host this as privacy.html
- `SUPPORT.html` - Host this as-is
- `APP_STORE_METADATA.md` - Copy/paste for App Store Connect
- `APP_STORE_REQUIREMENTS.md` - Full requirements checklist

---

**Last Updated:** October 12, 2025  
**App Version:** 1.0  
**Bundle ID:** com.benjaminshafii.corgina
