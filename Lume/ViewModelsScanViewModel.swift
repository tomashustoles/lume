//
//  ScanViewModel.swift
//  Museum Companion
//
//  ViewModel for camera scanning functionality
//

import Foundation
import SwiftUI
import UIKit
import AVFoundation
import Combine

@MainActor
class ScanViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var recognizedArtwork: Artwork?
    @Published var isProcessing = false
    @Published var currentFrame: FrameStyle = .classicalGilded
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showLimitReached = false
    @Published var cameraPermissionGranted = false
    
    private let geminiService = GeminiService.shared
    private var frameAnimationTimer: Timer?
    private let hapticGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Check Camera Permission
    
    func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            cameraPermissionGranted = await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            cameraPermissionGranted = false
        @unknown default:
            cameraPermissionGranted = false
        }
    }
    
    // MARK: - Capture and Process
    
    func captureAndProcess(
        image: UIImage,
        isProUser: Bool,
        scanLimitManager: ScanLimitManager,
        historyManager: HistoryManager
    ) async {
        // Check limits
        if !isProUser {
            let canScan = await scanLimitManager.useScan()
            if !canScan {
                showLimitReached = true
                return
            }
        }
        
        capturedImage = image
        isProcessing = true
        errorMessage = nil
        
        // Start frame animation
        startFrameAnimation()
        
        // Haptic feedback
        hapticGenerator.notificationOccurred(.success)
        
        do {
            let result = try await geminiService.recognizeArtwork(image: image)
            
            // Determine frame style based on period
            let frameStyle = determineFrameStyle(from: result.estimatedPeriod)
            currentFrame = frameStyle
            
            // Stop animation on final frame
            stopFrameAnimation()
            
            // Always store the captured image separately
            let capturedImageData = image.jpegData(compressionQuality: 0.8)
            
            // Try to fetch the real artwork image
            var finalImageData: Data?
            if let realImage = try await geminiService.fetchArtworkImage(title: result.title, artist: result.artist) {
                finalImageData = realImage.jpegData(compressionQuality: 0.8)
            }
            
            // Create artwork
            let artwork = Artwork(
                title: result.title,
                artist: result.artist,
                year: result.year,
                movement: result.movement,
                description: result.description,
                storyMode: result.storyMode,
                culturalContext: result.culturalContext,
                estimatedPeriod: result.estimatedPeriod,
                frameStyle: frameStyle,
                imageData: finalImageData,
                capturedImageData: capturedImageData
            )
            
            recognizedArtwork = artwork
            
            // Save to history
            await historyManager.addArtwork(artwork)
            
            isProcessing = false
            hapticGenerator.notificationOccurred(.success)
            
        } catch {
            stopFrameAnimation()
            isProcessing = false
            errorMessage = error.localizedDescription
            showError = true
            hapticGenerator.notificationOccurred(.error)
        }
    }
    
    // MARK: - Frame Animation
    
    private func startFrameAnimation() {
        let allFrames = FrameStyle.allCases
        
        // Use a class to hold mutable state
        class FrameCounter {
            var index = 0
        }
        let counter = FrameCounter()
        
        frameAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                counter.index = (counter.index + 1) % allFrames.count
                self.currentFrame = allFrames[counter.index]
            }
        }
    }
    
    private func stopFrameAnimation() {
        frameAnimationTimer?.invalidate()
        frameAnimationTimer = nil
    }
    
    // MARK: - Determine Frame Style
    
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
    
    // MARK: - Reset
    
    func reset() {
        capturedImage = nil
        recognizedArtwork = nil
        isProcessing = false
        errorMessage = nil
        showError = false
        currentFrame = .classicalGilded
        stopFrameAnimation()
    }
}
