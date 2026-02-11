# 🔍 TestFlight Troubleshooting - Release is Set But Still Failing

## Current Status

✅ You have `GEMINI_API_KEY` set for Release (I can see it in the expanded view)
❓ Need to verify `INFOPLIST_KEY_GEMINI_API_KEY` is also set for Release

## Step 1: Verify INFOPLIST_KEY for Release

1. **Expand `INFOPLIST_KEY_GEMINI_API_KEY`** (click the arrow/chevron)
2. **Check the "Release" sub-row**:
   - Does the **hammer column** (Release) have a value?
   - It should be: `$(GEMINI_API_KEY)` or your actual API key

If the Release sub-row's hammer column is empty, that's the problem!

## Step 2: Set INFOPLIST_KEY for Release (If Needed)

If `INFOPLIST_KEY_GEMINI_API_KEY` → Release → hammer column is empty:

1. **Click on the empty hammer column** for the Release sub-row
2. **Type**: `$(GEMINI_API_KEY)`
3. **Press Enter**

## Step 3: Verify Both Are Set for Release

After expanding both settings, you should see:

**`GEMINI_API_KEY`**:
- ✅ Release sub-row → hammer column = your API key

**`INFOPLIST_KEY_GEMINI_API_KEY`**:
- ✅ Release sub-row → hammer column = `$(GEMINI_API_KEY)`

## Step 4: Clean and Rebuild Archive

Even if settings are correct, you need to rebuild:

1. **Clean Build Folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Delete old archive** (if exists): Window → Organizer → Archives → Delete old ones
3. **Archive fresh**: Product → Archive
4. **Distribute**: Distribute to App Store Connect
5. **Wait for processing** (can take 10-30 minutes)
6. **Test in TestFlight**

## Step 5: Verify the Archive Actually Has the Key

After archiving, verify the key is in the built app:

1. **Window → Organizer → Archives**
2. **Right-click your archive** → "Show in Finder"
3. **Right-click the .xcarchive** → "Show Package Contents"
4. **Navigate to**: `Products/Applications/Lume.app`
5. **Right-click Lume.app** → "Show Package Contents"
6. **Open Info.plist** in TextEdit or any text editor
7. **Search for** `GEMINI_API_KEY`

**What you should see:**
- ✅ **Good**: Your actual API key (e.g., `AIzaSyD4Yc8DhfKOc...`)
- ❌ **Bad**: The literal string `$(GEMINI_API_KEY)` (means injection failed)

## Common Issues

### Issue 1: Archive Was Created Before Settings Were Updated

**Solution**: Delete old archive and create a fresh one after setting Release values.

### Issue 2: INFOPLIST_KEY Not Set for Release

**Solution**: Make sure `INFOPLIST_KEY_GEMINI_API_KEY` → Release → hammer column has `$(GEMINI_API_KEY)`

### Issue 3: Xcode Caching

**Solution**: 
- Quit Xcode completely
- Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/Lume-*`
- Reopen Xcode and archive again

### Issue 4: App Store Connect Processing

**Solution**: Sometimes it takes time for the new build to process. Wait 15-30 minutes after uploading.

## Quick Test: Build and Check Locally

Before uploading to TestFlight, verify locally:

1. **Change scheme to Release**: Product → Scheme → Edit Scheme → Run → Build Configuration → Release
2. **Build**: Cmd+B
3. **Find the built app**: Right-click Products → Lume.app → "Show in Finder"
4. **Check Info.plist** in the built app (same steps as above)
5. **Verify**: Should have actual API key, not `$(GEMINI_API_KEY)`

If the local Release build has the key, TestFlight should work too!
