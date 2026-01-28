# 🎯 Quick Start - API Key Setup

**The API key has been removed from the code for security!**

Follow these simple steps to get the app running:

---

## ✅ Step-by-Step Setup (2 minutes)

### 1. Open Scheme Editor
   - Click on the **scheme dropdown** (next to the play button)
   - Select **"Edit Scheme..."**
   
   OR use keyboard shortcut: **⌘ + <** (Command + Less Than)

### 2. Add Environment Variable
   - On the left, select **"Run"**
   - Click the **"Arguments"** tab at the top
   - Under **"Environment Variables"**, click the **+** button
   
### 3. Add Your API Key
   - **Name:** `GEMINI_API_KEY`
   - **Value:** `AIzaSyBY-nXv11y61eQOrqhZHo4Maau1gCc6AOA`
   
### 4. Close and Build
   - Click **"Close"**
   - Build and run the app (⌘ + R)
   
### ✨ Done! Your app is now running securely!

---

## 📋 Files Created

- ✅ `Config.swift` - Loads API key securely
- ✅ `.gitignore` - Prevents secrets from being committed
- ✅ `APIKeys.plist.template` - Template for other devs
- ✅ `Secrets.xcconfig.template` - Alternative config method

## 🔒 Security Benefits

- ❌ API key is NO LONGER in source code
- ✅ API key is in environment variable (not committed)
- ✅ `.gitignore` prevents accidental commits
- ✅ Safe to share your code publicly

---

## 🆘 Need Help?

**App crashes with "GEMINI_API_KEY not configured"?**

Double-check you:
1. Added the environment variable to the scheme
2. Used the correct name: `GEMINI_API_KEY`
3. Pasted the full API key value
4. Closed the scheme editor

Still having issues? Try:
- Clean Build Folder: **Shift + ⌘ + K**
- Restart Xcode
- Make sure no extra spaces in the API key value

---

**You're all set! 🚀**
