//
//  PaywallView.swift
//  Museum Companion
//
//  Native Apple-style paywall with StoreKit 2
//

import SwiftUI
import StoreKit

struct PaywallView: View {
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
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .task {
            await subscriptionManager.loadProducts()
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
                .foregroundColor(.black)
            
            Text("Unlock\nUnlimited Art")
                .font(.custom("NewYork", size: 42))
                .fontWeight(.semibold)
                .foregroundColor(.black)
            
            Text("Discover endless artworks with Museum Companion Pro")
                .font(.system(.title3))
                .foregroundColor(.black.opacity(0.6))
        }
    }
    
    // MARK: - Features
    
    private var features: some View {
        VStack(alignment: .leading, spacing: 20) {
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Scans",
                description: "Recognize as many artworks as you want"
            )
            
            FeatureRow(
                icon: "icloud.fill",
                title: "iCloud Sync",
                description: "Access your collection across all devices"
            )
            
            FeatureRow(
                icon: "book.fill",
                title: "Story Mode",
                description: "Experience emotional narratives for every piece"
            )
            
            FeatureRow(
                icon: "heart.fill",
                title: "Unlimited Favorites",
                description: "Build your personal art collection"
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Start Free Trial")
                        .font(.system(.body, design: .default))
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black)
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
                .foregroundColor(.black.opacity(0.6))
                .frame(maxWidth: .infinity)
        }
        .disabled(isPurchasing)
    }
    
    // MARK: - Legal
    
    private var legalText: some View {
        VStack(spacing: 8) {
            Text("7 days free, then \(selectedProduct?.displayPrice ?? "€2.99/month")")
                .font(.system(.caption))
                .foregroundColor(.black.opacity(0.5))
            
            Text("Subscription auto-renews. Cancel anytime in Settings.")
                .font(.system(.caption))
                .foregroundColor(.black.opacity(0.5))
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
            errorMessage = error.localizedDescription
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.black)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .default))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(.subheadline))
                    .foregroundColor(.black.opacity(0.6))
            }
        }
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
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
                            .foregroundColor(.black)
                        
                        if let subscription = product.subscription,
                           let savingsText = savingsText(for: subscription) {
                            Text(savingsText)
                                .font(.system(.caption))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(product.displayPrice)
                        .font(.system(.subheadline))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                Spacer()
                
                Circle()
                    .stroke(isSelected ? Color.black : Color.black.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(Color.black)
                            .frame(width: 14, height: 14)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.black : Color.black.opacity(0.2),
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
