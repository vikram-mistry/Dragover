import Foundation
import AppKit

/// Action to share items via Mail
struct MailAction: InstantAction {
    let id = "mail"
    let name = "Mail"
    let systemImageName = "envelope.fill"
    
    func execute(items: [ShelfItem]) async throws {
        let urls = items.compactMap { $0.url }
        guard !urls.isEmpty else { throw InstantActionError.noURLs }
        
        await MainActor.run {
            guard let service = NSSharingService(named: .composeEmail) else {
                return
            }
            
            if service.canPerform(withItems: urls) {
                service.perform(withItems: urls)
            }
        }
    }
}
