import Foundation
import AppKit
import Combine

/// Central manager for all shelf instances
class ShelfManager: ObservableObject {
    static let shared = ShelfManager()
    
    @Published private(set) var shelves: [Shelf] = []
    private var retractTimers: [UUID: Timer] = [:]
    private var preferencesObserver: NSObjectProtocol?
    
    private init() {
        setupAutoRetract()
    }
    
    // MARK: - Shelf Lifecycle
    
    /// Creates a new shelf at the specified position
    @discardableResult
    func createShelf(at position: ShelfPosition, on screen: NSScreen? = nil) -> Shelf {
        let shelf = Shelf(position: position)
        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first!
        
        let panel = ShelfPanel(shelf: shelf, screen: targetScreen)
        shelf.setPanel(panel)
        
        shelves.append(shelf)
        
        // Animate in
        panel.animateIn()
        
        // Setup auto-retract if enabled
        if PreferencesManager.shared.autoRetract {
            scheduleRetract(for: shelf)
        }
        
        return shelf
    }
    
    /// Creates a shelf near the current cursor position
    @discardableResult
    func createShelfAtCursor() -> Shelf {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main!
        
        let position = determinePosition(from: mouseLocation, on: screen)
        return createShelf(at: position, on: screen)
    }
    
    /// Creates a shelf with clipboard contents near cursor
    @discardableResult
    func createShelfFromClipboard(at point: NSPoint) -> Shelf? {
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main!
        let position = determinePosition(from: point, on: screen)
        
        // Check clipboard for files
        let pasteboard = NSPasteboard.general
        guard let items = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !items.isEmpty else {
            return nil
        }
        
        let shelf = createShelf(at: position, on: screen)
        addURLs(items, toShelfId: shelf.id)
        return shelf
    }
    
    private func determinePosition(from point: NSPoint, on screen: NSScreen) -> ShelfPosition {
        let screenFrame = screen.frame
        let relativeX = (point.x - screenFrame.minX) / screenFrame.width
        let relativeY = (point.y - screenFrame.minY) / screenFrame.height
        
        if relativeY > 0.7 {
            return relativeX < 0.5 ? .topLeft : .topRight
        } else if relativeY < 0.3 {
            return relativeX < 0.5 ? .bottomLeft : .bottomRight
        } else {
            return relativeX < 0.5 ? .left : .right
        }
    }
    
    /// Removes a shelf
    func removeShelf(_ shelf: Shelf) {
        retractTimers[shelf.id]?.invalidate()
        retractTimers.removeValue(forKey: shelf.id)
        
        shelf.getPanel()?.animateOut { [weak self] in
            shelf.close()
            self?.shelves.removeAll { $0.id == shelf.id }
        }
    }
    
    /// Removes all empty shelves
    func removeEmptyShelves() {
        let emptyShelves = shelves.filter { $0.isEmpty }
        emptyShelves.forEach { removeShelf($0) }
    }
    
    /// Gets or creates the active shelf
    func getOrCreateActiveShelf() -> Shelf {
        if let existingShelf = shelves.first(where: { !$0.isEmpty }) {
            return existingShelf
        }
        return createShelf(at: PreferencesManager.shared.defaultShelfPosition)
    }
    
    // MARK: - Item Management
    
    /// Adds items to the active shelf or creates a new one
    func addItems(_ items: [ShelfItem], toShelfId shelfId: UUID? = nil) {
        let shelf: Shelf
        
        if let id = shelfId, let existingShelf = shelves.first(where: { $0.id == id }) {
            shelf = existingShelf
        } else {
            shelf = getOrCreateActiveShelf()
        }
        
        shelf.addItems(items)
        resetRetractTimer(for: shelf)
    }
    
    /// Adds URLs by creating ShelfItems
    func addURLs(_ urls: [URL], toShelfId shelfId: UUID? = nil) {
        let items = urls.map { ShelfItem(url: $0) }
        addItems(items, toShelfId: shelfId)
    }
    
    // MARK: - Auto-Retract
    
    private func setupAutoRetract() {
        // Observe UserDefaults changes for autoRetract
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePreferencesChange()
        }
    }
    
    private func handlePreferencesChange() {
        let enabled = PreferencesManager.shared.autoRetract
        if enabled {
            shelves.forEach { scheduleRetract(for: $0) }
        } else {
            retractTimers.values.forEach { $0.invalidate() }
            retractTimers.removeAll()
        }
    }
    
    private func scheduleRetract(for shelf: Shelf) {
        retractTimers[shelf.id]?.invalidate()
        
        let delay = PreferencesManager.shared.autoRetractDelay
        retractTimers[shelf.id] = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            if shelf.isEmpty {
                self?.removeShelf(shelf)
            }
        }
    }
    
    private func resetRetractTimer(for shelf: Shelf) {
        if PreferencesManager.shared.autoRetract {
            scheduleRetract(for: shelf)
        }
    }
    
    // MARK: - Visibility
    
    func showAllShelves() {
        shelves.forEach { $0.show() }
    }
    
    func hideAllShelves() {
        shelves.forEach { $0.hide() }
    }
    
    deinit {
        if let observer = preferencesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
