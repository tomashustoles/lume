# Typography Consistency Updates

## Overview
Updated font styles across ArtworkDetailView and CollectionView to match the consistent editorial design established in SplashView, Analysing Artwork overlay, and PaywallView.

## Design System

### Primary Typography (Editorial Headlines)
- **Font**: `.font(.custom("NewYork", size: 42-48))`
- **Weight**: `.fontWeight(.semibold)`
- **Color**: `.foregroundColor(.black)`
- **Usage**: Main screen titles, splash screens, major headers

### Secondary Typography (Body Text)
- **Font**: `.font(.system(.body))` or `.font(.system(.title3))`
- **Weight**: `.fontWeight(.semibold)` for headings, regular for body
- **Color**: `.foregroundColor(.black)` for headings, `.foregroundColor(.black.opacity(0.6-0.7))` for body
- **Usage**: Section headers, descriptions, supporting text

### Tertiary Typography (Labels & Metadata)
- **Font**: `.font(.system(.caption))` or `.font(.system(.subheadline))`
- **Weight**: `.fontWeight(.semibold)` or `.fontWeight(.medium)`
- **Color**: `.foregroundColor(.black.opacity(0.4-0.5))`
- **Usage**: Metadata labels, timestamps, small UI elements

## Changes Made

### ArtworkDetailView.swift

#### 1. Artwork Title
**Before:**
```swift
Text(artwork.title)
    .font(.system(size: 34, weight: .bold, design: .serif))
```

**After:**
```swift
Text(artwork.title)
    .font(.custom("NewYork", size: 34))
    .fontWeight(.semibold)
```

#### 2. Artist Name
**Before:**
```swift
Text(artwork.artist)
    .font(.system(size: 18, weight: .medium))
```

**After:**
```swift
Text(artwork.artist)
    .font(.system(.title3))
```

#### 3. Section Headers (About, Story, Cultural Context)
**Before:**
```swift
Text("About the Artwork")
    .font(.system(size: 20, weight: .semibold))
    .foregroundColor(.primary)
```

**After:**
```swift
Text("About the Artwork")
    .font(.system(.body))
    .fontWeight(.semibold)
    .foregroundColor(.black)
```

#### 4. Body Text
**Before:**
```swift
Text(artwork.description)
    .font(.system(size: 16))
    .foregroundColor(.secondary)
```

**After:**
```swift
Text(artwork.description)
    .font(.system(.subheadline))
    .foregroundColor(.black.opacity(0.7))
```

#### 5. Story Text (kept italic but updated font)
**Before:**
```swift
Text(artwork.storyMode)
    .font(.system(size: 16, design: .serif))
    .foregroundColor(.secondary)
    .italic()
```

**After:**
```swift
Text(artwork.storyMode)
    .font(.system(.subheadline))
    .foregroundColor(.black.opacity(0.7))
    .italic()
```

#### 6. Metadata Labels
**Before:**
```swift
Text("YEAR")
    .font(.system(size: 11, weight: .semibold))
    .foregroundColor(.secondary)
```

**After:**
```swift
Text("YEAR")
    .font(.system(.caption))
    .fontWeight(.semibold)
    .foregroundColor(.black.opacity(0.5))
```

#### 7. Metadata Values
**Before:**
```swift
Text(artwork.year)
    .font(.system(size: 16, weight: .medium))
    .foregroundColor(.primary)
```

**After:**
```swift
Text(artwork.year)
    .font(.system(.body))
    .fontWeight(.medium)
    .foregroundColor(.black)
```

#### 8. Action Buttons
**Before:**
```swift
Text("Scanned Images")
    .font(.system(size: 17, weight: .medium))
.foregroundColor(.primary)
.background(Color(.secondarySystemBackground))
```

**After:**
```swift
Text("Scanned Images")
    .font(.system(.body))
    .fontWeight(.medium)
.foregroundColor(.black)
.background(Color.black.opacity(0.05))
```

### CollectionView.swift

#### 1. Empty State Title
**Before:**
```swift
Text("No Artworks Yet")
    .font(.custom("NewYork", size: 28))
    .fontWeight(.semibold)
    .foregroundColor(.black)
```

**After:**
```swift
Text("No Artworks Yet")
    .font(.custom("NewYork", size: 42))
    .fontWeight(.semibold)
    .foregroundColor(.black)
```

#### 2. Empty State Description
**Before:**
```swift
Text("Scan your first artwork to begin your journey.")
    .font(.body)
    .foregroundColor(.secondary)
```

**After:**
```swift
Text("Scan your first artwork to begin your journey.")
    .font(.system(.title3))
    .foregroundColor(.black.opacity(0.6))
```

## Color System

### Text Colors
- **Primary Text**: `.black`
- **Secondary Text**: `.black.opacity(0.6-0.7)`
- **Tertiary Text**: `.black.opacity(0.4-0.5)`

### Background Colors
- **Primary Background**: `.white`
- **Subtle Background**: `.black.opacity(0.05)`

## Consistency Across App

All screens now follow this hierarchy:

1. **SplashView** ✅
   - Title: NewYork 48pt semibold
   - Subtitle: System body

2. **Analysing Artwork Overlay** ✅
   - Title: NewYork 42pt semibold
   - Subtitle: System title3
   - Row titles: System body semibold
   - Row descriptions: System subheadline

3. **PaywallView** ✅
   - Title: NewYork 42pt semibold
   - Subtitle: System title3
   - Feature titles: System body semibold
   - Feature descriptions: System subheadline

4. **ArtworkDetailView** ✅ (UPDATED)
   - Title: NewYork 34pt semibold
   - Artist: System title3
   - Section headers: System body semibold
   - Body text: System subheadline

5. **CollectionView** ✅ (UPDATED)
   - Empty state: NewYork 42pt semibold
   - Description: System title3

## Benefits

1. **Visual Consistency**: All major screens now use the same editorial NewYork font for headlines
2. **Clear Hierarchy**: Consistent use of font sizes and weights throughout
3. **Better Readability**: Proper color opacity for different text importance levels
4. **Apple Design Guidelines**: Follows Apple's Human Interface Guidelines for typography
5. **Professional Polish**: Creates a cohesive, premium feel across the entire app

## Implementation Date
February 9, 2026
