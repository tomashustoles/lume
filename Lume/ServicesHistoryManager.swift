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
    private let imagesDirectory: URL
    
    init() {
        // Create directory for storing artwork images
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        imagesDirectory = documentsPath.appendingPathComponent("ArtworkImages", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        
        loadLocalData()
        
        // Migrate existing data if needed (one-time migration)
        migrateIfNeeded()
    }
    
    // MARK: - Migration
    
    private func migrateIfNeeded() {
        // Check if we have artworks with image data still in memory (from old storage)
        // If so, save them to files and update UserDefaults
        let needsMigration = artworks.contains { artwork in
            artwork.imageData != nil || artwork.capturedImageData != nil || artwork.artworkImageData != nil
        }
        
        if needsMigration {
            print("🔄 Migrating artwork images from UserDefaults to file storage...")
            saveLocalData() // This will save images to files and remove from UserDefaults
            print("✅ Migration complete")
        }
    }
    
    // MARK: - Add Artwork
    
    func addArtwork(_ artwork: Artwork) async {
        print("📝 HistoryManager.addArtwork - Adding: '\(artwork.title)' by '\(artwork.artist)' with ID: \(artwork.id)")
        print("📝 Before add - Total artworks: \(artworks.count)")
        print("📝 Artwork has imageData: \(artwork.imageData != nil), description length: \(artwork.description.count)")
        
        artworks.insert(artwork, at: 0)
        
        print("📝 After add - Total artworks: \(artworks.count)")
        print("📝 First artwork in array: '\(artworks.first?.title ?? "none")' with ID: \(artworks.first?.id.uuidString ?? "none")")
        
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
        
        // Delete associated image files
        let imageURL = imageFileURL(for: artwork.id)
        let capturedImageURL = capturedImageFileURL(for: artwork.id)
        let artworkImageURL = artworkImageFileURL(for: artwork.id)
        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: capturedImageURL)
        try? FileManager.default.removeItem(at: artworkImageURL)
        
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
            print("ℹ️ No local artwork data found")
            return
        }
        
        do {
            // Decode artworks without image data
            let loadedArtworksMetadata = try JSONDecoder().decode([Artwork].self, from: data)
            
            // Reconstruct artworks with image data loaded from files
            var loadedArtworks: [Artwork] = []
            
            for artworkMetadata in loadedArtworksMetadata {
                // Load image data from files
                var imageData: Data? = nil
                var capturedImageData: Data? = nil
                var artworkImageData: Data? = nil
                
                let imageURL = imageFileURL(for: artworkMetadata.id)
                if FileManager.default.fileExists(atPath: imageURL.path),
                   let data = try? Data(contentsOf: imageURL) {
                    imageData = data
                }
                
                let capturedImageURL = capturedImageFileURL(for: artworkMetadata.id)
                if FileManager.default.fileExists(atPath: capturedImageURL.path),
                   let data = try? Data(contentsOf: capturedImageURL) {
                    capturedImageData = data
                }
                
                let artworkImgURL = artworkImageFileURL(for: artworkMetadata.id)
                if FileManager.default.fileExists(atPath: artworkImgURL.path),
                   let data = try? Data(contentsOf: artworkImgURL) {
                    artworkImageData = data
                }
                
                // Reconstruct artwork with image data
                let artwork = Artwork(
                    id: artworkMetadata.id,
                    title: artworkMetadata.title,
                    artist: artworkMetadata.artist,
                    year: artworkMetadata.year,
                    movement: artworkMetadata.movement,
                    description: artworkMetadata.description,
                    storyMode: artworkMetadata.storyMode,
                    culturalContext: artworkMetadata.culturalContext,
                    estimatedPeriod: artworkMetadata.estimatedPeriod,
                    frameStyle: artworkMetadata.frameStyle,
                    imageData: imageData,
                    capturedImageData: capturedImageData ?? imageData,
                    artworkImageData: artworkImageData,
                    timestamp: artworkMetadata.timestamp,
                    isFavorite: artworkMetadata.isFavorite
                )
                loadedArtworks.append(artwork)
            }
            
            artworks = loadedArtworks
            print("✅ Loaded \(artworks.count) artworks from local storage")
        } catch {
            print("❌ Failed to load local artworks: \(error)")
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: localStorageKey)
            artworks = []
        }
    }
    
    private func saveLocalData() {
        do {
            // Save image data to files and create artworks without image data for UserDefaults
            var artworksForStorage: [Artwork] = []
            
            for artwork in artworks {
                // Save image data to files
                if let imageData = artwork.imageData {
                    let imageURL = imageFileURL(for: artwork.id)
                    try? imageData.write(to: imageURL)
                }
                if let capturedImageData = artwork.capturedImageData {
                    let capturedImageURL = capturedImageFileURL(for: artwork.id)
                    try? capturedImageData.write(to: capturedImageURL)
                }
                if let artworkImageData = artwork.artworkImageData {
                    let artworkImageURL = artworkImageFileURL(for: artwork.id)
                    try? artworkImageData.write(to: artworkImageURL)
                }
                
                // Create a copy without image data for UserDefaults storage
                let artworkForStorage = Artwork(
                    id: artwork.id,
                    title: artwork.title,
                    artist: artwork.artist,
                    year: artwork.year,
                    movement: artwork.movement,
                    description: artwork.description,
                    storyMode: artwork.storyMode,
                    culturalContext: artwork.culturalContext,
                    estimatedPeriod: artwork.estimatedPeriod,
                    frameStyle: artwork.frameStyle,
                    imageData: nil, // Don't store in UserDefaults
                    capturedImageData: nil, // Don't store in UserDefaults
                    artworkImageData: nil, // Don't store in UserDefaults
                    timestamp: artwork.timestamp,
                    isFavorite: artwork.isFavorite
                )
                artworksForStorage.append(artworkForStorage)
            }
            
            // Save metadata to UserDefaults (without image data)
            let data = try JSONEncoder().encode(artworksForStorage)
            UserDefaults.standard.set(data, forKey: localStorageKey)
            print("✅ Saved \(artworks.count) artworks to local storage (metadata only, images in files)")
        } catch {
            print("❌ Failed to save local artworks: \(error)")
        }
    }
    
    // MARK: - File Storage Helpers
    
    private func imageFileURL(for artworkID: UUID) -> URL {
        return imagesDirectory.appendingPathComponent("\(artworkID.uuidString).jpg")
    }
    
    private func capturedImageFileURL(for artworkID: UUID) -> URL {
        return imagesDirectory.appendingPathComponent("\(artworkID.uuidString)_captured.jpg")
    }
    
    private func artworkImageFileURL(for artworkID: UUID) -> URL {
        return imagesDirectory.appendingPathComponent("\(artworkID.uuidString)_artwork.jpg")
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
        if let artworkImageData = artwork.artworkImageData {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_artwork")
            try? artworkImageData.write(to: tempURL)
            record["artworkImageData"] = CKAsset(fileURL: tempURL)
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
        
        var artworkImageData: Data?
        if let asset = record["artworkImageData"] as? CKAsset,
           let fileURL = asset.fileURL {
            artworkImageData = try? Data(contentsOf: fileURL)
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
            capturedImageData: imageData,
            artworkImageData: artworkImageData,
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
