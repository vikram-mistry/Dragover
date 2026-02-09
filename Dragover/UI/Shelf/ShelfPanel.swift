import AppKit
import SwiftUI

/// Custom NSPanel for the floating shelf window
class ShelfPanel: NSPanel {
    private let shelf: Shelf
    private var hostingView: NSHostingView<ShelfContentView>?
    private var trackingArea: NSTrackingArea?
    private var dropTargetView: ShelfDropTargetView?
    
    init(shelf: Shelf, screen: NSScreen) {
        self.shelf = shelf
        
        let shelfSize = NSSize(width: 420, height: 280)
        let origin = shelf.position.frameOrigin(for: shelfSize, on: screen)
        let frame = NSRect(origin: origin, size: shelfSize)
        
        super.init(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // Allow panel to become key window to receive keyboard events
        self.becomesKeyOnlyIfNeeded = false // Allow becoming key
        self.hidesOnDeactivate = false

        
        setupPanel()
        setupPanel()
        setupContent()
        setupDragHandling()
    }
    
    // Allow panel to become key so it can receive keyboard events
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    // MARK: - Event Handling
    
    override func keyDown(with event: NSEvent) {
        // Handle standard shortcuts
        
        // Command + W -> Close
        if event.keyCode == 13 && event.modifierFlags.contains(.command) { // 13 is 'W'
            if PreferencesManager.shared.enableCloseShelfShortcut {
                close()
                return
            }
        }
        
        // Space -> Quick Look
        if event.keyCode == 49 { // 49 is 'Space'
            if PreferencesManager.shared.enableQuickLookShortcut {
                // Trigger Quick Look on selected item if any
                // We need to access the hosting view's coordinator or state
                // For now, let's try to find the selected item via notification or direct access if possible
                NotificationCenter.default.post(name: NSNotification.Name("TriggerQuickLook"), object: nil)
                return
            }
        }
        
        super.keyDown(with: event)
    }
    
    private func setupPanel() {
        // Panel configuration
        level = .floating
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }
    
    private func setupContent() {
        // Create drop target view as the base
        dropTargetView = ShelfDropTargetView(shelf: shelf)
        dropTargetView?.frame = contentView!.bounds
        dropTargetView?.autoresizingMask = [.width, .height]
        contentView?.addSubview(dropTargetView!)
        
        // Create visual effect background
        let visualEffectView = NSVisualEffectView(frame: dropTargetView!.bounds)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 16
        visualEffectView.layer?.masksToBounds = true
        
        dropTargetView?.addSubview(visualEffectView)
        
        // Add SwiftUI content
        let shelfContentView = ShelfContentView(shelf: shelf, panel: self)
        hostingView = NSHostingView(rootView: shelfContentView)
        hostingView?.frame = visualEffectView.bounds
        hostingView?.autoresizingMask = [.width, .height]
        
        visualEffectView.addSubview(hostingView!)
    }
    
    private func setupDragHandling() {
        // Track mouse for hover effects
        guard let view = dropTargetView else { return }
        
        let trackingArea = NSTrackingArea(
            rect: view.bounds,
            options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        view.addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }
    
    // MARK: - Animation
    
    func animateIn() {
        alphaValue = 0
        orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        }
    }
    
    func animateOut(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            completion?()
        })
    }
    
    // MARK: - Positioning
    
    func snapToEdge() {
        guard PreferencesManager.shared.snapIntoPlace,
              let screen = screen else { return }
        
        let shelfSize = frame.size
        let newOrigin = shelf.position.frameOrigin(for: shelfSize, on: screen)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrameOrigin(newOrigin)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        if PreferencesManager.shared.snapIntoPlace {
            updatePositionBasedOnFrame()
            snapToEdge()
        }
    }
    
    private func updatePositionBasedOnFrame() {
        guard let screen = screen else { return }
        
        let screenFrame = screen.visibleFrame
        let center = NSPoint(
            x: frame.midX,
            y: frame.midY
        )
        
        // Determine closest position based on current location
        let relativeX = (center.x - screenFrame.minX) / screenFrame.width
        let relativeY = (center.y - screenFrame.minY) / screenFrame.height
        
        let newPosition: ShelfPosition
        if relativeY > 0.7 {
            if relativeX < 0.33 {
                newPosition = .topLeft
            } else if relativeX > 0.66 {
                newPosition = .topRight
            } else {
                newPosition = .topCenter
            }
        } else if relativeY < 0.3 {
            if relativeX < 0.33 {
                newPosition = .bottomLeft
            } else if relativeX > 0.66 {
                newPosition = .bottomRight
            } else {
                newPosition = .bottomCenter
            }
        } else {
            newPosition = relativeX < 0.5 ? .left : .right
        }
        
        shelf.position = newPosition
    }
    
    // MARK: - Size Management
    
    func updateSize(for itemCount: Int) {
        // Grid is 4 columns, each item ~100px wide + spacing
        let gridWidth: CGFloat = 420  // 4 columns * 90 + padding
        let itemHeight: CGFloat = 110 // Each row height
        let headerHeight: CGFloat = 50
        let actionsHeight: CGFloat = 70
        let minHeight: CGFloat = 200
        let maxHeight: CGFloat = 500
        
        // Calculate rows needed (4 items per row)
        let rows = max(1, Int(ceil(Double(itemCount) / 4.0)))
        let contentHeight = CGFloat(rows) * itemHeight + 32 // padding
        
        let newHeight = min(maxHeight, max(minHeight, headerHeight + contentHeight + actionsHeight))
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            var newFrame = frame
            newFrame.size.width = gridWidth
            newFrame.size.height = newHeight
            animator().setFrame(newFrame, display: true)
        }
    }
}

// MARK: - Drop Target View

/// NSView subclass that handles drag and drop operations
class ShelfDropTargetView: NSView {
    private let shelf: Shelf
    
    init(shelf: Shelf) {
        self.shelf = shelf
        super.init(frame: .zero)
        
        registerForDraggedTypes([.fileURL, .string, .URL])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - NSDraggingDestination
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        
        // Handle file URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            // Filter out URLs that already exist in the shelf
            let existingUrls = Set(shelf.items.compactMap { $0.url })
            let newUrls = urls.filter { !existingUrls.contains($0) }
            
            if !newUrls.isEmpty {
                let items = newUrls.map { ShelfItem(url: $0) }
                shelf.addItems(items)
                return true
            }
        }
        
        // Handle text
        if let string = pasteboard.string(forType: .string) {
            let item = ShelfItem(text: string)
            shelf.addItem(item)
            return true
        }
        
        return false
    }
}
