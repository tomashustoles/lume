//
//  PaywallView.swift
//  Museum Companion
//
//  Native Apple-style paywall with StoreKit 2
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    // Header
                    header
                    
                    // Features
                    features
                    
                    // Products
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if subscriptionManager.subscriptionProducts.isEmpty {
                        Text("Unable to load subscription options. Please check your connection and try again.")
                            .font(.system(.subheadline))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        productSelection
                    }
                    
                    // Subscribe button
                    subscribeButton
                    
                    // Restore purchases
                    restoreButton
                    
                    // Legal
                    legalText
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
            }
        }
        .task {
            await subscriptionManager.loadProducts()
            // Auto-select first product so subscribe button is enabled when products load
            if selectedProduct == nil, let first = subscriptionManager.subscriptionProducts.first {
                selectedProduct = first
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("Unlock\nUnlimited Art")
                .font(.custom("NewYork", size: 42))
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("Discover endless artworks with Lume")
                .font(.system(.title3))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
        }
    }
    
    // MARK: - Features
    
    private var features: some View {
        VStack(alignment: .leading, spacing: 20) {
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Scans",
                description: "Recognize as many artworks as you want",
                colorScheme: colorScheme
            )
            
            FeatureRow(
                icon: "icloud.fill",
                title: "iCloud Sync",
                description: "Access your collection across all devices",
                colorScheme: colorScheme
            )
            
            FeatureRow(
                icon: "book.fill",
                title: "Story Mode",
                description: "Experience emotional narratives for every piece",
                colorScheme: colorScheme
            )
            
            FeatureRow(
                icon: "heart.fill",
                title: "Unlimited Favorites",
                description: "Build your personal art collection",
                colorScheme: colorScheme
            )
        }
    }
    
    // MARK: - Product Selection
    
    private var productSelection: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionManager.subscriptionProducts, id: \.id) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    colorScheme: colorScheme,
                    onSelect: {
                        selectedProduct = product
                    }
                )
            }
        }
    }
    
    // MARK: - Subscribe Button
    
    private var subscribeButton: some View {
        Button {
            Task {
                await purchase()
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .black : .white))
                } else {
                    Text("Start Free Trial")
                        .font(.system(.body, design: .default))
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(colorScheme == .dark ? .white : .black)
            .cornerRadius(12)
        }
        .disabled(selectedProduct == nil || isPurchasing)
        .opacity(selectedProduct == nil || isPurchasing ? 0.5 : 1.0)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button {
            Task {
                await restore()
            }
        } label: {
            Text("Restore Purchases")
                .font(.system(.body))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                .frame(maxWidth: .infinity)
        }
        .disabled(isPurchasing)
    }
    
    // MARK: - Legal
    
    private var legalText: some View {
        VStack(spacing: 8) {
            Text("7 days free, then \(selectedProduct?.displayPrice ?? "€2.99/month")")
                .font(.system(.caption))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
            
            Text("Subscription auto-renews. Cancel anytime in Settings.")
                .font(.system(.caption))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Actions
    
    private func purchase() async {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let transaction = try await subscriptionManager.purchase(product)
            if transaction != nil {
                dismiss()
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
    }
    
    private func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        await subscriptionManager.restorePurchases()
        
        if subscriptionManager.isProUser {
            dismiss()
        } else {
            errorMessage = "No previous purchases found."
            showError = true
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .default))
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(description)
                    .font(.system(.subheadline))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            }
        }
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.system(.body, design: .default))
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        if let subscription = product.subscription,
                           let savingsText = savingsText(for: subscription) {
                            Text(savingsText)
                                .font(.system(.caption))
                                .fontWeight(.medium)
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(colorScheme == .dark ? .white : .black)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(product.displayPrice)
                        .font(.system(.subheadline))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                }
                
                Spacer()
                
                Circle()
                    .stroke(
                        isSelected 
                            ? (colorScheme == .dark ? Color.white : Color.black) 
                            : (colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)), 
                        lineWidth: 2
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(colorScheme == .dark ? .white : .black)
                            .frame(width: 14, height: 14)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected 
                            ? (colorScheme == .dark ? Color.white : Color.black) 
                            : (colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2)),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
    
    private func savingsText(for subscription: Product.SubscriptionInfo) -> String? {
        // This is a simplified version - you could calculate actual savings
        if product.id.contains("yearly") {
            return "Save 44%"
        }
        return nil
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
