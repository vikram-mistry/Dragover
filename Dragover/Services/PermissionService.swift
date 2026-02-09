import Foundation
import AppKit
import ApplicationServices

/// Service for managing system permissions required by the app
class PermissionService {
    
    // MARK: - Accessibility Permission
    
    /// Checks if accessibility permission has been granted
    var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }
    
    /// Prompts the user to grant accessibility permission
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    /// Opens System Preferences to the Accessibility pane
    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Screen Recording Permission (for screenshot monitoring)
    
    /// Checks if screen recording permission has been granted
    /// Note: This is only needed if we want to capture screenshots ourselves
    var isScreenRecordingGranted: Bool {
        // macOS 10.15+ requires screen recording permission for certain operations
        if #available(macOS 10.15, *) {
            // Check by attempting to get the window list
            let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[CFString: Any]]
            // If we can get window names, permission is granted
            return windowList?.first?[kCGWindowName] != nil
        }
        return true
    }
    
    /// Opens System Preferences to the Screen Recording pane
    func openScreenRecordingPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Permission Status
    
    /// Returns a summary of all permission statuses
    var permissionStatus: PermissionStatus {
        return PermissionStatus(
            accessibility: isAccessibilityGranted,
            screenRecording: isScreenRecordingGranted
        )
    }
}

/// Status of all required permissions
struct PermissionStatus {
    let accessibility: Bool
    let screenRecording: Bool
    
    var allGranted: Bool {
        return accessibility && screenRecording
    }
    
    var essentialsGranted: Bool {
        // Screen recording is only needed for screenshot features
        return accessibility
    }
}
