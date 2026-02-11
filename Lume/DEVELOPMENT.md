# Development & Deployment Guide

## Getting Started

### Prerequisites

1. **Hardware**:
   - Mac with Apple Silicon or Intel processor
   - iOS device with camera (for testing)
   - iPhone 15 or newer recommended (iOS 18+)

2. **Software**:
   - Xcode 15.0 or later
   - macOS Sonoma 14.0 or later
   - iOS 18.0+ deployment target

3. **Apple Developer Account**:
   - Individual or Organization account ($99/year)
   - Required for:
     - StoreKit testing
     - CloudKit containers
     - Push notifications (future)
     - App Store distribution

### Initial Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourorg/museum-companion.git
   cd museum-companion
   ```

2. **Open in Xcode**
   ```bash
   open MuseumCompanion.xcodeproj
   ```

3. **Configure Signing**
   - Select project in navigator
   - Select target "Museum Companion"
   - Go to "Signing & Capabilities"
   - Select your team
   - Automatic signing recommended

4. **Enable Capabilities**
   - Click "+ Capability"
   - Add:
     - ✅ iCloud (CloudKit)
     - ✅ In-App Purchase
   - CloudKit container will be created automatically

5. **Configure Bundle Identifier**
   - Change from `com.museumcompanion.app` to your identifier
   - Update StoreKit product IDs to match
   - Update CloudKit container name

### StoreKit Configuration

#### Local Testing (Development)

1. **Use Configuration.storekit**
   - Already included in project
   - Enables testing without App Store Connect

2. **Run in Simulator or Device**
   - StoreKit will use local configuration
   - No credit card required
   - Instant transactions

3. **Test Scenarios**:
   ```
   Scheme > Edit Scheme > Run > Options
   StoreKit Configuration: Configuration.storekit
   ```

#### Production Setup (App Store Connect)

1. **Create App in App Store Connect**
   - Go to appstoreconnect.apple.com
   - My Apps > New App
   - Fill in metadata

2. **Configure In-App Purchases**
   - Features > In-App Purchases
   - Create Subscription Group: "Pro Subscription"
   - Add subscriptions:
     - Monthly: `com.museumcompanion.pro.monthly`
     - Yearly: `com.museumcompanion.pro.yearly`

3. **Set Pricing**
   - Monthly: €2.99
   - Yearly: €19.99
   - Enable 7-day free trial

4. **Submit for Review**
   - In-App Purchases must be submitted with first app version
   - Provide screenshots and descriptions

### CloudKit Setup

#### Development Container

1. **Automatic Creation**
   - Xcode creates container on first run
   - Format: `iCloud.com.yourteam.museumcompanion`

2. **Define Schema**
   - Open CloudKit Dashboard
   - Development > Schema
   - Create Record Types:

   **ScanLimit**:
   - `scansRemaining`: Int
   - `lastResetDate`: Date

   **Artwork**:
   - `title`: String
   - `artist`: String
   - `year`: String
   - `movement`: String
   - `description`: String
   - `storyMode`: String
   - `culturalContext`: String
   - `estimatedPeriod`: String
   - `frameStyle`: String
   - `timestamp`: Date
   - `isFavorite`: Int (0 or 1)
   - `imageData`: Asset

3. **Deploy to Production**
   - CloudKit Dashboard
   - Schema > Deploy to Production
   - Cannot be undone, review carefully

#### Testing CloudKit

```swift
// Test sync in debug mode
Task {
    await historyManager.syncFromCloud()
}
```

### API Configuration

#### Gemini API

The app uses xcconfig files for secure API key management. This approach:
- Keeps API keys out of source code and git
- Works for both development (Xcode) and distribution (TestFlight) builds
- Allows each developer to use their own key
- Supports CI/CD integration

**Setup Instructions**:

1. **Get Your Gemini API Key**:
   - Go to https://aistudio.google.com/app/apikey
   - Create a new API key
   - Copy the key

2. **Configure Local xcconfig**:
   - Copy `Config.local.xcconfig.example` to `Config.local.xcconfig`
   - Add your API key to `Config.local.xcconfig`
   - This file is gitignored and will not be committed

3. **Configure Xcode Project**:
   - Add `Config.xcconfig` to your Xcode project
   - Apply it to all build configurations (Debug, Release)
   - The build system will inject the API key into Info.plist at build time

4. **For CI/CD/TestFlight**:
   - Set `GEMINI_API_KEY` as an environment variable in your build system
   - Or create `Config.local.xcconfig` in CI with the API key from your secrets manager

See `SETUP.md` for detailed setup instructions.

#### Get Your Own Gemini API Key

1. Go to https://aistudio.google.com/app/apikey
2. Create new API key
3. Enable Gemini API
4. Replace in `GeminiService.swift`

### Running the App

#### Simulator

```bash
# Select scheme: Museum Companion
# Select destination: iPhone 15 Pro (iOS 18.0)
# Press Cmd+R
```

**Limitations**:
- No camera (use photo library)
- Limited CloudKit testing
- StoreKit works perfectly

#### Physical Device

```bash
# Connect iPhone via USB or WiFi
# Select device in Xcode
# Press Cmd+R
```

**Testing**:
- Full camera functionality
- Real StoreKit transactions (sandbox)
- CloudKit sync
- Performance testing

### Testing Checklist

#### Camera & Scanning

- [ ] Camera permission prompt appears
- [ ] Camera feed displays correctly
- [ ] Scan area overlay visible
- [ ] Capture button responds
- [ ] Image crops to square
- [ ] Frame animation plays during processing
- [ ] Result appears after recognition

#### AI Recognition

- [ ] Gemini API responds (check console)
- [ ] JSON parsing succeeds
- [ ] Artwork detail displays
- [ ] Info mode shows factual data
- [ ] Story mode shows narrative
- [ ] Frame style matches period

#### Subscription

- [ ] Products load from StoreKit
- [ ] Prices display correctly
- [ ] Purchase flow completes
- [ ] Transaction verifies
- [ ] Pro status activates
- [ ] Restore purchases works

#### Scan Limits

- [ ] Free users start with 3 scans
- [ ] Counter decrements on scan
- [ ] Limit reached shows paywall prompt
- [ ] Daily reset works (test by changing device date)
- [ ] Pro users have unlimited scans

#### Collection

- [ ] Artworks save to collection
- [ ] Search filters correctly
- [ ] Favorites toggle works
- [ ] Swipe actions function
- [ ] Detail view opens
- [ ] CloudKit syncs (test on two devices)

#### UI/UX

- [ ] Onboarding shows on first launch
- [ ] Tab navigation works
- [ ] Dark mode (if implemented)
- [ ] Dynamic Type scales correctly
- [ ] VoiceOver announces properly
- [ ] Haptic feedback feels good

### Building for Distribution

#### TestFlight

1. **Archive the App**
   ```
   Product > Archive
   ```

2. **Upload to App Store Connect**
   - Xcode Organizer
   - Distribute App > App Store Connect
   - Upload

3. **Configure TestFlight**
   - App Store Connect > TestFlight
   - Add internal testers
   - Add external testers (requires review)
   - Set test information

4. **Invite Testers**
   - Send invitations
   - Testers install via TestFlight app
   - Collect feedback

#### App Store Release

1. **Prepare Metadata**
   - See `AppStoreMetadata.md`
   - Upload screenshots
   - Write description
   - Set keywords

2. **Submit for Review**
   - App Store Connect
   - Version > Submit for Review
   - Answer questionnaire
   - Add review notes

3. **Review Process**
   - Typically 24-48 hours
   - Check status daily
   - Respond to questions promptly

4. **Release**
   - Manual release: Wait for approval, then release
   - Automatic release: Goes live immediately after approval
   - Phased release: 7-day rollout (recommended)

### Continuous Integration

#### Xcode Cloud

1. **Setup**
   - Xcode > Product > Xcode Cloud
   - Connect to git repository
   - Configure workflows

2. **Build Workflow**
   ```yaml
   # ci_workflows/build.yml
   name: Build and Test
   trigger:
     branch: main
   
   actions:
     - name: Build
       scheme: Museum Companion
       platform: iOS
     
     - name: Test
       scheme: Museum Companion
       platform: iOS
   ```

3. **TestFlight Workflow**
   ```yaml
   # ci_workflows/testflight.yml
   name: Deploy to TestFlight
   trigger:
     tag: v*
   
   actions:
     - name: Archive
       scheme: Museum Companion
       
     - name: Upload to TestFlight
       distribution: testflight
   ```

#### GitHub Actions (Alternative)

```yaml
# .github/workflows/ios.yml
name: iOS Build
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build
      run: |
        xcodebuild -scheme "Museum Companion" \
                   -sdk iphonesimulator \
                   -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
                   build
    - name: Test
      run: |
        xcodebuild -scheme "Museum Companion" \
                   -sdk iphonesimulator \
                   -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
                   test
```

### Versioning Strategy

#### Semantic Versioning

Format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Examples:
- `1.0.0` - Initial release
- `1.1.0` - Added sculpture recognition
- `1.1.1` - Fixed camera crash
- `2.0.0` - Redesigned UI

#### Build Numbers

Auto-increment:
```bash
# In build phase
buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")
buildNumber=$(($buildNumber + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"
```

### Environment Management

#### Debug vs Release

```swift
#if DEBUG
let apiBaseURL = "https://staging-api.example.com"
let logLevel = .verbose
#else
let apiBaseURL = "https://api.example.com"
let logLevel = .error
#endif
```

#### Feature Flags

```swift
enum FeatureFlags {
    static let sculptureRecognition = false
    static let socialSharing = false
    static let arMode = false
}
```

### Performance Monitoring

#### Instruments

1. **Time Profiler**
   - Identify slow code paths
   - Optimize frame animation
   - Reduce main thread blocking

2. **Allocations**
   - Track memory usage
   - Find memory leaks
   - Optimize image caching

3. **Network**
   - Monitor API calls
   - Track data usage
   - Identify slow requests

#### Xcode Metrics

```
Window > Organizer > Metrics
```

- Launch time
- Hang rate
- Memory usage
- Battery usage
- Crash rate

### Crash Reporting

#### TestFlight Crashes

- Automatic crash collection
- View in App Store Connect
- Symbolicate for debugging

#### Third-party (Optional)

Consider for production:
- Firebase Crashlytics
- Sentry
- Bugsnag

**Privacy**: Requires user consent

### Localization (Future)

#### Prepare for Localization

1. **Use String Catalogs**
   ```swift
   Text("Scan") // Automatically added to catalog
   ```

2. **Mark Non-localizable**
   ```swift
   Text(verbatim: "Museum Companion")
   ```

3. **Export/Import**
   ```
   Xcode > Product > Export Localizations
   ```

4. **Test**
   ```
   Scheme > Edit Scheme > App Language > French
   ```

### Analytics (Privacy-Preserving)

#### Apple Analytics

```swift
// No code needed, automatic if enabled by user
```

#### Custom Events (Future)

```swift
// Privacy-preserving approach
enum AnalyticsEvent {
    case artworkScanned(period: String) // No PII
    case subscriptionStarted(tier: String)
    case collectionViewed
}
```

### Support & Maintenance

#### User Support

1. **In-App Feedback**
   - Add feedback form in profile
   - Email to support@museumcompanion.com

2. **FAQ**
   - Common issues and solutions
   - How-to guides

3. **Status Page**
   - API status
   - Known issues
   - Maintenance windows

#### Bug Triage

Priority levels:
- **P0**: Crashes, data loss (fix immediately)
- **P1**: Major features broken (fix in 24h)
- **P2**: Minor issues (fix in next release)
- **P3**: Nice to have (backlog)

### Security Best Practices

#### Code Security

- [x] API keys not in git (using xcconfig files)
- [ ] Validate all user input
- [ ] Sanitize API responses
- [ ] Use HTTPS only
- [ ] Certificate pinning (consider for production)

#### Data Security

- [ ] Encrypt sensitive local data (Keychain)
- [ ] CloudKit private database only
- [ ] No analytics tracking PII
- [ ] Clear cache on logout (if implemented)

### Compliance

#### GDPR

- [ ] Privacy policy accessible
- [ ] User can delete data
- [ ] Data export available
- [ ] Clear consent for data collection
- [ ] DPO contact information

#### App Store Guidelines

- [ ] No tracking without consent
- [ ] Privacy labels accurate
- [ ] In-app purchases clear
- [ ] No misleading screenshots
- [ ] Content appropriate for 4+

### Post-Launch Checklist

#### Week 1

- [ ] Monitor crash reports
- [ ] Check App Store reviews
- [ ] Verify subscription renewals
- [ ] Test CloudKit sync under load
- [ ] Monitor API usage/costs

#### Month 1

- [ ] Analyze user behavior
- [ ] Collect feature requests
- [ ] Plan version 1.1
- [ ] A/B test paywall messaging
- [ ] Optimize conversion rate

#### Ongoing

- [ ] Regular bug fix releases
- [ ] Feature updates quarterly
- [ ] Security updates as needed
- [ ] iOS version support (current + 2 prior)
- [ ] Respond to reviews

### Rollback Plan

If critical bug in production:

1. **Immediate**:
   - Pull app from sale
   - Post status update
   - Notify users via social media

2. **Fix**:
   - Create hotfix branch
   - Fix bug
   - Test thoroughly
   - Fast-track review (request from Apple)

3. **Re-release**:
   - Submit update
   - Phased release
   - Monitor closely

### Resources

#### Documentation

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [StoreKit 2 Guide](https://developer.apple.com/documentation/storekit)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

#### Communities

- Apple Developer Forums
- Swift.org Forums
- iOS Dev Slack
- r/iOSProgramming

#### Tools

- Xcode (IDE)
- SF Symbols (icons)
- Figma (design)
- App Store Connect (distribution)

### Contact

For questions about this project:
- **Technical**: dev@museumcompanion.com
- **Support**: support@museumcompanion.com
- **Business**: hello@museumcompanion.com

---

**Last Updated**: January 28, 2026
