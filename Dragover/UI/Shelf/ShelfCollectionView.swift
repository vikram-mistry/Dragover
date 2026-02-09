import SwiftUI
import AppKit

/// SwiftUI wrapper for NSCollectionView to support advanced features
struct ShelfCollectionView: NSViewRepresentable {
    @ObservedObject var shelf: Shelf
    @Binding var selectedItemIds: Set<UUID>
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        
        let collectionView = KeyboardCollectionView()
        // We register class instead
        collectionView.register(ShelfCollectionViewItem.self, forItemWithIdentifier: ShelfCollectionViewItem.identifier)
        collectionView.backgroundColors = [.clear]
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = true
        
        let coordinator = context.coordinator
        collectionView.delegate = coordinator
        collectionView.dataSource = coordinator
        
        // Double Click Gesture
        let doubleClickGesture = NSClickGestureRecognizer(target: coordinator, action: #selector(Coordinator.onDoubleClick(_:)))
        doubleClickGesture.numberOfClicksRequired = 2
        doubleClickGesture.delaysPrimaryMouseButtonEvents = false
        collectionView.addGestureRecognizer(doubleClickGesture)
        
        // Key Handlers
        collectionView.onDelete = {
            coordinator.deleteSelectedItems()
        }
        
        collectionView.onQuickLook = {
            coordinator.quickLookSelectedItems()
        }
        
        // Layout
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 90, height: 110)
        flowLayout.sectionInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 10
        collectionView.collectionViewLayout = flowLayout
        
        // Drag settings
        collectionView.setDraggingSourceOperationMask(.copy, forLocal: false)
        
        scrollView.documentView = collectionView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let collectionView = nsView.documentView as? NSCollectionView else { return }
        
        // Update coordinator's items reference
        if context.coordinator.items != shelf.items {
            context.coordinator.items = shelf.items
            collectionView.reloadData()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
        var parent: ShelfCollectionView
        var items: [ShelfItem] = []
        
        init(_ parent: ShelfCollectionView) {
            self.parent = parent
            self.items = parent.shelf.items
        }
        
        // MARK: - DataSource
        
        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            return items.count
        }
        
        func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            let item = collectionView.makeItem(withIdentifier: ShelfCollectionViewItem.identifier, for: indexPath) as! ShelfCollectionViewItem
            
            // Debug verify
            // print("Dequeued item: \(item)")
            
            if indexPath.item < items.count {
                let shelfItem = items[indexPath.item]
                item.configure(with: shelfItem)
                
                // Handle Remove
                item.onRemove = { [weak self] in
                    if let self = self {
                        self.parent.shelf.removeItem(shelfItem)
                        // Reload is handled by updateNSView in parent
                    }
                }
            }
            
            return item
        }
        
        // MARK: - Delegate
        
        func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
            updateSelection(in: collectionView)
        }
        
        func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
            updateSelection(in: collectionView)
        }
        
        private func updateSelection(in collectionView: NSCollectionView) {
            let selectedIds = collectionView.selectionIndexPaths.compactMap { indexPath -> UUID? in
                guard indexPath.item < items.count else { return nil }
                return items[indexPath.item].id
            }
            DispatchQueue.main.async {
                self.parent.selectedItemIds = Set(selectedIds)
            }
        }
        
        // MARK: - Dragging Source
        
        func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
            guard indexPath.item < items.count else { return nil }
            let item = items[indexPath.item]
            guard let url = item.url else { return nil }
            return url as NSURL
        }
        
        // MARK: - Keyboard Handling
        
        // We need to subclass NSCollectionView to handle key events properly, 
        // or handle them in the window/panel and forward here. 
        // Since we have ShelfPanel handling keys, we can expose methods here or depend on ShelfPanel forwarding.
        // However, a specialized NSCollectionView subclass is cleaner for component-specific actions like 'Delete'.

        
        // MARK: - Actions
        
        func deleteSelectedItems() {
            // Get selected items from indices
            // Accessing collectionView safely would be better via property
            // Let's use parent.selectedItemIds which is bound
            
            // Safer approach: use current selection from CollectionView if possible, or source of truth
            // Let's rely on the bound selection in parent, or better, ask collection view
            // Since we don't have direct reference here, let's use the stored items and IDs
            
            let itemsToRemove = items.filter { parent.selectedItemIds.contains($0.id) }
            guard !itemsToRemove.isEmpty else { return }
            
            for item in itemsToRemove {
                parent.shelf.removeItem(item)
            }
            
            // Clear selection
            DispatchQueue.main.async {
                self.parent.selectedItemIds.removeAll()
            }
        }
        
        // MARK: - Context Menu
        
        func collectionView(_ collectionView: NSCollectionView, menuForItemAt indexPath: IndexPath) -> NSMenu? {
            // Check if multi-selection including this item
            let selectedIndexPaths = collectionView.selectionIndexPaths
            if selectedIndexPaths.count > 1 && selectedIndexPaths.contains(indexPath) {
                let menu = NSMenu(title: "Selected Items")
                
                let copyItem = NSMenuItem(title: "Copy \(selectedIndexPaths.count) Items", action: #selector(copyItem), keyEquivalent: "c")
                copyItem.target = self
                menu.addItem(copyItem)
                
                menu.addItem(NSMenuItem.separator())
                
                let removeItem = NSMenuItem(title: "Remove \(selectedIndexPaths.count) Items", action: #selector(removeItem), keyEquivalent: "\u{0008}")
                removeItem.target = self
                menu.addItem(removeItem)
                
                return menu
            }
            
            // Single Item Menu
            guard indexPath.item < items.count else { return nil }
            let item = items[indexPath.item]
            guard item.url != nil else { return nil }
            
            let menu = NSMenu(title: item.displayName)
            
            menu.addItem(withTitle: "Open", action: #selector(openItem), keyEquivalent: "")
            menu.addItem(withTitle: "Reveal in Finder", action: #selector(revealItem), keyEquivalent: "")
            menu.addItem(withTitle: "Quick Look", action: #selector(quickLookItem), keyEquivalent: " ")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Copy", action: #selector(copyItem), keyEquivalent: "c")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Remove", action: #selector(removeItem), keyEquivalent: "\u{0008}")
            
            // Set target for all items to coordinator
            for menuItem in menu.items {
                menuItem.target = self
                menuItem.representedObject = item
            }
            
            return menu
        }
        
        // MARK: - Actions Implementation
        
        // MARK: - Actions Implementation
        
        @objc func onDoubleClick(_ sender: NSGestureRecognizer) {
            guard let collectionView = sender.view as? NSCollectionView,
                  let indexPath = collectionView.selectionIndexPaths.first,
                  indexPath.item < items.count else { return }
            
            let item = items[indexPath.item]
            guard let url = item.url else { return }
            
            switch PreferencesManager.shared.doubleClickAction {
            case .revealInFinder:
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
            case .openFile:
                NSWorkspace.shared.open(url)
            case .quickLook:
                QuickLookHelper.show(url: url)
            }
        }
        
        @objc func openItem(_ sender: NSMenuItem) {
            guard let item = sender.representedObject as? ShelfItem, let url = item.url else { return }
            NSWorkspace.shared.open(url)
        }
        
        @objc func revealItem(_ sender: NSMenuItem) {
            guard let item = sender.representedObject as? ShelfItem, let url = item.url else { return }
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
        }
        
        @objc func quickLookItem(_ sender: NSMenuItem) {
             guard let item = sender.representedObject as? ShelfItem, let url = item.url else { return }
             QuickLookHelper.show(url: url)
        }
        
        @objc func copyItem(_ sender: NSMenuItem) {
            // Check if specific item target
            if let item = sender.representedObject as? ShelfItem, let url = item.url {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([url as NSURL])
            } else {
                // Handle Multi-Selection
                let itemsToCopy = items.filter { parent.selectedItemIds.contains($0.id) }
                let urls = itemsToCopy.compactMap { $0.url as NSURL? }
                guard !urls.isEmpty else { return }
                
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects(urls)
            }
        }
        
        @objc func removeItem(_ sender: NSMenuItem) {
            if let item = sender.representedObject as? ShelfItem {
                parent.shelf.removeItem(item)
            } else {
                deleteSelectedItems()
            }
        }

        func quickLookSelectedItems() {
            // Find first selected item
            if let firstId = parent.selectedItemIds.first,
               let showItem = items.first(where: { $0.id == firstId }),
               let url = showItem.url {
                QuickLookHelper.show(url: url)
            }
        }
    }
}

class KeyboardCollectionView: NSCollectionView {
    var onDelete: (() -> Void)?
    var onQuickLook: (() -> Void)?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        // Delete / Backspace
        if event.keyCode == 51 {
            onDelete?()
            return
        }
        
        if event.keyCode == 49 {
            onQuickLook?()
            return
        }
        
        // Command + A -> Select All (Check for 'a' character or key code 0)
        if event.modifierFlags.contains(.command) && (event.charactersIgnoringModifiers == "a" || event.keyCode == 0) {
            selectAll(nil)
            return
        }
        
        super.keyDown(with: event)
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        if let indexPath = indexPathForItem(at: point),
           let coordinator = delegate as? ShelfCollectionView.Coordinator,
           let menu = coordinator.collectionView(self, menuForItemAt: indexPath) {
            return menu
        }
        return super.menu(for: event)
    }
}
