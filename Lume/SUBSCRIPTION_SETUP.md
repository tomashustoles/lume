# Subscription Setup Guide

Create two subscription products from scratch: **Monthly** and **Yearly**.

---

## Product IDs (used in the app)
- **Monthly:** `com.h.lumeapp.1month`
- **Yearly:** `com.h.lumeapp.1year`

These IDs must match in Xcode, App Store Connect, and the app code.

---

## Step 1: Xcode StoreKit Configuration

Used for local testing without App Store Connect.

### If you see old products (e.g. `com.museumcomparison.pro.*`):
1. Select the old subscription in the left list
2. Press **Delete** (or right-click → Delete)
3. Repeat for each old product

### Add new products
1. In **AUTO-RENEWABLE SUBSCRIPTIONS**, click the **+** button
2. Choose **Add Auto-Renewable Subscription**
3. For the first product (Monthly):
   - **Reference Name:** `Pro Monthly`
   - **Product ID:** `com.h.lumeapp.1month`
   - **Price:** `2.99`
   - **Subscription Duration:** `1 Month`
   - **Family Sharing:** Off (or On, if desired)
   - (Optional) **Introductory Offer:** Add a free trial if needed
4. Click **+** again and add the second product (Yearly):
   - **Reference Name:** `Pro Yearly`
   - **Product ID:** `com.h.lumeapp.1year`
   - **Price:** `19.99`
   - **Subscription Duration:** `1 Year`
   - **Family Sharing:** Off (or On)
5. Set levels: Monthly = Level 1, Yearly = Level 2
6. Add localizations:
   - **Display Name:** e.g. "Lume Pro Monthly" / "Lume Pro Yearly"
   - **Description:** e.g. "Unlimited artwork scanning and all Pro features"

### Ensure scheme uses the right StoreKit file
1. **Product → Scheme → Edit Scheme…**
2. Select **Run** → **Options**
3. **StoreKit Configuration:** select **Lume/Configuration.storekit** or **Products.storekit** (whichever is in your project)

---

## Step 2: App Store Connect

Used for production and TestFlight.

1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → your app → **Subscriptions**
3. Create a **Subscription Group** (if deleted):
   - Name: e.g. "Lume Pro"
   - Reference Name: e.g. "Pro Subscription"
4. Add **Subscription 1 (Monthly)**:
   - **Product ID:** `com.h.lumeapp.1month`
   - **Reference Name:** `Pro Monthly`
   - **Subscription Duration:** 1 Month
   - **Price:** €2.99 (or your base price)
5. Add **Subscription 2 (Yearly)**:
   - **Product ID:** `com.h.lumeapp.1year`
   - **Reference Name:** `Pro Yearly`
   - **Subscription Duration:** 1 Year
   - **Price:** €19.99
   - Suggested level: 2 (higher than monthly)
6. Add **App Store localization** for both products
7. Submit for review when the group is ready

---

## Step 3: Attach subscriptions to app version

Before TestFlight/App Store:

1. **App Store Connect** → your app → **App Store** tab
2. Open the version you are preparing
3. In **In-App Purchases**, add both subscriptions to the build

---

## Checklist

- [ ] Product IDs match everywhere: `com.h.lumeapp.1month`, `com.h.lumeapp.1year`
- [ ] Xcode StoreKit config has both products
- [ ] Xcode scheme uses the StoreKit config file
- [ ] Subscription group created in App Store Connect
- [ ] Both products added to App Store Connect
- [ ] Subscriptions linked to the app version
- [ ] Local testing works in Simulator
- [ ] TestFlight / sandbox testing works on device
