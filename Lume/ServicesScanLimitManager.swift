//
//  ScanLimitManager.swift
//  Museum Companion
//
//  Manages daily scan limits with iCloud sync
//  Protects against clock changes and ensures fair usage
//

import Foundation
import CloudKit
import Combine

@MainActor
class ScanLimitManager: ObservableObject {
    @Published var scansRemaining: Int = 3
    @Published var lastResetDate: Date = Date()
    @Published var showLimitReached = false
    
    // CloudKit disabled for now to avoid crashes
    private var container: CKContainer? = nil
    
    private let freeScanLimit = 3
    private var cloudKitAvailable = false
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let scansRemaining = "scansRemaining"
        static let lastResetDate = "lastResetDate"
        static let firstLaunchDate = "firstLaunchDate"
        static let totalScansEver = "totalScansEver"
        static let lastKnownSystemUptime = "lastKnownSystemUptime"
    }
    
    init() {
        loadLocalData()
        // CloudKit disabled - using local storage only
        print("ScanLimitManager initialized with local storage")
    }
    
    private func checkCloudKitAvailability() {
        // CloudKit disabled for now
        cloudKitAvailable = false
    }
    
    // MARK: - Check Daily Reset
    
    func checkDailyReset() async {
        // Protect against manual clock changes
        let isClockManipulated = detectClockManipulation()
        
        if isClockManipulated {
            print("⚠️ Clock manipulation detected. Maintaining current scan limits.")
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we're in a new day
        if !calendar.isDate(lastResetDate, inSameDayAs: now) {
            // Verify we're actually moving forward in time
            if now > lastResetDate {
                // New day - reset scans
                scansRemaining = freeScanLimit
                lastResetDate = now
                saveLocalData()
                
                if cloudKitAvailable {
                    await syncToCloud()
                }
                
                print("✅ Daily scan limit reset. \(scansRemaining) scans available.")
            } else {
                print("⚠️ Time moved backward. Not resetting scan limit.")
            }
        } else if cloudKitAvailable {
            // Same day - try to sync from cloud
            await syncFromCloud()
        }
        
        // Update system uptime reference
        updateSystemUptimeReference()
    }
    
    // MARK: - Use Scan
    
    func useScan() async -> Bool {
        // Always check for daily reset first
        await checkDailyReset()
        
        guard scansRemaining > 0 else {
            showLimitReached = true
            return false
        }
        
        scansRemaining -= 1
        
        // Track total scans for analytics
        let totalScans = UserDefaults.standard.integer(forKey: Keys.totalScansEver)
        UserDefaults.standard.set(totalScans + 1, forKey: Keys.totalScansEver)
        
        saveLocalData()
        
        if cloudKitAvailable {
            await syncToCloud()
        }
        
        // Show soft notification after 3rd scan
        if scansRemaining == 0 {
            showLimitReached = true
        }
        
        return true
    }
    
    // MARK: - Reset for Pro User
    
    func resetForProUser() {
        scansRemaining = .max
        saveLocalData()
        showLimitReached = false
    }
    
    // MARK: - Check if User Can Scan
    
    func canScan(isProUser: Bool) async -> Bool {
        if isProUser {
            return true
        }
        
        // Check for daily reset
        await checkDailyReset()
        
        return scansRemaining > 0
    }
    
    // MARK: - Get Time Until Reset
    
    func timeUntilReset() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: lastResetDate),
              let startOfTomorrow = calendar.startOfDay(for: tomorrow) as Date? else {
            return 0
        }
        
        return startOfTomorrow.timeIntervalSince(now)
    }
    
    // MARK: - Clock Manipulation Detection
    
    private func detectClockManipulation() -> Bool {
        // Use system uptime as a reference
        let currentUptime = ProcessInfo.processInfo.systemUptime
        let lastUptime = UserDefaults.standard.double(forKey: Keys.lastKnownSystemUptime)
        
        // If there's no previous uptime recorded, can't detect manipulation
        if lastUptime == 0 {
            return false
        }
        
        // If uptime decreased, system was rebooted, which is fine
        if currentUptime < lastUptime {
            return false
        }
        
        // Calculate expected elapsed time
        let uptimeDifference = currentUptime - lastUptime
        
        // Calculate actual elapsed time
        let now = Date()
        let actualTimeDifference = now.timeIntervalSince(lastResetDate)
        
        // If actual time difference is negative or significantly different from uptime difference,
        // the clock may have been changed (allow 5 minute tolerance for clock drift)
        let tolerance: TimeInterval = 300 // 5 minutes
        let timeDifference = abs(actualTimeDifference - uptimeDifference)
        
        return actualTimeDifference >= 0 && timeDifference > tolerance
    }
    
    private func updateSystemUptimeReference() {
        let currentUptime = ProcessInfo.processInfo.systemUptime
        UserDefaults.standard.set(currentUptime, forKey: Keys.lastKnownSystemUptime)
    }
    
    // MARK: - Local Persistence
    
    private func loadLocalData() {
        // Load scan count
        let savedScans = UserDefaults.standard.integer(forKey: Keys.scansRemaining)
        scansRemaining = savedScans > 0 ? savedScans : freeScanLimit
        
        // Load last reset date
        if let savedDate = UserDefaults.standard.object(forKey: Keys.lastResetDate) as? Date {
            lastResetDate = savedDate
        } else {
            // First launch - set to start of today
            let calendar = Calendar.current
            lastResetDate = calendar.startOfDay(for: Date())
            UserDefaults.standard.set(lastResetDate, forKey: Keys.lastResetDate)
        }
        
        // Initialize first launch date if needed
        if UserDefaults.standard.object(forKey: Keys.firstLaunchDate) == nil {
            UserDefaults.standard.set(Date(), forKey: Keys.firstLaunchDate)
        }
        
        // Initialize system uptime reference
        updateSystemUptimeReference()
    }
    
    private func saveLocalData() {
        UserDefaults.standard.set(scansRemaining, forKey: Keys.scansRemaining)
        UserDefaults.standard.set(lastResetDate, forKey: Keys.lastResetDate)
        updateSystemUptimeReference()
    }
    
    // MARK: - iCloud Sync
    
    private func syncToCloud() async {
        guard let container = container else { return }
        
        do {
            let recordID = CKRecord.ID(recordName: "ScanLimitRecord")
            let record = CKRecord(recordType: "ScanLimit", recordID: recordID)
            record["scansRemaining"] = scansRemaining as CKRecordValue
            record["lastResetDate"] = lastResetDate as CKRecordValue
            
            let database = container.privateCloudDatabase
            _ = try await database.save(record)
        } catch {
            print("Failed to sync to iCloud: \(error)")
        }
    }
    
    private func syncFromCloud() async {
        guard let container = container else { return }
        
        do {
            let recordID = CKRecord.ID(recordName: "ScanLimitRecord")
            let database = container.privateCloudDatabase
            
            let record = try await database.record(for: recordID)
            
            if let cloudScansRemaining = record["scansRemaining"] as? Int,
               let cloudLastResetDate = record["lastResetDate"] as? Date {
                
                // Use the most restrictive value (lower scan count)
                // This prevents users from gaining extra scans by syncing from an old device
                if cloudScansRemaining < scansRemaining {
                    scansRemaining = cloudScansRemaining
                    lastResetDate = cloudLastResetDate
                    saveLocalData()
                }
            }
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet - create it
            await syncToCloud()
        } catch {
            print("Failed to sync from iCloud: \(error)")
        }
    }
    
    // MARK: - Analytics & Debugging
    
    func getUsageStats() -> (totalScans: Int, firstLaunchDate: Date?, daysUsed: Int) {
        let totalScans = UserDefaults.standard.integer(forKey: Keys.totalScansEver)
        let firstLaunch = UserDefaults.standard.object(forKey: Keys.firstLaunchDate) as? Date
        
        var daysUsed = 0
        if let firstLaunch = firstLaunch {
            let calendar = Calendar.current
            daysUsed = calendar.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        }
        
        return (totalScans, firstLaunch, daysUsed)
    }
}
