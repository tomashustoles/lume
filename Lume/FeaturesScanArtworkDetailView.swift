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
    let onNavigateToScan: (() -> Void)?
    
    @EnvironmentObject var historyManager: HistoryManager
    @State private var isFavorite: Bool
    @State private var displayImage: UIImage?
    @State private var fetchedArtworkImage: UIImage?
    @State private var showArtworkZoom = false
    @State private var showDeleteConfirmation = false
    
    init(artwork: Artwork, onDismiss: @escaping () -> Void, onNavigateToCollection: (() -> Void)? = nil, onNavigateToScan: (() -> Void)? = nil) {
        self.artwork = artwork
        self.onDismiss = onDismiss
        self.onNavigateToCollection = onNavigateToCollection
        self.onNavigateToScan = onNavigateToScan
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
                            
                            aboutDescriptionWithArtwork
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
                            
                            // Scan Next Artwork - navigate to Scan tab
                            Button {
                                onDismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onNavigateToScan?()
                                }
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
        .fullScreenCover(isPresented: $showArtworkZoom) {
            if let uiImage = fetchedArtworkImage {
                ArtworkZoomView(image: uiImage, onDismiss: { showArtworkZoom = false })
            }
        }
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
            // Hero/thumbnail: always use user's captured photo
            if let capturedData = artwork.capturedImageData, let image = UIImage(data: capturedData) {
                displayImage = image.fixedOrientation()
            } else if let imageData = artwork.imageData, let image = UIImage(data: imageData) {
                displayImage = image.fixedOrientation()
            } else {
                displayImage = nil
            }
            // Artwork image for content section (fetched original when available)
            if let artworkData = artwork.artworkImageData, let image = UIImage(data: artworkData) {
                fetchedArtworkImage = image.fixedOrientation()
            } else {
                fetchedArtworkImage = nil
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
    
    // MARK: - About Description with Artwork
    
    private var aboutDescriptionWithArtwork: some View {
        let paragraphs = artwork.description.components(separatedBy: "\n\n")
        let firstParagraph = paragraphs.first ?? artwork.description
        let restParagraphs = paragraphs.count > 1 ? paragraphs.dropFirst().joined(separator: "\n\n") : ""
        
        return VStack(alignment: .leading, spacing: 16) {
            Text(firstParagraph)
                .font(.system(.title3))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                .lineSpacing(6)
            
            // Show artwork at end of first paragraph when we have the fetched original
            if let uiImage = fetchedArtworkImage {
                Button {
                    showArtworkZoom = true
                } label: {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                        )
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                                .padding(12)
                        }
                }
                .buttonStyle(.plain)
            }
            
            if !restParagraphs.isEmpty {
                Text(restParagraphs)
                    .font(.system(.title3))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                    .lineSpacing(6)
            }
        }
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

// MARK: - Artwork Zoom View

struct ArtworkZoomView: View {
    let image: UIImage
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale < 1 { withAnimation { scale = 1; lastScale = 1 } }
                            if scale > 4 { scale = 4; lastScale = 4 }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.9))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .padding(24)
                }
                Spacer()
            }
        }
        .onTapGesture(count: 2) {
            withAnimation {
                if scale > 1 {
                    scale = 1
                    lastScale = 1
                    offset = .zero
                    lastOffset = .zero
                } else {
                    scale = 2
                    lastScale = 2
                }
            }
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
