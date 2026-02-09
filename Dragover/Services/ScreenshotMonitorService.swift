import Foundation
import AppKit
import UserNotifications

/// Service for monitoring screenshots and adding them to shelves
class ScreenshotMonitorService {
    private let shelfManager: ShelfManager
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var directoryDescriptor: Int32 = -1
    private var knownFiles: Set<String> = []
    
    init(shelfManager: ShelfManager) {
        self.shelfManager = shelfManager
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        let prefs = PreferencesManager.shared
        guard prefs.screenshotShelfEnabled else { return }
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        
        let folderPath = (prefs.screenshotFolderPath as NSString).expandingTildeInPath
        
        // Ensure directory exists
        guard FileManager.default.fileExists(atPath: folderPath) else {
            print("Screenshot folder does not exist: \(folderPath)")
            return
        }
        
        // Get initial file list
        updateKnownFiles(at: folderPath)
        
        // Open directory for monitoring
        directoryDescriptor = open(folderPath, O_EVTONLY)
        guard directoryDescriptor >= 0 else {
            print("Failed to open directory for monitoring")
            return
        }
        
        // Create dispatch source for file system events
        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: directoryDescriptor,
            eventMask: .write,
            queue: .main
        )
        
        fileMonitor?.setEventHandler { [weak self] in
            self?.checkForNewScreenshots(at: folderPath)
        }
        
        fileMonitor?.setCancelHandler { [weak self] in
            if let fd = self?.directoryDescriptor, fd >= 0 {
                close(fd)
            }
            self?.directoryDescriptor = -1
        }
        
        fileMonitor?.resume()
    }
    
    func stopMonitoring() {
        fileMonitor?.cancel()
        fileMonitor = nil
    }
    
    // MARK: - Private
    
    private func updateKnownFiles(at path: String) {
        let url = URL(fileURLWithPath: path)
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return
        }
        knownFiles = Set(contents.map { $0.lastPathComponent })
    }
    
    private func checkForNewScreenshots(at folderPath: String) {
        let url = URL(fileURLWithPath: folderPath)
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        let currentFiles = Set(contents.map { $0.lastPathComponent })
        let newFiles = currentFiles.subtracting(knownFiles)
        
        for fileName in newFiles {
            let fileURL = url.appendingPathComponent(fileName)
            
            // Check if it's a screenshot (typically starts with "Screenshot" or "Screen Shot")
            if isScreenshotFile(fileName) {
                handleNewScreenshot(at: fileURL)
            }
        }
        
        knownFiles = currentFiles
    }
    
    private func isScreenshotFile(_ fileName: String) -> Bool {
        // Skip hidden files (starting with .)
        if fileName.hasPrefix(".") {
            return false
        }
        
        let lowercased = fileName.lowercased()
        let screenshotPrefixes = ["screenshot", "screen shot", "capture"]
        let imageExtensions = ["png", "jpg", "jpeg", "tiff", "heic"]
        
        let hasScreenshotPrefix = screenshotPrefixes.contains { lowercased.contains($0) }
        let hasImageExtension = imageExtensions.contains { lowercased.hasSuffix(".\($0)") }
        
        return hasScreenshotPrefix && hasImageExtension
    }
    
    private func handleNewScreenshot(at url: URL) {
        let prefs = PreferencesManager.shared
        
        // Add to shelf
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let item = ShelfItem(url: url)
            
            if prefs.screenshotShowInNewShelf {
                let shelf = self.shelfManager.createShelf(at: prefs.defaultShelfPosition)
                shelf.addItem(item)
            } else {
                self.shelfManager.addItems([item])
            }
            
            // Copy to clipboard if enabled
            if prefs.screenshotCopyToClipboard {
                self.copyToClipboard(url)
            }
            
            // Show confirmation toast if enabled
            if prefs.screenshotShowConfirmation {
                self.showConfirmationToast(for: url)
            }
        }
    }
    
    private func copyToClipboard(_ url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    private func showConfirmationToast(for url: URL) {
        let content = UNMutableNotificationContent()
        content.title = "Screenshot Added to Shelf"
        content.body = url.lastPathComponent
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
}
