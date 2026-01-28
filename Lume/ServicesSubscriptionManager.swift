//
//  SubscriptionManager.swift
//  Museum Companion
//
//  Manages StoreKit 2 subscriptions with comprehensive entitlement logic
//

import Foundation
import StoreKit
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    @Published private(set) var subscriptionProducts: [Product] = []
    @Published private(set) var isProUser = false
    @Published private(set) var currentSubscription: Product.SubscriptionInfo.Status?
    @Published var isLoading = false
    @Published var subscriptionExpirationDate: Date?
    @Published var isInGracePeriod = false
    @Published var isInBillingRetry = false
    
    private var updateListenerTask: Task<Void, Error>?
    private var statusCheckTask: Task<Void, Never>?
    
    // Cached entitlement state for offline scenarios
    private let entitlementCacheKey = "cachedProUserStatus"
    private let lastVerificationDateKey = "lastEntitlementVerificationDate"
    
    init() {
        // Load cached entitlement state
        loadCachedEntitlement()
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Start periodic status checks
        statusCheckTask = Task { [weak self] in
            await self?.performPeriodicStatusCheck()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        statusCheckTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }
            let products = try await Product.products(for: productIDs)
            
            // Sort products: monthly first, then yearly
            subscriptionProducts = products.sorted { lhs, rhs in
                if lhs.id.contains("monthly") { return true }
                if rhs.id.contains("monthly") { return false }
                return lhs.displayPrice < rhs.displayPrice
            }
            
            print("✅ Loaded \(subscriptionProducts.count) subscription products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }
    
    // MARK: - Load Subscription Status
    
    func loadSubscriptionStatus() async {
        do {
            // Check for any current entitlements across all subscription products
            var hasActiveSubscription = false
            var newestStatus: Product.SubscriptionInfo.Status?
            var newestTransaction: Transaction?
            
            // Check all subscription products
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)
                
                // Check if this transaction is for one of our subscription products
                if SubscriptionProduct.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    // Only consider subscriptions (not consumables or non-consumables)
                    if transaction.productType == .autoRenewable {
                        hasActiveSubscription = true
                        
                        // Keep track of the newest transaction
                        if let newest = newestTransaction {
                            if transaction.purchaseDate > newest.purchaseDate {
                                newestTransaction = transaction
                            }
                        } else {
                            newestTransaction = transaction
                        }
                    }
                }
            }
            
            // If we found an active subscription, get its detailed status
            if hasActiveSubscription, let transaction = newestTransaction {
                // Get subscription status from the product
                if let product = subscriptionProducts.first(where: { $0.id == transaction.productID }),
                   let statuses = try await product.subscription?.status {
                    
                    for status in statuses {
                        switch status.state {
                        case .subscribed:
                            isProUser = true
                            isInGracePeriod = false
                            isInBillingRetry = false
                            newestStatus = status
                            
                        case .inGracePeriod:
                            // Still provide access during grace period
                            isProUser = true
                            isInGracePeriod = true
                            isInBillingRetry = false
                            newestStatus = status
                            
                        case .inBillingRetryPeriod:
                            // Still provide access during billing retry
                            isProUser = true
                            isInGracePeriod = false
                            isInBillingRetry = true
                            newestStatus = status
                            
                        case .revoked:
                            // Subscription was revoked
                            isProUser = false
                            isInGracePeriod = false
                            isInBillingRetry = false
                            
                        case .expired:
                            // Subscription ended
                            isProUser = false
                            isInGracePeriod = false
                            isInBillingRetry = false
                            
                        default:
                            // Handle any unknown or future states
                            isProUser = false
                            isInGracePeriod = false
                            isInBillingRetry = false
                        }
                    }
                }
            } else {
                // No active subscription found
                isProUser = false
                isInGracePeriod = false
                isInBillingRetry = false
            }
            
            currentSubscription = newestStatus
            
            // Update expiration date
            if let renewalInfo = newestStatus?.renewalInfo {
                switch renewalInfo {
                case .verified(let info):
                    // RenewalInfo doesn't have expirationDate directly
                    // We can use the renewal date instead, or calculate from other properties
                    subscriptionExpirationDate = info.renewalDate
                case .unverified:
                    subscriptionExpirationDate = nil
                }
            }
            
            // Cache the entitlement status
            cacheEntitlement()
            
            print("✅ Subscription status loaded. Pro user: \(isProUser)")
            
        } catch {
            print("❌ Failed to load subscription status: \(error)")
            
            // In case of network error, use cached status
            loadCachedEntitlement()
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        guard !isLoading else {
            throw SubscriptionError.purchaseInProgress
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await loadSubscriptionStatus()
                
                print("✅ Purchase successful: \(product.displayName)")
                return transaction
                
            case .userCancelled:
                print("ℹ️ User cancelled purchase")
                return nil
                
            case .pending:
                print("⏳ Purchase pending approval")
                return nil
                
            @unknown default:
                return nil
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Sync with App Store
            try await AppStore.sync()
            
            // Check subscription status
            await loadSubscriptionStatus()
            
            print("✅ Purchases restored")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
        }
    }
    
    // MARK: - Listen for Transactions
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)
                    
                    // Finish the transaction
                    await transaction?.finish()
                    
                    // Update subscription status
                    await self?.loadSubscriptionStatus()
                    
                    print("✅ Transaction update processed: \(transaction?.productID ?? "unknown")")
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Periodic Status Check
    
    private func performPeriodicStatusCheck() async {
        // Check status every hour
        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: 3_600_000_000_000) // 1 hour
                await loadSubscriptionStatus()
            } catch {
                // Task was cancelled
                break
            }
        }
    }
    
    // MARK: - Verify Transaction
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            // Verification failed
            print("❌ Transaction verification failed: \(error)")
            throw SubscriptionError.failedVerification
            
        case .verified(let transaction):
            // Verification successful
            return transaction
        }
    }
    
    // MARK: - Entitlement Caching (for offline support)
    
    private func cacheEntitlement() {
        UserDefaults.standard.set(isProUser, forKey: entitlementCacheKey)
        UserDefaults.standard.set(Date(), forKey: lastVerificationDateKey)
    }
    
    private func loadCachedEntitlement() {
        let cachedStatus = UserDefaults.standard.bool(forKey: entitlementCacheKey)
        
        // Only use cached status if it was verified recently (within 24 hours)
        if let lastVerification = UserDefaults.standard.object(forKey: lastVerificationDateKey) as? Date {
            let hoursSinceVerification = Date().timeIntervalSince(lastVerification) / 3600
            
            if hoursSinceVerification < 24 {
                isProUser = cachedStatus
                print("ℹ️ Using cached entitlement status: \(isProUser)")
            } else {
                print("⚠️ Cached entitlement expired, re-verification needed")
            }
        }
    }
    
    // MARK: - Subscription Info Helpers
    
    func getPrimarySubscription() -> Product? {
        // Return the current active subscription product
        guard let currentSub = currentSubscription else { return nil }
        
        // Unwrap the transaction VerificationResult
        switch currentSub.transaction {
        case .verified(let transaction):
            return subscriptionProducts.first { $0.id == transaction.productID }
        case .unverified:
            return nil
        }
    }
    
    func getSubscriptionStatusDescription() -> String {
        if isProUser {
            if isInGracePeriod {
                return "Active (Payment Issue)"
            } else if isInBillingRetry {
                return "Active (Retrying Payment)"
            } else {
                return "Active"
            }
        } else {
            return "Inactive"
        }
    }
    
    func getRenewalDate() -> Date? {
        guard let renewalInfo = currentSubscription?.renewalInfo else { return nil }
        
        switch renewalInfo {
        case .verified(let info):
            return info.renewalDate
        case .unverified:
            return nil
        }
    }
    
    func willRenew() -> Bool {
        guard let renewalInfo = currentSubscription?.renewalInfo else { return false }
        
        switch renewalInfo {
        case .verified(let info):
            return info.willAutoRenew
        case .unverified:
            return false
        }
    }
    
    // MARK: - Testing Helpers (for development and debugging)
    
    #if DEBUG
    func simulateProUser() {
        isProUser = true
        cacheEntitlement()
        print("⚠️ DEBUG: Simulated Pro User status")
    }
    
    func simulateFreeUser() {
        isProUser = false
        cacheEntitlement()
        print("⚠️ DEBUG: Simulated Free User status")
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: entitlementCacheKey)
        UserDefaults.standard.removeObject(forKey: lastVerificationDateKey)
        print("⚠️ DEBUG: Cleared entitlement cache")
    }
    #endif
}

// MARK: - Subscription Error

enum SubscriptionError: LocalizedError {
    case failedVerification
    case purchaseInProgress
    case networkError
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Unable to verify your purchase. Please try again."
        case .purchaseInProgress:
            return "A purchase is already in progress."
        case .networkError:
            return "Network connection required. Please check your internet connection."
        case .productNotFound:
            return "Subscription product not found. Please try again later."
        }
    }
}
