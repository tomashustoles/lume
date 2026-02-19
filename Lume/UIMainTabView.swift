//
//  MainTabView.swift
//  Museum Companion
//
//  Main tab bar navigation
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ScanView(
                onNavigateToCollection: { selectedTab = 1 },
                onNavigateToScan: { selectedTab = 0 }
            )
                .tabItem {
                    Label("Scan", systemImage: selectedTab == 0 ? "camera.fill" : "camera")
                }
                .tag(0)
            
            CollectionView(
                onNavigateToCollection: { selectedTab = 1 },
                onNavigateToScan: { selectedTab = 0 }
            )
                .tabItem {
                    Label("Collection", systemImage: selectedTab == 1 ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 2 ? "person.fill" : "person")
                }
                .tag(2)
        }
        .tint(colorScheme == .dark ? .white : .black)
    }
}

#Preview {
    MainTabView()
        .environmentObject(SubscriptionManager())
        .environmentObject(ScanLimitManager())
        .environmentObject(HistoryManager())
}
