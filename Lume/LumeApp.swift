//
//  LumeApp.swift
//  Lume
//
//  Created by Tomas Hustoles on 29/1/26.
//

import SwiftUI

@main
struct LumeApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var scanLimitManager = ScanLimitManager()
    @StateObject private var historyManager = HistoryManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(subscriptionManager)
                .environmentObject(scanLimitManager)
                .environmentObject(historyManager)
                .task {
                    await subscriptionManager.loadProducts()
                    await subscriptionManager.loadSubscriptionStatus()
                }
        }
    }
}
