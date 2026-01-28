# Files to Delete

To fix the "multiple @main" error, you need to delete these files in Xcode:

## 1. Delete MuseumCompanionApp.swift
- This is a duplicate of LumeApp.swift
- Location: `/Lume/MuseumCompanionApp.swift`
- **Action:** Right-click > Delete > Move to Trash

## 2. Delete ContentView.swift (if it exists)
- This is Xcode's default placeholder
- Location: `/Lume/ContentView.swift`
- **Action:** Right-click > Delete > Move to Trash

## What I've Already Fixed

✅ Updated `LumeApp.swift` with proper app structure
✅ Added `import Combine` to `ScanViewModel.swift`
✅ Added `import Combine` to `SubscriptionManager.swift`
✅ Added `import Combine` to `ScanLimitManager.swift`
✅ Added `import Combine` to `HistoryManager.swift`

## After Deleting Those Files

1. Clean Build Folder: `Cmd+Shift+K`
2. Build: `Cmd+B`

Your app should compile successfully! 🎉

## If You Still See Errors

Check for any other duplicate files:
- Multiple app entry points
- Duplicate view files
- Test files in the wrong target

The key is: **You can only have ONE file with `@main` in your entire app.**
