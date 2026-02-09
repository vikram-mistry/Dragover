import Foundation
import AppKit

/// Service for detecting drag operations and triggering shelf activation
/// Uses NSEvent monitoring which doesn't block the main thread
class DragDetectionService {
    private let shelfManager: ShelfManager
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    // Shake detection state
    private var cursorHistory: [(point: NSPoint, time: Date)] = []
    private let shakeHistoryDuration: TimeInterval = 0.4
    private let shakeThreshold: CGFloat = 80.0
    private let shakeMinDirectionChanges = 3
    
    // Drag state
    private var isDragging = false
    private var shelfShownInThisDrag = false
    
    init(shelfManager: ShelfManager) {
        self.shelfManager = shelfManager
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        print("[Dragover] Starting event monitors...")
        
        // Global monitor - catches events when app is not active
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDragged, .leftMouseUp, .leftMouseDown, .flagsChanged]
        ) { [weak self] event in
            self?.handleEvent(event)
        }
        
        // Local monitor - catches events when app is active
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDragged, .leftMouseUp, .leftMouseDown, .flagsChanged]
        ) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
        
        print("[Dragover] Event monitors started")
    }
    
    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    // MARK: - Event Handling
    
    private func handleEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            isDragging = false
            shelfShownInThisDrag = false
            cursorHistory.removeAll()
            
        case .leftMouseDragged:
            isDragging = true
            let location = NSEvent.mouseLocation
            let now = Date()
            
            // Track cursor position
            cursorHistory.append((point: location, time: now))
            
            // Keep only recent history
            cursorHistory = cursorHistory.filter { now.timeIntervalSince($0.time) <= shakeHistoryDuration }
            
            // Check activation triggers
            if !shelfShownInThisDrag {
                checkActivationTriggers(at: location, modifiers: event.modifierFlags)
            }
            
        case .leftMouseUp:
            isDragging = false
            shelfShownInThisDrag = false
            cursorHistory.removeAll()
            
        case .flagsChanged:
            // Check if modifier key is pressed during drag
            if isDragging && !shelfShownInThisDrag {
                let location = NSEvent.mouseLocation
                checkActivationTriggers(at: location, modifiers: event.modifierFlags)
            }
            
        default:
            break
        }
    }
    
    // MARK: - Activation Triggers
    
    private func checkActivationTriggers(at location: NSPoint, modifiers: NSEvent.ModifierFlags) {
        let prefs = PreferencesManager.shared
        
        // Check modifier key activation (Shift, Option, etc.)
        if prefs.enableModifierKey {
            if modifiers.contains(prefs.modifierKey.eventFlag) {
                print("[Dragover] Modifier key detected")
                activateShelf(at: location)
                return
            }
        }
        
        // Check cursor shake activation
        if prefs.enableCursorShake && detectShake() {
            print("[Dragover] Shake detected")
            activateShelf(at: location)
            cursorHistory.removeAll()
            return
        }
        
        // Check notch detection
        if prefs.enableDropToNotch && NotchDetectionService.shared.isInNotchArea(location) {
            print("[Dragover] Notch area detected")
            activateShelf(at: location)
            return
        }
    }
    
    private func detectShake() -> Bool {
        guard cursorHistory.count >= 4 else { return false }
        
        let sensitivity = PreferencesManager.shared.shakeSensitivity
        let adjustedThreshold = shakeThreshold * CGFloat(2.0 - sensitivity)
        
        var directionChanges = 0
        var lastDirection: CGFloat = 0
        var totalDistance: CGFloat = 0
        
        for i in 1..<cursorHistory.count {
            let prev = cursorHistory[i - 1].point
            let curr = cursorHistory[i].point
            
            let deltaX = curr.x - prev.x
            totalDistance += abs(deltaX)
            
            let currentDirection = deltaX > 0 ? 1.0 : -1.0
            
            if lastDirection != 0 && currentDirection != lastDirection && abs(deltaX) > 3.0 {
                directionChanges += 1
            }
            if abs(deltaX) > 3.0 {
                lastDirection = currentDirection
            }
        }
        
        return directionChanges >= shakeMinDirectionChanges && totalDistance >= adjustedThreshold
    }
    
    private func activateShelf(at location: NSPoint) {
        guard !shelfShownInThisDrag else { return }
        shelfShownInThisDrag = true
        
        DispatchQueue.main.async { [weak self] in
            self?.shelfManager.createShelfAtCursor()
        }
    }
}
