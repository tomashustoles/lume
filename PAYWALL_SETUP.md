# Paywall Setup Guide for App Store

This guide explains how to set up the in-app purchase paywall so it works correctly in development, TestFlight, and production.

## Prerequisites

- Apple Developer account (paid)
- App registered in App Store Connect
- Xcode 15+ with StoreKit 2 support

## 1. App Store Connect Configuration

### Create Subscription Products

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → Your App → **In-App Purchases**
2. Create a **Subscription Group** (e.g., "Pro Subscription")
3. Add two auto-renewable subscriptions:
   - **Monthly**: `txh.lume.pro.monthly`
   - **Yearly**: `txh.lume.pro.yearly`
4. Configure introductory offer (7-day free trial recommended)
5. Add localizations and pricing for each territory
6. Submit for review (subscriptions are reviewed with your app)

### Product IDs Must Match

Ensure `ModelsModels.swift` enum `SubscriptionProduct` matches your App Store Connect product IDs:

```swift
enum SubscriptionProduct: String, CaseIterable {
    case monthly = "txh.lume.pro.monthly"  // Must match App Store Connect
    case yearly = "txh.lume.pro.yearly"
}
```

These must match the product IDs configured in App Store Connect for bundle ID `txh.Lume`.

## 2. StoreKit Configuration (Local Testing)

For testing without a real App Store connection:

1. In Xcode, open **Configuration.storekit** (or create one: File → New → StoreKit Configuration File)
2. Add subscriptions matching your product IDs
3. In your scheme: **Edit Scheme** → **Run** → **Options** → **StoreKit Configuration** → Select your config file
4. Use the StoreKit Transaction Manager (Debug → StoreKit → Manage Transactions) to test purchases, restores, and subscriptions

### Sandbox Testing

1. Sign out of your Apple ID in Settings
2. Run the app on a device or simulator
3. When prompted, sign in with a Sandbox Tester account (create in App Store Connect → Users and Access → Sandbox Testers)
4. Purchases will not charge real money

## 3. Why "Upgrade to Pro" May Do Nothing

The paywall button can appear unresponsive when:

### Products Don't Load

**Symptom**: "Unable to load subscription options" message, or disabled Upgrade button.

**Fixes**:
1. Ensure product IDs in code match App Store Connect
2. Subscriptions must be in "Ready to Submit" state
3. For TestFlight: Use a real device, Sandbox account, and wait for products to sync (can take minutes on first launch)
4. Check Xcode console for `❌ Failed to load products`

### Missing Environment Objects

The app now explicitly passes `SubscriptionManager` and `ScanLimitManager` to `PaywallView` when presented as a sheet. If you add new presentation paths, ensure:

```swift
PaywallView()
    .environmentObject(subscriptionManager)
    .environmentObject(scanLimitManager)
```

### Network / Sandbox Issues

- Ensure device has internet connectivity
- Sandbox can be slow; wait 30–60 seconds after launch
- Try the **Retry** button if products fail to load

## 4. Scan Limit Flow

When a free user has 0 scans remaining:

1. **Overlay appears**: "Scan Limit Reached. You've used all 3 daily scans. Upgrade to Pro for unlimited scanning."
2. **Upgrade to Pro button**: Presents the PaywallView sheet
3. **PaywallView**: Same design as Profile → Upgrade to Pro
4. After purchase or restore: Scan limit resets, overlay dismisses

## 5. App Store Review Checklist

- [ ] Privacy Policy URL set in Info.plist (`PRIVACY_POLICY_URL`)
- [ ] Terms of Service URL set in Info.plist (`TERMS_OF_SERVICE_URL`)
- [ ] Subscription terms and pricing clearly visible on paywall
- [ ] Restore Purchases works correctly
- [ ] Free trial terms displayed (e.g., "7 days free, then €2.99/month")
- [ ] Manage Subscription link for Pro users (Profile → Manage Subscription)
- [ ] No placeholder/example.com URLs in production build

## 6. Info.plist for Production URLs

Add to your project's Info.plist (or via xcconfig):

```xml
<key>PRIVACY_POLICY_URL</key>
<string>https://yourdomain.com/privacy</string>
<key>TERMS_OF_SERVICE_URL</key>
<string>https://yourdomain.com/terms</string>
```

Replace with your actual hosted policy URLs. App Review will reject apps linking to `example.com`.
