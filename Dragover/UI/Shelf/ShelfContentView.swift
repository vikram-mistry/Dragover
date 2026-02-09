import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Main SwiftUI view for shelf content with grid layout
struct ShelfContentView: View {
    @ObservedObject var shelf: Shelf
    weak var panel: ShelfPanel?
    
    @State private var selectedItemIds: Set<UUID> = []
    
    // Grid with 4 columns
    private let columns = [
        GridItem(.fixed(90), spacing: 8),
        GridItem(.fixed(90), spacing: 8),
        GridItem(.fixed(90), spacing: 8),
        GridItem(.fixed(90), spacing: 8)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Draggable header bar - full width
            headerView
            
            Divider()
                .padding(.horizontal, 12)
            
            // Items area
            if shelf.items.isEmpty {
                emptyStateView
            } else {
                itemsGridView
            }
            
            // Instant Actions row
            if PreferencesManager.shared.enableInstantActions && !shelf.items.isEmpty {
                Divider()
                    .padding(.horizontal, 12)
                InstantActionsView(items: shelf.items, selectedItemIds: selectedItemIds)
            }
        }
        .frame(minWidth: 420, minHeight: 200)
        .onAppear {
            // Update size on appear
            panel?.updateSize(for: shelf.items.count)
        }
        .onChange(of: shelf.items.count) { newCount in
            panel?.updateSize(for: newCount)
        }
    }
    
    // MARK: - Header (Full width draggable)
    
    private var headerView: some View {
        HStack(spacing: 8) {
            // Drag handle indicator
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Shelf")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(shelf.items.count) items")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Button(action: closeShelf) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle()) // Make entire header area respond to gestures
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    moveWindow(by: value.translation)
                }
        )
    }
    
    private func moveWindow(by translation: CGSize) {
        guard let window = panel else { return }
        let currentOrigin = window.frame.origin
        let newOrigin = NSPoint(
            x: currentOrigin.x + translation.width,
            y: currentOrigin.y - translation.height
        )
        window.setFrameOrigin(newOrigin)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Drop files here")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 100)
    }
    
    // MARK: - Grid View
    
    // MARK: - Grid View
    
    private var itemsGridView: some View {
        ShelfCollectionView(shelf: shelf, selectedItemIds: Binding(
            get: { selectedItemIds },
            set: { selectedItemIds = $0 }
        ))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerQuickLook"))) { _ in
            if let id = selectedItemIds.first, let item = shelf.items.first(where: { $0.id == id }), let url = item.url {
                QuickLookHelper.show(url: url)
            } else if let first = shelf.items.first, let url = first.url {
                 // Default to first item if none selected
                QuickLookHelper.show(url: url)
            }
        }
    }
    
    // MARK: - Actions
    
    private func closeShelf() {
        ShelfManager.shared.removeShelf(shelf)
    }
}

/// Individual grid item view
struct ShelfGridItem: View {
    let item: ShelfItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    let onDoubleClick: () -> Void
    
    @State private var isHovering = false
    @State private var thumbnail: NSImage?
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // Thumbnail/Icon
                thumbnailView
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                
                // Remove button on hover
                if isHovering {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                    }
                    .buttonStyle(.plain)
                    .offset(x: 8, y: -8)
                }
            }
            
            // Label
            Text(item.displayName)
                .font(.system(size: 10))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80, height: 28)
                .foregroundColor(.primary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                onDoubleClick()
            }
        )
        .onAppear {
            loadThumbnail()
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.2)
        } else if isHovering {
            return Color.primary.opacity(0.08)
        }
        return Color.clear
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail = thumbnail {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let url = item.url {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(4)
        } else {
            Image(systemName: "doc.fill")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        if let url = item.url {
            Button("Open") {
                NSWorkspace.shared.open(url)
            }
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
            }
            Button("Quick Look") {
                QuickLookHelper.show(url: url)
            }
            Divider()
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([url as NSURL])
            }
        }
        Divider()
        Button("Remove", role: .destructive) {
            onRemove()
        }
    }
    
    private func loadThumbnail() {
        guard let url = item.url else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
            guard imageExtensions.contains(url.pathExtension.lowercased()),
                  let image = NSImage(contentsOf: url) else { return }
            
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}
