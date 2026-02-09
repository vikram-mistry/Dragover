import Foundation
import AppKit

/// Protocol defining the interface for instant actions
protocol InstantAction: Identifiable {
    var id: String { get }
    var name: String { get }
    var icon: NSImage { get }
    var systemImageName: String { get }
    
    func execute(items: [ShelfItem]) async throws
    func canExecute(items: [ShelfItem]) -> Bool
}

extension InstantAction {
    var icon: NSImage {
        NSImage(systemSymbolName: systemImageName, accessibilityDescription: name) ?? NSImage()
    }
    
    func canExecute(items: [ShelfItem]) -> Bool {
        !items.isEmpty
    }
}

/// Error types for instant actions
enum InstantActionError: LocalizedError {
    case noItems
    case noURLs
    case serviceUnavailable(String)
    case operationFailed(String)
    case fileNotFound(URL)
    
    var errorDescription: String? {
        switch self {
        case .noItems:
            return "No items to process"
        case .noURLs:
            return "No file URLs available"
        case .serviceUnavailable(let service):
            return "\(service) is not available"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        }
    }
}
