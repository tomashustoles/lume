//
//  ProfileView.swift
//  Mona - Art Companion
//
//  User profile and settings
//

import SwiftUI
import StoreKit

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
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
                                Text("Art Companion Pro")
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
                                .foregroundColor(colorScheme == .dark ? .white : .black)
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
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    
                                    Text("Unlock unlimited scans")
                                        .font(.system(.caption))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "sparkles")
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                        }
                        
                        HStack {
                            Text("Daily Scans")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Spacer()
                            
                            Text(scanLimitManager.scansRemaining == Int.max ? "Unlimited" : "\(scanLimitManager.scansRemaining) / 3")
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
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
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
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: AppConfig.privacyPolicyURL)!)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Link("Terms of Service", destination: URL(string: AppConfig.termsOfServiceURL)!)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Link("EULA", destination: URL(string: AppConfig.eulaURL)!)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Link("Contact Support", destination: URL(string: "mailto:\(AppConfig.supportEmail)")!)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
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
                .environmentObject(subscriptionManager)
                .environmentObject(scanLimitManager)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(SubscriptionManager())
        .environmentObject(ScanLimitManager())
        .environmentObject(HistoryManager())
}
