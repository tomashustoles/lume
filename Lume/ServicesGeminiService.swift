//
//  GeminiService.swift
//  Mona - Art Companion
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
        // API key is now loaded from AppConfig (which reads from xcconfig or environment)
        let key = AppConfig.geminiAPIKey
        if key.isEmpty {
            print("❌ ERROR: Gemini API key is not configured!")
            print("   Please set GEMINI_API_KEY environment variable in Xcode:")
            print("   Edit Scheme → Run → Arguments → Environment Variables")
            print("   Get your key from: https://aistudio.google.com/app/apikey")
        } else {
            print("✅ Gemini API key loaded successfully (length: \(key.count))")
        }
        self.apiKey = key
    }
    
    // MARK: - Diagnostic
    
    func validateAPIKey() -> Bool {
        if apiKey.isEmpty {
            print("❌ API key is empty")
            return false
        }
        print("✅ API key is present (length: \(apiKey.count), prefix: \(String(apiKey.prefix(10)))...)")
        return true
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
        // Always get fresh API key (in case it was cached from environment variable)
        let currentKey = AppConfig.geminiAPIKey
        
        // Use current key if available, otherwise fall back to stored key from init
        let keyToUse = currentKey.isEmpty ? apiKey : currentKey
        
        guard !keyToUse.isEmpty else {
            print("❌ API key is empty - cannot make request")
            print("❌ Stored API key (from init) length: \(apiKey.count)")
            print("❌ Current AppConfig key length: \(currentKey.count)")
            print("❌ This usually means the app was restarted without running from Xcode")
            print("❌ Environment variables are only available when running from Xcode")
            throw GeminiError.apiKeyInvalid
        }
        
        // Log which key we're using
        if currentKey != apiKey {
            if !currentKey.isEmpty {
                print("⚠️ Using fresh AppConfig key (different from stored key)")
            } else {
                print("⚠️ Using stored API key (AppConfig returned empty)")
            }
        }
        
        print("🔑 Using API key (length: \(keyToUse.count), prefix: \(String(keyToUse.prefix(10)))...)")
        
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
        
        // Construct URL with properly encoded API key (using keyToUse from validation above)
        guard let encodedKey = keyToUse.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?key=\(encodedKey)") else {
            print("❌ Failed to construct URL with API key")
            throw GeminiError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        // Log request details (without exposing full API key)
        let maskedURL = baseURL + "?key=" + String(repeating: "*", count: min(apiKey.count, 20))
        print("📡 Making request to: \(maskedURL)")
        print("📡 Request body size: \(jsonData.count) bytes")
        print("📡 Image base64 size: \(base64Image.count) characters")
        
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
                
                // Check for API key errors and provide helpful message
                if errorString.contains("API_KEY_INVALID") || errorString.contains("API Key not found") {
                    print("\n🔑 API Key Error Detected!")
                    print("   Your Gemini API key is invalid or not configured.")
                    print("   To fix this:")
                    print("   1. Get a valid API key from: https://aistudio.google.com/app/apikey")
                    print("   2. In Xcode: Edit Scheme → Run → Arguments → Environment Variables")
                    print("   3. Add GEMINI_API_KEY with your valid API key value")
                    print("   4. Rebuild and run the app\n")
                }
            }
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Request failed with status: \(httpResponse.statusCode)")
            
            // Log full error response for debugging
            let errorString = String(data: data, encoding: .utf8) ?? ""
            if !errorString.isEmpty {
                print("❌ Full error response: \(errorString.prefix(500))")
            }
            
            // Provide more specific error for API key issues (400 status)
            if httpResponse.statusCode == 400 {
                print("❌ 400 Bad Request - checking for API key issues...")
                
                let lowercasedError = errorString.lowercased()
                if lowercasedError.contains("api_key_invalid") || 
                   lowercasedError.contains("api key not found") ||
                   lowercasedError.contains("invalid api key") ||
                   (lowercasedError.contains("api") && lowercasedError.contains("key")) {
                    print("❌ API key error detected in 400 response")
                    throw GeminiError.apiKeyInvalid
                }
            }
            
            // Handle 429 (Too Many Requests) - rate limiting
            if httpResponse.statusCode == 429 {
                print("❌ 429 Too Many Requests - Rate limit exceeded")
                throw GeminiError.rateLimitExceeded
            }
            
            // Handle 403 errors specifically (quota exceeded, rate limiting, etc.)
            if httpResponse.statusCode == 403 {
                let errorString = String(data: data, encoding: .utf8) ?? ""
                print("❌ 403 Forbidden Error - Full response:")
                print("   \(errorString)")
                print("   Possible causes:")
                print("   - API quota exceeded")
                print("   - Rate limit reached")
                print("   - API key restrictions")
                print("   - Billing not enabled")
                print("   - API key expired or revoked")
                print("   - Request too large")
                
                // Parse JSON error if available
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("   Parsed error message: \(message)")
                    
                    // Check for specific error messages
                    let lowercasedMessage = message.lowercased()
                    if lowercasedMessage.contains("quota") || lowercasedMessage.contains("exceeded") {
                        throw GeminiError.quotaExceeded
                    } else if lowercasedMessage.contains("rate") || lowercasedMessage.contains("limit") {
                        throw GeminiError.rateLimitExceeded
                    } else if lowercasedMessage.contains("billing") || lowercasedMessage.contains("payment") {
                        throw GeminiError.forbidden
                    } else if lowercasedMessage.contains("permission") || lowercasedMessage.contains("forbidden") {
                        throw GeminiError.forbidden
                    }
                }
                
                // Check for specific error messages in raw string
                let lowercasedError = errorString.lowercased()
                if lowercasedError.contains("quota") || lowercasedError.contains("quota_exceeded") {
                    throw GeminiError.quotaExceeded
                } else if lowercasedError.contains("rate") || lowercasedError.contains("rate_limit") {
                    throw GeminiError.rateLimitExceeded
                } else {
                    throw GeminiError.forbidden
                }
            }
            
            throw GeminiError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Check if response is empty
        guard !data.isEmpty else {
            print("❌ API returned empty response")
            throw GeminiError.noResponse
        }
        
        // Log raw response for debugging (first 1000 chars)
        let rawResponseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        print("📥 Raw API response (first 1000 chars): \(String(rawResponseString.prefix(1000)))")
        print("📥 Response data size: \(data.count) bytes")
        
        // Check if response looks like an error
        if rawResponseString.contains("\"error\"") {
            print("⚠️ Response contains error field")
        }
        
        // Try to decode the Gemini response
        let geminiResponse: GeminiResponse
        do {
            geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            print("❌ Failed to decode GeminiResponse structure")
            print("❌ Decoding error: \(error)")
            print("❌ Full response: \(rawResponseString)")
            
            // Check if it's an error response instead
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = errorJson["error"] as? [String: Any] {
                print("❌ API returned an error response")
                if let message = errorObj["message"] as? String {
                    print("❌ Error message: \(message)")
                }
                if let code = errorObj["code"] as? Int {
                    print("❌ Error code: \(code)")
                    if code == 429 {
                        throw GeminiError.rateLimitExceeded
                    } else if code == 403 {
                        throw GeminiError.forbidden
                    }
                }
            }
            
            throw GeminiError.invalidResponse
        }
        
        guard let responseText = geminiResponse.text else {
            print("❌ No text in response candidates")
            print("❌ Response structure: \(geminiResponse)")
            throw GeminiError.noResponse
        }
        
        print("✅ Extracted response text (length: \(responseText.count) chars)")
        
        // Clean the response text - remove markdown code blocks if present
        var cleanedText = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if JSON appears to be truncated (doesn't end with })
        if !cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("}") {
            print("⚠️ JSON appears to be truncated (doesn't end with })")
            // Try to find the last complete field and close the JSON
            // Look for the last complete key-value pair
            if let lastComma = cleanedText.lastIndex(of: ",") {
                // Remove everything after the last comma and try to close the JSON
                let truncated = String(cleanedText[..<lastComma])
                // Try to add missing required fields
                var fixedText = truncated
                if !fixedText.contains("\"culturalContext\":") {
                    fixedText += ",\"culturalContext\": \"\""
                }
                if !fixedText.contains("\"estimatedPeriod\":") {
                    fixedText += ",\"estimatedPeriod\": \"Contemporary\""
                }
                if !fixedText.contains("\"wikiArtId\":") {
                    fixedText += ",\"wikiArtId\": \"\""
                }
                fixedText += "}"
                cleanedText = fixedText
                print("⚠️ Attempted to fix truncated JSON")
            }
        }
        
        guard let resultData = cleanedText.data(using: .utf8) else {
            print("❌ Failed to convert cleaned text to data")
            throw GeminiError.decodingFailed
        }
        
        do {
            let result = try JSONDecoder().decode(ArtworkRecognitionResult.self, from: resultData)
            print("✅ Successfully decoded ArtworkRecognitionResult")
            return result
        } catch let decodingError {
            print("❌ Decoding error: \(decodingError)")
            print("❌ Error type: \(type(of: decodingError))")
            if let context = decodingError as? DecodingError {
                switch context {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key.stringValue) at path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type) at path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: \(type) at path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted at path: \(context.codingPath), debugDescription: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            print("❌ Response text (first 1000 chars): \(String(cleanedText.prefix(1000)))")
            print("❌ Response text (last 1000 chars): \(String(cleanedText.suffix(1000)))")
            print("❌ Full cleaned text length: \(cleanedText.count) chars")
            
            // Try to extract partial data if possible
            if let json = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any] {
                print("⚠️ Partial JSON parsed, attempting to create result with available fields")
                print("⚠️ Available keys: \(json.keys.joined(separator: ", "))")
                // Create result with available fields, using defaults for missing ones
                let result = ArtworkRecognitionResult(
                    title: json["title"] as? String ?? "Unknown Artwork",
                    artist: json["artist"] as? String ?? "Unknown Artist",
                    year: json["year"] as? String ?? "Unknown",
                    movement: json["movement"] as? String ?? "Unknown",
                    description: json["description"] as? String ?? "Description unavailable.",
                    storyMode: json["storyMode"] as? String ?? "Story unavailable.",
                    culturalContext: json["culturalContext"] as? String ?? "Cultural context unavailable.",
                    estimatedPeriod: json["estimatedPeriod"] as? String ?? "Contemporary",
                    wikiArtId: json["wikiArtId"] as? String
                )
                print("✅ Created partial result from truncated JSON")
                return result
            } else {
                print("❌ Could not parse JSON at all - response may not be JSON")
            }
            
            throw GeminiError.decodingFailed
        }
    }
    
    // MARK: - Fetch Artwork Image
    
    func fetchArtworkImage(title: String, artist: String) async throws -> UIImage? {
        // Try multiple strategies - Wikipedia pages for artworks are usually titled with artwork name only
        // Strategy 1: Wikipedia with artwork title only (e.g. "The Great Wave off Kanagawa")
        if let image = await fetchWikipediaImage(titles: title) {
            return image
        }
        
        // Strategy 2: Wikipedia with "title (artist)" format
        if let image = await fetchWikipediaImage(titles: "\(title) (\(artist))") {
            return image
        }
        
        // Strategy 3: Wikipedia with title + artist
        if let image = await fetchWikipediaImage(titles: "\(title) \(artist)") {
            return image
        }
        
        // Strategy 4: Wikimedia Commons - try title only first
        if let image = await fetchWikimediaCommonsImage(query: title) {
            return image
        }
        
        // Strategy 5: Wikimedia Commons with full search
        if let image = await fetchWikimediaCommonsImage(query: "\(title) \(artist)") {
            return image
        }
        
        print("⚠️ Could not find artwork image for: \(title) by \(artist)")
        return nil
    }
    
    private func fetchWikipediaImage(titles: String) async -> UIImage? {
        let encoded = titles.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=pageimages&piprop=original&titles=\(encoded)&redirects=1"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print("📷 Wikipedia lookup for '\(titles)': \(String(data: data, encoding: .utf8)?.prefix(300) ?? "nil")")
            
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
    
    private func fetchWikimediaCommonsImage(query: String) async -> UIImage? {
        // Search Wikimedia Commons for the artwork file directly
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
    case apiKeyInvalid
    case quotaExceeded
    case rateLimitExceeded
    case forbidden
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the image. Please try again."
        case .invalidRequest:
            return "Invalid request. Please try again."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .httpError(let statusCode):
            return "Server error (\(statusCode)). Please try again."
        case .noResponse:
            return "No response received. Please check your connection."
        case .decodingFailed:
            return "Failed to understand the response. Please try again."
        case .networkError:
            return "Network connection failed. Please check your internet connection."
        case .apiKeyInvalid:
            return "API key is invalid or not configured. If you restarted the app without running from Xcode, environment variables are not available. Please run from Xcode or add the key to Info.plist."
        case .quotaExceeded:
            return "API quota exceeded. Please check your Gemini API quota or try again later."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait a moment and try again."
        case .forbidden:
            return "Access forbidden. Please check your API key permissions and billing status."
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

