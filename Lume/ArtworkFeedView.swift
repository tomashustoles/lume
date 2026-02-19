//
//  ArtworkFeedView.swift
//  Lume
//
//  Shows scanned artworks in a vertical feed
//

import SwiftUI

struct ArtworkFeedView: View {
    @EnvironmentObject var historyManager: HistoryManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if historyManager.artworks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 32) {
                            ForEach(historyManager.artworks) { artwork in
                                ArtworkCard(artwork: artwork)
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Scanned Artworks")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Artworks Yet")
                .font(.custom("NewYork", size: 28))
                .fontWeight(.semibold)
            
            Text("Scan your first artwork to begin your collection")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct ArtworkCard: View {
    let artwork: Artwork
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Image - use user's captured photo
            if let imageData = artwork.capturedImageData ?? artwork.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage.fixedOrientation())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(8)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(artwork.title)
                    .font(.custom("NewYork", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text(artwork.artist)
                    .font(.system(.title3))
                    .foregroundColor(.black.opacity(0.7))
                
                Text(artwork.year + " • " + artwork.movement)
                    .font(.system(.subheadline))
                    .foregroundColor(.black.opacity(0.5))
                
                Text(artwork.description)
                    .font(.system(.body))
                    .foregroundColor(.black.opacity(0.8))
                    .lineLimit(3)
                    .padding(.top, 8)
            }
            
            // Timestamp
            Text(formatDate(artwork.timestamp))
                .font(.system(.caption))
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ArtworkFeedView()
        .environmentObject(HistoryManager())
}
