//
//  ArtworkDetailView.swift
//  Museum Companion
//
//  Detailed view of recognized artwork with Info/Story modes
//

import SwiftUI

struct ArtworkDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let artwork: Artwork
    let onDismiss: () -> Void
    let onNavigateToCollection: (() -> Void)?
    
    @EnvironmentObject var historyManager: HistoryManager
    @State private var isFavorite: Bool
    @State private var displayImage: UIImage?
    @State private var showDeleteConfirmation = false
    
    init(artwork: Artwork, onDismiss: @escaping () -> Void, onNavigateToCollection: (() -> Void)? = nil) {
        self.artwork = artwork
        self.onDismiss = onDismiss
        self.onNavigateToCollection = onNavigateToCollection
        _isFavorite = State(initialValue: artwork.isFavorite)
    }
    
    var body: some View {
        let _ = print("🎨 ArtworkDetailView rendering - Title: '\(artwork.title)', Artist: '\(artwork.artist)', ImageData exists: \(artwork.imageData != nil), DisplayImage exists: \(displayImage != nil)")
        
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Artwork image with gradient and title/artist overlay (starts at very top)
                    artworkImage
                    // Content below image
                    VStack(alignment: .leading, spacing: 24) {
                        // Metadata (Year, Movement)
                        metadataSection
                            .padding(.top, 24)
                        
                        Divider()
                        
                        // Info description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ABOUT")
                                .font(.system(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                                .tracking(1)
                            
                            Text(artwork.description)
                                .font(.system(.title3))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                                .lineSpacing(6)
                        }
                        
                        Divider()
                        
                        // Story
                        VStack(alignment: .leading, spacing: 12) {
                            Text("STORY")
                                .font(.system(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                                .tracking(1)
                            
                            Text(artwork.storyMode)
                                .font(.system(.title3))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                                .lineSpacing(6)
                                .italic()
                        }
                        
                        Divider()
                        
                        // Cultural Context
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CULTURAL CONTEXT")
                                .font(.system(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                                .tracking(1)
                            
                            Text(artwork.culturalContext)
                                .font(.system(.title3))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                                .lineSpacing(6)
                        }
                        
                        // Navigation options
                        VStack(spacing: 12) {
                            // Scanned images button - navigates to Collection tab
                            Button {
                                onDismiss() // Dismiss the sheet first
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onNavigateToCollection?() // Then switch to Collection tab
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "photo.stack")
                                        .font(.system(.title3))
                                    Text("Scanned Images")
                                        .font(.system(.body))
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(.caption))
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding()
                                .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                .cornerRadius(12)
                            }
                            
                            // Next artwork button (return to camera)
                            Button {
                                onDismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "camera")
                                        .font(.system(.title3))
                                    Text("Scan Next Artwork")
                                        .font(.system(.body))
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(.caption))
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding()
                                .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                .cornerRadius(12)
                            }
                            
                            // Delete recognized artwork
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(.title3))
                                    Text("Delete recognized artwork")
                                        .font(.system(.body))
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(.caption))
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
                                }
                                .foregroundColor(Color.red)
                                .padding()
                                .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .symbolRenderingMode(.hierarchical)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isFavorite.toggle()
                        Task {
                            await historyManager.toggleFavorite(for: artwork.id)
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(isFavorite ? .red : .white)
                            .symbolRenderingMode(.hierarchical)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .confirmationDialog("Are you sure you want to delete?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await historyManager.deleteArtwork(artwork)
                    onDismiss()
                }
            }
            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = false
            }
        }
        .task(id: artwork.id) {
            // Load the image from artwork.imageData (which already contains the correct image
            // - either the fetched original painting if it matched, or the captured image if it didn't)
            if let imageData = artwork.imageData, let image = UIImage(data: imageData) {
                displayImage = image.fixedOrientation()
                print("✅ Loaded image from artwork.imageData for: \(artwork.title)")
            } else if let capturedData = artwork.capturedImageData, let image = UIImage(data: capturedData) {
                // Fallback to captured image if imageData is not available
                displayImage = image.fixedOrientation()
                print("✅ Loaded captured image as fallback for: \(artwork.title)")
            } else {
                print("⚠️ No image data available for: \(artwork.title)")
            }
        }
    }
    
    // MARK: - Artwork Image
    
    private var artworkImage: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            
            ZStack(alignment: .bottomLeading) {
                // Show artwork image, with a loading placeholder while fetching
                if let uiImage = displayImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: width)
                        .clipped()
                        .transition(.opacity.animation(.easeIn(duration: 0.4)))
                } else {
                    // Placeholder when no image is available
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: width, height: width)
                        .overlay {
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                        }
                }
                
                // Bottom gradient overlay for text readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: width, height: width)
                
                // Title and artist at bottom over gradient
                VStack(alignment: .leading, spacing: 6) {
                    Text(artwork.title)
                        .font(.custom("NewYork", size: 34))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(artwork.artist)
                        .font(.system(.title3))
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(width: width, height: width)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YEAR")
                    .font(.system(.caption))
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                    .tracking(1)
                
                Text(artwork.year)
                    .font(.system(.body))
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("MOVEMENT")
                    .font(.system(.caption))
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                    .tracking(1)
                
                Text(artwork.movement)
                    .font(.system(.body))
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            
            Spacer()
        }
    }
}

// MARK: - Metadata Item

struct MetadataItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(.caption, design: .default))
                .fontWeight(.medium)
                .foregroundColor(.black.opacity(0.5))
                .tracking(1)
            
            Text(value)
                .font(.system(.body))
                .foregroundColor(.black)
        }
    }
}

#Preview {
    ArtworkDetailView(
        artwork: Artwork(
            title: "Starry Night",
            artist: "Vincent van Gogh",
            year: "1889",
            movement: "Post-Impressionism",
            description: "A swirling night sky over a French village with a prominent cypress tree.",
            storyMode: "Under the vast cosmos, Van Gogh painted his longing for connection. Each swirling star represents a dream, each curve a prayer. This is not just a night sky—it's the artist's soul laid bare.",
            culturalContext: "Created during Van Gogh's stay at an asylum, this masterpiece captures both his turbulent mental state and his extraordinary vision.",
            estimatedPeriod: "Modern",
            frameStyle: .modernMinimalist
        ),
        onDismiss: {}
    )
    .environmentObject(HistoryManager())
}
