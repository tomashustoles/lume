//
//  SubscriptionManagerTests.swift
//  Mona - Art Companion Tests
//
//  Unit tests for SubscriptionManager
//

import Testing
import StoreKit
@testable import Lume

@Suite("Subscription Manager Tests")
struct SubscriptionManagerTests {
    
    @Test("Initialize subscription manager")
    @MainActor
    func initializeManager() async throws {
        let manager = SubscriptionManager()
        
        #expect(!manager.isProUser, "User should not be Pro by default")
        #expect(manager.subscriptionProducts.isEmpty, "Products should be empty initially")
        #expect(!manager.isLoading, "Should not be loading initially")
    }
    
    @Test("Load products from StoreKit")
    @MainActor
    func loadProducts() async throws {
        let manager = SubscriptionManager()
        
        await manager.loadProducts()
        
        // Note: In testing environment, products may not load without StoreKit configuration
        // This test validates the loading mechanism doesn't crash
        #expect(manager.isLoading == false, "Loading should complete")
    }
    
    @Test("Cached entitlement retrieval")
    @MainActor
    func cachedEntitlement() async throws {
        let manager = SubscriptionManager()
        
        #if DEBUG
        // Simulate Pro user
        manager.simulateProUser()
        #expect(manager.isProUser, "Pro user status should be set")
        
        // Create new manager instance to test cache loading
        let newManager = SubscriptionManager()
        
        // Cache should be loaded
        #expect(newManager.isProUser, "Cached Pro status should persist")
        
        // Clean up
        manager.simulateFreeUser()
        manager.clearCache()
        #endif
    }
    
    @Test("Subscription status description")
    @MainActor
    func subscriptionStatusDescription() async throws {
        let manager = SubscriptionManager()
        
        // Free user
        #expect(manager.getSubscriptionStatusDescription() == "Inactive")
        
        #if DEBUG
        // Simulate Pro user
        manager.simulateProUser()
        #expect(manager.getSubscriptionStatusDescription() == "Active")
        
        // Clean up
        manager.simulateFreeUser()
        #endif
    }
    
    @Test("Subscription error descriptions")
    func errorDescriptions() {
        #expect(SubscriptionError.failedVerification.errorDescription != nil)
        #expect(SubscriptionError.purchaseInProgress.errorDescription != nil)
        #expect(SubscriptionError.networkError.errorDescription != nil)
        #expect(SubscriptionError.productNotFound.errorDescription != nil)
    }
}

@Suite("Subscription Product Tests")
struct SubscriptionProductTests {
    
    @Test("Product IDs are valid")
    func productIDs() {
        let monthly = SubscriptionProduct.monthly
        let yearly = SubscriptionProduct.yearly
        
        #expect(monthly.rawValue == "com.museumcompanion.pro.monthly")
        #expect(yearly.rawValue == "com.museumcompanion.pro.yearly")
    }
    
    @Test("Product display names")
    func displayNames() {
        #expect(SubscriptionProduct.monthly.displayName == "Monthly")
        #expect(SubscriptionProduct.yearly.displayName == "Yearly")
    }
    
    @Test("Product pricing display")
    func pricingDisplay() {
        #expect(SubscriptionProduct.monthly.displayPrice == "€2.99/month")
        #expect(SubscriptionProduct.yearly.displayPrice == "€19.99/year")
    }
    
    @Test("Savings text")
    func savingsText() {
        #expect(SubscriptionProduct.monthly.savingsText == nil)
        #expect(SubscriptionProduct.yearly.savingsText == "Save 44%")
    }
    
    @Test("All cases present")
    func allCases() {
        let products = SubscriptionProduct.allCases
        #expect(products.count == 2)
        #expect(products.contains(.monthly))
        #expect(products.contains(.yearly))
    }
}
