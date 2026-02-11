# ✅ Final Setup Checklist for TestFlight

## Step 1: Verify Build Settings (Current Status)

You should have these build settings in Target "Lume" → Build Settings:

### Required Settings:

1. **`GEMINI_API_KEY`** (User-Defined Setting)
   - ✅ Should exist
   - ✅ Value: Your actual API key (e.g., `AIzaSy...`)
   - ✅ **CRITICAL**: Must have value in **Release** column (not just Debug)
   - Check: Look at the columns - both Debug and Release should show your key

2. **`INFOPLIST_KEY_GEMINI_API_KEY`** (User-Defined Setting)
   - ✅ Should exist
   - ✅ Value: `$(GEMINI_API_KEY)`
   - ✅ **CRITICAL**: Must be set for **Release** column (not just Debug)
   - This tells Xcode to inject the API key into Info.plist

## Step 2: Verify Info.plist

The Info.plist should have:
```xml
<key>GEMINI_API_KEY</key>
<string>$(GEMINI_API_KEY)</string>
```

This is already set up correctly! ✅

## Step 3: Test the Setup

### Test 1: Verify Build Settings Are Injected

1. **Build the app** (Cmd+B)
2. **Right-click** the app in Products folder → "Show in Finder"
3. **Right-click** the .app → "Show Package Contents"
4. **Open** `Info.plist` in a text editor
5. **Search** for `GEMINI_API_KEY`
6. **Verify**: The value should be your actual API key (NOT `$(GEMINI_API_KEY)`)

If you see `$(GEMINI_API_KEY)` literally, the injection isn't working - check Step 1 again.

### Test 2: Archive for TestFlight

1. **Clean Build Folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Archive**: Product → Archive
3. **Distribute**: Distribute to App Store Connect
4. **Test in TestFlight**: Install on device and test scanning

## Common Issues

### Issue: Still getting "API Key is invalid" in TestFlight

**Check:**
- [ ] `GEMINI_API_KEY` has value in **Release** column (not just Debug)
- [ ] `INFOPLIST_KEY_GEMINI_API_KEY` = `$(GEMINI_API_KEY)` in **Release** column
- [ ] Cleaned build folder before archiving
- [ ] Verified Info.plist in built app has actual key (not `$(GEMINI_API_KEY)`)

**Solution:**
- Make sure both settings are set for **Release** configuration
- Clean build folder and archive again

### Issue: Works in Xcode but not TestFlight

This means Release configuration isn't set up:
- Check that both build settings have values in the **Release** column
- The Release column is used for TestFlight/App Store builds

## Quick Verification Commands

After building, you can verify the injection worked:

```bash
# Find the built app
find ~/Library/Developer/Xcode/DerivedData -name "Lume.app" -type d | head -1

# Check Info.plist (replace PATH with actual path)
plutil -p /PATH/TO/Lume.app/Info.plist | grep GEMINI_API_KEY
```

The output should show your actual API key, not `$(GEMINI_API_KEY)`.

## Success Criteria

✅ Build succeeds without errors
✅ Info.plist in built app contains actual API key (not placeholder)
✅ App works in Xcode (Debug build)
✅ App works in TestFlight (Release build)
