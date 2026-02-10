//
//  SimpleScanViewModel.swift
//  Lume
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
        cleanupSession()
    }
    
    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Clean up capture session on deallocation
        cleanupSession()
    }
    
    private func cleanupSession() {
        guard let session = captureSession else { return }
        
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
        
        captureSession = nil
        photoOutput = nil
        isCameraSetup = false
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
            // Crop to square
            let croppedImage = cropToSquare(image)
            
            // Send to Gemini
            let result = try await geminiService.recognizeArtwork(image: croppedImage)
            
            // Try to fetch the real artwork image
            var finalImageData: Data?
            if let realImage = try await geminiService.fetchArtworkImage(title: result.title, artist: result.artist) {
                // Use the real artwork image
                finalImageData = realImage.jpegData(compressionQuality: 0.8)
            } else {
                // Fall back to the captured image if we can't find the real one
                finalImageData = croppedImage.jpegData(compressionQuality: 0.8)
            }
            
            // Save to history
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
                imageData: finalImageData
            )
            
            await historyManager.addArtwork(artwork)
            
            isProcessing = false
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
            showError = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
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
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
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
