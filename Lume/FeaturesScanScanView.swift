//
//  ScanView.swift
//  Museum Companion
//
//  Main scanning interface with camera and frame animation
//

import SwiftUI

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager
    @EnvironmentObject var historyManager: HistoryManager
    
    @State private var showPaywall = false
    @State private var showResult = false
    @State private var cameraViewController: CameraViewController?
    @State private var isAnalyzing = false
    @State private var frozenImage: UIImage?
    
    let onNavigateToCollection: (() -> Void)?
    
    init(onNavigateToCollection: (() -> Void)? = nil) {
        self.onNavigateToCollection = onNavigateToCollection
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
        .sheet(isPresented: $showResult) {
            if let artwork = viewModel.recognizedArtwork {
                ArtworkDetailView(
                    artwork: artwork,
                    onDismiss: {
                        showResult = false
                        frozenImage = nil
                        viewModel.reset()
                    },
                    onNavigateToCollection: onNavigateToCollection
                )
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Scan Limit Reached", isPresented: $viewModel.showLimitReached) {
            Button("Upgrade to Pro") {
                showPaywall = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You've used all 3 daily scans. Upgrade to Pro for unlimited scanning.")
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
        VStack {
            Spacer()
            
            Button {
                print("🔵 Capture button tapped")
                if let controller = findCameraViewController() {
                    print("✅ Found CameraViewController")
                    controller.capturePhoto()
                } else {
                    print("❌ CameraViewController not found")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                }
            }
            .disabled(viewModel.isProcessing || isAnalyzing)
            .opacity((viewModel.isProcessing || isAnalyzing) ? 0.5 : 1.0)
            .padding(.bottom, 40)
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
                        .foregroundColor(.white)
                    
                    Text("scans left")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                )
                .padding(.trailing, 20)
            }
            .padding(.top, 60)
            
            Spacer()
        }
    }
    
    // MARK: - Analyzing Overlay
    
    private var analyzingOverlay: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Analyzing artwork...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Identifying the artist and details")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: isAnalyzing)
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


