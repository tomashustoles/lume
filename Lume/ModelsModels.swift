//
//  Models.swift
//  Mona - Art Companion
//
//  Core data models for the app
//

import Foundation
import SwiftUI

// MARK: - Artwork Model

struct Artwork: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let year: String
    let movement: String
    let description: String
    let storyMode: String
    let culturalContext: String
    let estimatedPeriod: String
    let frameStyle: FrameStyle
    let imageData: Data?           // User's captured photo (thumbnail/hero)
    let capturedImageData: Data?   // Photo taken by the user (same as imageData, kept for compatibility)
    let artworkImageData: Data?    // Fetched original artwork image (shown in content when available)
    let timestamp: Date
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        year: String,
        movement: String,
        description: String,
        storyMode: String,
        culturalContext: String,
        estimatedPeriod: String,
        frameStyle: FrameStyle,
        imageData: Data? = nil,
        capturedImageData: Data? = nil,
        artworkImageData: Data? = nil,
        timestamp: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.year = year
        self.movement = movement
        self.description = description
        self.storyMode = storyMode
        self.culturalContext = culturalContext
        self.estimatedPeriod = estimatedPeriod
        self.frameStyle = frameStyle
        self.imageData = imageData
        self.capturedImageData = capturedImageData
        self.artworkImageData = artworkImageData
        self.timestamp = timestamp
        self.isFavorite = isFavorite
    }
}

// MARK: - Frame Style

enum FrameStyle: String, Codable, CaseIterable {
    case classicalGilded = "Classical Gilded"
    case baroqueOrnate = "Baroque Ornate"
    case modernMinimalist = "Modern Minimalist"
    case bauhausGeometric = "Bauhaus Geometric"
    case contemporaryGallery = "Contemporary Gallery"
    
    var animationDuration: Double {
        2.5
    }
    
    var strokeColor: Color {
        switch self {
        case .classicalGilded:
            return Color(white: 0.7)
        case .baroqueOrnate:
            return Color(white: 0.6)
        case .modernMinimalist:
            return Color(white: 0.2)
        case .bauhausGeometric:
            return Color(white: 0.3)
        case .contemporaryGallery:
            return Color(white: 0.15)
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .classicalGilded:
            return 8
        case .baroqueOrnate:
            return 12
        case .modernMinimalist:
            return 2
        case .bauhausGeometric:
            return 4
        case .contemporaryGallery:
            return 1
        }
    }
    
    var cornerStyle: RoundedCornerStyle {
        switch self {
        case .classicalGilded, .baroqueOrnate:
            return .continuous
        case .modernMinimalist, .bauhausGeometric, .contemporaryGallery:
            return .circular
        }
    }
}

// Note: GeminiResponse and ArtworkRecognitionResult have been moved to ServicesGeminiService.swift
// to avoid MainActor isolation issues from SwiftUI imports

// MARK: - Subscription Product

enum SubscriptionProduct: String, CaseIterable {
    case monthly = "txh.lume.pro.monthly"
    case yearly = "txh.lume.pro.yearly"
    
    var displayName: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
    
    var displayPrice: String {
        switch self {
        case .monthly:
            return "€2.99/month"
        case .yearly:
            return "€19.99/year"
        }
    }
    
    var savingsText: String? {
        switch self {
        case .yearly:
            return "Save 44%"
        default:
            return nil
        }
    }
}

// MARK: - Display Mode

enum DisplayMode {
    case info
    case story
}
