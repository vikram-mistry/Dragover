import Foundation
import AppKit

/// Action to copy items to clipboard
struct CopyAction: InstantAction {
    let id = "copy"
    let name = "Copy"
    let systemImageName = "doc.on.doc.fill"
    
    func execute(items: [ShelfItem]) async throws {
        guard !items.isEmpty else { throw InstantActionError.noItems }
        
        await MainActor.run {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            
            // Collect all URLs
            let urls = items.compactMap { $0.url }
            if !urls.isEmpty {
                pasteboard.writeObjects(urls as [NSURL])
            }
            
            // Handle text items
            let textItems = items.filter { $0.type == .text }
            if !textItems.isEmpty {
                let combinedText = textItems.compactMap { $0.textContent }.joined(separator: "\n")
                pasteboard.setString(combinedText, forType: .string)
            }
            
            // Handle image items - also copy as images
            let imageItems = items.filter { $0.type == .image }
            for item in imageItems {
                if let url = item.url, let image = NSImage(contentsOf: url) {
                    pasteboard.writeObjects([image])
                }
            }
        }
    }
}
