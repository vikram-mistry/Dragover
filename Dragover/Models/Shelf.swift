import Foundation
import AppKit
import Combine

/// Represents a shelf container that holds multiple items
class Shelf: ObservableObject, Identifiable {
    let id: UUID
    @Published var items: [ShelfItem] = []
    @Published var position: ShelfPosition
    @Published var isExpanded: Bool = true
    var lastActivityDate: Date
    
    private var panel: ShelfPanel?
    
    init(position: ShelfPosition = .bottomRight) {
        self.id = UUID()
        self.position = position
        self.lastActivityDate = Date()
    }
    
    // MARK: - Item Management
    
    func addItem(_ item: ShelfItem) {
        items.append(item)
        lastActivityDate = Date()
    }
    
    func addItems(_ newItems: [ShelfItem]) {
        items.append(contentsOf: newItems)
        lastActivityDate = Date()
    }
    
    func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
        lastActivityDate = Date()
    }
    
    func removeItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
        lastActivityDate = Date()
    }
    
    func clearItems() {
        items.removeAll()
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
    
    var itemCount: Int {
        items.count
    }
    
    // MARK: - Panel Management
    
    func setPanel(_ panel: ShelfPanel) {
        self.panel = panel
    }
    
    func getPanel() -> ShelfPanel? {
        return panel
    }
    
    func show() {
        panel?.orderFront(nil)
    }
    
    func hide() {
        panel?.orderOut(nil)
    }
    
    func close() {
        panel?.close()
        panel = nil
    }
}

/// Position options for shelf placement
enum ShelfPosition: String, CaseIterable, Codable {
    case topLeft = "Top Left"
    case topCenter = "Top Center"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomCenter = "Bottom Center"
    case bottomRight = "Bottom Right"
    case left = "Left"
    case right = "Right"
    
    var isTop: Bool {
        switch self {
        case .topLeft, .topCenter, .topRight:
            return true
        default:
            return false
        }
    }
    
    var isBottom: Bool {
        switch self {
        case .bottomLeft, .bottomCenter, .bottomRight:
            return true
        default:
            return false
        }
    }
    
    func frameOrigin(for shelfSize: NSSize, on screen: NSScreen) -> NSPoint {
        let screenFrame = screen.visibleFrame
        let padding: CGFloat = 20
        
        switch self {
        case .topLeft:
            return NSPoint(
                x: screenFrame.minX + padding,
                y: screenFrame.maxY - shelfSize.height - padding
            )
        case .topCenter:
            return NSPoint(
                x: screenFrame.midX - shelfSize.width / 2,
                y: screenFrame.maxY - shelfSize.height - padding
            )
        case .topRight:
            return NSPoint(
                x: screenFrame.maxX - shelfSize.width - padding,
                y: screenFrame.maxY - shelfSize.height - padding
            )
        case .bottomLeft:
            return NSPoint(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding
            )
        case .bottomCenter:
            return NSPoint(
                x: screenFrame.midX - shelfSize.width / 2,
                y: screenFrame.minY + padding
            )
        case .bottomRight:
            return NSPoint(
                x: screenFrame.maxX - shelfSize.width - padding,
                y: screenFrame.minY + padding
            )
        case .left:
            return NSPoint(
                x: screenFrame.minX + padding,
                y: screenFrame.midY - shelfSize.height / 2
            )
        case .right:
            return NSPoint(
                x: screenFrame.maxX - shelfSize.width - padding,
                y: screenFrame.midY - shelfSize.height / 2
            )
        }
    }
}
