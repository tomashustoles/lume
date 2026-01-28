# App Store Connect Configuration Guide

Complete guide for setting up subscriptions in App Store Connect for Museum Companion.

---

## Prerequisites

- Apple Developer Program membership ($99/year)
- App created in App Store Connect
- Bank account and tax forms completed in App Store Connect

---

## Part 1: Agreements and Banking

### 1.1 Complete Paid Applications Agreement

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **Agreements, Tax, and Banking**
3. Find **Paid Applications** agreement
4. Click **Request** if not yet requested
5. Review and accept agreement
6. Status should show **Active**

### 1.2 Set Up Banking Information

1. In **Agreements, Tax, and Banking**
2. Click **Banking Information**
3. Click **Add Bank Account**
4. Select your country/region
5. Fill in:
   - Bank name
   - Account holder name
   - IBAN or account number
   - SWIFT/BIC code
6. Click **Save**
7. Status changes to **Pending Verification** (takes 1-2 business days)

### 1.3 Complete Tax Forms

1. Click **Tax Forms**
2. Select your tax classification:
   - Individual
   - Company
   - Partnership
3. Fill out required forms (W-9 for US, W-8BEN for non-US)
4. Submit forms
5. Wait for Apple review (usually 1-2 business days)

**⚠️ Important**: You cannot test subscriptions in production without completing all three steps above.

---

## Part 2: Create Subscription Group

### 2.1 Navigate to Subscriptions

1. In App Store Connect, select your app
2. Click **Features** tab
3. Click **In-App Purchases and Subscriptions**
4. You should see two tabs:
   - **In-App Purchases** (for non-subscription items)
   - **Subscriptions** (for recurring subscriptions)
5. Click **Subscriptions** tab

### 2.2 Create Subscription Group

1. Click **"+"** button or **"Create"**
2. Enter Subscription Group information:

**Reference Name**: `pro_subscriptions`
- This is for your reference only, not shown to customers
- Cannot be changed once created

**App Name**: `Museum Companion Pro`
- This appears in subscription management UI
- Customer sees this when managing subscriptions

**Optional Fields**:
- Leave blank for now, can add later

3. Click **Create**

### 2.3 Configure Group Settings

After creation, configure group-level settings:

**Subscription Group Name** (Localized):
- Language: English (U.S.)
- Name: `Museum Companion Pro`
- This appears in Settings > Apple ID > Subscriptions

**Review Information**:
- Add screenshot showing subscription features
- Add notes for App Review explaining subscription value

---

## Part 3: Create Monthly Subscription

### 3.1 Add Monthly Product

1. In your subscription group, click **"+"**
2. Select **Create Subscription**

### 3.2 Configure Reference Information

**Reference Name**: `Museum Companion Pro (Monthly)`
- For your reference only

**Product ID**: `com.museumcompanion.pro.monthly`
- Must be unique across all apps
- Cannot be changed once created
- Must match exactly in your code
- Format: reverse domain notation recommended

### 3.3 Set Subscription Duration

**Duration**: `1 Month`
- Select from dropdown
- Cannot be changed once subscription is live

### 3.4 Add Subscription Localizations

Click **"+" under Subscription Localizations**

For **English (U.S.)**:
- **Name**: `Museum Companion Pro`
- **Description**: 
```
Unlock unlimited artwork scans and exclusive features:

• Unlimited daily scans
• iCloud sync across all devices
• Exclusive story mode narratives
• Unlimited favorites collection
• Priority support

Subscription auto-renews monthly. Cancel anytime in Settings.
```

Add localizations for other languages:
- Spanish
- French
- German
- Italian
- Japanese
- Chinese (Simplified)
- Chinese (Traditional)

### 3.5 Set Pricing

1. Click **Subscription Prices** section
2. Click **Add Subscription Price**
3. Select all territories you want to sell in
4. Choose base price: **€2.99** (EUR Tier 3)
   - App Store will auto-calculate prices for other regions
   - Example conversions:
     - USD: $2.99
     - GBP: £2.99
     - JPY: ¥450

5. Set **Start Date**: Immediately
6. No End Date (ongoing subscription)
7. Click **Next** and **Confirm**

### 3.6 Review Settings

- Product ID: ✅ `com.museumcompanion.pro.monthly`
- Duration: ✅ 1 Month
- Price: ✅ €2.99
- Localizations: ✅ At least English
- Status: 🟡 Ready to Submit

---

## Part 4: Create Yearly Subscription

### 4.1 Add Yearly Product

1. In same subscription group, click **"+"** again
2. Select **Create Subscription**

### 4.2 Configure Reference Information

**Reference Name**: `Museum Companion Pro (Yearly)`

**Product ID**: `com.museumcompanion.pro.yearly`
- Must be different from monthly
- Must match exactly in your code

### 4.3 Set Duration

**Duration**: `1 Year`

### 4.4 Add Localizations

For **English (U.S.)**:
- **Name**: `Museum Companion Pro (Yearly)`
- **Description**:
```
Get the best value with our yearly plan!

All Pro features included:
• Unlimited artwork scans every day
• iCloud sync across all your devices
• Exclusive story mode for deeper insights
• Unlimited favorites collection
• Priority customer support

Save 44% compared to monthly billing.

Subscription auto-renews yearly. Cancel anytime in Settings.
```

### 4.5 Set Pricing

1. Click **Subscription Prices**
2. Click **Add Subscription Price**
3. Select territories
4. Choose base price: **€19.99** (EUR Tier 20)
   - Example conversions:
     - USD: $19.99
     - GBP: £19.99
     - JPY: ¥3,000

5. Confirm pricing

### 4.6 Set as Best Value (Ranking)

1. In subscription group view, you'll see both subscriptions
2. Drag **Yearly** subscription to top position
3. This marks it as the recommended option
4. Appears with "Best Value" badge in Apple's subscription UI

---

## Part 5: Configure Optional Features

### 5.1 Introductory Offers (Optional)

Offer a free trial to new subscribers:

1. Edit Monthly or Yearly subscription
2. Scroll to **Subscription Prices**
3. Click **Add Introductory Offer**
4. Configure offer:
   - **Type**: Free
   - **Duration**: 7 days
   - **Number of Periods**: 1
   - **Eligibility**: First-time subscribers
5. Click **Save**

**⚠️ Note**: Introductory offers require special entitlement. Request from App Store Connect.

### 5.2 Promotional Offers (Optional)

Win-back or retention offers:

1. Edit subscription
2. Click **Add Promotional Offer**
3. Configure:
   - **Reference Name**: Win-back offer
   - **Offer Code**: COMEBACK2026
   - **Type**: Pay as you go
   - **Price**: €0.99
   - **Duration**: 1 month
   - **Number of Periods**: 1

### 5.3 Offer Codes (Optional)

Generate codes for marketing campaigns:

1. In subscription group
2. Click **Subscription Offer Codes**
3. Click **Create Offer Code**
4. Set up code parameters
5. Generate codes to distribute

### 5.4 Family Sharing

Enable sharing with family members:

1. Edit subscription
2. Find **Family Sharing** toggle
3. Enable for both Monthly and Yearly
4. Up to 6 family members can share one subscription
5. Recommended: Enable for consumer apps

---

## Part 6: App Information

### 6.1 Add Subscription Information

1. Go to app's **App Information** section
2. Scroll to **Subscriptions**
3. Click **Edit**
4. Fill in required fields:

**Subscription Group Name**: (Already set in group)

**Optional Subscription Description**:
```
Museum Companion Pro gives you unlimited access to recognize and 
learn about artworks around the world. Scan as many pieces as you 
want with no daily limits.
```

5. Click **Save**

### 6.2 Set Privacy Policy URL

Required for apps with subscriptions:

1. In **App Privacy** section
2. Add **Privacy Policy URL**
3. Example: `https://museumcompanion.app/privacy`
4. Must be accessible and include:
   - Data collection practices
   - Subscription billing information
   - How user data is used
   - How to cancel subscriptions

### 6.3 Add Terms of Service (Optional but Recommended)

1. Add **EULA URL** (End User License Agreement)
2. Example: `https://museumcompanion.app/terms`
3. Should include:
   - License grant
   - Usage restrictions
   - Subscription terms
   - Refund policy
   - Liability limitations

---

## Part 7: App Review Information

### 7.1 Subscription Review Notes

In app submission, add detailed notes for reviewers:

```
SUBSCRIPTION TESTING INFORMATION

Overview:
Museum Companion uses a freemium model:
- Free: 3 artwork scans per day
- Pro: Unlimited scans, iCloud sync, story mode

Test Credentials:
Email: reviewer@museumcompanion.test
Password: Review2026!

Testing Instructions:
1. Launch app without signing in
2. Tap camera icon to scan artwork
3. Point camera at any artwork (or use sample images in app)
4. Scan works up to 3 times
5. After 3rd scan, "Daily limit reached" notification appears
6. 4th scan attempt shows subscription paywall
7. Paywall displays two options: Monthly (€2.99) and Yearly (€19.99)
8. Use sandbox account above to complete test purchase
9. After purchase, unlimited scans are enabled

Subscription Features:
✓ Clear pricing before purchase
✓ Restore purchases button available
✓ Terms and privacy policy linked
✓ Subscription management via iOS Settings
✓ No forced upgrade loops
✓ Easy exit from paywall

Notes:
- Free tier resets every 24 hours
- All features accessible through standard iOS subscription management
- Cancellation does not require contacting support
```

### 7.2 Add Demo Video (Recommended)

1. Record screen demonstrating:
   - Free tier usage
   - Reaching limit
   - Paywall appearance
   - Purchase flow
   - Pro features unlocked
2. Upload to YouTube (unlisted)
3. Add link in Review Notes

---

## Part 8: Submission Checklist

Before submitting for review:

### Business Setup
- [ ] Paid Applications agreement signed
- [ ] Banking information added and verified
- [ ] Tax forms completed and approved

### Subscription Configuration
- [ ] Subscription group created
- [ ] Monthly product configured (€2.99)
- [ ] Yearly product configured (€19.99)
- [ ] Product IDs match code exactly
- [ ] All localizations added
- [ ] Pricing set for all territories

### App Metadata
- [ ] Privacy policy URL added
- [ ] Terms of service URL added (recommended)
- [ ] App description mentions subscriptions
- [ ] Screenshots show Pro features
- [ ] Subscription information filled out

### Review Information
- [ ] Detailed testing instructions provided
- [ ] Test account credentials included
- [ ] Feature list clearly explained
- [ ] Demo video uploaded (recommended)

### Code Implementation
- [ ] StoreKit 2 integrated
- [ ] Product IDs match exactly
- [ ] Restore purchases implemented
- [ ] Error handling in place
- [ ] Receipt validation implemented
- [ ] Offline support added
- [ ] Analytics integrated

### Testing
- [ ] Local StoreKit testing passed
- [ ] Sandbox testing completed
- [ ] All test scenarios verified
- [ ] Edge cases handled
- [ ] UI tested on multiple devices

---

## Part 9: Monitoring and Analytics

### 9.1 Track Subscription Metrics

In App Store Connect:

1. **Sales and Trends**
   - Daily subscription sales
   - New subscribers vs. renewals
   - Revenue breakdown by product

2. **App Analytics**
   - Conversion rate
   - Trial starts vs. conversions
   - Churn rate
   - Resubscription rate

3. **Subscription Reports**
   - Active subscribers
   - Subscription status changes
   - Refunds and cancellations
   - Billing issues

### 9.2 Set Up Financial Reports

1. Go to **Sales and Trends**
2. Enable **Financial Reports**
3. Download monthly reports
4. Track:
   - Gross revenue
   - Apple's commission (15% or 30%)
   - Net revenue
   - Proceeds by territory

### 9.3 Monitor Customer Feedback

1. Check **Ratings and Reviews**
2. Monitor subscription-related issues
3. Respond to customer concerns
4. Iterate based on feedback

---

## Part 10: Post-Launch Management

### 10.1 Managing Active Subscriptions

**View Subscribers**:
- Not directly available in App Store Connect
- Use App Store Server API for programmatic access
- Implement server-side dashboard

**Handle Refunds**:
- Customers request refunds through Apple
- Apple processes refund requests
- You receive notification via App Store Server Notifications
- Update entitlement in your app

**Grace Periods**:
- Automatically enabled by Apple
- Gives users extra time when payment fails
- Maintain access during grace period
- Handle in your app via StoreKit status

### 10.2 Updating Subscription Pricing

**Price Increase**:
1. Edit subscription in App Store Connect
2. Add new price with future start date
3. Existing subscribers notified 30 days in advance
4. Must accept new price or subscription cancels
5. New subscribers see new price immediately

**Price Decrease**:
1. Edit subscription
2. Add new lower price
3. Applies immediately to all subscribers
4. No notification required

### 10.3 Managing Promotional Campaigns

**Create Offer Codes**:
1. Set up promotional offers
2. Generate offer codes
3. Distribute via:
   - Email campaigns
   - Social media
   - Influencer partnerships
   - App Store product page

**Monitor Performance**:
- Track redemption rates
- Measure conversion from offer to paid
- A/B test different offers
- Adjust strategy based on data

### 10.4 Customer Support

**Common Support Scenarios**:

**"I can't restore my purchase"**
- Verify they're using same Apple ID
- Check subscription status in App Store Connect
- Use App Store Server API to verify
- May need to re-subscribe if expired

**"I was charged but don't have access"**
- Check transaction status via StoreKit
- Verify receipt validation is working
- Check for app version mismatches
- May need to restore purchases

**"How do I cancel?"**
- Direct to Settings > Apple ID > Subscriptions
- Or iTunes Store on desktop
- Cannot cancel through your app directly
- Apple handles all cancellations

**"I want a refund"**
- Direct to Apple's refund request page
- You cannot issue refunds directly
- Apple reviews and approves/denies
- Refunds granted = access revoked

---

## Part 11: Compliance and Best Practices

### 11.1 App Store Guidelines

**Guideline 3.1.2 - Subscriptions**

✅ **Do**:
- Clearly identify auto-renewable subscriptions
- Show price and renewal frequency before purchase
- Link to Terms of Service and Privacy Policy
- Use StoreKit for all in-app transactions
- Provide restore purchases mechanism
- Allow cancellation through iOS Settings

❌ **Don't**:
- Hide subscription terms
- Use manipulative tactics to prevent cancellation
- Offer alternative payment methods for digital content
- Make cancellation difficult
- Charge before free trial ends without notice

### 11.2 Privacy Requirements

**Required Disclosures**:
- What data is collected
- How subscription data is used
- Third-party sharing (if any)
- User rights (access, deletion)
- How to cancel subscriptions

**App Privacy Labels**:
1. In App Store Connect
2. Go to App Privacy
3. Fill out questionnaire
4. Declare data types collected:
   - Contact information (email for account)
   - Purchase history
   - Usage data (scan count)
5. Explain purpose and retention

### 11.3 Transparency Best Practices

**Clear Communication**:
- Show pricing before any commitment
- Explain what users get with subscription
- Indicate free trial duration clearly
- State when billing begins
- Provide easy access to terms

**Fair Limitations**:
- Make free tier genuinely useful (3 scans/day)
- Don't artificially cripple free experience
- Provide value that justifies subscription price
- Allow reasonable use without paying

**Respectful UX**:
- Don't spam with upgrade prompts
- Provide "Not now" option always
- Don't block navigation to force upgrade
- Respect user's choice to stay free

---

## Part 12: Troubleshooting

### Issue: Subscriptions Not Appearing in App Store Connect

**Causes**:
- App not yet created
- Paid Applications agreement not signed
- Banking/tax info incomplete

**Solutions**:
1. Complete all business setup steps
2. Wait 24 hours for processing
3. Sign out and back in to App Store Connect
4. Contact Apple Developer Support if persists

### Issue: "Invalid Product IDs" Error

**Causes**:
- Product IDs in code don't match App Store Connect
- Subscriptions not yet approved
- App hasn't been submitted once

**Solutions**:
1. Double-check product ID spelling
2. Ensure products are in "Ready to Submit" state
3. Submit app for review (products become active)
4. Wait for product propagation (can take hours)

### Issue: Sandbox Testing Not Working

**Causes**:
- Signed in with production Apple ID
- Subscription not in "Ready to Submit"
- Product not propagated yet

**Solutions**:
1. Sign out of production App Store
2. Use sandbox tester account only
3. Wait 24 hours after creating products
4. Try deleting app and reinstalling

### Issue: Family Sharing Not Working

**Causes**:
- Family Sharing not enabled for product
- Organizer doesn't have active subscription
- Family member using different Apple ID

**Solutions**:
1. Verify Family Sharing toggle is ON
2. Check organizer's subscription is active
3. Family members must be in same Family Sharing group
4. May need to sign out/in to refresh

---

## Resources

### Apple Documentation
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [In-App Purchase Programming Guide](https://developer.apple.com/in-app-purchase/)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)

### Support Channels
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [App Review Support](https://developer.apple.com/contact/app-store/)
- [Technical Support](https://developer.apple.com/support/)

### Tools
- [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)
- [App Store Server Notifications](https://developer.apple.com/documentation/appstoreservernotifications)
- [Subscription Reports](https://help.apple.com/app-store-connect/#/itc71da05939)

---

**Last Updated**: January 29, 2026  
**Version**: 1.0.0  
**Status**: Ready for App Store Connect Configuration
