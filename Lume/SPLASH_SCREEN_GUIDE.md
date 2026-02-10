# Splash Screen & Onboarding Guide

## Overview

The new `SplashView.swift` combines the splash screen, introduction, and simple onboarding into one elegant experience. It tells users they can capture artwork and the app will analyze it.

## Three Variants Available

### 1. **SplashView** (Recommended) ⭐
The main version with a two-step animated sequence:

**Step 1 - Splash (2 seconds):**
- Sparkles icon
- "Museum Companion" app name
- "Experience Art with Emotion" tagline

**Step 2 - Onboarding:**
- Camera icon with frame
- "Capture Any Artwork" headline
- Clear instruction: "Point your camera at a painting and we'll analyze it for you"
- 3 feature highlights
- "Get Started" button

**Total Duration:** ~4 seconds (then user taps button)

---

### 2. **SplashViewSimple**
Single-screen minimal onboarding:
- Camera icon with frame
- App name + instruction
- "Get Started" button
- **Best for:** Quick onboarding without splash

---

### 3. **SplashViewWithAnimation**
Includes "Analyzing..." animation:
- Shows app name with "Analyzing..." text
- Mimics the analyzing artwork screen
- Transitions to onboarding
- "Start Exploring" button
- **Best for:** Creating familiarity with the analyzing state

---

## How to Use

### Integration

In your `MuseumCompanionApp.swift` or wherever you handle onboarding:

```swift
import SwiftUI

@main
struct MuseumCompanionApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var scanLimitManager = ScanLimitManager()
    @StateObject private var historyManager = HistoryManager()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                // Show splash/onboarding
                SplashView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                // Show main app
                MainTabView()
                    .environmentObject(subscriptionManager)
                    .environmentObject(scanLimitManager)
                    .environmentObject(historyManager)
            }
        }
    }
}
```

### Alternative: Using Different Variants

```swift
// Simple version (faster)
SplashViewSimple(hasCompletedOnboarding: $hasCompletedOnboarding)

// With analyzing animation
SplashViewWithAnimation(hasCompletedOnboarding: $hasCompletedOnboarding)
```

---

## Design Consistency

All variants match your app's design system:

✅ **Colors:**
- White background
- Black text and icons
- Subtle grays for secondary text

✅ **Typography:**
- New York serif for headlines (42-52pt)
- SF Pro for body text
- Clear hierarchy

✅ **Icons:**
- SF Symbols throughout
- Camera viewfinder for main action
- Sparkles for app icon (matches paywall)

✅ **Animations:**
- Smooth, calm transitions (0.5-0.6s)
- Subtle scale and fade effects
- easeInOut timing

✅ **Layout:**
- Generous spacing (40, 50, 60pt)
- Center-aligned content
- Bottom-aligned CTA button
- Matches paywall and analyzing screens

---

## Customization

### Adjust Timing

In the `animateSequence()` function:

```swift
// Hold splash longer
try? await Task.sleep(for: .seconds(2.5)) // Change from 1.5

// Faster transitions
withAnimation(.easeOut(duration: 0.4)) { // Change from 0.6
    showIcon = true
}
```

### Change Text

```swift
// Main headline
Text("Capture\nAny Artwork") // Change this

// Instruction
Text("Point your camera at a painting\nand we'll analyze it for you")

// Button
Text("Get Started") // Or "Let's Go", "Start Now", etc.
```

### Modify Features

```swift
VStack(spacing: 16) {
    FeatureItem(icon: "sparkles", text: "AI-powered recognition")
    FeatureItem(icon: "book.fill", text: "Detailed information")
    FeatureItem(icon: "heart.fill", text: "Emotional narratives")
    // Add more features here
}
```

---

## Animation Sequence Breakdown

### SplashView (Main Version)

```
Time    Action
────────────────────────────────────────────
0.0s    Show white screen
0.0s    → Fade in sparkles icon (0.6s)
0.3s    → Fade in app name (0.6s)
0.9s    Hold splash screen
2.4s    → Transition to step 2 (0.5s)
2.9s    → Show camera icon (0.6s)
3.1s    → Show headline & text (0.6s)
3.4s    → Show button (0.5s)
3.9s    User interaction ready
```

---

## Testing

### Preview in Xcode

The file includes three preview configurations:

```swift
#Preview("Main Splash") {
    SplashView(hasCompletedOnboarding: .constant(false))
}

#Preview("Simple Version") {
    SplashViewSimple(hasCompletedOnboarding: .constant(false))
}

#Preview("With Animation") {
    SplashViewWithAnimation(hasCompletedOnboarding: .constant(false))
}
```

### Reset Onboarding for Testing

To test the splash screen again:

```swift
// In Xcode, select Debug > Delete App
// Or manually clear:
UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

// Or use @AppStorage in a debug view
@AppStorage("hasCompletedOnboarding") private var hasCompleted = false

Button("Reset Onboarding") {
    hasCompleted = false
}
```

---

## Best Practices

### ✅ Do:
- Keep the splash screen short (2-4 seconds)
- Make the message clear and action-oriented
- Match your app's overall design language
- Test on different device sizes
- Ensure text is readable at all sizes

### ❌ Don't:
- Add too many features/benefits (keep it simple)
- Use long paragraphs
- Make the splash too long (users want to get started)
- Use different visual styles than the rest of the app
- Forget to make text accessible

---

## Accessibility

The splash screen supports:

- **Dynamic Type**: Text scales with user preferences
- **VoiceOver**: All text and buttons are accessible
- **Reduce Motion**: Animations respect user preferences (optional enhancement)

### Optional: Add Reduce Motion Support

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// In animations:
withAnimation(reduceMotion ? .none : .easeOut(duration: 0.6)) {
    showIcon = true
}
```

---

## File Location

```
Features/
└── Splash/
    └── SplashView.swift
```

---

## Summary

You now have three polished splash/onboarding options that:

1. ✅ Introduce the app elegantly
2. ✅ Explain the core feature (capture & analyze)
3. ✅ Match your visual design (paywall, analyzing screen)
4. ✅ Are ready to use immediately
5. ✅ Support your onboarding flow

**Recommended:** Use `SplashView` for the best balance of branding, instruction, and user experience.

---

*Created: February 9, 2026*
