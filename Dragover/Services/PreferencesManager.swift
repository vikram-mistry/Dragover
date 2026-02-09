import Foundation
import SwiftUI
import ServiceManagement

/// Centralized preferences manager using UserDefaults
class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - General Settings
    
    @AppStorage("showInMenuBar") var showInMenuBar = true
    @AppStorage("showInDock") var showInDock = false
    @AppStorage("launchAtLogin") var launchAtLogin = false {
        didSet {
            updateLaunchAtLogin()
        }
    }
    @AppStorage("offlineModeEnabled") var offlineModeEnabled = true
    
    // MARK: - Shelf Activation
    
    @AppStorage("enableCursorShake") var enableCursorShake = true
    @AppStorage("shakeSensitivity") var shakeSensitivity = 0.5
    @AppStorage("enableModifierKey") var enableModifierKey = true
    @AppStorage("modifierKey") var modifierKey: ModifierKeyOption = .shift
    @AppStorage("enableDropToNotch") var enableDropToNotch = true
    @AppStorage("defaultShelfPosition") var defaultShelfPosition: ShelfPosition = .bottomRight
    
    // Keyboard shortcuts
    @AppStorage("enableNewShelfShortcut") var enableNewShelfShortcut = true
    @AppStorage("enableClipboardShelfShortcut") var enableClipboardShelfShortcut = true
    @AppStorage("enableCloseShelfShortcut") var enableCloseShelfShortcut = true
    @AppStorage("enableQuickLookShortcut") var enableQuickLookShortcut = true
    
    // MARK: - Shelf Interaction
    
    @AppStorage("doubleClickAction") var doubleClickAction: DoubleClickAction = .revealInFinder
    @AppStorage("autoRetract") var autoRetract = false
    @AppStorage("autoRetractDelay") var autoRetractDelay = 5.0
    @AppStorage("snapIntoPlace") var snapIntoPlace = true
    @AppStorage("closeDetailViewAutomatically") var closeDetailViewAutomatically = false
    
    // MARK: - Instant Actions
    
    @AppStorage("enableInstantActions") var enableInstantActions = true
    @AppStorage("enabledActionsData") var enabledActionsData: Data = Data()
    
    var enabledActions: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: enabledActionsData)) ?? 
            ["airdrop", "messages", "mail", "copy", "compress", "getinfo"]
        }
        set {
            enabledActionsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    // MARK: - Screenshot Shelf
    
    @AppStorage("screenshotShelfEnabled") var screenshotShelfEnabled = false
    @AppStorage("screenshotFolderPath") var screenshotFolderPath = "~/Desktop"
    @AppStorage("screenshotCopyToClipboard") var screenshotCopyToClipboard = false
    @AppStorage("screenshotShowConfirmation") var screenshotShowConfirmation = true
    @AppStorage("screenshotShowInNewShelf") var screenshotShowInNewShelf = true
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Launch at Login
    
    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
    
    // MARK: - Reset (Safe Implementation)
    
    func resetToDefaults() {
        // AppStorage bound properties
        showInMenuBar = true
        showInDock = false
        launchAtLogin = false
        offlineModeEnabled = true
        
        enableCursorShake = true
        shakeSensitivity = 0.5
        enableModifierKey = true
        modifierKey = .shift
        enableDropToNotch = true
        defaultShelfPosition = .bottomRight
        
        enableNewShelfShortcut = true
        enableClipboardShelfShortcut = true
        enableCloseShelfShortcut = true
        enableQuickLookShortcut = true
        
        doubleClickAction = .revealInFinder
        autoRetract = false
        autoRetractDelay = 5.0
        snapIntoPlace = true
        closeDetailViewAutomatically = false
        
        enableInstantActions = true
        enabledActions = ["airdrop", "messages", "mail", "copy", "compress", "getinfo"]
        
        screenshotShelfEnabled = false
        screenshotFolderPath = "~/Desktop"
        screenshotCopyToClipboard = false
        screenshotShowConfirmation = true
        screenshotShowInNewShelf = true
        
        // Ensure changes are persisted
        defaults.synchronize()
    }
}

// MARK: - Supporting Types

enum ModifierKeyOption: String, CaseIterable, Codable {
    case shift = "Shift"
    case option = "Option"
    
    var symbol: String {
        switch self {
        case .shift: return "⇧"
        case .option: return "⌥"
        }
    }
    
    var eventFlag: NSEvent.ModifierFlags {
        switch self {
        case .shift: return .shift
        case .option: return .option
        }
    }
}

enum DoubleClickAction: String, CaseIterable, Codable {
    case revealInFinder = "Reveal in Finder"
    case openFile = "Open File"
    case quickLook = "Quick Look"
}


