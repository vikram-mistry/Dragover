import Foundation
import AppKit

/// Action to share items via AirDrop
struct AirDropAction: InstantAction {
    let id = "airdrop"
    let name = "AirDrop"
    let systemImageName = "airdrop"
    
    var icon: NSImage {
        if let image = NSImage(systemSymbolName: "airdrop", accessibilityDescription: name) {
            return image
        }
        // Fallback to generic share icon if airdrop symbol is missing
        return NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: name) ?? NSImage()
    }
    
    func execute(items: [ShelfItem]) async throws {
        let urls = items.compactMap { $0.url }
        guard !urls.isEmpty else { throw InstantActionError.noURLs }
        
        await MainActor.run {
            guard let service = NSSharingService(named: .sendViaAirDrop) else {
                return
            }
            
            if service.canPerform(withItems: urls) {
                service.perform(withItems: urls)
            }
        }
    }
}
