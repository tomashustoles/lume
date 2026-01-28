//
//  ProfileView.swift
//  Museum Companion
//
//  User profile and settings
//

import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager
    @EnvironmentObject var historyManager: HistoryManager
    
    @State private var showPaywall = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription section
                Section {
                    if subscriptionManager.isProUser {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Museum Companion Pro")
                                    .font(.system(.body, design: .default))
                                    .fontWeight(.semibold)
                                
                                Text("Unlimited scans and features")
                                    .font(.system(.caption))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        
                        Button {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                Task {
                                    try? await AppStore.showManageSubscriptions(in: windowScene)
                                }
                            }
                        } label: {
                            Text("Manage Subscription")
                                .foregroundColor(.black)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upgrade to Pro")
                                        .font(.system(.body, design: .default))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                    
                                    Text("Unlock unlimited scans")
                                        .font(.system(.caption))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "sparkles")
                                    .foregroundColor(.black)
                            }
                        }
                        
                        HStack {
                            Text("Daily Scans")
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text("\(scanLimitManager.scansRemaining) / 3")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Statistics
                Section("Statistics") {
                    HStack {
                        Text("Artworks Scanned")
                        Spacer()
                        Text("\(historyManager.artworks.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Favorites")
                        Spacer()
                        Text("\(historyManager.favorites.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Data
                Section("Data") {
                    Button {
                        Task {
                            await historyManager.syncFromCloud()
                        }
                    } label: {
                        HStack {
                            Text("Sync with iCloud")
                                .foregroundColor(.black)
                            
                            if historyManager.isLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(historyManager.isLoading)
                }
                
                // App
                Section("App") {
                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Text("Show Onboarding")
                            .foregroundColor(.black)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        .foregroundColor(.black)
                    
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                        .foregroundColor(.black)
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Profile")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(SubscriptionManager())
        .environmentObject(ScanLimitManager())
        .environmentObject(HistoryManager())
}
