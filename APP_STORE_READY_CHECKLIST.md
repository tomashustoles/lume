# App Store Connect App Review Readiness Checklist

Use this checklist before submitting Mona - Art Companion to App Store Connect for review.

## Paywall & Subscriptions

- [ ] **In-App Purchases configured** in App Store Connect with product IDs matching `SubscriptionProduct` in `ModelsModels.swift`
- [ ] **Subscription group** created with Monthly and Yearly options
- [ ] **StoreKit tested** – Purchase flow works in Sandbox
- [ ] **Restore Purchases** works correctly
- [ ] **Free trial terms** displayed on paywall (e.g., "7 days free, then €2.99/month")
- [ ] **Manage Subscription** works for Pro users (Profile tab)
- [ ] **Scan limit overlay** appears at 0 scans with "Upgrade to Pro" button
- [ ] **Upgrade to Pro** button presents paywall and purchase flow

See [PAYWALL_SETUP.md](PAYWALL_SETUP.md) for configuration details.

## Legal URLs (Required – App Review will reject without these)

- [ ] **Privacy Policy**: Replace `https://example.com/privacy` in Info.plist
  - Add `PRIVACY_POLICY_URL` key or set `INFOPLIST_KEY_PRIVACY_POLICY_URL` in xcconfig
  - Must be a live, accessible URL
- [ ] **Terms of Service**: Replace `https://example.com/terms` in Info.plist
  - Add `TERMS_OF_SERVICE_URL` key or set `INFOPLIST_KEY_TERMS_OF_SERVICE_URL` in xcconfig
  - Must be a live, accessible URL
  - Include subscription terms (auto-renewal, cancellation, etc.)

## App Metadata

- [ ] **App name** and **subtitle** set in App Store Connect
- [ ] **Screenshots** for all required device sizes
- [ ] **App description** and **keywords**
- [ ] **Support URL** and **Marketing URL** (optional but recommended)
- [ ] **Age rating** completed
- [ ] **Copyright** and **Privacy Policy URL** in App Store Connect match the app

## Technical

- [ ] **Gemini API key** configured for production (no test/empty keys)
- [ ] **Export compliance** – `ITSAppUsesNonExemptEncryption` is set (already in Info.plist)
- [ ] **No debug-only UI** in release builds (e.g., "Show Onboarding" in Profile – consider removing or hiding for production)
- [ ] **Version and build number** incremented for each submission

## Testing

- [ ] Test on **physical device** with Sandbox account
- [ ] **Fresh install** → 3 free scans → Paywall at 4th attempt
- [ ] **Purchase** → Unlimited scans work
- [ ] **Restore** → Unlimited scans restored
- [ ] **Subscription expiry** (test with StoreKit) → Limits re-applied

## Common Rejection Reasons to Avoid

1. **Placeholder URLs** – Never submit with example.com; use real hosted pages
2. **Missing subscription terms** – Cancellation, renewal, and pricing must be clear
3. **Non-functional purchase flow** – Products must load and complete in Sandbox
4. **Crash on launch** – Test on multiple devices and iOS versions
5. **Incomplete permission descriptions** – Camera, etc. must have clear usage strings
