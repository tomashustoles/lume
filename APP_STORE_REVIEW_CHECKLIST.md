# App Store Review – Resubmission Checklist

Follow-up tasks from App Store review. Code changes are done; complete the steps below before resubmitting.

## Done in code

- **EULA in subscription UI** – The paywall (subscription screen) now shows an “End User License Agreement (EULA)” link in the legal section at the bottom. Profile → App also has an EULA link.
- **EULA URL** – Configured in `Lume/Info.plist` as `EULA_URL`. Currently set to your privacy policy URL; replace with a dedicated EULA page URL if you have one.

## You need to do

### 1. EULA in App Store Connect

- In [App Store Connect](https://appstoreconnect.apple.com) → your app → **App Information**.
- Either:
  - Set **EULA** (End User License Agreement) to your EULA text or URL, or  
  - Add the EULA link in the **App Store description** (e.g. “End User License Agreement: [link]”).
- Apple requires the EULA to be visible in the app (done) and in the listing or EULA field (this step).

### 2. Test IAP end-to-end in sandbox

- In Xcode, the **Lume** scheme already uses **StoreKit Configuration**: `Lume/Configuration.storekit`.
- Run the app (Product → Run).
- Sign out of the App Store on the device/simulator if needed, then when prompted use a **Sandbox** Apple ID (create one in App Store Connect → Users and Access → Sandbox → Testers).
- Open the paywall (e.g. Profile → Upgrade to Pro or trigger it after using free scans).
- Complete a test subscription purchase and confirm it unlocks Pro.
- Optionally: restore purchases, cancel subscription in Settings, and run again to verify restore/expiry behavior.

### 3. Upload a new binary and resubmit

- Increment **Version** or **Build** number in Xcode (e.g. Project → Lume → General).
- Archive: Product → Archive.
- Distribute to App Store Connect (Organizer → Distribute App).
- In App Store Connect, submit the new build for review (include a note that EULA was added in-app and in the listing/EULA field, and that IAP was tested in sandbox).

---

**Summary:** EULA link is in the subscription UI and in Profile. Set EULA in App Store Connect (or description), test IAP in sandbox, then upload a new build and resubmit.
