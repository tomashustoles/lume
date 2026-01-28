//
//  GeminiService.swift
//  Museum Companion
//
//  Service for communicating with Gemini API
//

import Foundation
import UIKit

final class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    private init() {
        // API key is now loaded from Config (which reads from xcconfig or environment)
        self.apiKey = Config.geminiAPIKey
    }
    
    // MARK: - List Available Models (for debugging)
    
    func listAvailableModels() async throws -> [String] {
        let listURL = "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
        
        guard let url = URL(string: listURL) else {
            throw GeminiError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error listing models: \(errorString)")
            }
            throw GeminiError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse the response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let models = json["models"] as? [[String: Any]] {
            let modelNames = models.compactMap { $0["name"] as? String }
            print("✅ Available models:")
            modelNames.forEach { print("  - \($0)") }
            return modelNames
        }
        
        return []
    }
    
    // MARK: - Recognize Artwork
    
    func recognizeArtwork(image: UIImage) async throws -> ArtworkRecognitionResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        You are an expert art historian and museum curator. Analyze this painting and provide detailed information in JSON format.
        
        Return ONLY valid JSON with this exact structure (no markdown, no code blocks):
        {
            "title": "The exact title of the artwork",
            "artist": "The artist's full name",
            "year": "Year or period created",
            "movement": "Art movement or style",
            "description": "A factual 2-3 sentence description of the artwork, its composition, and technique",
            "storyMode": "A poetic, emotional narrative about this artwork in 3-4 sentences. Make the viewer feel connected to the art. Describe what emotions it evokes, what story it tells, and why it matters.",
            "culturalContext": "2-3 sentences about the historical and cultural significance",
            "estimatedPeriod": "Classical, Baroque, Modern, Bauhaus, or Contemporary",
            "wikiArtId": "The WikiArt or commons identifier if known, otherwise empty string"
        }
        
        If you cannot identify the specific artwork, provide your best educated analysis based on visible style, technique, and period characteristics. Be confident in your assessment.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 2048
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw GeminiError.invalidRequest
        }
        
        var request = URLRequest(url: URL(string: "\(baseURL)?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        // Log response for debugging
        if httpResponse.statusCode != 200 {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            print("URL: \(request.url?.absoluteString ?? "unknown")")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GeminiError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let responseText = geminiResponse.text else {
            throw GeminiError.noResponse
        }
        
        // Clean the response text - remove markdown code blocks if present
        let cleanedText = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let resultData = cleanedText.data(using: .utf8) else {
            throw GeminiError.decodingFailed
        }
        
        do {
            let result = try JSONDecoder().decode(ArtworkRecognitionResult.self, from: resultData)
            return result
        } catch {
            print("Decoding error: \(error)")
            print("Response text: \(cleanedText)")
            throw GeminiError.decodingFailed
        }
    }
    
    // MARK: - Fetch Artwork Image
    
    func fetchArtworkImage(title: String, artist: String) async throws -> UIImage? {
        // Strategy 1: Try Wikipedia page image (most reliable for famous artworks)
        if let image = await fetchWikipediaImage(query: "\(title) \(artist)") {
            return image
        }
        
        // Strategy 2: Try Wikimedia Commons direct file search
        if let image = await fetchWikimediaCommonsImage(title: title, artist: artist) {
            return image
        }
        
        print("⚠️ Could not find artwork image for: \(title) by \(artist)")
        return nil
    }
    
    private func fetchWikipediaImage(query: String) async -> UIImage? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=pageimages&piprop=original&titles=\(encoded)&redirects=1"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print("📷 Wikipedia response for '\(query)': \(String(data: data, encoding: .utf8)?.prefix(500) ?? "nil")")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let queryObj = json["query"] as? [String: Any],
               let pages = queryObj["pages"] as? [String: Any] {
                
                for (_, pageValue) in pages {
                    if let page = pageValue as? [String: Any],
                       let original = page["original"] as? [String: Any],
                       let sourceStr = original["source"] as? String,
                       let imageURL = URL(string: sourceStr) {
                        print("✅ Found Wikipedia image: \(sourceStr)")
                        let (imageData, _) = try await URLSession.shared.data(from: imageURL)
                        return UIImage(data: imageData)
                    }
                }
            }
        } catch {
            print("❌ Wikipedia fetch error: \(error)")
        }
        return nil
    }
    
    private func fetchWikimediaCommonsImage(title: String, artist: String) async -> UIImage? {
        // Search Wikimedia Commons for the artwork file directly
        let query = "\(title) \(artist)"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://commons.wikimedia.org/w/api.php?action=query&format=json&list=search&srsearch=\(encoded)&srnamespace=6&srlimit=1&prop=imageinfo&iiprop=url"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let queryObj = json["query"] as? [String: Any],
               let searchResults = queryObj["search"] as? [[String: Any]],
               let firstResult = searchResults.first,
               let pageTitle = firstResult["title"] as? String {
                
                // Get the actual image URL using the file title
                let fileEncoded = pageTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let infoURLString = "https://commons.wikimedia.org/w/api.php?action=query&format=json&titles=\(fileEncoded)&prop=imageinfo&iiprop=url&iiurlwidth=1024"
                
                if let infoURL = URL(string: infoURLString) {
                    let (infoData, _) = try await URLSession.shared.data(from: infoURL)
                    
                    if let infoJson = try? JSONSerialization.jsonObject(with: infoData) as? [String: Any],
                       let queryObj2 = infoJson["query"] as? [String: Any],
                       let pages = queryObj2["pages"] as? [String: Any] {
                        
                        for (_, pageValue) in pages {
                            if let page = pageValue as? [String: Any],
                               let imageInfoArray = page["imageinfo"] as? [[String: Any]],
                               let imageInfo = imageInfoArray.first,
                               let thumbURL = imageInfo["thumburl"] as? String ?? imageInfo["url"] as? String,
                               let imageURL = URL(string: thumbURL) {
                                print("✅ Found Wikimedia Commons image: \(thumbURL)")
                                let (imageData, _) = try await URLSession.shared.data(from: imageURL)
                                return UIImage(data: imageData)
                            }
                        }
                    }
                }
            }
        } catch {
            print("❌ Wikimedia Commons fetch error: \(error)")
        }
        return nil
    }
}

// MARK: - Gemini Errors

enum GeminiError: LocalizedError {
    case imageProcessingFailed
    case invalidRequest
    case invalidResponse
    case httpError(statusCode: Int)
    case noResponse
    case decodingFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the image. Please try again."
        case .invalidRequest:
            return "Invalid request. Please try again."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .httpError(let statusCode):
            return "Server error (\(statusCode)). Please try again later."
        case .noResponse:
            return "No response received. Please check your connection."
        case .decodingFailed:
            return "Failed to understand the response. Please try again."
        case .networkError:
            return "Network connection failed. Please check your internet connection."
        }
    }
}
// MARK: - API Response Models

struct GeminiResponse: Codable, Sendable {
    let candidates: [Candidate]
    
    struct Candidate: Codable, Sendable {
        let content: Content
        
        struct Content: Codable, Sendable {
            let parts: [Part]
            
            struct Part: Codable, Sendable {
                let text: String
            }
        }
    }
    
    var text: String? {
        candidates.first?.content.parts.first?.text
    }
}

struct ArtworkRecognitionResult: Codable, Sendable {
    let title: String
    let artist: String
    let year: String
    let movement: String
    let description: String
    let storyMode: String
    let culturalContext: String
    let estimatedPeriod: String
    let wikiArtId: String?
}

