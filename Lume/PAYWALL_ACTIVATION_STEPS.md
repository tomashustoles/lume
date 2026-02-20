# Paywall Activation – What to Do

## ✅ Done in Code

- **Product IDs** updated to match App Store Connect:
  - `com.h.lumeapp.pro.monthly`
  - `com.h.lumeapp.pro.yearly`
- **Configuration.storekit** updated with both products for local testing.

---

## 1. App Store Connect – Fix "Missing Metadata"

For **Lume Pro Monthly** and **Lume Pro Yearly**:

### Subscription prices
1. Open each product in App Store Connect.
2. In **Subscription Prices**, tap **+** or **Add Subscription Price**.
3. Set a price (e.g. €2.99 for monthly, €19.99 for yearly).
4. Choose a **Base Country or Region** (e.g. United States).
5. Save.

### Localization
1. In **Localization**, tap **+**.
2. Add **English (U.S.)** (or your primary language).
3. Set:
   - **Display Name:** e.g. "Lume Pro Monthly" / "Lume Pro Yearly"
   - **Description:** e.g. "Unlimited artwork scanning and all Pro features"
4. Save.

Repeat for both products until "Missing Metadata" is gone.

---

## 2. Attach Subscriptions to App Version

1. Go to **App Store Connect** → your app → **App Store** tab.
2. Open the version you plan to submit (e.g. 1.0 Prepare for Submission).
3. In **In-App Purchases and Subscriptions**, tap **+**.
4. Select **Lume Pro Monthly** and **Lume Pro Yearly** from your subscription group.
5. Save.

Subscriptions must be attached to an app version before you submit for review.

---

## 3. Local Testing (Xcode Simulator)

1. In Xcode: **Product** → **Scheme** → **Edit Scheme…**
2. **Run** → **Options**
3. **StoreKit Configuration:** select **Lume/Configuration.storekit**
4. Run the app in Simulator – the paywall should load the two products.

---

## 4. TestFlight / Real Device (Sandbox)

1. Set **StoreKit Configuration** in the scheme to **None** (or remove it).
2. Upload a build and distribute via TestFlight.
3. Sign in with a **Sandbox Tester** account on the device.
4. Open the app and try the paywall – it will load products from App Store Connect.

---

## Checklist

- [ ] Subscription prices set for both products in App Store Connect
- [ ] Localization added for both products (Display Name + Description)
- [ ] Both subscriptions added to the app version’s In-App Purchases section
- [ ] App version submitted (or ready to submit) for App Review
- [ ] Local testing with Configuration.storekit works in Simulator
- [ ] TestFlight testing with sandbox account works on device
