# 🎯 Simpler Setup - Skip xcconfig if Needed

If you're having trouble with the xcconfig setup, here's a **simpler alternative** that will work immediately:

## Quick Alternative: Direct Build Setting

Instead of using xcconfig files, you can set the API key directly as a build setting:

### Step 1: Add API Key as Build Setting

1. **Open Xcode**: Open `Lume.xcodeproj`
2. **Select project**: Click the blue "Lume" project icon
3. **Select target**: Click "Lume" under TARGETS
4. **Go to Build Settings**: Click "Build Settings" tab
5. **Add user-defined setting**:
   - Click the **"+"** button at the top (or right-click → "Add User-Defined Setting")
   - Name: `GEMINI_API_KEY`
   - Value: Paste your actual API key here (e.g., `AIzaSy...your-key`)
   - Press Enter
6. **Verify**: Make sure it appears for both Debug and Release configurations

### Step 2: Update Info.plist (Already Done!)

The Info.plist already has the entry: `GEMINI_API_KEY = $(GEMINI_API_KEY)`

This will automatically read from the build setting you just created.

### Step 3: Test

1. Clean build (Shift+Cmd+K)
2. Build and run (Cmd+R)
3. Test scanning - it should work!

## ⚠️ Important Notes

**For TestFlight/Production:**
- Make sure the `GEMINI_API_KEY` build setting is set for **Release** configuration (not just Debug)
- When you archive, the Release configuration will be used

**Security:**
- This method stores the key in the Xcode project file
- The project file should be in `.gitignore` if it contains secrets
- For better security, use the xcconfig method (see XCODE_SETUP_INSTRUCTIONS.md)

## Why This Works

The app reads the API key from Info.plist, which reads from the build setting `$(GEMINI_API_KEY)`. By setting it directly as a build setting, we bypass the need for xcconfig files.

## Going Back to xcconfig Later

If you want to use the more secure xcconfig method later:
1. Follow `XCODE_SETUP_INSTRUCTIONS.md`
2. Remove the `GEMINI_API_KEY` build setting
3. Set up Config.xcconfig as described
