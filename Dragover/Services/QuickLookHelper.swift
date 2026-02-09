import AppKit
import Quartz

/// Helper to show Quick Look preview for files
class QuickLookHelper: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookHelper()
    
    private var urls: [URL] = []
    
    static func show(url: URL) {
        shared.show(urls: [url])
    }
    
    static func show(urls: [URL]) {
        shared.show(urls: urls)
    }
    
    private func show(urls: [URL]) {
        self.urls = urls
        
        if QLPreviewPanel.sharedPreviewPanelExists() && QLPreviewPanel.shared().isVisible {
            QLPreviewPanel.shared().reloadData()
        } else {
            QLPreviewPanel.shared().makeKeyAndOrderFront(nil)
        }
        
        QLPreviewPanel.shared().dataSource = self
        QLPreviewPanel.shared().delegate = self
        QLPreviewPanel.shared().reloadData()
    }
    
    // MARK: - QLPreviewPanelDataSource
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return urls.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return urls[index] as NSURL
    }
    
    // MARK: - QLPreviewPanelDelegate
    
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        if event.type == .keyDown {
            if event.keyCode == 53 { // Escape key
                panel.close()
                return true
            }
        }
        return false
    }
}
