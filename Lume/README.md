# Museum Companion

A premium iOS app that recognizes paintings via camera and explains them using Gemini API, combining factual identification with emotional storytelling.

## Overview

Museum Companion transforms how people experience art. Point your camera at any painting, and instantly receive both factual information and emotional narratives that bring the artwork to life.

## Features

### 🎨 Camera & Scan
- Fullscreen immersive camera experience
- Square scanning area with elegant frame animations
- Animated picture frames representing different art periods:
  - Classical Gilded
  - Baroque Ornate
  - Modern Minimalist
  - Bauhaus Geometric
  - Contemporary Gallery
- One-tap capture with auto-crop
- Subtle haptic feedback

### 🤖 AI Recognition
- Powered by Gemini 2.0 Flash API
- Structured data extraction:
  - Title, Artist, Year
  - Movement and Period
  - Factual description
  - Story mode (emotional narrative)
  - Cultural context
- Two viewing modes: Info and Story

### 💎 Free / Pro System
- **Free**: 3 scans per day (resets at midnight)
- **Pro**: Unlimited scans
- iCloud sync across devices
- Soft limit notifications

### 💰 Subscription
- Monthly: €2.99
- Yearly: €19.99 (Save 44%)
- StoreKit 2 implementation
- Native Apple-style paywall
- Restore purchases support

### 📚 History & Collection
- Save all recognized artworks
- Favorites system
- Search functionality
- Vertical editorial timeline
- CloudKit sync
- Swipe actions (delete, favorite)

### 🎭 Design System
- **Minimalistic but artsy**
- Editorial, museum-inspired aesthetic
- Clean geometry and neutral surfaces
- Serif headlines (New York)
- Sans-serif body (SF Pro)
- Black & white color scheme
- Liquid Glass effects (scan button only)
- shadcn/ui-inspired components

### 🎯 Onboarding
Three-screen flow:
1. **Discover** - Camera introduction
2. **Understand** - Information showcase
3. **Feel** - Emotional connection

## Technical Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Architecture**: MVVM
- **Concurrency**: async/await
- **Camera**: AVFoundation
- **Subscriptions**: StoreKit 2
- **Cloud Sync**: CloudKit
- **API**: Gemini 2.0 Flash

## Project Structure

```
Museum Companion/
├── MuseumCompanionApp.swift       # App entry point
├── Models/
│   └── Models.swift                # Data models
├── Services/
│   ├── GeminiService.swift         # Gemini API integration
│   ├── SubscriptionManager.swift   # StoreKit 2 manager
│   ├── ScanLimitManager.swift      # Daily limits with iCloud
│   └── HistoryManager.swift        # CloudKit sync
├── ViewModels/
│   └── ScanViewModel.swift         # Scan logic
├── Features/
│   ├── Scan/
│   │   ├── ScanView.swift          # Main camera view
│   │   └── ArtworkDetailView.swift # Detail display
│   ├── Collection/
│   │   └── CollectionView.swift    # History list
│   ├── Profile/
│   │   └── ProfileView.swift       # Settings
│   ├── Paywall/
│   │   └── PaywallView.swift       # Subscription screen
│   └── Onboarding/
│       └── OnboardingView.swift    # First-time flow
└── UI/
    ├── Camera/
    │   └── CameraView.swift        # UIKit camera wrapper
    └── MainTabView.swift            # Tab navigation
```

## Setup

### Prerequisites
- Xcode 15.0+
- iOS 18.0+ deployment target
- Apple Developer account (for StoreKit and CloudKit)

### Installation

1. Clone the repository
2. Open `MuseumCompanion.xcodeproj` in Xcode
3. Configure your development team
4. Enable capabilities:
   - iCloud (CloudKit)
   - In-App Purchase
   - Background Modes (if needed)

### Configuration

#### Gemini API
Configure your Gemini API key as an environment variable in Xcode:
1. Edit Scheme → Run → Arguments → Environment Variables
2. Add `GEMINI_API_KEY` with your API key value
3. Get your key from: https://aistudio.google.com/app/apikey

#### StoreKit Configuration
1. Create a StoreKit configuration file in Xcode
2. Add two subscription products:
   - `com.museumcompanion.pro.monthly` - €2.99/month
   - `com.museumcompanion.pro.yearly` - €19.99/year
3. Configure subscription group and features

#### CloudKit Setup
1. Enable iCloud capability
2. Select CloudKit
3. Create a container: `iCloud.com.museumcompanion`
4. Define record types:
   - `ScanLimit`: scansRemaining (Int), lastResetDate (Date)
   - `Artwork`: All artwork fields

### Camera Permissions
Add to `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to recognize artworks.</string>
```

## Architecture

### MVVM Pattern
- **Models**: Pure data structures
- **ViewModels**: Business logic and state management
- **Views**: SwiftUI declarative UI

### Dependency Injection
All managers are injected via `@EnvironmentObject`:
```swift
.environmentObject(subscriptionManager)
.environmentObject(scanLimitManager)
.environmentObject(historyManager)
```

### Async/Await
All networking and heavy operations use Swift Concurrency:
```swift
await geminiService.recognizeArtwork(image: image)
await historyManager.addArtwork(artwork)
```

## Testing

### Unit Tests
Create tests for:
- `GeminiService` (mock API responses)
- `SubscriptionManager` (StoreKit logic)
- `HistoryManager` (CloudKit sync)
- `ScanLimitManager` (daily reset logic)

### UI Tests
Test flows:
- Onboarding completion
- Scan and recognition
- Subscription purchase
- Collection management

### Preview Providers
All views include SwiftUI previews:
```swift
#Preview {
    ScanView()
        .environmentObject(SubscriptionManager())
}
```

## Privacy & Compliance

### GDPR Compliance
- No tracking or analytics
- On-device image preprocessing
- CloudKit for user data only
- Clear data deletion

### Privacy Labels
- Camera: Required for artwork scanning
- iCloud: Optional for sync
- Network: API calls for recognition

### App Store Guidelines
- No dark patterns in paywall
- Clear subscription terms
- Restore purchases available
- Privacy policy linked

## Performance

### Optimizations
- Lazy loading in collection views
- Image compression (JPEG 80%)
- Background task processing
- Efficient CloudKit queries
- Caching where appropriate

### Memory Management
- Actor isolation for services
- Automatic reference counting
- Proper cleanup in deinit

## App Store Metadata

### Name
Museum Companion

### Subtitle
AI-Powered Art Recognition

### Description
Transform your museum visits with Museum Companion. Point your camera at any painting and instantly discover its story, artist, and cultural significance.

**Features:**
• Instant artwork recognition using advanced AI
• Detailed information about artist, period, and technique
• Emotional narratives that bring art to life
• Build your personal art collection
• iCloud sync across all your devices
• Beautiful, museum-inspired design

**Free**: 3 scans per day
**Pro**: Unlimited scans, full collection access

Perfect for art lovers, museum visitors, tourists, and students.

### Keywords
art, museum, painting, recognition, AI, culture, history, education, gallery, artwork

### Category
Primary: Education
Secondary: Reference

### Screenshots
1. Camera scanning with frame animation
2. Artwork detail in Info mode
3. Story mode narrative
4. Collection timeline
5. Paywall

## Future Enhancements

### Version 1.1
- [ ] Sculpture recognition
- [ ] Multi-language support
- [ ] Audio descriptions
- [ ] AR features
- [ ] Social sharing

### Version 1.2
- [ ] Museum location integration
- [ ] Guided tours
- [ ] Artist timelines
- [ ] Comparative analysis

## Support

For support, contact: support@museumcompanion.com

## License

Copyright © 2026 Museum Companion. All rights reserved.

## Credits

- **AI**: Gemini 2.0 Flash by Google
- **Design**: Inspired by Apple's design principles and shadcn/ui
- **Typography**: SF Pro & New York by Apple
