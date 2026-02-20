//
//  SimpleScanViewModel.swift
//  Mona - Art Companion
//
//  Handles camera capture and AI recognition
//

import Foundation
import SwiftUI
@preconcurrency import AVFoundation
import UIKit
import Combine

@MainActor
class SimpleScanViewModel: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showLimitReached = false
    @Published var showPaywall = false
    @Published var isScanningEnabled = true
    @Published var recognizedArtwork: Artwork?
    @Published var showResult = false
    
    private(set) var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private let geminiService = GeminiService.shared
    
    // Store for async processing
    private var pendingHistoryManager: HistoryManager?
    private var pendingIsProUser = false
    
    private var isCameraSetup = false
    
    override init() {
        super.init()
        // Don't setup camera in init - wait for explicit call
        
        // Listen for app lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        print("🔴 App entered background - stopping camera")
        stopSession()
    }
    
    @objc private func appWillTerminate() {
        print("🔴 App will terminate - cleaning up camera")
        Task { @MainActor in
            cleanupSession()
        }
    }
    
    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Clean up capture session on deallocation
        cleanupSession()
    }
    
    nonisolated private func cleanupSession() {
        // Access MainActor-isolated properties safely
        MainActor.assumeIsolated {
            guard let session = self.captureSession else { return }
            
            // Stop session on background queue to avoid blocking
            let cleanupQueue = DispatchQueue(label: "camera.cleanup", qos: .userInitiated)
            cleanupQueue.sync {
                if session.isRunning {
                    session.stopRunning()
                }
                
                // Properly remove all inputs and outputs
                session.beginConfiguration()
                for input in session.inputs {
                    session.removeInput(input)
                }
                for output in session.outputs {
                    session.removeOutput(output)
                }
                session.commitConfiguration()
            }
            
            self.captureSession = nil
            self.photoOutput = nil
            self.isCameraSetup = false
        }
    }
    
    func setupCameraIfNeeded() {
        guard !isCameraSetup else { return }
        isCameraSetup = true
        setupCamera()
    }
    
    private func setupCamera() {
        // Clean up any existing session first
        cleanupSession()
        
        // Create fresh session
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        // Try to get camera device - with error handling
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ Camera device not available")
            isCameraSetup = false
            return
        }
        
        // Check if camera is available (not locked by another process)
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            let output = AVCapturePhotoOutput()
            
            session.beginConfiguration()
            
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                print("❌ Cannot add camera input")
                session.commitConfiguration()
                isCameraSetup = false
                return
            }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            } else {
                print("❌ Cannot add photo output")
                session.commitConfiguration()
                isCameraSetup = false
                return
            }
            
            session.commitConfiguration()
            
            self.captureSession = session
            self.photoOutput = output
            print("✅ Camera setup complete")
        } catch {
            print("❌ Failed to create camera input: \(error.localizedDescription)")
            isCameraSetup = false
            // Reset after a short delay to allow camera to become available
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                if !isCameraSetup {
                    setupCameraIfNeeded()
                }
            }
        }
    }
    
    func startSession() {
        guard let session = captureSession else {
            // If session doesn't exist, try to set it up again
            if !isCameraSetup {
                setupCameraIfNeeded()
            }
            return
        }
        Task.detached { [weak session] in
            guard let session = session, !session.isRunning else { return }
            session.startRunning()
        }
    }
    
    func stopSession() {
        guard let session = captureSession else { return }
        Task.detached { [weak session] in
            guard let session = session, session.isRunning else { return }
            session.stopRunning()
        }
    }
    
    func capturePhoto(
        isProUser: Bool,
        scanLimitManager: ScanLimitManager,
        historyManager: HistoryManager
    ) async {
        print("🔵 capturePhoto called - isProUser: \(isProUser)")
        
        // Don't allow capture if already processing
        guard !isProcessing else {
            print("⚠️ Already processing, ignoring capture request")
            return
        }
        
        // Reset previous result state to allow new scan
        showResult = false
        recognizedArtwork = nil
        
        // Store for later use
        pendingIsProUser = isProUser
        
        // Check if user can scan
        let canScan = await scanLimitManager.canScan(isProUser: isProUser)
        print("🔵 canScan result: \(canScan)")
        
        if !canScan {
            print("❌ Cannot scan - showing paywall")
            // Show paywall for 4th scan attempt
            showPaywall = true
            isScanningEnabled = false
            return
        }
        
        // Check limits for free users
        if !isProUser {
            print("🔵 Free user - checking scan limit")
            let didUseScan = await scanLimitManager.useScan()
            print("🔵 didUseScan result: \(didUseScan)")
            
            if !didUseScan {
                print("❌ Scan limit reached - showing paywall")
                // Limit reached - show paywall
                showPaywall = true
                isScanningEnabled = false
                return
            }
            
            // After 3rd successful scan (scansRemaining == 0)
            if scanLimitManager.scansRemaining == 0 {
                print("⚠️ Last scan used - showing limit notification")
                // Show soft notification
                showLimitReached = true
                isScanningEnabled = false
            }
        }
        
        print("📸 Starting photo capture...")
        isProcessing = true
        pendingHistoryManager = historyManager
        
        // Ensure we have a photo output
        guard let output = photoOutput else {
            print("❌ Photo output is nil")
            isProcessing = false
            return
        }
        
        // Capture photo
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
        print("📸 Photo capture triggered")
    }
    
    func dismissPaywall(didPurchase: Bool) {
        showPaywall = false
        
        if didPurchase {
            // Re-enable scanning after purchase
            isScanningEnabled = true
            showLimitReached = false
        }
        // If user dismissed without purchasing, scanning remains disabled
    }
    
    func acknowledgeLimit() {
        showLimitReached = false
        // Keep scanning disabled until upgrade or daily reset
    }
    
    private func processImage(_ image: UIImage, historyManager: HistoryManager) async {
        do {
            // Fix orientation first, then crop to square
            let fixedImage = image.fixedOrientation()
            let croppedImage = cropToSquare(fixedImage)
            
            // Send to Gemini
            let result = try await geminiService.recognizeArtwork(image: croppedImage)
            
            // Always save the captured image for thumbnail and hero
            let capturedImageData = croppedImage.jpegData(compressionQuality: 0.8)
            
            // Optionally fetch the original artwork image for display in content (not for thumbnail/hero)
            var artworkImageData: Data? = nil
            print("🖼️ Fetching original artwork image for: '\(result.title)' by '\(result.artist)'")
            do {
                if let fetchedImage = try await geminiService.fetchArtworkImage(
                    title: result.title,
                    artist: result.artist
                ) {
                    print("✅ Found original artwork image - will show in content for: \(result.title)")
                    let fixedFetchedImage = fetchedImage.fixedOrientation()
                    artworkImageData = fixedFetchedImage.jpegData(compressionQuality: 0.8)
                } else {
                    print("⚠️ Could not find artwork image online for: \(result.title)")
                }
            } catch {
                print("❌ Error fetching artwork image: \(error.localizedDescription) for: \(result.title)")
            }
            
            // Save to history - always use captured photo for thumbnail and hero
            let artwork = Artwork(
                title: result.title,
                artist: result.artist,
                year: result.year,
                movement: result.movement,
                description: result.description,
                storyMode: result.storyMode,
                culturalContext: result.culturalContext,
                estimatedPeriod: result.estimatedPeriod,
                frameStyle: determineFrameStyle(from: result.estimatedPeriod),
                imageData: capturedImageData,
                capturedImageData: capturedImageData,
                artworkImageData: artworkImageData
            )
            
            // Set recognized artwork BEFORE saving to history
            // This ensures the sheet can be shown even if saving fails
            recognizedArtwork = artwork
            isProcessing = false
            
            // Save to history (non-blocking for sheet presentation)
            Task {
                await historyManager.addArtwork(artwork)
            }
            
            // Ensure we're on MainActor for UI updates
            await MainActor.run {
                // Reset showResult first to ensure sheet can be shown again
                showResult = false
            }
            
            // Small delay to ensure UI is ready before showing sheet
            try? await Task.sleep(for: .milliseconds(150))
            
            // Show the sheet on MainActor
            await MainActor.run {
                showResult = true
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            // Ensure we're on MainActor for UI updates
            await MainActor.run {
                isProcessing = false
                recognizedArtwork = nil
                showResult = false
                
                // Log detailed error information
                print("❌ Error in processImage: \(error)")
                if let geminiError = error as? GeminiError {
                    print("❌ GeminiError type: \(geminiError)")
                }
                print("❌ Error description: \(error.localizedDescription)")
                
                errorMessage = error.localizedDescription
                showError = true
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
    
    private func cropToSquare(_ image: UIImage) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let sideLength = min(originalWidth, originalHeight)
        
        let xOffset = (originalWidth - sideLength) / 2
        let yOffset = (originalHeight - sideLength) / 2
        
        let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        // Return with .up orientation since we've already fixed orientation before cropping
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
    
    private func determineFrameStyle(from period: String) -> FrameStyle {
        let lowercased = period.lowercased()
        
        if lowercased.contains("classical") || lowercased.contains("renaissance") {
            return .classicalGilded
        } else if lowercased.contains("baroque") || lowercased.contains("rococo") {
            return .baroqueOrnate
        } else if lowercased.contains("modern") || lowercased.contains("impressionist") {
            return .modernMinimalist
        } else if lowercased.contains("bauhaus") || lowercased.contains("constructivist") {
            return .bauhausGeometric
        } else {
            return .contemporaryGallery
        }
    }
}

// MARK: - Photo Capture Delegate

extension SimpleScanViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📸 Photo output callback received")
        
        if let error = error {
            print("❌ Photo capture error: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("❌ Failed to get image data")
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            print("❌ Failed to create UIImage from data")
            return
        }
        
        print("✅ Photo captured successfully, size: \(image.size)")
        
        Task { @MainActor [weak self] in
            guard let self = self, let historyManager = self.pendingHistoryManager else {
                print("❌ Self or historyManager is nil")
                return
            }
            print("🔄 Processing image...")
            await self.processImage(image, historyManager: historyManager)
            self.pendingHistoryManager = nil
        }
    }
}
