# Technical Architecture Document

## Overview

Museum Companion is a native iOS application built with SwiftUI and MVVM architecture. It leverages modern Swift features including async/await, actors, and structured concurrency.

## Architecture Pattern: MVVM

### Models
Pure data structures with no business logic.

**Key Models**:
- `Artwork`: Represents a recognized artwork with all metadata
- `FrameStyle`: Enum for different frame animation styles
- `GeminiResponse`: API response structure
- `ArtworkRecognitionResult`: Parsed recognition data
- `SubscriptionProduct`: Enum for subscription tiers

### ViewModels
Business logic and state management using `@MainActor` for UI thread safety.

**Key ViewModels**:
- `ScanViewModel`: Manages camera capture and AI recognition flow
  - Handles frame animations
  - Coordinates with services
  - Manages error states

### Views
SwiftUI declarative UI with no business logic.

**Key Views**:
- `ScanView`: Main camera interface
- `ArtworkDetailView`: Artwork display with Info/Story modes
- `PaywallView`: Subscription flow
- `CollectionView`: History and favorites
- `ProfileView`: Settings and stats
- `OnboardingView`: First-time user experience

## Services Layer

All services are implemented as actors or `@MainActor` classes for thread safety.

### GeminiService
```swift
actor GeminiService {
    func recognizeArtwork(image: UIImage) async throws -> ArtworkRecognitionResult
}
```

**Responsibilities**:
- Image preprocessing (compression, base64 encoding)
- API communication
- Response parsing
- Error handling

**API Flow**:
1. Compress image to JPEG (80% quality)
2. Convert to base64
3. Create structured prompt
4. POST to Gemini API
5. Parse JSON response
6. Clean markdown formatting
7. Decode to `ArtworkRecognitionResult`

**Error Handling**:
- Network errors
- HTTP errors (4xx, 5xx)
- JSON parsing errors
- Invalid responses

### SubscriptionManager
```swift
@MainActor
class SubscriptionManager: ObservableObject {
    @Published var subscriptionProducts: [Product] = []
    @Published var isProUser = false
    @Published var currentSubscription: Product.SubscriptionInfo.Status?
}
```

**Responsibilities**:
- Load products from App Store
- Handle purchases
- Verify transactions
- Listen for transaction updates
- Restore purchases

**StoreKit 2 Flow**:
1. Load products on app launch
2. Check subscription status
3. Listen for transaction updates
4. Verify all transactions
5. Update `isProUser` state

**Transaction Verification**:
All transactions are verified using StoreKit 2's built-in verification:
```swift
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw SubscriptionError.failedVerification
    case .verified(let safe):
        return safe
    }
}
```

### ScanLimitManager
```swift
@MainActor
class ScanLimitManager: ObservableObject {
    @Published var scansRemaining: Int = 3
    @Published var lastResetDate: Date = Date()
}
```

**Responsibilities**:
- Track daily scan usage
- Reset at midnight
- Sync with iCloud
- Manage Pro user unlimited access

**Sync Strategy**:
- Local: UserDefaults for immediate access
- Cloud: CloudKit for cross-device sync
- Conflict Resolution: Use most restrictive value

**Daily Reset Logic**:
```swift
func checkDailyReset() async {
    let calendar = Calendar.current
    let now = Date()
    
    if !calendar.isDate(lastResetDate, inSameDayAs: now) {
        scansRemaining = freeScanLimit
        lastResetDate = now
        saveLocalData()
        await syncToCloud()
    }
}
```

### HistoryManager
```swift
@MainActor
class HistoryManager: ObservableObject {
    @Published var artworks: [Artwork] = []
    @Published var isLoading = false
}
```

**Responsibilities**:
- Manage artwork collection
- Handle favorites
- Search functionality
- CloudKit synchronization
- Local persistence

**Storage Strategy**:
- **Local**: UserDefaults (encoded JSON)
- **Cloud**: CloudKit (CKRecord)
- **Images**: Stored as data, synced via CKAsset

**Sync Flow**:
1. Save locally immediately
2. Sync to CloudKit asynchronously
3. On launch, fetch from CloudKit
4. Merge with local data
5. Resolve conflicts (newest wins)

## Data Flow

### Scan Flow
```
User taps capture button
    ↓
CameraViewController captures photo
    ↓
Image cropped to square
    ↓
ScanViewModel.captureAndProcess()
    ↓
Check scan limits (ScanLimitManager)
    ↓
Start frame animation
    ↓
GeminiService.recognizeArtwork()
    ↓
Determine frame style from period
    ↓
Create Artwork object
    ↓
Save to HistoryManager
    ↓
Show ArtworkDetailView
```

### Subscription Flow
```
User opens PaywallView
    ↓
SubscriptionManager.loadProducts()
    ↓
Display products with pricing
    ↓
User selects product and taps subscribe
    ↓
SubscriptionManager.purchase(product)
    ↓
StoreKit 2 purchase flow
    ↓
Verify transaction
    ↓
Update isProUser state
    ↓
Finish transaction
    ↓
Update ScanLimitManager for unlimited
    ↓
Dismiss paywall
```

### CloudKit Sync Flow
```
User adds/modifies artwork
    ↓
Save to local UserDefaults
    ↓
Update UI immediately
    ↓
Convert Artwork to CKRecord
    ↓
Save to CloudKit (async)
    ↓
Handle errors gracefully
    ↓
On app launch/refresh:
    ↓
Fetch records from CloudKit
    ↓
Merge with local data
    ↓
Update UI
```

## Threading Model

### Main Actor
All UI-related classes use `@MainActor`:
- All ViewModels
- SubscriptionManager
- ScanLimitManager
- HistoryManager

### Actor Isolation
GeminiService uses `actor` for thread-safe API calls:
```swift
actor GeminiService {
    // All methods are automatically serialized
}
```

### Async/Await
All async operations use structured concurrency:
```swift
Task {
    await viewModel.captureAndProcess(...)
}
```

## Error Handling

### Gemini Errors
```swift
enum GeminiError: LocalizedError {
    case imageProcessingFailed
    case invalidRequest
    case invalidResponse
    case httpError(statusCode: Int)
    case noResponse
    case decodingFailed
    case networkError
}
```

Each error provides user-friendly descriptions via `errorDescription`.

### UI Error Presentation
```swift
.alert("Error", isPresented: $viewModel.showError) {
    Button("OK") {}
} message: {
    Text(viewModel.errorMessage ?? "Unknown error")
}
```

### Graceful Degradation
- Network errors: Show retry option
- Camera permission denied: Show settings link
- Subscription errors: Offer restore purchases
- CloudKit errors: Fall back to local storage

## Performance Optimizations

### Image Compression
```swift
image.jpegData(compressionQuality: 0.8)
```
Balance between quality and API payload size.

### Lazy Loading
```swift
LazyVStack {
    ForEach(artworks) { artwork in
        ArtworkRow(artwork: artwork)
    }
}
```

### Caching
- UserDefaults for frequent reads (limits, settings)
- In-memory caching for products
- Asset caching for images

### Background Processing
```swift
DispatchQueue.global(qos: .userInitiated).async {
    self.captureSession?.startRunning()
}
```

## Security

### API Key Management
API key is embedded in code. For production:
- Consider server-side proxy
- Or use Secrets.xcconfig (not committed to git)
- Or environment variables in CI/CD

### Transaction Verification
All StoreKit transactions are verified:
```swift
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T
```

### Data Privacy
- Images processed on-device before upload
- CloudKit data scoped to user's private database
- No analytics or tracking
- Clear data deletion

## Testing Strategy

### Unit Tests
Test business logic in isolation:
- Service methods
- ViewModel state changes
- Data transformations

### Integration Tests
Test service interactions:
- StoreKit flow
- CloudKit sync
- API communication (mocked)

### UI Tests
Test user flows:
- Onboarding completion
- Scan and recognition
- Subscription purchase
- Collection management

### Preview Tests
All views have SwiftUI previews for visual testing:
```swift
#Preview {
    ScanView()
        .environmentObject(SubscriptionManager())
}
```

## Dependency Injection

All dependencies injected via `@EnvironmentObject`:
```swift
@EnvironmentObject var subscriptionManager: SubscriptionManager
@EnvironmentObject var scanLimitManager: ScanLimitManager
@EnvironmentObject var historyManager: HistoryManager
```

Injected at app root:
```swift
MainTabView()
    .environmentObject(subscriptionManager)
    .environmentObject(scanLimitManager)
    .environmentObject(historyManager)
```

## Build Configurations

### Debug
- Verbose logging
- StoreKit sandbox
- CloudKit development container

### Release
- Minimal logging
- StoreKit production
- CloudKit production container

## API Rate Limiting

### Gemini API
- No explicit rate limiting implemented
- Naturally limited by scan limits (3/day free)
- Pro users: Reasonable use expected

### CloudKit
- Automatic throttling by Apple
- Operations batched where possible
- Errors handled gracefully

## Memory Management

### Image Handling
- Compress before storage
- Release camera session when not in use
- Clear captured image after processing

### Observation
- `@StateObject` for ownership
- `@EnvironmentObject` for shared state
- `@State` for local UI state

### Cleanup
```swift
deinit {
    updateListenerTask?.cancel()
    stopSession()
}
```

## Accessibility

### VoiceOver Support
- All buttons have labels
- Images have descriptions
- Semantic structure

### Dynamic Type
```swift
.font(.system(.body))
```
All text respects user font size preferences.

### Color Contrast
Black on white ensures high contrast for readability.

## Scalability Considerations

### Future Features
Architecture supports:
- Multiple recognition modes (sculptures, architecture)
- Offline mode (Core ML model)
- Social features (shared collections)
- AR features (spatial placement)

### Data Growth
- Pagination for large collections
- Archive old artworks
- Image cleanup utilities

### API Changes
- Service protocol abstraction
- Easy to swap AI providers
- Version compatibility handling

## Monitoring & Analytics

### Current: None
Privacy-first approach, no tracking.

### Future Considerations
- Privacy-preserving metrics
- Crash reporting (opt-in)
- Anonymous usage statistics
- A/B testing framework

## Deployment

### App Store
- Automatic signing
- TestFlight for beta testing
- Phased release recommended

### CI/CD
- Xcode Cloud integration
- Automated testing
- Build number auto-increment

## Documentation Standards

### Code Comments
- Minimal inline comments
- MARK: for organization
- DocC for public APIs

### README
- Setup instructions
- Architecture overview
- Contributing guidelines

### Change Log
- Semantic versioning
- Feature/fix documentation
- Migration guides

## Conclusion

This architecture provides:
- **Maintainability**: Clear separation of concerns
- **Testability**: Dependency injection and protocols
- **Scalability**: Modular design
- **Performance**: Async/await and efficient data handling
- **Reliability**: Comprehensive error handling
- **Privacy**: Local-first with optional cloud sync
