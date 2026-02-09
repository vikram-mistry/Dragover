import AppKit
import SwiftUI
import Quartz

/// Preview panel for shelf items
class ItemPreviewPanel: NSPanel, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    private var previewItems: [URL] = []
    private var currentIndex: Int = 0
    
    static let shared = ItemPreviewPanel()
    
    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        title = "Preview"
        isReleasedWhenClosed = false
    }
    
    // MARK: - Public API
    
    func showPreview(for items: [ShelfItem]) {
        previewItems = items.compactMap { $0.url }
        currentIndex = 0
        
        guard !previewItems.isEmpty else { return }
        
        if let panel = QLPreviewPanel.shared() {
            panel.dataSource = self
            panel.delegate = self
            panel.currentPreviewItemIndex = 0
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    func showPreview(for item: ShelfItem) {
        showPreview(for: [item])
    }
    
    // MARK: - QLPreviewPanelDataSource
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return previewItems.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard index < previewItems.count else { return nil }
        return previewItems[index] as NSURL
    }
    
    // MARK: - QLPreviewPanelDelegate
    
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        return false
    }
}
