//
//  Config.swift
//  Lume
//
//  Secure configuration for API keys and sensitive data
//

import Foundation

enum Config {
    /// Gemini API Key
    /// IMPORTANT: Never commit your actual API key to version control!
    /// 
    /// To use this app:
    /// Option 1: Set environment variable GEMINI_API_KEY in your scheme
    /// Option 2: Create APIKeys.plist (see APIKeys.plist.template)
    static var geminiAPIKey: String {
        // Try environment variable first (recommended for development)
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !key.isEmpty {
            return key
        }
        
        // Try loading from APIKeys.plist (gitignored)
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["GEMINI_API_KEY"] as? String,
           !key.isEmpty {
            return key
        }
        
        // For development only - will prompt developer to configure
        fatalError("""
            ⚠️ GEMINI_API_KEY not configured!
            
            Please set up your API key using ONE of these methods:
            
            📋 Method 1 (Recommended): Environment Variable
            1. In Xcode: Product > Scheme > Edit Scheme
            2. Select "Run" > "Arguments" tab
            3. Add Environment Variable:
               Name: GEMINI_API_KEY
               Value: your_api_key_here
            
            📄 Method 2: Configuration File
            1. Copy APIKeys.plist.template to APIKeys.plist
            2. Replace YOUR_API_KEY_HERE with your actual key
            3. Add APIKeys.plist to your Xcode project
            
            Get your API key from: https://aistudio.google.com/app/apikey
            """)
    }
}
