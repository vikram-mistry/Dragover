import SwiftUI
import AppKit

/// View for individual items in the shelf
struct ShelfItemView: View {
    let item: ShelfItem
    let onRemove: () -> Void
    let onDoubleClick: () -> Void
    
    @State private var isHovering = false
    @State private var clickCount = 0
    @State private var clickTimer: Timer?
    @State private var loadedThumbnail: NSImage?
    
    var body: some View {
        VStack(spacing: 4) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                thumbnailView
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                
                // Remove button on hover
                if isHovering {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white, .red)
                    }
                    .buttonStyle(.plain)
                    .offset(x: 6, y: -6)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Label
            Text(item.displayName)
                .font(.system(size: 9))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 56)
                .foregroundColor(.primary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.primary.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            handleClick()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onAppear {
            loadThumbnail()
        }
    }
    
    // MARK: - Thumbnail View
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail = loadedThumbnail ?? item.thumbnail {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            iconView
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        switch item.type {
        case .file, .folder:
            if let url = item.url {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "doc")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
        case .image:
            if let url = item.url {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
        case .text:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.2))
                
                Image(systemName: "doc.text")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Thumbnail Loading
    
    private func loadThumbnail() {
        guard let url = item.url else { return }
        
        // Load thumbnail asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            var nsImage: NSImage?
            
            // Check if it's an image file
            let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
            if imageExtensions.contains(url.pathExtension.lowercased()) {
                nsImage = NSImage(contentsOf: url)
            }
            
            // If we got an image, scale it down for display
            if let image = nsImage {
                let scaledImage = resizeImage(image, to: NSSize(width: 96, height: 96))
                DispatchQueue.main.async {
                    self.loadedThumbnail = scaledImage
                }
            }
        }
    }
    
    private func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
    
    // MARK: - Click Handling
    
    private func handleClick() {
        clickCount += 1
        
        clickTimer?.invalidate()
        clickTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            if clickCount >= 2 {
                onDoubleClick()
            }
            clickCount = 0
        }
    }
}
