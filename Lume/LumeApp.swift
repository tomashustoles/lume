//
//  LumeApp.swift
//  Mona - Art Companion
//
//  Created by Tomas Hustoles on 29/1/26.
//

import SwiftUI

@main
struct LumeApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var scanLimitManager = ScanLimitManager()
    @StateObject private var historyManager = HistoryManager()
    
    // Show splash screen on every launch
    @State private var isShowingSplash = true
    
    // Track app lifecycle
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app
                MainTabView()
                    .environmentObject(subscriptionManager)
                    .environmentObject(scanLimitManager)
                    .environmentObject(historyManager)
                    .task {
                        #if DEBUG
                        // Check API key on launch (debug builds only)
                        let apiKey = AppConfig.geminiAPIKey
                        if apiKey.isEmpty {
                            print("❌ CRITICAL: API key is empty on app launch!")
                        }
                        #endif
                        
                        // Start subscription manager listeners
                        subscriptionManager.startListening()
                        
                        // Load products and status
                        await subscriptionManager.loadProducts()
                        await subscriptionManager.loadSubscriptionStatus()
                        // Sync scan limits with subscription
                        if subscriptionManager.isProUser {
                            scanLimitManager.resetForProUser()
                        } else {
                            scanLimitManager.resetForFreeUserIfNeeded()
                        }
                    }
                
                // Splash screen overlay (shows on every launch)
                if isShowingSplash {
                    SplashView(isShowingSplash: $isShowingSplash)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .statusBar(hidden: true)
            .animation(.easeOut(duration: 0.5), value: isShowingSplash)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
    }
    
    // MARK: - Lifecycle Handling
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            print("✅ App became active")
            
        case .inactive:
            // App became inactive (e.g., during transition)
            print("ℹ️ App became inactive")
            
        case .background:
            // App went to background
            print("ℹ️ App entered background")
            
        @unknown default:
            break
        }
    }
}
