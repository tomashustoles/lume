# TestFlight Paywall – Why It Might Not Work & How to Fix

If the paywall shows "Unable to load subscription options" or the Upgrade button does nothing in TestFlight, use this checklist.

## 1. Link Subscriptions to the App Version (most common cause)

TestFlight/App Store will not load products until they are linked to the app version.

1. App Store Connect → **Mona - Art Companion** → **iOS App** → **1.0 Prepare for Submission**
2. Scroll to **In-App Purchases and Subscriptions**
3. Click **+** and add both:
   - `txh.lume.pro.monthly`
   - `txh.lume.pro.yearly`
4. Save

## 2. Complete Subscription Metadata

Both subscriptions had "Missing Metadata" – they must be complete:

1. App Store Connect → **Monetization** → **Subscriptions**
2. Open your subscription group → click each subscription (Year, Month)
3. For each, fill in:
   - Display name
   - Description
   - Pricing (select territories)
   - Review screenshot (if required)
   - App Store Promotion (if using)

Status must be **Ready to Submit** (no yellow warning).

## 3. Sandbox Tester Setup

TestFlight uses Sandbox for purchases (no real charges):

1. App Store Connect → **Users and Access** → **Sandbox** → **Testers**
2. Create a Sandbox Tester (use a fake email, e.g. `test@example.com`)
3. On the **device** running TestFlight: Settings → App Store → **Sign Out** (of your real Apple ID)
4. Launch Mona, trigger the paywall, tap **Upgrade to Pro**
5. When the purchase sheet appears, sign in with the **Sandbox Tester** account
6. Complete the "purchase" – no real money is charged

## 4. Agreements, Tax & Banking

In-app purchases require:

- **Paid Apps** agreement signed: App Store Connect → **Agreements, Tax, and Banking**
- **Banking information** added
- **Tax forms** completed

## 5. Wait a Few Minutes

After linking subscriptions to the version or pushing a new build:

- It can take **5–15 minutes** for products to propagate
- Try again after a short wait
- Use the **Retry** button on the paywall if products still fail to load

## 6. Check the Error Message

The paywall now shows the StoreKit error when products fail to load. Use it to debug:

- **"Unable to connect to the iTunes Store"** → Network or Apple backend issue; retry later
- **"No products available"** → Subscriptions not linked to the version, or metadata incomplete
- **"Invalid product ID"** → Product IDs in code don’t match App Store Connect

## 7. Verify Product IDs Match

In `ModelsModels.swift`:

- `txh.lume.pro.monthly`
- `txh.lume.pro.yearly`

These must match your App Store Connect product IDs exactly.

## 8. Quick Test: Profile → Upgrade to Pro

1. Open Mona (TestFlight build)
2. Go to **Profile** tab
3. Tap **Upgrade to Pro**
4. If products load here, the paywall works – the problem may be how/when it’s shown from the scan flow

---

**Most likely fix:** Step 1 – add the subscriptions to the app version on the 1.0 Prepare for Submission page. Without this, StoreKit will return no products in TestFlight.
