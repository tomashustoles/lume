//
//  CollectionView.swift
//  Museum Companion
//
//  History and favorites collection view
//

import SwiftUI

// Wrapper to make UUID work with .sheet(item:)
struct IdentifiableUUID: Identifiable {
    let id: UUID
}

struct CollectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var historyManager: HistoryManager
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var selectedArtworkWrapper: IdentifiableUUID?
    
    private var filteredArtworks: [Artwork] {
        let artworks = showFavoritesOnly ? historyManager.favorites : historyManager.artworks
        return searchText.isEmpty ? artworks : historyManager.search(query: searchText)
    }
    
    // Helper to find artwork by ID (searches in all artworks, not just filtered)
    private func findArtwork(by id: UUID) -> Artwork? {
        return historyManager.artworks.first(where: { $0.id == id })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredArtworks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredArtworks) { artwork in
                                ArtworkRow(artwork: artwork, colorScheme: colorScheme)
                                    .onTapGesture {
                                        print("🔵 CollectionView - Tapped artwork: '\(artwork.title)' by '\(artwork.artist)', ID: \(artwork.id)")
                                        print("🔵 Artwork has imageData: \(artwork.imageData != nil), description: '\(artwork.description.prefix(50))...'")
                                        print("🔵 Current historyManager.artworks count: \(historyManager.artworks.count)")
                                        selectedArtworkWrapper = IdentifiableUUID(id: artwork.id)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            Task {
                                                await historyManager.deleteArtwork(artwork)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            Task {
                                                await historyManager.toggleFavorite(for: artwork.id)
                                            }
                                        } label: {
                                            Label(
                                                artwork.isFavorite ? "Unfavorite" : "Favorite",
                                                systemImage: artwork.isFavorite ? "heart.slash" : "heart"
                                            )
                                        }
                                        .tint(.pink)
                                    }
                                
                                if artwork.id != filteredArtworks.last?.id {
                                    Divider()
                                        .padding(.leading, 24)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .refreshable {
                        await historyManager.syncFromCloud()
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .navigationTitle("Collection")
            .searchable(text: $searchText, prompt: "Search artworks...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(showFavoritesOnly ? .red : (colorScheme == .dark ? .white : .black))
                    }
                }
            }
            .sheet(item: $selectedArtworkWrapper) { wrapper in
                // Sheet content is evaluated fresh each time with the latest data
                let artworkID = wrapper.id
                let artwork = findArtwork(by: artworkID)
                
                let _ = print("🔍 CollectionView sheet - Looking for artwork ID: \(artworkID)")
                let _ = print("🔍 Total artworks in manager: \(historyManager.artworks.count)")
                
                if let artwork = artwork {
                    let _ = print("✅ CollectionView sheet - Found artwork: '\(artwork.title)' by '\(artwork.artist)', has imageData: \(artwork.imageData != nil), description length: \(artwork.description.count)")
                    ArtworkDetailView(artwork: artwork) {
                        selectedArtworkWrapper = nil
                    }
                    .environmentObject(historyManager)
                } else {
                    let _ = print("❌ CollectionView sheet - Artwork not found for ID: \(artworkID.uuidString)")
                    // Fallback if artwork not found
                    VStack(spacing: 20) {
                        Text("Artwork Not Found")
                            .font(.headline)
                        Text("ID: \(artworkID.uuidString.prefix(8))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Total artworks: \(historyManager.artworks.count)")
                            .font(.caption)
                        if historyManager.artworks.count > 0 {
                            Text("Available IDs:")
                                .font(.caption2)
                            ForEach(historyManager.artworks.prefix(3)) { art in
                                Text("\(art.id.uuidString.prefix(8))... - \(art.title)")
                                    .font(.caption2)
                            }
                        }
                        Button("Close") {
                            selectedArtworkWrapper = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: showFavoritesOnly ? "heart.slash" : "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(showFavoritesOnly ? "No Favorites Yet" : "No Artworks Yet")
                .font(.custom("NewYork", size: 42))
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text(showFavoritesOnly ? "Start favoriting artworks to build your collection." : "Scan your first artwork to begin your journey.")
                .font(.system(.title3))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Artwork Row

struct ArtworkRow: View {
    let artwork: Artwork
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Thumbnail
            if let imageData = artwork.imageData,
               let uiImage = UIImage(data: imageData) {
                ZStack {
                    Image(uiImage: uiImage.fixedOrientation())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                    
                    RoundedRectangle(
                        cornerRadius: artwork.frameStyle == .modernMinimalist || artwork.frameStyle == .contemporaryGallery ? 2 : 4,
                        style: artwork.frameStyle.cornerStyle
                    )
                    .stroke(artwork.frameStyle.strokeColor, lineWidth: 2)
                }
                .frame(width: 80, height: 80)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(artwork.title)
                        .font(.system(.body, design: .default))
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .lineLimit(2)
                    
                    if artwork.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                
                Text(artwork.artist)
                    .font(.system(.subheadline))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                    .lineLimit(1)
                
                Text(artwork.movement)
                    .font(.system(.caption))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                    .lineLimit(1)
                
                Text(formatDate(artwork.timestamp))
                    .font(.system(.caption2))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    CollectionView()
        .environmentObject(HistoryManager())
}
