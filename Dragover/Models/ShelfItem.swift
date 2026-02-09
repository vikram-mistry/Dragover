import Foundation
import AppKit

/// Represents an item stored in a shelf
struct ShelfItem: Identifiable, Equatable {
    let id: UUID
    let type: ItemType
    let url: URL?
    let textContent: String?
    var thumbnail: NSImage?
    let createdAt: Date
    
    enum ItemType: String, Codable {
        case file
        case folder
        case image
        case text
    }
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.textContent = nil
        self.createdAt = Date()
        
        // Determine type based on URL
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        if isDirectory.boolValue {
            self.type = .folder
        } else if Self.isImageFile(url: url) {
            self.type = .image
        } else {
            self.type = .file
        }
        
        self.thumbnail = Self.generateThumbnail(for: url, type: self.type)
    }
    
    init(text: String) {
        self.id = UUID()
        self.type = .text
        self.url = nil
        self.textContent = text
        self.createdAt = Date()
        self.thumbnail = nil
    }
    
    // MARK: - Helpers
    
    private static func isImageFile(url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
    
    private static func generateThumbnail(for url: URL, type: ItemType) -> NSImage? {
        switch type {
        case .folder:
            return nil // Let cell load system icon
        case .image:
            return nil // Let cell load async
        case .file:
            return nil // Let cell load system icon
        case .text:
            return NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Text")
        }
    }
    
    var displayName: String {
        if let url = url {
            return url.lastPathComponent
        } else if let text = textContent {
            return String(text.prefix(50)) + (text.count > 50 ? "..." : "")
        }
        return "Unknown Item"
    }
    
    static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - NSImage Extension

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
