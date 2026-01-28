//
//  CollectionView.swift
//  Museum Companion
//
//  History and favorites collection view
//

import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var historyManager: HistoryManager
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var selectedArtwork: Artwork?
    @State private var showDetail = false
    
    private var filteredArtworks: [Artwork] {
        let artworks = showFavoritesOnly ? historyManager.favorites : historyManager.artworks
        return searchText.isEmpty ? artworks : historyManager.search(query: searchText)
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
                                ArtworkRow(artwork: artwork)
                                    .onTapGesture {
                                        selectedArtwork = artwork
                                        showDetail = true
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
            .background(Color.white)
            .navigationTitle("Collection")
            .searchable(text: $searchText, prompt: "Search artworks...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(showFavoritesOnly ? .red : .black)
                    }
                }
            }
            .sheet(isPresented: $showDetail) {
                if let artwork = selectedArtwork {
                    ArtworkDetailView(artwork: artwork) {
                        showDetail = false
                        selectedArtwork = nil
                    }
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
                .font(.custom("NewYork", size: 28))
                .fontWeight(.semibold)
                .foregroundColor(.black)
            
            Text(showFavoritesOnly ? "Start favoriting artworks to build your collection." : "Scan your first artwork to begin your journey.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Artwork Row

struct ArtworkRow: View {
    let artwork: Artwork
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Thumbnail
            if let imageData = artwork.imageData,
               let uiImage = UIImage(data: imageData) {
                ZStack {
                    Image(uiImage: uiImage)
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
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
                    if artwork.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                
                Text(artwork.artist)
                    .font(.system(.subheadline))
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(1)
                
                Text(artwork.movement)
                    .font(.system(.caption))
                    .foregroundColor(.black.opacity(0.5))
                    .lineLimit(1)
                
                Text(formatDate(artwork.timestamp))
                    .font(.system(.caption2))
                    .foregroundColor(.black.opacity(0.4))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.3))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white)
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
