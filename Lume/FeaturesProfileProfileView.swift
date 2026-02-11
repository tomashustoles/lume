//
//  ProfileView.swift
//  Museum Companion
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
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                // API Key Debug (for TestFlight)
                Section("API Key Status") {
                    let apiKey = AppConfig.geminiAPIKey
                    let infoDict = Bundle.main.infoDictionary
                    let plistKey = infoDict?["GEMINI_API_KEY"] as? String
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Status:")
                            Spacer()
                            Text(apiKey.isEmpty ? "❌ Missing" : "✅ Found")
                                .foregroundColor(apiKey.isEmpty ? .red : .green)
                        }
                        
                        if !apiKey.isEmpty {
                            Text("Length: \(apiKey.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Prefix: \(String(apiKey.prefix(10)))...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        Text("Info.plist Status:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let plistKey = plistKey {
                            Text("Found in Info.plist: \(plistKey.isEmpty ? "Empty" : "\(plistKey.count) chars")")
                                .font(.caption)
                                .foregroundColor(plistKey.isEmpty ? .red : .green)
                            if plistKey == "$(GEMINI_API_KEY)" {
                                Text("⚠️ Still contains placeholder!")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        } else {
                            Text("❌ Not found in Info.plist")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Text("Available keys: \(infoDict?.keys.sorted().joined(separator: ", ") ?? "none")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
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
