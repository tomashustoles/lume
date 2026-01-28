//
//  UIImage+FixOrientation.swift
//  Museum Companion
//
//  Extension to fix image orientation issues from camera capture
//

import UIKit

extension UIImage {
    /// Returns a copy of the image with the orientation fixed to .up
    /// This is useful for images captured from the camera which may have incorrect orientation metadata
    func fixedOrientation() -> UIImage {
        // If the image is already in the correct orientation, return it as-is
        if imageOrientation == .up {
            return self
        }
        
        // Create a graphics context with the correct size
        guard let cgImage = self.cgImage else { return self }
        
        // Calculate the transform needed to orient the image correctly
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
            
        case .up, .upMirrored:
            break
            
        @unknown default:
            break
        }
        
        // Handle mirrored orientations
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .up, .down, .left, .right:
            break
            
        @unknown default:
            break
        }
        
        // Create a context and draw the image with the correct transform
        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: cgImage.bitmapInfo.rawValue
              ) else {
            return self
        }
        
        context.concatenate(transform)
        
        // Draw the image into the context
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        // Create a new image from the context
        guard let newCGImage = context.makeImage() else {
            return self
        }
        
        return UIImage(cgImage: newCGImage)
    }
}
