//
//  ScanView.swift
//  Mona - Art Companion
//
//  Main scanning interface with camera and frame animation
//

import SwiftUI
import PhotosUI

struct ScanView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = ScanViewModel()
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager
    @EnvironmentObject var historyManager: HistoryManager
    
    @State private var showResult = false
    @State private var cameraViewController: CameraViewController?
    @State private var isAnalyzing = false
    @State private var frozenImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    let onNavigateToCollection: (() -> Void)?
    let onNavigateToScan: (() -> Void)?
    
    init(onNavigateToCollection: (() -> Void)? = nil, onNavigateToScan: (() -> Void)? = nil) {
        self.onNavigateToCollection = onNavigateToCollection
        self.onNavigateToScan = onNavigateToScan
    }
    
    var body: some View {
        ZStack {
            // Camera feed
            if viewModel.cameraPermissionGranted {
                CameraView(capturedImage: $viewModel.capturedImage) { image in
                    // Freeze the captured image
                    frozenImage = image
                    isAnalyzing = true
                    
                    Task {
                        await viewModel.captureAndProcess(
                            image: image,
                            isProUser: subscriptionManager.isProUser,
                            scanLimitManager: scanLimitManager,
                            historyManager: historyManager
                        )
                        isAnalyzing = false
                        // Keep frozenImage visible as background behind the result sheet
                        showResult = true
                    }
                }
                .ignoresSafeArea()
                .opacity(isAnalyzing ? 0 : 1) // Hide live camera when analyzing
                
                // Show frozen captured image while analyzing
                if isAnalyzing, let frozenImage = frozenImage {
                    GeometryReader { geometry in
                        Image(uiImage: frozenImage.fixedOrientation())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    .ignoresSafeArea()
                }
                
                // Scan area overlay
                scanAreaOverlay
                
                // Analyzing indicator
                if isAnalyzing {
                    analyzingOverlay
                }
                
                // Capture button
                captureButton
                
                // Photo picker button (bottom left corner)
                photoPickerButton
                
                // Scan counter
                if !subscriptionManager.isProUser {
                    scanCounter
                }
                
            } else {
                // Permission required view
                permissionView
            }
        }
        .task {
            await viewModel.checkCameraPermission()
        }
        .onAppear {
            // Show Unlock Unlimited Art sheet when user has 0 scans (same as Profile > Upgrade to Pro)
            if !subscriptionManager.isProUser && scanLimitManager.scansRemaining == 0 {
                viewModel.showPaywall = true
            }
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let newValue {
                    await loadAndProcessPhoto(from: newValue)
                }
            }
        }
        .sheet(isPresented: $showResult) {
            if let artwork = viewModel.recognizedArtwork {
                ArtworkDetailView(
                    artwork: artwork,
                    onDismiss: {
                        showResult = false
                        frozenImage = nil
                        viewModel.reset()
                        // Show paywall after 3rd scan when user dismisses result
                        if !subscriptionManager.isProUser && scanLimitManager.scansRemaining == 0 {
                            viewModel.showPaywall = true
                        }
                    },
                    onNavigateToCollection: onNavigateToCollection,
                    onNavigateToScan: onNavigateToScan
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showPaywall },
            set: { viewModel.showPaywall = $0 }
        )) {
            PaywallView()
                .environmentObject(subscriptionManager)
                .environmentObject(scanLimitManager)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    // MARK: - Scan Area Overlay
    
    private var scanAreaOverlay: some View {
        GeometryReader { geometry in
            let sideLength = min(geometry.size.width, geometry.size.height) * 0.7
            
            ZStack {
                // Dim overlay
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                // Clear center square
                Rectangle()
                    .frame(width: sideLength, height: sideLength)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .allowsHitTesting(false)
            
            // Frame border
            if viewModel.isProcessing {
                AnimatedFrameView(
                    frameStyle: viewModel.currentFrame,
                    sideLength: sideLength
                )
                .frame(width: sideLength, height: sideLength)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    .frame(width: sideLength, height: sideLength)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
    
    // MARK: - Capture Button
    
    private var captureButton: some View {
        GeometryReader { geometry in
            let sideLength = min(geometry.size.width, geometry.size.height) * 0.7
            let squareBottom = (geometry.size.height / 2) + (sideLength / 2)
            let availableSpace = geometry.size.height - squareBottom
            let buttonYPosition = squareBottom + (availableSpace / 2)
            
            Button {
                print("🔵 Capture button tapped")
                if !subscriptionManager.isProUser && scanLimitManager.scansRemaining == 0 {
                    viewModel.showPaywall = true
                } else if let controller = findCameraViewController() {
                    print("✅ Found CameraViewController")
                    controller.capturePhoto()
                } else {
                    print("❌ CameraViewController not found")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                }
                .frame(width: 80, height: 80)
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .disabled(viewModel.isProcessing || isAnalyzing)
            .opacity((viewModel.isProcessing || isAnalyzing) ? 0.5 : 1.0)
            .position(x: geometry.size.width / 2, y: buttonYPosition)
        }
    }
    
    // MARK: - Photo Picker Button
    
    private var photoPickerButton: some View {
        GeometryReader { geometry in
            let sideLength = min(geometry.size.width, geometry.size.height) * 0.7
            let squareLeft = (geometry.size.width / 2) - (sideLength / 2)
            let squareBottom = (geometry.size.height / 2) + (sideLength / 2)
            let availableSpace = geometry.size.height - squareBottom
            let buttonYPosition = squareBottom + (availableSpace / 2)
            
            // Calculate safe position with padding from left edge
            let buttonRadius: CGFloat = 25 // Half of button width (50/2)
            let padding: CGFloat = 20 // Padding from screen edge
            let minXPosition = buttonRadius + padding
            let preferredXPosition = squareLeft - 40
            let safeXPosition = max(minXPosition, preferredXPosition)
            
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .disabled(viewModel.isProcessing || isAnalyzing)
            .opacity((viewModel.isProcessing || isAnalyzing) ? 0.5 : 1.0)
            .position(x: safeXPosition, y: buttonYPosition)
        }
    }
    
    // MARK: - Scan Counter
    
    private var scanCounter: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(scanLimitManager.scansRemaining)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("scans left")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .capsule)
                .padding(.trailing, 20)
            }
            .padding(.top, 60)
            
            Spacer()
        }
    }
    
    // MARK: - Analyzing Overlay
    
    private var analyzingOverlay: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                    .scaleEffect(1.3)
                    .frame(width: 32, height: 32)
                
                Text("Analysing\nArtwork...")
                    .font(.custom("NewYork", size: 42))
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text("Identifying the artist and details")
                    .font(.system(.title3))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
            }
            
            // Detail rows
            VStack(alignment: .leading, spacing: 20) {
                AnalysingRow(
                    icon: "paintpalette.fill",
                    title: "Detecting Style",
                    description: "Analysing brushwork and composition",
                    colorScheme: colorScheme
                )
                AnalysingRow(
                    icon: "person.fill",
                    title: "Identifying Artist",
                    description: "Matching against known works",
                    colorScheme: colorScheme
                )
                AnalysingRow(
                    icon: "clock.fill",
                    title: "Dating the Piece",
                    description: "Estimating period and movement",
                    colorScheme: colorScheme
                )
            }
        }
        .padding(28)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isAnalyzing)
    }
    
    // MARK: - Permission View
    
    private var permissionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.custom("NewYork", size: 28))
                .fontWeight(.semibold)
            
            Text("To recognize artworks, we need access to your camera. Please enable camera access in Settings.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Helper
    
    private func findCameraViewController() -> CameraViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return nil
        }
        
        return findCameraViewController(in: rootVC)
    }
    
    private func findCameraViewController(in viewController: UIViewController) -> CameraViewController? {
        if let cameraVC = viewController as? CameraViewController {
            return cameraVC
        }
        
        for child in viewController.children {
            if let found = findCameraViewController(in: child) {
                return found
            }
        }
        
        if let presented = viewController.presentedViewController {
            return findCameraViewController(in: presented)
        }
        
        return nil
    }
    
    private func loadAndProcessPhoto(from item: PhotosPickerItem) async {
        // Show paywall if user has 0 scans (same as Profile > Upgrade to Pro)
        if !subscriptionManager.isProUser && scanLimitManager.scansRemaining == 0 {
            viewModel.showPaywall = true
            selectedPhotoItem = nil
            return
        }
        
        guard let imageData = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Freeze the selected image
        frozenImage = image
        isAnalyzing = true
        
        await viewModel.captureAndProcess(
            image: image,
            isProUser: subscriptionManager.isProUser,
            scanLimitManager: scanLimitManager,
            historyManager: historyManager
        )
        
        isAnalyzing = false
        showResult = true
        selectedPhotoItem = nil // Reset selection
    }
}

// MARK: - Analysing Row

struct AnalysingRow: View {
    let icon: String
    let title: String
    let description: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body))
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(description)
                    .font(.system(.subheadline))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
            }
        }
    }
}

// MARK: - Animated Frame View

struct AnimatedFrameView: View {
    let frameStyle: FrameStyle
    let sideLength: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: frameStyle == .modernMinimalist || frameStyle == .contemporaryGallery ? 2 : 8, style: frameStyle.cornerStyle)
            .stroke(frameStyle.strokeColor, lineWidth: frameStyle.strokeWidth)
            .animation(.easeInOut(duration: 0.5), value: frameStyle)
    }
}

#Preview {
    ScanView()
        .environmentObject(SubscriptionManager())
        .environmentObject(ScanLimitManager())
        .environmentObject(HistoryManager())
}


