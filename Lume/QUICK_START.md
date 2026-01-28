# Quick Start Guide - Freemium Paywall Testing

**Goal**: Get the subscription system up and running in 15 minutes.

---

## Step 1: Create StoreKit Configuration (5 minutes)

### 1.1 Create File
1. Open Xcode
2. `File > New > File...` (⌘N)
3. Type "storekit" in filter
4. Select **"StoreKit Configuration File"**
5. Name: `Products.storekit`
6. Save in project root

### 1.2 Add Subscription Group
1. Click **"+"** at bottom
2. Choose **"Add Subscription Group"**
3. Reference Name: `pro_subscriptions`

### 1.3 Add Monthly Subscription
1. Click **"+"** in group
2. Choose **"Add Auto-Renewable Subscription"**
3. Fill in:
   - Product ID: `com.museumcompanion.pro.monthly`
   - Reference Name: `Museum Companion Pro (Monthly)`
   - Duration: `1 Month`
   - Price: `€2.99`
4. Add localization (English): 
   - Name: `Museum Companion Pro`
   - Description: `Unlimited scans and exclusive features`

### 1.4 Add Yearly Subscription
1. Click **"+"** in group again
2. Fill in:
   - Product ID: `com.museumcompanion.pro.yearly`
   - Reference Name: `Museum Companion Pro (Yearly)`
   - Duration: `1 Year`
   - Price: `€19.99`
3. Add localization (English):
   - Name: `Museum Companion Pro (Yearly)`
   - Description: `Save 44% with yearly billing`

---

## Step 2: Enable StoreKit in Scheme (1 minute)

1. `Product > Scheme > Edit Scheme...` (⌘<)
2. Select **"Run"** in left sidebar
3. Click **"Options"** tab
4. Set **"StoreKit Configuration"**: `Products.storekit`
5. Click **Close**

---

## Step 3: Build and Run (1 minute)

1. Select simulator (iPhone 15 Pro recommended)
2. `Product > Run` (⌘R)
3. Wait for build to complete
4. App launches

---

## Step 4: Test Free Tier (3 minutes)

### First Scan
1. Tap camera icon
2. Point at any artwork or use sample
3. ✅ Scan succeeds
4. Notice: "2 scans remaining" (if UI shows)

### Second Scan
1. Tap camera icon again
2. ✅ Scan succeeds
3. Notice: "1 scan remaining"

### Third Scan
1. Tap camera icon again
2. ✅ Scan succeeds
3. ✅ **"Daily limit reached"** notification appears
4. ✅ Scan button becomes disabled

### Fourth Scan Attempt
1. Try to tap camera icon
2. ✅ **Paywall appears** (or button is disabled)
3. ✅ Shows two subscription options
4. ✅ Shows pricing: €2.99/month and €19.99/year

---

## Step 5: Test Purchase Flow (3 minutes)

### Make Purchase
1. On paywall, select **Yearly** option
2. ✅ Selection indicator appears
3. Tap **"Upgrade"** button
4. StoreKit test dialog appears
5. Tap **"Subscribe"** in dialog
6. ✅ Purchase completes instantly
7. ✅ Paywall dismisses
8. ✅ Return to scan view

### Verify Unlimited Access
1. Tap camera icon multiple times
2. ✅ All scans succeed
3. ✅ No limit enforced
4. ✅ No counter showing

---

## Step 6: Test Restore (2 minutes)

### Simulate Clean Install
1. In Xcode: `Debug > Delete Application`
2. Build and run again (⌘R)
3. App launches fresh

### Restore Purchases
1. Use all 3 free scans
2. Trigger paywall
3. Tap **"Restore Purchases"**
4. ✅ Loading indicator appears
5. ✅ Pro status restored
6. ✅ Paywall dismisses
7. ✅ Unlimited scans work

---

## ✅ Success Checklist

After completing all steps, verify:

- [ ] Products loaded in paywall
- [ ] Free tier limits to 3 scans
- [ ] Limit notification shows after 3rd scan
- [ ] Paywall appears on 4th attempt
- [ ] Purchase completes successfully
- [ ] Unlimited scans work after purchase
- [ ] Restore purchases works after reinstall
- [ ] No crashes or errors

---

## 🐛 Quick Troubleshooting

### Products Don't Load
**Problem**: Paywall shows no subscription options

**Fix**:
1. Check scheme has StoreKit config enabled
2. Verify product IDs match exactly:
   - `com.museumcompanion.pro.monthly`
   - `com.museumcompanion.pro.yearly`
3. Clean build folder: `Product > Clean Build Folder` (⌘⇧K)
4. Rebuild and run

### Purchase Fails
**Problem**: Error when clicking "Upgrade"

**Fix**:
1. Check Console for error messages
2. Verify subscription group is set in .storekit
3. Delete app and reinstall
4. Try restarting simulator

### Restore Doesn't Work
**Problem**: "No purchases found" message

**Fix**:
1. Check Transaction Manager: `Debug > StoreKit > Manage Transactions`
2. Verify purchase is listed
3. Try `Debug > StoreKit > Clear All Purchases` then repurchase
4. Restart app

### Limit Doesn't Reset
**Problem**: Still shows 0 scans after 24 hours

**Fix**:
1. Quit app completely
2. Change system date to tomorrow
3. Launch app
4. Should detect clock change (won't reset as protection)
5. Reset date to automatic
6. Relaunch app - should work normally

---

## 📖 Next Steps

### For Detailed Testing
See: `STOREKIT_TESTING_GUIDE.md`
- 8 comprehensive test scenarios
- Transaction Manager usage
- Advanced testing techniques

### For App Store Setup
See: `APP_STORE_CONFIGURATION.md`
- Complete App Store Connect setup
- Banking and tax requirements
- Subscription configuration
- Review submission guide

### For Implementation Details
See: `FREEMIUM_PAYWALL_DOCUMENTATION.md`
- Architecture overview
- Security details
- Compliance guidelines
- API references

---

## 💡 Pro Tips

1. **Use Transaction Manager** to simulate subscriptions:
   - `Debug > StoreKit > Manage Transactions`
   - Can expire, refund, or renew subscriptions manually

2. **Check Console Logs** for detailed info:
   - ✅ Success: Green checkmarks
   - ⚠️ Warnings: Yellow caution
   - ❌ Errors: Red X marks

3. **Reset Everything** for clean testing:
   ```
   1. Debug > StoreKit > Clear All Purchases
   2. Debug > Delete Application  
   3. Clean Build Folder (⌘⇧K)
   4. Build and Run (⌘R)
   ```

4. **Test Clock Protection**:
   - Use all 3 scans
   - Change system date forward
   - Verify limit NOT reset (protection working)
   - Reset date to automatic

5. **Verify State Persistence**:
   - Make purchase
   - Force quit app (not delete)
   - Relaunch
   - Pro status should persist

---

## 🎯 Common Test Scenarios

### Happy Path
1. New user → 3 free scans → Paywall → Purchase → Unlimited ✅

### Restore Path  
1. Delete app → Reinstall → Restore → Unlimited ✅

### Cancellation Path
1. Start purchase → Cancel in dialog → Still free tier ✅

### Expiration Path
1. Purchase → Expire in Transaction Manager → Back to free ✅

### Upgrade Path
1. Purchase monthly → Purchase yearly → Now on yearly plan ✅

---

## 🚀 Launch Checklist

Before submitting to App Store:

- [ ] All quick start tests pass
- [ ] All 8 scenarios in testing guide pass
- [ ] Sandbox testing completed
- [ ] Products created in App Store Connect
- [ ] Banking and tax completed
- [ ] Privacy policy added
- [ ] Review notes written
- [ ] Test account credentials provided

---

## 📞 Need Help?

### Documentation
- Quick issues: This guide
- Detailed testing: `STOREKIT_TESTING_GUIDE.md`
- Implementation: `FREEMIUM_PAYWALL_DOCUMENTATION.md`
- App Store: `APP_STORE_CONFIGURATION.md`

### Code
- SubscriptionManager: `Services/SubscriptionManager.swift`
- ScanLimitManager: `Services/ScanLimitManager.swift`
- PaywallView: `Features/Paywall/PaywallView.swift`

### Testing
- Unit tests: `Tests/SubscriptionManagerTests.swift`
- Limit tests: `Tests/ScanLimitManagerTests.swift`

---

**Time to Complete**: 15 minutes  
**Difficulty**: Easy  
**Prerequisites**: Xcode 15+, iOS 17+ Simulator  
**Status**: Ready to Test

---

**Last Updated**: January 29, 2026  
**Version**: 1.0.0
