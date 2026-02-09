import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var shelfManager: ShelfManager!
    private var dragDetectionService: DragDetectionService!
    private var notchDetectionService: NotchDetectionService!
    private var screenshotMonitorService: ScreenshotMonitorService!
    private var permissionService: PermissionService!
    private var onboardingWindow: NSWindow?
    private var preferencesWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup services first
        setupServices()
        setupMenuBar()
        
        // Start monitoring shortcuts
        GlobalShortcutService.shared.startMonitoring()
        
        // Configure dock visibility
        updateDockVisibility()
        
        // Check permissions after a short delay to prevent beach ball
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAndRequestPermissions()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        dragDetectionService?.stopMonitoring()
        screenshotMonitorService?.stopMonitoring()
        GlobalShortcutService.shared.stopMonitoring()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When app is reopened from Dock or Spotlight, show Preferences
        if !flag {
            openPreferences()
        }
        return true
    }
    
    // MARK: - Setup
    
    private func setupServices() {
        permissionService = PermissionService()
        shelfManager = ShelfManager.shared
        dragDetectionService = DragDetectionService(shelfManager: shelfManager)
        notchDetectionService = NotchDetectionService()
        screenshotMonitorService = ScreenshotMonitorService(shelfManager: shelfManager)
    }
    
    private func setupMenuBar() {
        // Always show menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "Dragover")
        }
        
        let menu = NSMenu()
        
        let showShelfItem = NSMenuItem(title: "Show Shelf", action: #selector(showShelf), keyEquivalent: "s")
        showShelfItem.target = self
        menu.addItem(showShelfItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let permissionsItem = NSMenuItem(title: "Request Permissions...", action: #selector(requestPermissions), keyEquivalent: "")
        permissionsItem.target = self
        menu.addItem(permissionsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Dragover", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func checkAndRequestPermissions() {
        if !permissionService.isAccessibilityGranted {
            showOnboarding()
        } else {
            // Permission already granted, start services after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.startServicesIfPermitted()
            }
        }
        
        // Poll for permission changes
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.permissionService.isAccessibilityGranted {
                timer.invalidate()
                self.onboardingWindow?.close()
                self.onboardingWindow = nil
                
                // Start services after permission granted
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.startServicesIfPermitted()
                }
                print("[Dragover] Accessibility permission granted. Starting services.")
            }
        }
    }
    
    private func startServicesIfPermitted() {
        guard permissionService.isAccessibilityGranted else {
            print("[Dragover] Cannot start services - accessibility not granted")
            return
        }
        
        print("[Dragover] Starting drag detection service...")
        dragDetectionService.startMonitoring()
        
        if PreferencesManager.shared.screenshotShelfEnabled {
            screenshotMonitorService.startMonitoring()
        }
    }
    
    private func updateDockVisibility() {
        if PreferencesManager.shared.showInDock {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    // MARK: - Actions
    
    @objc private func showShelf() {
        shelfManager.createShelf(at: PreferencesManager.shared.defaultShelfPosition)
    }
    
    @objc private func requestPermissions() {
        permissionService.openAccessibilityPreferences()
    }
    
    @objc private func openPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 650, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.title = "Dragover Preferences"
            preferencesWindow?.contentView = NSHostingView(rootView: PreferencesView())
            preferencesWindow?.isReleasedWhenClosed = false
        }
        preferencesWindow?.center()
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func showOnboarding() {
        if onboardingWindow == nil {
            onboardingWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 600),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            onboardingWindow?.title = "Welcome to Dragover"
            onboardingWindow?.contentView = NSHostingView(rootView: PermissionOnboardingView())
            onboardingWindow?.isReleasedWhenClosed = false
        }
        onboardingWindow?.center()
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
