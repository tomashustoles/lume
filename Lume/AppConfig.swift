//
//  AppConfig.swift
//  Lume
//
//  Configuration management for API keys and other settings
//

import Foundation

enum AppConfig {
    /// Gemini API key loaded from environment variable or xcconfig
    static var geminiAPIKey: String {
        // Try environment variable first (for Xcode scheme configuration)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Try Info.plist (for build-time configuration via xcconfig)
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !plistKey.isEmpty {
            return plistKey
        }
        
        // Fallback: return empty string (will cause API error, but better than crash)
        // This helps developers realize they need to configure the key
        print("⚠️ WARNING: GEMINI_API_KEY not found in environment or Info.plist")
        print("⚠️ Please configure your API key:")
        print("   1. Edit Scheme → Run → Arguments → Environment Variables")
        print("   2. Add GEMINI_API_KEY with your API key value")
        print("   3. Get your key from: https://aistudio.google.com/app/apikey")
        return ""
    }
}
