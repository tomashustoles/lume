//
//  CameraView.swift
//  Museum Companion
//
//  SwiftUI wrapper for camera with UIKit integration
//

import SwiftUI
import AVFoundation
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    let onCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func didCaptureImage(_ image: UIImage) {
            parent.capturedImage = image
            parent.onCapture(image)
        }
    }
}

// MARK: - Camera View Controller Delegate

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
}

// MARK: - Camera View Controller

class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let captureSession = captureSession,
              let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    func capturePhoto() {
        print("📸 CameraViewController.capturePhoto() called")
        
        guard let photoOutput = photoOutput else {
            print("❌ photoOutput is nil")
            return
        }
        
        print("📸 Triggering photo capture...")
        
        // Check if we're running on Mac using multiple detection methods
        let isMac: Bool = {
            #if targetEnvironment(macCatalyst)
            return true
            #else
            // Check for Mac using ProcessInfo
            if #available(iOS 14.0, *) {
                return ProcessInfo.processInfo.isiOSAppOnMac
            }
            // Fallback: check system name
            return UIDevice.current.systemName == "iOS" && 
                   ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] == nil &&
                   UIDevice.current.userInterfaceIdiom == .pad // Running as iPad on Mac
            #endif
        }()
        
        print("📸 Is Mac: \(isMac)")
        
        if isMac {
            print("📸 Detected Mac - using video frame capture")
            capturePhotoForMac()
            return
        }
        
        #if targetEnvironment(simulator)
        // Simulator - use test image
        print("⚠️ Running on simulator - using test image")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let testImage = self?.createTestImage() {
                print("📸 Using test image for simulator")
                self?.delegate?.didCaptureImage(testImage)
            }
        }
        #else
        // iOS/iPad - standard photo capture
        print("📸 Using standard photo capture for iOS/iPad")
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
        #endif
    }
    
    private func capturePhotoForMac() {
        print("📸 Using Mac-specific capture method")
        
        guard let captureSession = captureSession else {
            print("❌ Cannot get capture session")
            return
        }
        
        // Try to capture a frame from the video output instead
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            
            let queue = DispatchQueue(label: "videoQueue")
            
            // Reduced delay from 0.5 to 0.2 seconds - camera should be ready quickly since it's already streaming
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                print("📸 Camera ready, capturing frame...")
                
                let delegate = VideoFrameCaptureDelegate { [weak self] image in
                    print("✅ Captured frame from video on Mac")
                    self?.delegate?.didCaptureImage(image)
                    
                    // Remove video output after capture
                    if captureSession.outputs.contains(videoOutput) {
                        captureSession.removeOutput(videoOutput)
                    }
                }
                videoOutput.setSampleBufferDelegate(delegate, queue: queue)
                
                // Store delegate to prevent deallocation
                objc_setAssociatedObject(self as Any, "frameDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
        } else {
            print("❌ Cannot add video output - falling back to standard photo")
            // Fallback to standard photo capture
            let settings = AVCapturePhotoSettings()
            photoOutput?.capturePhoto(with: settings, delegate: self)
        }
    }
    
    // Helper class to capture a single frame
    private class VideoFrameCaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private let completion: (UIImage) -> Void
        private var captured = false
        
        init(completion: @escaping (UIImage) -> Void) {
            self.completion = completion
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard !captured else { return }
            captured = true
            
            print("📸 Video frame received")
            
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("❌ Cannot get image buffer from sample")
                return
            }
            
            print("📸 Creating CIImage from pixel buffer")
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            print("📸 CIImage extent: \(ciImage.extent)")
            
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                print("❌ Cannot create CGImage from CIImage")
                return
            }
            
            print("📸 CGImage created - size: \(cgImage.width)x\(cgImage.height)")
            
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right).fixedOrientation()
            print("📸 UIImage created - size: \(image.size)")
            
            // Check if image is completely black
            let pixelData = cgImage.dataProvider?.data
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            let bytesPerRow = cgImage.bytesPerRow
            let bytesPerPixel = cgImage.bitsPerPixel / 8
            
            var isBlack = true
            for y in stride(from: 0, to: cgImage.height, by: cgImage.height / 10) {
                for x in stride(from: 0, to: cgImage.width, by: cgImage.width / 10) {
                    let pixelIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                    if pixelIndex < CFDataGetLength(pixelData) - 3 {
                        let r = data[pixelIndex]
                        let g = data[pixelIndex + 1]
                        let b = data[pixelIndex + 2]
                        if r > 10 || g > 10 || b > 10 {
                            isBlack = false
                            break
                        }
                    }
                }
                if !isBlack { break }
            }
            
            if isBlack {
                print("⚠️ WARNING: Captured image appears to be completely black!")
            } else {
                print("✅ Image has visual content")
            }
            
            DispatchQueue.main.async {
                print("📸 Calling completion handler with image")
                self.completion(image)
            }
        }
    }
    
    private func createTestImage() -> UIImage? {
        let size = CGSize(width: 1000, height: 1000)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemBlue.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        let text = "Test Capture\n(Simulator/Mac)" as NSString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 50, weight: .bold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Photo Capture Delegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Fix orientation before cropping so the image is always upright
        let orientedImage = image.fixedOrientation()
        
        // Crop to square (center crop)
        let croppedImage = cropToSquare(orientedImage)
        
        DispatchQueue.main.async {
            self.delegate?.didCaptureImage(croppedImage)
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
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
}
