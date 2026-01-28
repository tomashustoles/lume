//
//  SimpleCameraView.swift
//  Lume
//
//  Camera interface with square scan area
//

import SwiftUI
import AVFoundation

struct SimpleCameraView: View {
    @StateObject private var viewModel = SimpleScanViewModel()
    @EnvironmentObject var scanLimitManager: ScanLimitManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()
            
            // Square scan area overlay
            GeometryReader { geometry in
                let sideLength = min(geometry.size.width, geometry.size.height) * 0.7
                
                ZStack {
                    // Dim overlay
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    // Clear center
                    Rectangle()
                        .frame(width: sideLength, height: sideLength)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                
                // Square border
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: sideLength, height: sideLength)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            
            // Scan button at bottom
            VStack {
                Spacer()
                
                Button {
                    Task {
                        await viewModel.capturePhoto(
                            isProUser: subscriptionManager.isProUser,
                            scanLimitManager: scanLimitManager,
                            historyManager: historyManager
                        )
                    }
                } label: {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                        }
                        
                        Text(viewModel.isProcessing ? "Analyzing..." : "Scan Artwork")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.black)
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
                }
                .disabled(viewModel.isProcessing)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .alert("Scan Limit Reached", isPresented: $viewModel.showLimitReached) {
            Button("OK") {}
        } message: {
            Text("You've used all 3 daily scans. The limit resets at midnight.")
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        // Don't set frame here, will be set in updateUIView
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

#Preview {
    SimpleCameraView()
        .environmentObject(ScanLimitManager())
        .environmentObject(HistoryManager())
        .environmentObject(SubscriptionManager())
}
