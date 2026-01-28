# StoreKit Testing Guide for Museum Companion

## Quick Start

This guide walks you through testing the subscription system locally using Xcode's StoreKit testing capabilities.

---

## Prerequisites

- Xcode 15.0+
- iOS 17.0+ Simulator or Device
- Museum Companion project open in Xcode

---

## Step 1: Create StoreKit Configuration File

### 1.1 Create the File

1. In Xcode, select `File > New > File...` (or press `⌘N`)
2. In the filter box, type "storekit"
3. Select **"StoreKit Configuration File"**
4. Click **Next**
5. Name it: `Products.storekit`
6. Choose location: Project root (same level as the `.xcodeproj` file)
7. Click **Create**

### 1.2 Configure Subscription Group

1. In the `Products.storekit` file editor, click the **"+"** button at the bottom
2. Select **"Add Subscription Group"**
3. Set Reference Name: `pro_subscriptions`
4. Click **Done**

### 1.3 Add Monthly Subscription

1. With the subscription group selected, click **"+"** in the group
2. Select **"Add Auto-Renewable Subscription"**
3. Configure:
   - **Product ID**: `com.museumcompanion.pro.monthly`
   - **Reference Name**: `Museum Companion Pro (Monthly)`
   - **Price**: `€2.99`
   - **Subscription Duration**: `1 Month`
   - **Subscription Group**: `pro_subscriptions`
   - **Family Shareable**: Check ✓
4. Click **Add Localization**
   - **Locale**: `en_US` (English - United States)
   - **Display Name**: `Museum Companion Pro`
   - **Description**: `Unlimited artwork scans and exclusive features`
5. Click **Done**

### 1.4 Add Yearly Subscription

1. Click **"+"** in the subscription group again
2. Select **"Add Auto-Renewable Subscription"**
3. Configure:
   - **Product ID**: `com.museumcompanion.pro.yearly`
   - **Reference Name**: `Museum Companion Pro (Yearly)`
   - **Price**: `€19.99`
   - **Subscription Duration**: `1 Year`
   - **Subscription Group**: `pro_subscriptions`
   - **Family Shareable**: Check ✓
4. Click **Add Localization**
   - **Locale**: `en_US`
   - **Display Name**: `Museum Companion Pro (Yearly)`
   - **Description**: `One year of unlimited artwork scans with 44% savings`
5. Click **Done**

### 1.5 Verify Configuration

Your `Products.storekit` should now look like this:

```
Subscription Groups
└── pro_subscriptions
    ├── com.museumcompanion.pro.monthly (€2.99/month)
    └── com.museumcompanion.pro.yearly (€19.99/year)
```

---

## Step 2: Enable StoreKit Testing in Xcode Scheme

### 2.1 Edit Scheme

1. In Xcode menu: `Product > Scheme > Edit Scheme...` (or press `⌘<`)
2. Select **"Run"** in the left sidebar
3. Go to the **"Options"** tab
4. Find **"StoreKit Configuration"** section
5. From dropdown, select: `Products.storekit`
6. Click **Close**

### 2.2 Verify Setup

- ✅ Scheme should now show StoreKit enabled
- ✅ Products will load from local configuration file
- ✅ No Apple ID or sandbox account needed for local testing

---

## Step 3: Testing Scenarios

### Scenario A: Free User Limit Testing

**Objective**: Verify 3-scan daily limit

**Steps**:
1. Launch app in simulator/device
2. Navigate to scan view
3. Tap scan button (1st scan)
   - ✅ Scan should succeed
   - ✅ "2 scans remaining" message
4. Tap scan button (2nd scan)
   - ✅ Scan should succeed
   - ✅ "1 scan remaining" message
5. Tap scan button (3rd scan)
   - ✅ Scan should succeed
   - ✅ "Daily limit reached" notification appears
   - ✅ Scan button becomes disabled
6. Tap scan button (4th scan attempt)
   - ✅ Paywall should appear
   - ✅ Shows subscription options

**Expected Result**: Paywall blocks 4th scan attempt

---

### Scenario B: Subscription Purchase Flow

**Objective**: Test purchasing a subscription

**Steps**:
1. Continue from Scenario A (paywall visible)
2. Review paywall content:
   - ✅ Headline: "Unlock Unlimited Art"
   - ✅ Two subscription options visible
   - ✅ Prices displayed: €2.99/month and €19.99/year
3. Select "Yearly" option
   - ✅ Selection indicator appears
   - ✅ Upgrade button shows yearly price
4. Tap **"Upgrade"** button
5. In StoreKit dialog, tap **"Subscribe"**
   - ✅ Purchase completes instantly (local testing)
   - ✅ Success feedback (haptic/visual)
   - ✅ Paywall dismisses automatically
6. Return to scan view
   - ✅ Scan button is re-enabled
   - ✅ No scan limit indicator
7. Tap scan button multiple times
   - ✅ All scans succeed
   - ✅ No limit enforcement

**Expected Result**: Unlimited scans after purchase

---

### Scenario C: Subscription Status Persistence

**Objective**: Verify subscription persists across app launches

**Steps**:
1. Continue from Scenario B (Pro user)
2. Force quit the app (swipe up in app switcher)
3. Relaunch app
4. Check subscription status:
   - ✅ Pro badge/indicator visible
   - ✅ Unlimited scans still available
5. Navigate to Settings/Profile (if available)
   - ✅ Shows "Active" subscription status
   - ✅ Displays subscription details

**Expected Result**: Pro status maintained

---

### Scenario D: Restore Purchases

**Objective**: Test restore purchases functionality

**Steps**:
1. Continue from previous scenario (Pro user)
2. In Xcode: `Debug > Delete Application`
3. Relaunch app (clean install)
4. Attempt 4th scan to trigger paywall
5. In paywall, tap **"Restore Purchases"**
6. Wait for restore process
   - ✅ Loading indicator appears
   - ✅ Success message shown
   - ✅ Paywall dismisses
   - ✅ Pro status restored
7. Verify unlimited scans work

**Expected Result**: Subscription restored without re-purchasing

---

### Scenario E: Subscription Expiration

**Objective**: Test behavior when subscription expires

**Steps**:
1. With app running and Pro user active
2. Open **Transaction Manager**:
   - In Xcode simulator: `Debug > StoreKit > Manage Transactions`
3. Find your subscription transaction
4. Click **"Expire Subscription"** or adjust expiration date
5. Close Transaction Manager
6. In app, pull to refresh or restart
7. Check status:
   - ✅ Pro status reverts to free
   - ✅ Daily limit re-enabled
   - ✅ Scan counter shows 3 remaining
8. Use 3 scans
9. Attempt 4th scan
   - ✅ Paywall appears again

**Expected Result**: Reverts to free tier after expiration

---

### Scenario F: Subscription Upgrade

**Objective**: Test upgrading from monthly to yearly

**Steps**:
1. Start with free user, trigger paywall
2. Purchase **Monthly** subscription
3. Verify Pro status active
4. Open paywall again (via Settings or menu)
5. Select **Yearly** subscription
6. Tap **"Upgrade"**
7. Confirm purchase in StoreKit dialog
8. Check subscription status:
   - ✅ Now subscribed to yearly plan
   - ✅ Previous monthly subscription replaced
   - ✅ Unlimited access maintained

**Expected Result**: Successfully upgrades to yearly plan

---

### Scenario G: Purchase Cancellation

**Objective**: Test user cancelling purchase

**Steps**:
1. Start as free user, trigger paywall
2. Select subscription option
3. Tap **"Upgrade"**
4. In StoreKit dialog, tap **"Cancel"**
5. Check status:
   - ✅ Paywall remains open
   - ✅ No purchase completed
   - ✅ Still free user
6. Tap close button (X) on paywall
7. Return to scan view:
   - ✅ Scan button still disabled
   - ✅ Daily limit still enforced

**Expected Result**: No changes to free tier status

---

### Scenario H: Clock Manipulation Detection

**Objective**: Verify protection against time changes

**Steps**:
1. As free user, use all 3 scans
2. Note current time
3. On device/simulator:
   - Open Settings > General > Date & Time
   - Disable "Set Automatically"
   - Change date to tomorrow
4. Return to app
5. Attempt to scan:
   - ✅ Still shows 0 scans remaining
   - ✅ Paywall triggered (no reset)
6. Check console logs:
   - ✅ Should see: "⚠️ Clock manipulation detected"
7. Reset time to automatic
8. Quit and relaunch app
9. Daily reset should work normally on actual new day

**Expected Result**: System detects clock change, doesn't reset limit

---

## Step 4: Using Transaction Manager

### 4.1 Open Transaction Manager

While app is running:
1. In Xcode: `Debug > StoreKit > Manage Transactions`
2. Transaction Manager window opens

### 4.2 View Transactions

- See all purchases made
- View transaction details
- Check subscription status
- Review renewal information

### 4.3 Modify Transactions

**Renew Subscription**:
- Select transaction
- Click "Renew" button
- Simulates next billing cycle

**Expire Subscription**:
- Select transaction
- Click "Expire" button
- Immediately expires subscription

**Refund Transaction**:
- Select transaction
- Click "Refund" button
- Simulates App Store refund

**Enter Billing Retry**:
- Select transaction
- Click "Billing Retry" button
- Simulates payment failure

**Clear All Purchases**:
- Click "Clear All Purchases"
- Resets to clean state

---

## Step 5: Debugging Tips

### Enable Console Logging

Add breakpoints or observe console for:

```
✅ Subscription status loaded. Pro user: true
✅ Loaded 2 subscription products
✅ Purchase successful: Museum Companion Pro (Yearly)
✅ Daily scan limit reset. 3 scans available.
⚠️ Clock manipulation detected. Maintaining current scan limits.
```

### Check User Defaults

In debugger console:
```swift
(lldb) po UserDefaults.standard.integer(forKey: "scansRemaining")
// Should show remaining scan count

(lldb) po UserDefaults.standard.bool(forKey: "cachedProUserStatus")
// Should show Pro status
```

### Verify StoreKit Configuration

In scheme settings:
- Ensure `Products.storekit` is selected
- Check product IDs match exactly
- Verify prices are set

---

## Step 6: Common Issues & Solutions

### Issue: Products not loading

**Symptom**: Empty products array, paywall shows no options

**Solutions**:
1. Check scheme has StoreKit configuration enabled
2. Verify product IDs in code match `.storekit` file
3. Clean build folder: `Product > Clean Build Folder` (⌘⇧K)
4. Restart Xcode

### Issue: Purchase fails immediately

**Symptom**: Error message right after clicking purchase

**Solutions**:
1. Check console for specific error
2. Verify subscription group is set in `.storekit`
3. Ensure subscription durations are valid
4. Try deleting app and clean install

### Issue: Restore doesn't find purchases

**Symptom**: "No previous purchases found" message

**Solutions**:
1. Verify purchase actually completed (check Transaction Manager)
2. Try `Debug > StoreKit > Clear All Purchases` then re-purchase
3. Check product IDs match exactly
4. Restart app after purchase

### Issue: Scan limit doesn't reset

**Symptom**: Still showing 0 scans after expected reset

**Solutions**:
1. Check `lastResetDate` in User Defaults
2. Verify system time is set correctly
3. Relaunch app to trigger reset check
4. Check console for clock manipulation warnings

---

## Step 7: Transitioning to Sandbox Testing

Once local testing is complete, test with real App Store sandbox:

### 7.1 Create Sandbox Tester

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Users and Access > Sandbox Testers
3. Click "+" to add tester
4. Fill in details (use unique email)
5. Save

### 7.2 Configure Scheme for Sandbox

1. `Product > Scheme > Edit Scheme...`
2. Run > Options
3. Set **StoreKit Configuration** to: `None`
4. This enables real App Store sandbox

### 7.3 Sign In to Sandbox

1. On device: Settings > App Store
2. Sign out of production account
3. Launch app
4. When prompted for App Store login, use sandbox account

### 7.4 Test Real Subscriptions

- Purchases use real StoreKit servers
- Transactions recorded in App Store Connect
- Can test family sharing
- Can test across devices
- Renewal happens automatically

---

## Step 8: Best Practices

### Testing Checklist

Before submitting to App Store:

- [ ] Products load successfully
- [ ] Purchase flow completes
- [ ] Restore purchases works
- [ ] Subscription persists across launches
- [ ] Free tier limits enforced correctly
- [ ] Paywall UI displays properly
- [ ] Error messages are clear
- [ ] Grace period handled correctly
- [ ] Billing retry handled correctly
- [ ] Expiration handled correctly
- [ ] Clock manipulation detected
- [ ] Offline caching works
- [ ] All UI strings localized
- [ ] Analytics tracking works
- [ ] Privacy policy linked

### Test Matrix

| Scenario | Free User | Pro User | Expected Result |
|----------|-----------|----------|-----------------|
| 1st Scan | ✅ Allowed | ✅ Allowed | Success |
| 2nd Scan | ✅ Allowed | ✅ Allowed | Success |
| 3rd Scan | ✅ Allowed + Soft Warning | ✅ Allowed | Success |
| 4th Scan | ❌ Paywall | ✅ Allowed | Paywall or Success |
| After Purchase | ✅ Unlimited | ✅ Unlimited | Success |
| After Expiration | ⏱️ Back to 3/day | ❌ Back to Free | Limit enforced |
| After Restore | ✅ Unlimited | ✅ Unlimited | Success |

---

## Resources

- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
- [Transaction Manager Guide](https://developer.apple.com/documentation/xcode/testing-in-app-purchases-with-storekit-test-in-xcode)

---

## Support

For issues or questions:
1. Check console logs for error messages
2. Review this guide for troubleshooting steps
3. Consult main documentation: `FREEMIUM_PAYWALL_DOCUMENTATION.md`
4. Check Apple Developer Forums

---

**Last Updated**: January 29, 2026  
**Version**: 1.0.0
