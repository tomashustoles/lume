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
            ScanView(onNavigateToCollection: {
                selectedTab = 1 // Switch to Collection tab
            })
                .tabItem {
                    Label("Scan", systemImage: "camera")
                }
                .tag(0)
            
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.stack.3d.up")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
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
