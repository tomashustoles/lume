# Photo Picker Implementation

## Overview
Added a photo picker button to the main capture screen that allows users to select artwork images from their camera roll instead of only using the live camera.

## Changes Made

### ScanView.swift

#### 1. Added PhotosUI Import
```swift
import PhotosUI
```

#### 2. Added State Variable
```swift
@State private var selectedPhotoItem: PhotosPickerItem?
```

#### 3. Added Photo Picker Button
The button is positioned in the bottom left corner of the scan area, aligned with the main capture button but on the left side.

**Location**: Bottom left of the capture area
- Uses GeometryReader to calculate position relative to the scan square
- Positioned at `squareLeft - 40` horizontally
- Vertically centered in the space below the scan square

**Design**:
- Icon: `photo.on.rectangle` SF Symbol
- Size: 50x50 points
- Effect: Glass effect with interactive style
- Disabled when processing or analyzing

#### 4. Added onChange Handler
```swift
.onChange(of: selectedPhotoItem) { oldValue, newValue in
    Task {
        if let newValue {
            await loadAndProcessPhoto(from: newValue)
        }
    }
}
```

#### 5. Added Helper Function
```swift
private func loadAndProcessPhoto(from item: PhotosPickerItem) async
```

This function:
- Loads the selected image data using `loadTransferable(type: Data.self)`
- Converts to UIImage
- Freezes the image for display during analysis
- Calls the same `viewModel.captureAndProcess()` method used for camera captures
- Shows the result sheet when processing completes
- Resets the picker selection

## User Experience

1. User taps the photo icon in the bottom left corner
2. iOS system photo picker appears
3. User selects an artwork image
4. The selected image is displayed and analyzed exactly like a camera capture
5. The analyzing overlay appears with progress indicators
6. Results are shown in the artwork detail sheet
7. The selection is reset, ready for another pick

## Features

- **Unified Processing**: Selected photos go through the same recognition pipeline as camera captures
- **Visual Consistency**: Uses the same frozen image display and analyzing overlay
- **Scan Limits**: Photo selections count toward daily scan limits (for non-Pro users)
- **Disabled States**: Button is disabled during processing to prevent multiple concurrent requests
- **Glass Effect**: Matches the visual style of other UI elements in the app

## Privacy

The PhotosPicker API respects user privacy:
- No photo library permission required (iOS 14+)
- User explicitly selects which photos to share
- App only receives access to selected photos

## Benefits

1. **Flexibility**: Users can analyze artwork photos they've already taken
2. **Testing**: Easier for users to test with images they know
3. **Offline Use**: Users can take photos in museums (no flash) and analyze later
4. **Better Quality**: Users can select their best photo of an artwork instead of being limited to a single live capture
