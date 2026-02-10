# How to See the Splash Screen

## ✅ Changes Made

1. **Updated `LumeApp.swift`** - Added onboarding check
2. **Updated `SplashView.swift`** - Changed "Museum Companion" to "Lume"
3. **Created `DebugSettingsView.swift`** - Easy way to reset onboarding for testing

---

## 🎬 To See the Splash Screen NOW

### Option 1: Delete and Reinstall (Recommended)

1. **Stop the app** in Xcode (click the Stop button or press Cmd+.)
2. **Delete the app** from your iPad:
   - On Simulator: Long press the app icon → Remove App → Delete App
   - On Device: Long press the app icon → Remove App → Delete App
3. **Run the app again** in Xcode (Cmd+R)
4. **The splash screen will appear!** 🎉

### Option 2: Use Terminal Command (Simulator Only)

```bash
# Reset the simulator completely
xcrun simctl erase all

# Then run the app again
```

### Option 3: Manually Reset UserDefaults

Add this code temporarily to your `LumeApp.swift` (remove after testing):

```swift
init() {
    // TEMPORARY: Reset onboarding for testing
    UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
}
```

Then delete the app and run again.

---

## 📱 Testing Different Variants

To try the different splash screen styles, change the splash view in `LumeApp.swift`:

### Current (Main Version):
```swift
SplashView(hasCompletedOnboarding: $hasCompletedOnboarding)
```

### Simple Version (One Screen):
```swift
SplashViewSimple(hasCompletedOnboarding: $hasCompletedOnboarding)
```

### With Animation (Shows "Analyzing..."):
```swift
SplashViewWithAnimation(hasCompletedOnboarding: $hasCompletedOnboarding)
```

---

## 🔄 How It Works

**First Launch:**
- `hasCompletedOnboarding` = `false` (default)
- App shows `SplashView`
- User taps "Get Started"
- `hasCompletedOnboarding` is set to `true`
- App shows `MainTabView`

**Subsequent Launches:**
- `hasCompletedOnboarding` = `true` (stored in UserDefaults)
- App goes directly to `MainTabView`
- Splash screen is skipped

---

## 🎨 What You'll See

### Step 1 (2 seconds):
- ✨ Sparkles icon fades in
- "Lume" app name appears
- "Experience Art with Emotion" tagline

### Step 2 (User-controlled):
- 📷 Camera icon with frame
- "Capture Any Artwork" headline
- Instructions: "Point your camera at a painting and we'll analyze it for you"
- 3 feature bullets:
  - AI-powered recognition
  - Detailed information
  - Emotional narratives
- "Get Started" button

---

## 🐛 Troubleshooting

### "I still don't see the splash screen"

**Check 1:** Make sure you deleted the app completely
```swift
// The app needs to be deleted so UserDefaults is cleared
```

**Check 2:** Check the LumeApp.swift file has the updated code
```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

if !hasCompletedOnboarding {
    SplashView(hasCompletedOnboarding: $hasCompletedOnboarding)
} else {
    MainTabView()
    // ...
}
```

**Check 3:** Make sure SplashView.swift is included in your target
- Select `SplashView.swift` in Xcode
- Check the File Inspector (right sidebar)
- Ensure your app target is checked under "Target Membership"

### "The app crashes when showing splash"

**Possible issue:** Missing file reference

1. In Xcode, go to **File → Add Files to "Lume"...**
2. Select `FeaturesSplashSplashView.swift`
3. Make sure "Copy items if needed" is checked
4. Make sure your app target is selected

---

## 🎯 Quick Reset for Testing

**Add this to ProfileView or create a settings button:**

```swift
Button("Reset Onboarding (Debug)") {
    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    // Then quit and relaunch the app
}
```

Or use the `DebugSettingsView.swift` I created!

---

## ✨ Next Steps

After you see the splash screen and confirm it works:

1. ✅ Test on different iPad sizes (Pro, Air, Mini)
2. ✅ Test in both portrait and landscape
3. ✅ Adjust timing if needed (currently ~4 seconds total)
4. ✅ Customize text if you want different messaging
5. ✅ Remove any debug reset buttons before shipping

---

**The splash screen is now integrated!** Just delete the app and run it again to see it. 🎉
