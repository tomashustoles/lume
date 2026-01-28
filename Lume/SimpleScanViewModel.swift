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
    
    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private let geminiService = GeminiService.shared
    
    // Store for async processing
    private var pendingHistoryManager: HistoryManager?
    private var pendingIsProUser = false
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Camera not available")
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
    }
    
    func startSession() {
        let session = captureSession
        Task.detached {
            session.startRunning()
        }
    }
    
    func stopSession() {
        let session = captureSession
        Task.detached {
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
        
        // Capture photo
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
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
