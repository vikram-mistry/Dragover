import Foundation
import AppKit

/// Action to share items via Messages
struct MessagesAction: InstantAction {
    let id = "messages"
    let name = "Messages"
    let systemImageName = "message.fill"
    
    func execute(items: [ShelfItem]) async throws {
        let urls = items.compactMap { $0.url }
        guard !urls.isEmpty else { throw InstantActionError.noURLs }
        
        await MainActor.run {
            guard let service = NSSharingService(named: .composeMessage) else {
                return
            }
            
            if service.canPerform(withItems: urls) {
                service.perform(withItems: urls)
            }
        }
    }
}
