//
//  HistoryManager.swift
//  Museum Companion
//
//  Manages artwork history with CloudKit sync
//

import Foundation
import CloudKit
import UIKit
import Combine

@MainActor
class HistoryManager: ObservableObject {
    @Published var artworks: [Artwork] = []
    @Published var isLoading = false
    
    // CloudKit disabled for now to avoid crashes
    private var container: CKContainer? = nil
    
    private let localStorageKey = "savedArtworks"
    
    init() {
        loadLocalData()
    }
    
    // MARK: - Add Artwork
    
    func addArtwork(_ artwork: Artwork) async {
        artworks.insert(artwork, at: 0)
        saveLocalData()
        await syncToCloud(artwork)
    }
    
    // MARK: - Toggle Favorite
    
    func toggleFavorite(for artworkID: UUID) async {
        guard let index = artworks.firstIndex(where: { $0.id == artworkID }) else {
            return
        }
        
        artworks[index].isFavorite.toggle()
        saveLocalData()
        await updateInCloud(artworks[index])
    }
    
    // MARK: - Delete Artwork
    
    func deleteArtwork(_ artwork: Artwork) async {
        artworks.removeAll { $0.id == artwork.id }
        saveLocalData()
        await deleteFromCloud(artwork)
    }
    
    // MARK: - Search
    
    func search(query: String) -> [Artwork] {
        guard !query.isEmpty else {
            return artworks
        }
        
        return artworks.filter { artwork in
            artwork.title.localizedCaseInsensitiveContains(query) ||
            artwork.artist.localizedCaseInsensitiveContains(query) ||
            artwork.movement.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Get Favorites
    
    var favorites: [Artwork] {
        artworks.filter { $0.isFavorite }
    }
    
    // MARK: - Local Persistence
    
    private func loadLocalData() {
        guard let data = UserDefaults.standard.data(forKey: localStorageKey) else {
            return
        }
        
        do {
            artworks = try JSONDecoder().decode([Artwork].self, from: data)
        } catch {
            print("Failed to load local artworks: \(error)")
        }
    }
    
    private func saveLocalData() {
        do {
            let data = try JSONEncoder().encode(artworks)
            UserDefaults.standard.set(data, forKey: localStorageKey)
        } catch {
            print("Failed to save local artworks: \(error)")
        }
    }
    
    // MARK: - CloudKit Sync
    
    func syncFromCloud() async {
        guard let container = container else {
            print("CloudKit not available")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let database = container.privateCloudDatabase
            let query = CKQuery(recordType: "Artwork", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            let results = try await database.records(matching: query)
            var cloudArtworks: [Artwork] = []
            
            for (_, result) in results.matchResults {
                do {
                    let record = try result.get()
                    if let artwork = artworkFromRecord(record) {
                        cloudArtworks.append(artwork)
                    }
                } catch {
                    print("Failed to process record: \(error)")
                }
            }
            
            // Merge with local data
            mergeArtworks(cloudArtworks)
            saveLocalData()
            
        } catch {
            print("Failed to sync from CloudKit: \(error)")
        }
    }
    
    private func syncToCloud(_ artwork: Artwork) async {
        guard let container = container else { return }
        
        do {
            let record = recordFromArtwork(artwork)
            let database = container.privateCloudDatabase
            _ = try await database.save(record)
        } catch {
            print("Failed to sync artwork to CloudKit: \(error)")
        }
    }
    
    private func updateInCloud(_ artwork: Artwork) async {
        await syncToCloud(artwork)
    }
    
    private func deleteFromCloud(_ artwork: Artwork) async {
        guard let container = container else { return }
        
        do {
            let recordID = CKRecord.ID(recordName: artwork.id.uuidString)
            let database = container.privateCloudDatabase
            _ = try await database.deleteRecord(withID: recordID)
        } catch {
            print("Failed to delete artwork from CloudKit: \(error)")
        }
    }
    
    // MARK: - CloudKit Conversion
    
    private func recordFromArtwork(_ artwork: Artwork) -> CKRecord {
        let recordID = CKRecord.ID(recordName: artwork.id.uuidString)
        let record = CKRecord(recordType: "Artwork", recordID: recordID)
        
        record["title"] = artwork.title as CKRecordValue
        record["artist"] = artwork.artist as CKRecordValue
        record["year"] = artwork.year as CKRecordValue
        record["movement"] = artwork.movement as CKRecordValue
        record["description"] = artwork.description as CKRecordValue
        record["storyMode"] = artwork.storyMode as CKRecordValue
        record["culturalContext"] = artwork.culturalContext as CKRecordValue
        record["estimatedPeriod"] = artwork.estimatedPeriod as CKRecordValue
        record["frameStyle"] = artwork.frameStyle.rawValue as CKRecordValue
        record["timestamp"] = artwork.timestamp as CKRecordValue
        record["isFavorite"] = artwork.isFavorite as CKRecordValue
        
        if let imageData = artwork.imageData {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? imageData.write(to: tempURL)
            record["imageData"] = CKAsset(fileURL: tempURL)
        }
        
        return record
    }
    
    private func artworkFromRecord(_ record: CKRecord) -> Artwork? {
        guard
            let title = record["title"] as? String,
            let artist = record["artist"] as? String,
            let year = record["year"] as? String,
            let movement = record["movement"] as? String,
            let description = record["description"] as? String,
            let storyMode = record["storyMode"] as? String,
            let culturalContext = record["culturalContext"] as? String,
            let estimatedPeriod = record["estimatedPeriod"] as? String,
            let frameStyleRaw = record["frameStyle"] as? String,
            let frameStyle = FrameStyle(rawValue: frameStyleRaw),
            let timestamp = record["timestamp"] as? Date
        else {
            return nil
        }
        
        let isFavorite = record["isFavorite"] as? Bool ?? false
        
        var imageData: Data?
        if let asset = record["imageData"] as? CKAsset,
           let fileURL = asset.fileURL {
            imageData = try? Data(contentsOf: fileURL)
        }
        
        guard let idString = record.recordID.recordName.components(separatedBy: "/").last,
              let id = UUID(uuidString: idString) else {
            return nil
        }
        
        return Artwork(
            id: id,
            title: title,
            artist: artist,
            year: year,
            movement: movement,
            description: description,
            storyMode: storyMode,
            culturalContext: culturalContext,
            estimatedPeriod: estimatedPeriod,
            frameStyle: frameStyle,
            imageData: imageData,
            timestamp: timestamp,
            isFavorite: isFavorite
        )
    }
    
    private func mergeArtworks(_ cloudArtworks: [Artwork]) {
        var mergedArtworks = artworks
        
        for cloudArtwork in cloudArtworks {
            if let index = mergedArtworks.firstIndex(where: { $0.id == cloudArtwork.id }) {
                // Update existing
                if cloudArtwork.timestamp > mergedArtworks[index].timestamp {
                    mergedArtworks[index] = cloudArtwork
                }
            } else {
                // Add new
                mergedArtworks.append(cloudArtwork)
            }
        }
        
        // Sort by timestamp
        artworks = mergedArtworks.sorted { $0.timestamp > $1.timestamp }
    }
}
