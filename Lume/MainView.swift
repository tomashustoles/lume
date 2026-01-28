//
//  MainView.swift
//  Lume
//
//  Main app interface with camera and feed
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SimpleCameraView()
                .tabItem {
                    Label("Scan", systemImage: "camera")
                }
                .tag(0)
            
            ArtworkFeedView()
                .tabItem {
                    Label("Collection", systemImage: "square.stack.fill")
                }
                .tag(1)
        }
        .tint(.black)
    }
}

#Preview {
    MainView()
        .environmentObject(ScanLimitManager())
        .environmentObject(HistoryManager())
        .environmentObject(SubscriptionManager())
}
