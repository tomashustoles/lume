# Setup Guide

This guide will help you set up the Lume app for development and distribution.

## Prerequisites

- Xcode 15.0 or later
- macOS Sonoma 14.0 or later
- iOS 18.0+ deployment target
- Apple Developer account (for distribution)

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Lume
```

### 2. Configure API Key

The app uses xcconfig files for secure API key management. This ensures:
- API keys are never committed to git
- Works in both development and TestFlight builds
- Each developer can use their own key

#### Step 1: Get Your Gemini API Key

1. Visit https://aistudio.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key

#### Step 2: Create Local Configuration

1. Copy the example file:
   ```bash
   cp Config.local.xcconfig.example Config.local.xcconfig
   ```

2. Open `Config.local.xcconfig` in a text editor

3. Replace `YOUR_API_KEY_HERE` with your actual API key:
   ```xcconfig
   GEMINI_API_KEY = AIzaSy...your-actual-key-here
   ```

4. Save the file

**Important**: `Config.local.xcconfig` is gitignored and will never be committed to the repository.

#### Step 3: Configure Xcode Project

1. Open the project in Xcode:
   ```bash
   open Lume.xcodeproj
   ```

2. Add `Config.xcconfig` to the project:
   - Right-click on the project in the navigator
   - Select "Add Files to Lume..."
   - Select `Config.xcconfig`
   - Ensure "Copy items if needed" is unchecked (file should be referenced)
   - Click "Add"

3. Apply xcconfig to build configurations:
   - Select the project in the navigator
   - Select the target "Lume"
   - Go to "Build Settings" tab
   - Search for "Configuration File"
   - For both Debug and Release configurations:
     - Set "Configuration File" to `Config.xcconfig`

4. Configure Info.plist injection:
   - In Build Settings, search for "Info.plist"
   - Find "Info.plist Preprocessor Definitions" or "Info.plist Values"
   - Add a new entry:
     - Key: `GEMINI_API_KEY`
     - Value: `$(GEMINI_API_KEY)`
   
   Alternatively, you can set this via build setting:
   - Search for "INFOPLIST_KEY"
   - Add `INFOPLIST_KEY_GEMINI_API_KEY = $(GEMINI_API_KEY)`

### 3. Configure Signing

1. Select the project in Xcode navigator
2. Select the target "Lume"
3. Go to "Signing & Capabilities" tab
4. Select your development team
5. Enable "Automatically manage signing"

### 4. Enable Capabilities

1. In "Signing & Capabilities", click "+ Capability"
2. Add the following:
   - **iCloud (CloudKit)** - For syncing scan history
   - **In-App Purchase** - For subscription management

## Verification

### Test Development Build

1. Build and run the app from Xcode (⌘R)
2. The app should launch successfully
3. Try scanning an artwork - it should work without errors

### Test Distribution Build

1. Archive the app: Product → Archive (⌘B then Product → Archive)
2. Once archived, click "Distribute App"
3. Select "App Store Connect" or "Ad Hoc"
4. Follow the distribution wizard
5. Install on a device via TestFlight
6. Verify the app works correctly

## Troubleshooting

### API Key Not Found Error

If you see: "API Key is invalid or not configured"

**Check:**
1. `Config.local.xcconfig` exists and contains your API key
2. `Config.xcconfig` is added to the Xcode project
3. xcconfig is applied to your build configuration
4. Info.plist has the `GEMINI_API_KEY` entry
5. Build settings include `INFOPLIST_KEY_GEMINI_API_KEY = $(GEMINI_API_KEY)`

**Solution:**
- Clean build folder: Product → Clean Build Folder (⇧⌘K)
- Rebuild the project
- Verify the API key is correct in `Config.local.xcconfig`

### Works in Xcode but Not in TestFlight

This usually means the API key isn't being injected into Info.plist at build time.

**Check:**
1. Verify xcconfig is applied to Release configuration (not just Debug)
2. Verify `INFOPLIST_KEY_GEMINI_API_KEY` is set in build settings
3. Check that `Config.local.xcconfig` has the correct key

**Solution:**
- Ensure xcconfig is applied to all configurations
- For CI/CD, set `GEMINI_API_KEY` as an environment variable in your build system

## CI/CD Setup

For automated builds (GitHub Actions, Fastlane, etc.):

### Option 1: Environment Variable

Set `GEMINI_API_KEY` as a secret in your CI/CD system:

```bash
export GEMINI_API_KEY="your-api-key-here"
xcodebuild ...
```

### Option 2: Create Config File in CI

Create `Config.local.xcconfig` during the build:

```bash
echo "GEMINI_API_KEY = $GEMINI_API_KEY_SECRET" > Config.local.xcconfig
xcodebuild ...
```

### Option 3: Secrets Manager

Use your CI/CD system's secrets manager to inject the key:
- GitHub Actions: Repository secrets
- Fastlane: Match or environment variables
- Bitrise: Environment variables

## Security Best Practices

1. **Never commit API keys**:
   - `Config.local.xcconfig` is gitignored
   - Never add API keys to source code
   - Never commit scheme files with environment variables

2. **Rotate keys if exposed**:
   - If a key is accidentally committed, rotate it immediately
   - Revoke the old key in Google AI Studio
   - Generate a new key and update `Config.local.xcconfig`

3. **Use separate keys**:
   - Development: Use a test key with limited quota
   - Production: Use a production key with proper restrictions

4. **Monitor usage**:
   - Regularly check API usage in Google AI Studio
   - Set up billing alerts
   - Monitor for unexpected usage spikes

## Next Steps

- See `README.md` for project overview
- See `DEVELOPMENT.md` for development guidelines
- See `ARCHITECTURE.md` for technical details
