# Production Setup Guide - API Key Configuration

This guide explains the **production-ready, secure** method for configuring the Gemini API key for TestFlight and App Store distribution.

## ✅ Current Solution (Production Ready)

The app uses **Xcode Build Settings** with the `INFOPLIST_KEY_` mechanism to securely inject the API key into `Info.plist` at build time. This ensures:

- ✅ **Secure**: API key never committed to git
- ✅ **Works in TestFlight**: Key is injected during archive/build
- ✅ **Works in Production**: Same mechanism for App Store builds
- ✅ **Fast**: No build scripts needed
- ✅ **Standard**: Uses Apple's recommended approach

## How It Works

1. **Info.plist** contains a placeholder: `$(GEMINI_API_KEY)`
2. **Build Settings** contain:
   - `GEMINI_API_KEY` = Your actual API key (stored in Xcode, not in source files)
   - `INFOPLIST_KEY_GEMINI_API_KEY` = `$(GEMINI_API_KEY)` (references the build setting)
3. **Xcode automatically replaces** the placeholder during build with the actual key

## Setup Instructions

### Step 1: Get Your Gemini API Key

1. Visit https://aistudio.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key

### Step 2: Configure Xcode Build Settings

1. **Open Xcode** and select your project
2. **Select the "Lume" target**
3. **Go to "Build Settings" tab**
4. **Search for "GEMINI_API_KEY"**

   If it doesn't exist:
   - Click the "+" button at the top
   - Select "Add User-Defined Setting"
   - Name it: `GEMINI_API_KEY`
   - Set the value to your actual API key

5. **Set for both Debug and Release:**
   - Click on the value field
   - Enter your API key: `AIzaSy...your-key-here`
   - Make sure it's set in the **Hammer (Target)** column for both Debug and Release

6. **Search for "INFOPLIST_KEY"**
   - Find or create: `INFOPLIST_KEY_GEMINI_API_KEY`
   - Set the value to: `$(GEMINI_API_KEY)` (references the build setting above)
   - Make sure it's set in the **Hammer (Target)** column for both Debug and Release

### Step 3: Verify Info.plist

1. **Open `Lume/Info.plist`** (or `LumeInfo.plist` if that's what `INFOPLIST_FILE` points to)
2. **Verify it contains:**
   ```xml
   <key>GEMINI_API_KEY</key>
   <string>$(GEMINI_API_KEY)</string>
   ```
3. **Do NOT put your actual API key here** - it will be replaced automatically

### Step 4: Verify Build Settings

In Build Settings, verify:

- ✅ `INFOPLIST_FILE` = `Lume/Info.plist` (or `LumeInfo.plist`)
- ✅ `PRODUCT_BUNDLE_IDENTIFIER` = `txh.Lume`
- ✅ `GEMINI_API_KEY` = Your actual API key (both Debug & Release)
- ✅ `INFOPLIST_KEY_GEMINI_API_KEY` = `$(GEMINI_API_KEY)` (both Debug & Release)

### Step 5: Test

1. **Clean Build Folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Archive**: Product → Archive
3. **Distribute to TestFlight**
4. **Test on device**: The API key should work correctly

## Security Checklist

Before pushing to GitHub:

- ✅ **Info.plist** contains `$(GEMINI_API_KEY)` placeholder, NOT the actual key
- ✅ **No API keys in source code** (check with: `grep -r "AIzaSy" .`)
- ✅ **Build settings are stored in Xcode**, not in source files
- ✅ **`.gitignore`** excludes `*.xcscheme` files (may contain environment variables)
- ✅ **No API keys in documentation files**

## How to Verify No Keys Are Committed

Run this command before committing:

```bash
# Search for API keys in the repository
grep -r "AIzaSy" . --exclude-dir=.git --exclude-dir=DerivedData

# Should return NO results (or only in .gitignore files)
```

## CI/CD Setup

For automated builds (GitHub Actions, Fastlane, etc.):

### Option 1: Environment Variable (Recommended)

Set `GEMINI_API_KEY` as a secret in your CI/CD system:

```bash
# GitHub Actions
env:
  GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}

# Then in your build command:
xcodebuild \
  -project Lume.xcodeproj \
  -scheme Lume \
  -configuration Release \
  GEMINI_API_KEY="$GEMINI_API_KEY" \
  archive
```

### Option 2: Xcode Cloud

1. Go to Xcode Cloud settings
2. Add `GEMINI_API_KEY` as an environment variable
3. Xcode Cloud will automatically use it during builds

### Option 3: Fastlane

```ruby
# In Fastfile
lane :build do
  api_key = ENV["GEMINI_API_KEY"]
  
  xcodebuild(
    project: "Lume.xcodeproj",
    scheme: "Lume",
    configuration: "Release",
    build_settings: {
      "GEMINI_API_KEY" => api_key
    }
  )
end
```

## Troubleshooting

### API Key Not Working in TestFlight

**Check:**
1. `GEMINI_API_KEY` is set in Build Settings for **Release** configuration (not just Debug)
2. `INFOPLIST_KEY_GEMINI_API_KEY` = `$(GEMINI_API_KEY)` for **Release**
3. Info.plist contains the placeholder `$(GEMINI_API_KEY)`, not the actual key
4. Clean build folder and rebuild

**Verify in Archive:**
1. Archive the app
2. Right-click archive → Show in Finder
3. Right-click `.xcarchive` → Show Package Contents
4. Navigate to `Products/Applications/Lume.app/`
5. Open `Info.plist` in a text editor
6. Search for `GEMINI_API_KEY`
7. Should see your **actual API key** (not the placeholder)

### Works in Xcode but Not in TestFlight

This means the key is only set for Debug configuration:

**Fix:**
1. In Build Settings, find `GEMINI_API_KEY`
2. Make sure it's set in the **Release** column (hammer icon)
3. Same for `INFOPLIST_KEY_GEMINI_API_KEY`

### Build Setting Not Visible

If you can't find `GEMINI_API_KEY` in Build Settings:

1. Click the "+" button at the top of Build Settings
2. Select "Add User-Defined Setting"
3. Name: `GEMINI_API_KEY`
4. Value: Your API key
5. Make sure it's set for both Debug and Release

## Best Practices

1. **Separate Keys for Dev/Prod:**
   - Development: Use a test key with limited quota
   - Production: Use a production key with proper restrictions

2. **Rotate Keys Regularly:**
   - Rotate keys every 6-12 months
   - If a key is exposed, rotate immediately

3. **Monitor Usage:**
   - Check API usage in Google AI Studio regularly
   - Set up billing alerts
   - Monitor for unexpected spikes

4. **Never Commit Keys:**
   - Always use placeholders in source files
   - Store keys only in build settings or CI/CD secrets
   - Use `.gitignore` to exclude sensitive files

## Summary

✅ **Current Solution**: Build Settings + `INFOPLIST_KEY_` mechanism  
✅ **Secure**: Keys never in source code  
✅ **Works**: TestFlight and App Store ready  
✅ **Standard**: Apple's recommended approach  
✅ **Fast**: No build scripts needed  

This is the **production-ready, secure, and maintainable** solution.
