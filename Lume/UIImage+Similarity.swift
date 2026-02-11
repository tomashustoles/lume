//
//  UIImage+Similarity.swift
//  Lume
//
//  Extension to compare images for visual similarity
//

import UIKit

extension UIImage {
    /// Compares two images for visual similarity
    /// - Parameters:
    ///   - other: The image to compare against
    ///   - threshold: Similarity threshold (0.0 to 1.0). Default is 0.85 (85% similar)
    /// - Returns: True if images are similar above the threshold, false otherwise
    func isSimilar(to other: UIImage?, threshold: Double = 0.85) -> Bool {
        guard let other = other else { return false }
        
        // Resize both images to a common size for efficient comparison
        let comparisonSize = CGSize(width: 100, height: 100)
        guard let resizedSelf = self.resized(to: comparisonSize),
              let resizedOther = other.resized(to: comparisonSize) else {
            return false
        }
        
        // Convert to grayscale for comparison
        guard let selfGrayscale = resizedSelf.grayscale(),
              let otherGrayscale = resizedOther.grayscale() else {
            return false
        }
        
        // Calculate similarity score
        let similarity = calculateSimilarity(between: selfGrayscale, and: otherGrayscale)
        
        return similarity >= threshold
    }
    
    /// Resizes the image to the specified size
    private func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Converts the image to grayscale
    private func grayscale() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = cgImage.width
        let height = cgImage.height
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let grayscaleCGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: grayscaleCGImage)
    }
    
    /// Calculates similarity score between two grayscale images
    private func calculateSimilarity(between image1: UIImage, and image2: UIImage) -> Double {
        guard let cgImage1 = image1.cgImage,
              let cgImage2 = image2.cgImage,
              cgImage1.width == cgImage2.width,
              cgImage1.height == cgImage2.height else {
            return 0.0
        }
        
        let width = cgImage1.width
        let height = cgImage1.height
        
        // Get pixel data
        guard let data1 = cgImage1.dataProvider?.data,
              let data2 = cgImage2.dataProvider?.data,
              let bytes1 = CFDataGetBytePtr(data1),
              let bytes2 = CFDataGetBytePtr(data2) else {
            return 0.0
        }
        
        let bytesPerRow1 = cgImage1.bytesPerRow
        let bytesPerRow2 = cgImage2.bytesPerRow
        
        var totalDifference: Int64 = 0
        var pixelCount = 0
        
        // Sample pixels (every 2nd pixel for performance)
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let index1 = y * bytesPerRow1 + x
                let index2 = y * bytesPerRow2 + x
                
                guard index1 < CFDataGetLength(data1),
                      index2 < CFDataGetLength(data2) else {
                    continue
                }
                
                let pixel1 = Int(bytes1[index1])
                let pixel2 = Int(bytes2[index2])
                
                totalDifference += Int64(abs(pixel1 - pixel2))
                pixelCount += 1
            }
        }
        
        guard pixelCount > 0 else { return 0.0 }
        
        // Calculate average difference
        let averageDifference = Double(totalDifference) / Double(pixelCount)
        
        // Convert to similarity (0-255 range, inverted)
        // Lower difference = higher similarity
        let similarity = 1.0 - (averageDifference / 255.0)
        
        return max(0.0, min(1.0, similarity))
    }
}
