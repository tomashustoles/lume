//
//  AppConfig.swift
//  Lume
//
//  Configuration management for API keys and other settings
//

import Foundation

enum AppConfig {
    private static let cachedKeyUserDefaultsKey = "cachedGeminiAPIKey"
    
    /// Gemini API key loaded from environment variable, Info.plist, or cached value
    static var geminiAPIKey: String {
        // Try environment variable first (for Xcode scheme configuration - only works when running from Xcode)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            print("✅ Found API key in environment variable")
            // Cache it for when environment variable is not available (e.g., after app restart)
            UserDefaults.standard.set(envKey, forKey: cachedKeyUserDefaultsKey)
            return envKey
        }
        
        // Try Info.plist (for build-time configuration via xcconfig)
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !plistKey.isEmpty {
            print("✅ Found API key in Info.plist")
            // Cache it
            UserDefaults.standard.set(plistKey, forKey: cachedKeyUserDefaultsKey)
            return plistKey
        }
        
        // Fallback: Try cached value (for when app is restarted without Xcode)
        if let cachedKey = UserDefaults.standard.string(forKey: cachedKeyUserDefaultsKey), !cachedKey.isEmpty {
            print("⚠️ Using cached API key (environment variable not available - app likely restarted without Xcode)")
            print("⚠️ For production, add GEMINI_API_KEY to Info.plist or use a server-side proxy")
            return cachedKey
        }
        
        // No key found anywhere
        print("❌ ERROR: GEMINI_API_KEY not found in environment, Info.plist, or cache")
        print("❌ This happens when:")
        print("   1. App was restarted without running from Xcode (environment variables not available)")
        print("   2. API key was never cached from a previous Xcode run")
        print("❌ Solutions:")
        print("   1. Run from Xcode to cache the key, OR")
        print("   2. Add GEMINI_API_KEY to Info.plist (for production builds), OR")
        print("   3. Use a server-side proxy (recommended for production)")
        print("   4. Get your key from: https://aistudio.google.com/app/apikey")
        return ""
    }
    
    /// Clear the cached API key (for security/testing)
    static func clearCachedAPIKey() {
        UserDefaults.standard.removeObject(forKey: cachedKeyUserDefaultsKey)
        print("🗑️ Cleared cached API key")
    }
}
