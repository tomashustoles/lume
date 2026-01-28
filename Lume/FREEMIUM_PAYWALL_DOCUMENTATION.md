# Museum Companion - Freemium Paywall System Documentation

## Overview

Museum Companion implements a comprehensive freemium monetization model using StoreKit 2, providing a fair and transparent subscription system that complies with App Store guidelines.

## Table of Contents

1. [Monetization Model](#monetization-model)
2. [Architecture](#architecture)
3. [Implementation Details](#implementation-details)
4. [Testing Guide](#testing-guide)
5. [App Store Configuration](#app-store-configuration)
6. [Compliance & Best Practices](#compliance--best-practices)

---

## Monetization Model

### Free Tier
- **Daily Limit**: 3 artwork scans per 24-hour period
- **Reset Schedule**: Daily at midnight (local time)
- **Features**: Basic artwork recognition, limited history, standard UI

### Pro Tier (Subscription)
- **Unlimited Scans**: No daily limit
- **iCloud Sync**: Cross-device synchronization
- **Enhanced Features**: Story mode, unlimited favorites, priority support
- **Pricing**: 
  - Monthly: €2.99/month
  - Yearly: €19.99/year (44% savings)

### User Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      User Opens App                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
            ┌────────────────────────┐
            │  Load Subscription     │
            │  Status from StoreKit  │
            └────────┬───────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────┐          ┌──────────────┐
│  Pro User    │          │  Free User   │
│  Detected    │          │  Detected    │
└──────┬───────┘          └──────┬───────┘
       │                         │
       │                         ▼
       │                  ┌──────────────┐
       │                  │ Check Daily  │
       │                  │    Limits    │
       │                  └──────┬───────┘
       │                         │
       │              ┌──────────┴──────────┐
       │              │                     │
       │              ▼                     ▼
       │      ┌───────────────┐    ┌───────────────┐
       │      │ Scans < 3     │    │ Scans = 3     │
       │      │ Allow Scan    │    │ Show Paywall  │
       │      └───────────────┘    └───────────────┘
       │                                   │
       │                                   ▼
       │                          ┌────────────────┐
       │                          │ User Upgrades  │
       │                          │   or Waits     │
       │                          └────────┬───────┘
       │                                   │
       └───────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │ Unlimited Access │
              └──────────────────┘
```

---

## Architecture

### Core Components

#### 1. SubscriptionManager
**Location**: `Services/SubscriptionManager.swift`

**Responsibilities**:
- Load subscription products from StoreKit
- Verify transaction receipts
- Track subscription status (active, grace period, billing retry)
- Handle purchase and restore operations
- Listen for transaction updates
- Cache entitlement state for offline support

**Key Properties**:
```swift
@Published private(set) var isProUser: Bool
@Published private(set) var subscriptionProducts: [Product]
@Published private(set) var currentSubscription: Product.SubscriptionInfo.Status?
@Published var isLoading: Bool
@Published var subscriptionExpirationDate: Date?
@Published var isInGracePeriod: Bool
@Published var isInBillingRetry: Bool
```

**Key Methods**:
```swift
func loadProducts() async
func loadSubscriptionStatus() async
func purchase(_ product: Product) async throws -> Transaction?
func restorePurchases() async
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T
```

#### 2. ScanLimitManager
**Location**: `Services/ScanLimitManager.swift`

**Responsibilities**:
- Track daily scan usage
- Enforce 3-scan limit for free users
- Detect clock manipulation attempts
- Sync limits via iCloud (optional)
- Reset counter daily at midnight
- Track usage analytics

**Key Properties**:
```swift
@Published var scansRemaining: Int
@Published var lastResetDate: Date
@Published var showLimitReached: Bool
```

**Key Methods**:
```swift
func useScan() async -> Bool
func canScan(isProUser: Bool) async -> Bool
func checkDailyReset() async
func resetForProUser()
func timeUntilReset() -> TimeInterval
func detectClockManipulation() -> Bool
```

#### 3. PaywallView
**Location**: `Features/Paywall/PaywallView.swift`

**Responsibilities**:
- Present subscription options
- Display feature comparison
- Handle purchase flow
- Restore previous purchases
- Show legal information

**Design Principles**:
- White background with black typography
- Serif headlines (New York)
- SF Pro body text
- No colors, gradients, or flashy elements
- Clean, museum-like aesthetic

#### 4. SimpleScanViewModel
**Location**: `SimpleScanViewModel.swift`

**Responsibilities**:
- Coordinate scan attempts with limit checking
- Trigger paywall presentation
- Manage camera capture session
- Handle scan results and errors

**Integration Points**:
```swift
func capturePhoto(
    isProUser: Bool,
    scanLimitManager: ScanLimitManager,
    historyManager: HistoryManager
) async

func dismissPaywall(didPurchase: Bool)
func acknowledgeLimit()
```

---

## Implementation Details

### 1. Subscription Status Verification

The app uses StoreKit 2's modern verification APIs to ensure transaction authenticity:

```swift
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified(let unverifiedTransaction, let error):
        print("❌ Transaction verification failed: \(error)")
        throw SubscriptionError.failedVerification
        
    case .verified(let transaction):
        return transaction
    }
}
```

### 2. Entitlement Caching

For offline support, the app caches entitlement status locally:

```swift
private func cacheEntitlement() {
    UserDefaults.standard.set(isProUser, forKey: entitlementCacheKey)
    UserDefaults.standard.set(Date(), forKey: lastVerificationDateKey)
}

private func loadCachedEntitlement() {
    let cachedStatus = UserDefaults.standard.bool(forKey: entitlementCacheKey)
    
    // Only use cached status if verified within 24 hours
    if let lastVerification = UserDefaults.standard.object(forKey: lastVerificationDateKey) as? Date {
        let hoursSinceVerification = Date().timeIntervalSince(lastVerification) / 3600
        
        if hoursSinceVerification < 24 {
            isProUser = cachedStatus
        }
    }
}
```

**Cache Lifetime**: 24 hours
**Fallback**: Re-verification required after cache expiration

### 3. Clock Manipulation Protection

To prevent users from gaming the system by changing device time:

```swift
private func detectClockManipulation() -> Bool {
    let currentUptime = ProcessInfo.processInfo.systemUptime
    let lastUptime = UserDefaults.standard.double(forKey: Keys.lastKnownSystemUptime)
    
    if currentUptime < lastUptime {
        return false // System reboot is fine
    }
    
    let uptimeDifference = currentUptime - lastUptime
    let actualTimeDifference = Date().timeIntervalSince(lastResetDate)
    
    let tolerance: TimeInterval = 300 // 5 minutes
    let timeDifference = abs(actualTimeDifference - uptimeDifference)
    
    return timeDifference > tolerance
}
```

**Detection Method**: Compares system uptime with elapsed real time
**Tolerance**: 5 minutes to account for clock drift
**Response**: Maintains current scan limits without reset

### 4. Transaction Listening

Automatic updates when subscriptions change:

```swift
private func listenForTransactions() -> Task<Void, Error> {
    return Task.detached { [weak self] in
        for await result in Transaction.updates {
            do {
                let transaction = try await self?.checkVerified(result)
                await transaction?.finish()
                await self?.loadSubscriptionStatus()
            } catch {
                print("❌ Transaction verification failed: \(error)")
            }
        }
    }
}
```

**Triggers**:
- New purchase
- Renewal
- Cancellation
- Expiration
- Family sharing changes

### 5. Grace Period & Billing Retry Handling

The app maintains access during payment issues:

```swift
switch status.state {
case .subscribed:
    isProUser = true
    isInGracePeriod = false
    isInBillingRetry = false
    
case .inGracePeriod:
    isProUser = true  // Still provide access
    isInGracePeriod = true
    
case .inBillingRetryPeriod:
    isProUser = true  // Still provide access
    isInBillingRetry = true
    
case .revoked, .expired:
    isProUser = false
    
@unknown default:
    isProUser = false
}
```

---

## Testing Guide

### Local Testing with StoreKit Configuration

#### 1. Create StoreKit Configuration File

1. In Xcode: `File > New > File`
2. Choose "StoreKit Configuration File"
3. Name it `Products.storekit`

#### 2. Configure Products

Add two auto-renewable subscriptions:

**Monthly Subscription**
- Product ID: `com.museumcompanion.pro.monthly`
- Reference Name: Museum Companion Pro (Monthly)
- Price: €2.99
- Duration: 1 Month
- Subscription Group: pro_subscriptions

**Yearly Subscription**
- Product ID: `com.museumcompanion.pro.yearly`
- Reference Name: Museum Companion Pro (Yearly)
- Price: €19.99
- Duration: 1 Year
- Subscription Group: pro_subscriptions

#### 3. Enable StoreKit Testing in Scheme

1. `Product > Scheme > Edit Scheme`
2. Select "Run" in sidebar
3. Go to "Options" tab
4. Set "StoreKit Configuration" to `Products.storekit`

#### 4. Testing Scenarios

**Scenario 1: New User Free Trial**
```swift
// Actions:
1. Launch app
2. Attempt 3 scans
3. Verify limit reached notification
4. Attempt 4th scan
5. Verify paywall appears

// Expected Results:
- First 3 scans succeed
- Limit notification shows after 3rd scan
- Paywall appears on 4th attempt
- Scan button is disabled
```

**Scenario 2: Purchase Flow**
```swift
// Actions:
1. Reach scan limit
2. Open paywall
3. Select yearly plan
4. Tap "Upgrade"
5. Confirm purchase in StoreKit dialog

// Expected Results:
- Purchase completes successfully
- isProUser becomes true
- Paywall dismisses
- Unlimited scans enabled
```

**Scenario 3: Restore Purchases**
```swift
// Actions:
1. Delete and reinstall app
2. Launch app
3. Open paywall
4. Tap "Restore Purchases"

// Expected Results:
- Previous subscription detected
- Pro status restored
- Unlimited access granted
```

**Scenario 4: Expired Subscription**
```swift
// Actions:
1. Use StoreKit Transaction Manager
2. Set subscription to expired
3. Relaunch app

// Expected Results:
- isProUser becomes false
- Daily limit enforced again
- Paywall available
```

**Scenario 5: Clock Manipulation**
```swift
// Actions:
1. Use all 3 daily scans
2. Change device time to next day
3. Attempt scan

// Expected Results:
- Clock change detected
- Scan count NOT reset
- Limit remains enforced
```

### Sandbox Testing

#### Setup

1. **Create Sandbox Tester Account**
   - Go to App Store Connect
   - Users and Access > Sandbox Testers
   - Click "+" to create new tester
   - Use a unique email (can use +tag addressing)

2. **Configure Device**
   - Settings > App Store
   - Sign out of production account
   - Install app from Xcode
   - When prompted, sign in with sandbox account

#### Testing Checklist

- [ ] Load subscription products
- [ ] Purchase monthly subscription
- [ ] Verify unlimited access
- [ ] Cancel subscription in Settings
- [ ] Verify access maintained until expiration
- [ ] Purchase yearly subscription
- [ ] Upgrade from monthly to yearly
- [ ] Downgrade from yearly to monthly
- [ ] Test restore purchases
- [ ] Test family sharing (if applicable)
- [ ] Test introductory offers
- [ ] Test promotional offers
- [ ] Verify receipt validation
- [ ] Test offline scenarios
- [ ] Test account switching

### UI Testing

Create UI tests for critical user journeys:

```swift
import XCTest

class PaywallUITests: XCTestCase {
    
    func testPaywallAppearance() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Use 3 scans
        for _ in 0..<3 {
            app.buttons["Scan Button"].tap()
            sleep(2)
        }
        
        // Attempt 4th scan
        app.buttons["Scan Button"].tap()
        
        // Verify paywall appears
        XCTAssertTrue(app.staticTexts["Unlock"].exists)
        XCTAssertTrue(app.staticTexts["Unlimited Art"].exists)
        XCTAssertTrue(app.buttons["Upgrade"].exists)
    }
    
    func testPaywallDismissal() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Trigger paywall
        // ... (reach scan limit)
        
        // Tap close button
        app.buttons["xmark"].tap()
        
        // Verify returned to scan view
        XCTAssertTrue(app.buttons["Scan Button"].exists)
        
        // Verify scan button is disabled
        XCTAssertFalse(app.buttons["Scan Button"].isEnabled)
    }
}
```

---

## App Store Configuration

### 1. In-App Purchases Setup

#### Navigate to App Store Connect
1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to "Features" > "In-App Purchases and Subscriptions"

#### Create Subscription Group
1. Click "+" under Subscription Groups
2. Name: "Museum Companion Pro"
3. Reference Name: pro_subscriptions

#### Add Monthly Subscription
1. Click "+" in subscription group
2. Select "Auto-Renewable Subscription"
3. Configure:
   - Product ID: `com.museumcompanion.pro.monthly`
   - Reference Name: Museum Companion Pro (Monthly)
   - Duration: 1 Month
   - Price: €2.99 (Tier 3)
4. Provide localizations for each supported region
5. Add subscription display name and description

#### Add Yearly Subscription
1. Repeat process with:
   - Product ID: `com.museumcompanion.pro.yearly`
   - Duration: 1 Year
   - Price: €19.99 (Tier 20)

#### Configure Subscription Information
- **Display Name**: Museum Companion Pro
- **Description**: Unlimited artwork scans, iCloud sync, and exclusive story mode. Discover art without limits.
- **Privacy Policy URL**: Required
- **Review Information**: Provide test account credentials

### 2. Subscription Settings

#### Pricing
- Set base price in EUR
- Let App Store calculate regional pricing
- Enable all available territories

#### Trial Period (Optional)
- Offer: 7 days free trial
- Eligibility: First-time subscribers only
- Configure in "Introductory Offers"

#### Family Sharing
- Recommend: Enable for both subscriptions
- Allows up to 6 family members to share

#### Subscription Ranking
- Yearly should be highest (best value)
- Monthly should be standard

### 3. App Review Guidelines Compliance

#### Required Elements

**Clear Value Proposition**
- ✅ Feature comparison (Free vs Pro)
- ✅ No misleading claims
- ✅ Accurate pricing display

**Transparent Billing**
- ✅ Price shown before purchase
- ✅ Subscription terms clearly stated
- ✅ Auto-renewal information provided

**Easy Cancellation**
- ✅ Link to subscription management
- ✅ Instructions in app settings
- ✅ No obstacles to canceling

**Restore Functionality**
- ✅ "Restore Purchases" button
- ✅ Works across devices
- ✅ No re-purchase required

#### App Review Submission Notes

Include in review notes:
```
SUBSCRIPTION TESTING:

Test Account:
Email: [your-sandbox-tester@email.com]
Password: [password]

Testing Instructions:
1. Launch app without signing in
2. Attempt to scan 3 artworks
3. After 3rd scan, limit notification appears
4. On 4th scan attempt, paywall appears
5. Sign in with test account above
6. Purchase "Monthly" subscription to test checkout
7. Verify unlimited scans are enabled

Notes:
- Free tier: 3 scans per day
- Subscription: Unlimited scans
- All prices displayed before purchase
- Restore purchases available on paywall
- Subscription management via iOS Settings
```

---

## Compliance & Best Practices

### App Store Review Guidelines

#### Guideline 3.1.1: In-App Purchase
✅ All paid features use StoreKit  
✅ No alternative payment methods  
✅ Clear pricing and terms

#### Guideline 3.1.2: Subscriptions
✅ Clearly identify subscription features  
✅ Show price and billing frequency  
✅ Link to Terms of Service and Privacy Policy  
✅ Restore mechanism provided

#### Guideline 5.1.1: Data Collection and Storage
✅ Privacy policy covers subscription data  
✅ Minimal data collection  
✅ Secure storage of purchase information

### User Experience Best Practices

#### Transparency
- Show pricing upfront
- Explain what features unlock
- Display renewal information
- No hidden charges

#### Fairness
- Reasonable free tier (3 scans/day)
- No artificial restrictions
- Daily reset, not total limit
- Value-based pricing

#### Accessibility
- Clear exit options
- "Not now" button available
- No forced upgrade loops
- Subscription management accessible

#### Value Communication
- Feature-focused messaging
- Calm, museum-like tone
- No aggressive upselling
- Respect user choice

### Privacy & Security

#### Data Handling
```swift
// Only cache essential data
UserDefaults.standard.set(isProUser, forKey: "cachedProUserStatus")

// Never store:
// ❌ Credit card information
// ❌ Apple ID
// ❌ Transaction receipts (use StoreKit APIs)
// ❌ Personal financial data
```

#### Receipt Validation
```swift
// Always verify locally with StoreKit 2
let verified = try checkVerified(result)

// Never trust client-side values alone
// Always validate through Apple's servers
```

### Localization

Support multiple languages for:
- Paywall text
- Feature descriptions
- Subscription terms
- Error messages
- Success confirmations

Example structure:
```swift
// Localizable.strings
"paywall.title" = "Unlock Unlimited Art";
"paywall.subtitle" = "Discover endless artworks";
"paywall.feature.scans" = "Unlimited Scans";
"paywall.feature.sync" = "iCloud Sync";
"paywall.cta" = "Upgrade";
```

### Analytics & Monitoring

Track key metrics (respecting privacy):
- Paywall impression count
- Conversion rate
- Subscription retention
- Churn analysis
- Daily active users vs. Pro users

```swift
// Example: Privacy-preserving analytics
func trackPaywallShown() {
    // Send anonymous event
    Analytics.track("paywall_shown", properties: [
        "user_type": isProUser ? "pro" : "free",
        "scans_used_today": scanLimitManager.scansRemaining
    ])
}
```

### Error Handling

Provide clear, actionable error messages:

```swift
enum SubscriptionError: LocalizedError {
    case failedVerification
    case purchaseInProgress
    case networkError
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Unable to verify your purchase. Please try again."
        case .purchaseInProgress:
            return "A purchase is already in progress."
        case .networkError:
            return "Network connection required. Please check your internet connection."
        case .productNotFound:
            return "Subscription product not found. Please try again later."
        }
    }
}
```

---

## Troubleshooting

### Common Issues

#### Issue: Products not loading
**Symptoms**: Empty subscription products array  
**Causes**:
- StoreKit configuration not selected in scheme
- Product IDs mismatch
- Network connectivity issues
- App Store Connect setup incomplete

**Solutions**:
```swift
// Enable verbose logging
func loadProducts() async {
    do {
        let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }
        print("📦 Loading products: \(productIDs)")
        
        let products = try await Product.products(for: productIDs)
        print("✅ Loaded \(products.count) products")
        
        subscriptionProducts = products
    } catch {
        print("❌ Failed to load products: \(error)")
    }
}
```

#### Issue: Purchase fails with "Cannot connect to iTunes Store"
**Causes**:
- Not signed in to sandbox account
- Network issues
- StoreKit server problems

**Solutions**:
1. Sign in to sandbox account in Settings > App Store
2. Check network connectivity
3. Try again in a few minutes
4. Check Apple System Status

#### Issue: Restore purchases doesn't work
**Causes**:
- Different Apple ID used
- Transaction not finished properly
- Cache not cleared

**Solutions**:
```swift
func restorePurchases() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
        // Sync with App Store
        print("🔄 Syncing with App Store...")
        try await AppStore.sync()
        
        // Re-check subscription status
        print("🔍 Checking subscription status...")
        await loadSubscriptionStatus()
        
        if isProUser {
            print("✅ Pro status restored")
        } else {
            print("ℹ️ No active subscription found")
        }
    } catch {
        print("❌ Restore failed: \(error)")
    }
}
```

#### Issue: Limit doesn't reset after 24 hours
**Causes**:
- Clock manipulation detected
- App not launched to trigger reset
- Date calculation error

**Solutions**:
```swift
func checkDailyReset() async {
    let isClockManipulated = detectClockManipulation()
    
    if isClockManipulated {
        print("⚠️ Clock manipulation detected")
        return
    }
    
    let calendar = Calendar.current
    let now = Date()
    
    print("📅 Last reset: \(lastResetDate)")
    print("📅 Current time: \(now)")
    
    if !calendar.isDate(lastResetDate, inSameDayAs: now) {
        if now > lastResetDate {
            print("✅ New day detected - resetting scans")
            scansRemaining = freeScanLimit
            lastResetDate = now
            saveLocalData()
        }
    }
}
```

---

## Support & Resources

### Documentation
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Tools
- [App Store Connect](https://appstoreconnect.apple.com)
- [StoreKit Transaction Manager](https://developer.apple.com/documentation/xcode/testing-in-app-purchases-with-storekit-test-in-xcode)
- [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)

### Testing Resources
- [StoreKit Testing Guide](https://developer.apple.com/documentation/xcode/testing-at-all-stages-of-development-with-xcode-cloud)
- [Sandbox Testing](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)

---

## Changelog

### Version 1.0.0 (2026-01-29)
- Initial implementation
- StoreKit 2 integration
- Free tier: 3 scans/day
- Pro tier: Unlimited scans
- Clock manipulation protection
- Offline entitlement caching
- Grace period handling
- Comprehensive testing suite

---

## License

Proprietary - Museum Companion  
© 2026 All Rights Reserved
