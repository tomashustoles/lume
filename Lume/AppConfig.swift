//
//  AppConfig.swift
//  Lume
//
//  Configuration management for API keys and other settings
//

import Foundation
import UIKit

enum AppConfig {
    private static let cachedKeyUserDefaultsKey = "cachedGeminiAPIKey"
    
    /// Gemini API key loaded from environment variable, Info.plist, or cached value
    static var geminiAPIKey: String {
        // Try environment variable first (for Xcode scheme configuration - only works when running from Xcode)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            #if DEBUG
            print("✅ Found API key in environment variable")
            #endif
            // Cache it for when environment variable is not available (e.g., after app restart)
            UserDefaults.standard.set(envKey, forKey: cachedKeyUserDefaultsKey)
            return envKey
        }
        
        // Try Info.plist (for build-time configuration)
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !plistKey.isEmpty {
            // Check if it's still the placeholder (shouldn't happen in production)
            if plistKey == "$(GEMINI_API_KEY)" {
                #if DEBUG
                print("❌ ERROR: GEMINI_API_KEY in Info.plist is still the placeholder!")
                print("❌ The INFOPLIST_KEY_ mechanism did not replace it during build.")
                #endif
            } else {
                #if DEBUG
                print("✅ Found API key in Info.plist")
                #endif
                // Cache it
                UserDefaults.standard.set(plistKey, forKey: cachedKeyUserDefaultsKey)
                return plistKey
            }
        }
        
        // Fallback: Try cached value (for when app is restarted without Xcode)
        if let cachedKey = UserDefaults.standard.string(forKey: cachedKeyUserDefaultsKey), !cachedKey.isEmpty {
            #if DEBUG
            print("⚠️ Using cached API key")
            #endif
            return cachedKey
        }
        
        // No key found anywhere
        #if DEBUG
        print("❌ ERROR: GEMINI_API_KEY not found in environment, Info.plist, or cache")
        #endif
        
        // Show alert in UI for TestFlight users
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                let alert = UIAlertController(
                    title: "API Key Missing",
                    message: "GEMINI_API_KEY not found in Info.plist. Check Profile → API Key Status for details.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                rootViewController.present(alert, animated: true)
            }
        }
        
        return ""
    }
    
    /// Clear the cached API key (for security/testing)
    static func clearCachedAPIKey() {
        UserDefaults.standard.removeObject(forKey: cachedKeyUserDefaultsKey)
        #if DEBUG
        print("🗑️ Cleared cached API key")
        #endif
    }
}
