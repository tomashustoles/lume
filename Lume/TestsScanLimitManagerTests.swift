//
//  ScanLimitManagerTests.swift
//  Museum Companion Tests
//
//  Unit tests for ScanLimitManager
//

import Testing
import Foundation
@testable import Lume

@Suite("Scan Limit Manager Tests")
struct ScanLimitManagerTests {
    
    @Test("Initialize scan limit manager")
    @MainActor
    func initializeManager() async throws {
        let manager = ScanLimitManager()
        
        #expect(manager.scansRemaining == 3, "Should start with 3 scans")
        #expect(!manager.showLimitReached, "Limit notification should not be shown")
    }
    
    @Test("Use scan decrements counter")
    @MainActor
    func useScan() async throws {
        let manager = ScanLimitManager()
        
        // First scan
        let result1 = await manager.useScan()
        #expect(result1 == true, "First scan should succeed")
        #expect(manager.scansRemaining == 2, "Should have 2 scans remaining")
        
        // Second scan
        let result2 = await manager.useScan()
        #expect(result2 == true, "Second scan should succeed")
        #expect(manager.scansRemaining == 1, "Should have 1 scan remaining")
        
        // Third scan
        let result3 = await manager.useScan()
        #expect(result3 == true, "Third scan should succeed")
        #expect(manager.scansRemaining == 0, "Should have 0 scans remaining")
        #expect(manager.showLimitReached == true, "Limit notification should be shown")
        
        // Fourth scan should fail
        let result4 = await manager.useScan()
        #expect(result4 == false, "Fourth scan should fail")
        #expect(manager.scansRemaining == 0, "Should still have 0 scans remaining")
    }
    
    @Test("Pro user reset")
    @MainActor
    func proUserReset() async throws {
        let manager = ScanLimitManager()
        
        // Use all scans
        _ = await manager.useScan()
        _ = await manager.useScan()
        _ = await manager.useScan()
        
        #expect(manager.scansRemaining == 0)
        
        // Reset for pro user
        manager.resetForProUser()
        
        #expect(manager.scansRemaining == Int.max, "Pro users should have unlimited scans")
        #expect(manager.showLimitReached == false, "Limit notification should be hidden")
    }
    
    @Test("Can scan check for free user")
    @MainActor
    func canScanFreeUser() async throws {
        let manager = ScanLimitManager()
        
        // Free user with scans remaining
        let canScan1 = await manager.canScan(isProUser: false)
        #expect(canScan1 == true, "Free user with scans should be able to scan")
        
        // Use all scans
        _ = await manager.useScan()
        _ = await manager.useScan()
        _ = await manager.useScan()
        
        // Free user with no scans remaining
        let canScan2 = await manager.canScan(isProUser: false)
        #expect(canScan2 == false, "Free user without scans should not be able to scan")
    }
    
    @Test("Can scan check for pro user")
    @MainActor
    func canScanProUser() async throws {
        let manager = ScanLimitManager()
        
        // Use all scans
        _ = await manager.useScan()
        _ = await manager.useScan()
        _ = await manager.useScan()
        
        #expect(manager.scansRemaining == 0)
        
        // Pro user should always be able to scan
        let canScan = await manager.canScan(isProUser: true)
        #expect(canScan == true, "Pro user should always be able to scan")
    }
    
    @Test("Time until reset calculation")
    @MainActor
    func timeUntilReset() async throws {
        let manager = ScanLimitManager()
        
        let timeRemaining = manager.timeUntilReset()
        
        // Should be less than 24 hours
        #expect(timeRemaining > 0, "Time until reset should be positive")
        #expect(timeRemaining <= 86400, "Time until reset should be less than 24 hours")
    }
    
    @Test("Usage stats tracking")
    @MainActor
    func usageStats() async throws {
        let manager = ScanLimitManager()
        
        // Use some scans
        _ = await manager.useScan()
        _ = await manager.useScan()
        
        let stats = manager.getUsageStats()
        
        #expect(stats.totalScans >= 2, "Should track total scans")
        #expect(stats.firstLaunchDate != nil, "Should track first launch date")
        #expect(stats.daysUsed >= 0, "Days used should be non-negative")
    }
    
    @Test("Daily reset logic")
    @MainActor
    func dailyReset() async throws {
        let manager = ScanLimitManager()
        
        // Use all scans
        _ = await manager.useScan()
        _ = await manager.useScan()
        _ = await manager.useScan()
        
        #expect(manager.scansRemaining == 0)
        
        // Check daily reset (should not reset on same day)
        await manager.checkDailyReset()
        #expect(manager.scansRemaining == 0, "Should not reset on same day")
        
        // Note: Testing actual day change is difficult without mocking Date
        // In production, this would reset after midnight
    }
}
