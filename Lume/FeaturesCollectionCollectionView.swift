//
//  CollectionView.swift
//  Mona - Art Companion
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
    let onNavigateToCollection: (() -> Void)?
    let onNavigateToScan: (() -> Void)?
    
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var selectedArtworkWrapper: IdentifiableUUID?
    @State private var artworkToDelete: Artwork?
    
    init(onNavigateToCollection: (() -> Void)? = nil, onNavigateToScan: (() -> Void)? = nil) {
        self.onNavigateToCollection = onNavigateToCollection
        self.onNavigateToScan = onNavigateToScan
    }
    
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
                    List {
                        ForEach(Array(filteredArtworks.enumerated()), id: \.element.id) { index, artwork in
                            SwipeableArtworkRow(
                                artwork: artwork,
                                colorScheme: colorScheme,
                                onTap: { selectedArtworkWrapper = IdentifiableUUID(id: artwork.id) },
                                onDelete: { artworkToDelete = artwork },
                                onToggleFavorite: {
                                    Task { await historyManager.toggleFavorite(for: artwork.id) }
                                }
                            )
                            .overlay(alignment: .bottom) {
                                if index < filteredArtworks.count - 1 {
                                    Divider()
                                        .padding(.leading, 24)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .allowsHitTesting(false)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(colorScheme == .dark ? Color.black : Color.white)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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
                    ArtworkDetailView(
                        artwork: artwork,
                        onDismiss: { selectedArtworkWrapper = nil },
                        onNavigateToCollection: onNavigateToCollection,
                        onNavigateToScan: onNavigateToScan
                    )
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
            .confirmationDialog("Are you sure you want to delete?", isPresented: Binding(
                get: { artworkToDelete != nil },
                set: { if !$0 { artworkToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let artwork = artworkToDelete {
                        Task {
                            await historyManager.deleteArtwork(artwork)
                            artworkToDelete = nil
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    artworkToDelete = nil
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

// MARK: - Swipeable Artwork Row
// Uses horizontal ScrollView so vertical List scroll works (horizontal scroll only captures horizontal swipes)

private struct SwipeableArtworkRow: View {
    let artwork: Artwork
    let colorScheme: ColorScheme
    let onTap: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    
    private let swipeRevealWidth: CGFloat = 136
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Row content (tappable)
                    ArtworkRow(artwork: artwork, colorScheme: colorScheme)
                        .frame(width: geometry.size.width)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTap()
                        }
                    
                    // Action buttons (revealed on swipe)
                    HStack(spacing: 12) {
                        Button(action: onToggleFavorite) {
                            Image(systemName: artwork.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundStyle(artwork.isFavorite ? .red : (colorScheme == .dark ? .white : .black))
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .background(Color.red, in: Circle())
                    }
                    .padding(.trailing, 20)
                    .frame(width: swipeRevealWidth, height: 104)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }
            }
        }
        .frame(height: 104)
    }
}

// MARK: - Artwork Row

struct ArtworkRow: View {
    let artwork: Artwork
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Thumbnail - always use user's captured photo
            if let imageData = artwork.capturedImageData ?? artwork.imageData,
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
