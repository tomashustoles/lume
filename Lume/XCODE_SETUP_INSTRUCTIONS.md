# Xcode Configuration - Quick Setup Guide

## What You Need to Do (5 minutes)

I've created all the necessary files. Now you just need to configure Xcode to use them. Follow these steps:

### Step 1: Add Config.xcconfig to Xcode Project

1. **Open Xcode**: Open `Lume.xcodeproj` in Xcode
2. **Add the file**:
   - In the left navigator, right-click on the project root (the blue "Lume" icon)
   - Select **"Add Files to Lume..."**
   - Navigate to and select `Config.xcconfig` (it's in the project root, same level as Lume.xcodeproj)
   - **IMPORTANT**: Uncheck "Copy items if needed" (we want to reference it, not copy it)
   - Click **"Add"**

### Step 2: Configure API Key (Choose One Method)

**⚠️ IMPORTANT: "Configuration File" is NOT in Target Build Settings!**
It's in the **PROJECT Info tab**, not the target Build Settings tab.

---

## Method A: Using xcconfig Files (Recommended for Production)

### Step 2A.1: Add Config.xcconfig to Project Info

1. **Select the PROJECT (not target)**:
   - Click the blue "Lume" project icon at the very top of the navigator
   - In the main editor area, you'll see two sections: "PROJECTS" and "TARGETS"
   - Under **"PROJECTS"** (not TARGETS), click "Lume"
   
2. **Go to Info tab**:
   - Click the **"Info"** tab at the top (it's next to Build Settings, Build Phases, etc.)
   - This is different from the target's Build Settings!
   
3. **Find Configurations section**:
   - Scroll down in the Info tab
   - You should see a section called **"Configurations"** with a table
   - The table has rows for "Debug" and "Release"
   
4. **Set Configuration File**:
   - Find the **"Based on Configuration File"** column (rightmost column)
   - For **Debug** row: Click the dropdown → Select `Config.xcconfig`
   - For **Release** row: Click the dropdown → Select `Config.xcconfig`
   - If `Config.xcconfig` doesn't appear in the dropdown, make sure you added it to the project in Step 1!

### Step 2A.2: Create Your API Key File

1. **Open Terminal** in project root:
   ```bash
   cd /Users/tomas.hustoles/Lume
   ```

2. **Copy the example**:
   ```bash
   cp Config.local.xcconfig.example Config.local.xcconfig
   ```

3. **Edit and add your key**:
   ```bash
   open -a TextEdit Config.local.xcconfig
   ```
   Replace `YOUR_API_KEY_HERE` with your actual Gemini API key

---

## Method B: Direct Build Setting (Simpler, Works Immediately)

If you can't find the Configurations section, use this simpler method:

### Step 2B: Add API Key as Direct Build Setting

1. **You're already in the right place!** (Target Build Settings)
   - You're currently viewing: Target "Lume" → Build Settings tab ✅

2. **Add User-Defined Setting**:
   - Click the **"+"** button at the top of the Build Settings table
   - Or right-click in the settings area → "Add User-Defined Setting"
   
3. **Create the setting**:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: Paste your actual API key here (e.g., `AIzaSy...your-key`)
   - Press Enter
   
4. **Verify for both configurations**:
   - Make sure the value appears in both **Debug** and **Release** columns
   - If you only see it in one, click the value and make sure it's set for both

**That's it!** This method bypasses xcconfig and works immediately.

---

## Which Method Should You Use?

**Method A (xcconfig)**: 
- ✅ More secure (key not in project file)
- ✅ Better for teams (each developer has their own key)
- ✅ Better for CI/CD
- ⚠️ Requires finding the PROJECT Info tab

**Method B (Direct Build Setting)**:
- ✅ Simpler (you're already in Build Settings!)
- ✅ Works immediately
- ✅ No need to find Configurations section
- ⚠️ Key stored in project file (less secure, but fine for solo dev)

**Recommendation**: Start with **Method B** to get it working, then switch to **Method A** later if needed.

### Step 3: Configure Info.plist Injection

**If you used Method A (xcconfig)**, you need this step:
1. **Still in Target Build Settings**, search for: `INFOPLIST_KEY`
2. **Add new setting**:
   - Click the "+" button → "Add User-Defined Setting"
   - Name: `INFOPLIST_KEY_GEMINI_API_KEY`
   - Value: `$(GEMINI_API_KEY)`
   - Press Enter
   - Make sure it's set for both Debug and Release

**If you used Method B (Direct Build Setting)**, you can skip this step! 
The Info.plist already reads from `$(GEMINI_API_KEY)`, which will automatically use your build setting.

### Step 4: Verify It Works

1. **Clean build**: In Xcode, go to **Product → Clean Build Folder** (Shift+Cmd+K)
2. **Build**: Press **Cmd+B** to build
3. **Run**: Press **Cmd+R** to run
4. **Test**: Try scanning an artwork - it should work!

## Troubleshooting

### "API Key is invalid or not configured" Error

**Check:**
1. ✅ `Config.local.xcconfig` exists and has your API key
2. ✅ `Config.xcconfig` is added to the Xcode project
3. ✅ xcconfig is applied to both Debug AND Release configurations
4. ✅ `INFOPLIST_KEY_GEMINI_API_KEY` is set in Build Settings
5. ✅ You cleaned the build folder

**Solution:**
- Clean build folder again (Shift+Cmd+K)
- Quit and restart Xcode
- Rebuild the project

### Works in Xcode but Not in TestFlight

This means the Release configuration isn't set up correctly:

1. Check that `Config.xcconfig` is applied to **Release** (not just Debug)
2. Verify `INFOPLIST_KEY_GEMINI_API_KEY` is set for Release configuration
3. Archive and test again

## Visual Guide

### Where to Find Build Settings

```
Xcode Window
├── Left Navigator
│   └── Blue "Lume" project icon ← Click this
│       └── TARGETS
│           └── "Lume" ← Click this
│               └── Build Settings tab ← Click this
│                   └── Search: "Configuration File"
```

### What the Settings Should Look Like

**Configuration File:**
```
Debug     | Config.xcconfig
Release   | Config.xcconfig
```

**INFOPLIST_KEY_GEMINI_API_KEY:**
```
Debug     | $(GEMINI_API_KEY)
Release   | $(GEMINI_API_KEY)
```

## That's It!

Once you complete these steps, your app will:
- ✅ Work in Xcode (development)
- ✅ Work in TestFlight (distribution)
- ✅ Keep API keys secure (not in git)
- ✅ Be ready for production

If you get stuck, check `SETUP.md` for more detailed instructions.
