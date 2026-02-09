import Foundation
import AppKit

/// Service for detecting the MacBook notch area for shelf activation
class NotchDetectionService {
    static let shared = NotchDetectionService()
    
    private var notchFrames: [NSScreen: NSRect] = [:]
    
    init() {
        calculateNotchAreas()
        
        // Observe screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notch Detection
    
    /// Checks if a point is within the notch area of any screen
    func isInNotchArea(_ point: NSPoint) -> Bool {
        for (screen, notchFrame) in notchFrames {
            // Convert point to screen coordinates
            let screenFrame = screen.frame
            if screenFrame.contains(point) && notchFrame.contains(point) {
                return true
            }
        }
        return false
    }
    
    /// Gets the notch frame for a specific screen, if it has one
    func notchFrame(for screen: NSScreen) -> NSRect? {
        return notchFrames[screen]
    }
    
    /// Checks if a screen has a notch
    func hasNotch(_ screen: NSScreen) -> Bool {
        return notchFrames[screen] != nil
    }
    
    // MARK: - Private
    
    @objc private func screensDidChange() {
        calculateNotchAreas()
    }
    
    private func calculateNotchAreas() {
        notchFrames.removeAll()
        
        for screen in NSScreen.screens {
            if let notchFrame = detectNotch(on: screen) {
                notchFrames[screen] = notchFrame
            }
        }
    }
    
    private func detectNotch(on screen: NSScreen) -> NSRect? {
        // On macOS 12+, we can detect the notch by comparing visibleFrame to frame
        let frame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // Calculate the menu bar height (area above visible frame)
        let menuBarHeight = frame.maxY - visibleFrame.maxY
        
        // MacBook Pro with notch has a taller menu bar area (approximately 37-38 points)
        // Regular Macs have a menu bar of about 24 points
        let notchThreshold: CGFloat = 30.0
        
        guard menuBarHeight > notchThreshold else {
            return nil
        }
        
        // The notch is roughly centered and about 200 points wide
        let notchWidth: CGFloat = 200
        let notchHeight = menuBarHeight
        let notchX = frame.midX - notchWidth / 2
        let notchY = frame.maxY - notchHeight
        
        // Create a slightly larger hit target for easier activation
        let hitTargetPadding: CGFloat = 50
        return NSRect(
            x: notchX - hitTargetPadding,
            y: notchY,
            width: notchWidth + hitTargetPadding * 2,
            height: notchHeight
        )
    }
    
    /// Gets the best position for a shelf triggered from the notch area
    func shelfPositionForNotch(on screen: NSScreen) -> ShelfPosition {
        return .topCenter
    }
}
