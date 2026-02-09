import Cocoa
import Carbon

/// Service to handle global keyboard shortcuts using Carbon HotKeys
class GlobalShortcutService {
    static let shared = GlobalShortcutService()
    
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    
    // Key Codes
    private let kVK_Space: UInt32 = 0x31
    private let kVK_ANSI_A: UInt32 = 0x00
    
    // Modifier flags for RegisterEventHotKey
    // cmdKey = 1<<8 (256)
    // shiftKey = 1<<9 (512)
    // optionKey = 1<<11 (2048)
    private let carbonCmdKey: UInt32 = 256
    private let carbonShiftKey: UInt32 = 512
    private let carbonOptionKey: UInt32 = 2048
    
    // IDs
    private enum ShortcutID: UInt32 {
        case newShelf = 1
        case clipboardShelf = 2
    }
    
    private init() {}
    
    func startMonitoring() {
        // Option + Shift + Space
        register(
            keyCode: kVK_Space,
            modifiers: carbonOptionKey | carbonShiftKey,
            id: ShortcutID.newShelf.rawValue
        )
        
        // Option + Shift + A
        register(
            keyCode: kVK_ANSI_A,
            modifiers: carbonOptionKey | carbonShiftKey,
            id: ShortcutID.clipboardShelf.rawValue
        )
        
        installEventHandler()
    }
    
    func stopMonitoring() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
    
    private func register(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("Drov".asResID)
        hotKeyID.id = id
        
        var hotKeyRef: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs[id] = ref
            print("Successfully registered hotkey ID: \(id)")
        } else {
            print("Failed to register hotkey \(id): \(status)")
        }
    }
    
    private func installEventHandler() {
        let eventSpec = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        ]
        
        // C-style callback for Carbon event
        let callback: EventHandlerProcPtr = { (handler, event, userData) -> OSStatus in
            guard let event = event else { return OSStatus(eventNotHandledErr) }
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status != noErr { return status }
            
            if hotKeyID.signature == OSType("Drov".asResID) {
                 return GlobalShortcutService.shared.handleHotKey(id: hotKeyID.id)
            }
            
            return OSStatus(eventNotHandledErr)
        }
        
        var handler: EventHandlerRef?
        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            eventSpec,
            nil,
            &handler
        )
        eventHandler = handler
    }
    
    private func handleHotKey(id: UInt32) -> OSStatus {
        guard let type = ShortcutID(rawValue: id) else { return OSStatus(eventNotHandledErr) }
        
        DispatchQueue.main.async { [weak self] in
            self?.performAction(for: type)
        }
        
        return OSStatus(noErr)
    }
    
    private func performAction(for type: ShortcutID) {
        switch type {
        case .newShelf:
            // Check preference
            if PreferencesManager.shared.enableNewShelfShortcut {
                ShelfManager.shared.createShelfAtCursor()
            }
            
        case .clipboardShelf:
            if PreferencesManager.shared.enableClipboardShelfShortcut {
                let mouseLoc = NSEvent.mouseLocation
                ShelfManager.shared.createShelfFromClipboard(at: mouseLoc)
            }
        }
    }
}

private extension String {
    var asResID: UInt32 {
        var result: UInt32 = 0
        for (idx, char) in unicodeScalars.enumerated() {
            if idx < 4 {
                result = (result << 8) | UInt32(char.value)
            }
        }
        return result
    }
}
