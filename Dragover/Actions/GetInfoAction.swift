import Foundation
import AppKit

/// Action to show file info in Finder
struct GetInfoAction: InstantAction {
    let id = "getinfo"
    let name = "Get Info"
    let systemImageName = "info.circle.fill"
    
    func execute(items: [ShelfItem]) async throws {
        let urls = items.compactMap { $0.url }
        guard !urls.isEmpty else { throw InstantActionError.noURLs }
        
        await MainActor.run {
            for url in urls {
                showGetInfo(for: url)
            }
        }
    }
    
    private func showGetInfo(for url: URL) {
        // Method 1: Use Finder's "Get Info" via Services
        NSWorkspace.shared.activateFileViewerSelecting([url])
        
        // Small delay then send Cmd+I
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Send Cmd+I keystroke to Finder
            let source = CGEventSource(stateID: .hidSystemState)
            
            // Key down
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x22, keyDown: true) { // 'i' key
                keyDown.flags = .maskCommand
                keyDown.post(tap: .cghidEventTap)
            }
            
            // Key up
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x22, keyDown: false) {
                keyUp.flags = .maskCommand
                keyUp.post(tap: .cghidEventTap)
            }
        }
    }
}
