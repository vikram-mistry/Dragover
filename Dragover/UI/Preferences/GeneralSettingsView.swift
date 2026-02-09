import SwiftUI
import ServiceManagement

/// General settings tab
struct GeneralSettingsView: View {
    // General
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("showInDock") private var showInDock = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("offlineModeEnabled") private var offlineModeEnabled = true
    
    // Manage/Reset states
    @State private var showResetConfirmation = false
    @State private var showDataInfo = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Show in menu bar", isOn: $showInMenuBar)
                    .help("Display Dragover icon in the menu bar")
                
                Toggle("Show in Dock", isOn: $showInDock)
                    .help("Show Dragover in the Dock")
                    .onChange(of: showInDock) { newValue in
                        updateDockVisibility(newValue)
                    }
            } header: {
                Text("Appearance")
            }
            
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .help("Automatically start Dragover when you log in")
                    .onChange(of: launchAtLogin) { newValue in
                        updateLaunchAtLogin(newValue)
                    }
            } header: {
                Text("Startup")
            }
            
            Section {
                Toggle("Disable online features", isOn: $offlineModeEnabled)
                    .help("Dragover works fully offline")
                
                HStack {
                    Text("Application data")
                    Spacer()
                    Button("Manage...") {
                        // Open app support directly
                        openAppSupportFolder()
                    }
                }
            } header: {
                Text("Privacy")
            }
            
            Section {
                Button("Reset All Settings") {
                    showResetConfirmation = true
                }
                .foregroundColor(.red)
                
                Text("This will restore all preferences to their default values.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Reset")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .alert("Reset All Settings?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetAllSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All preferences will be restored to their default values. This cannot be undone.")
        }
    }
    
    private func updateDockVisibility(_ showInDock: Bool) {
        if showInDock {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
    
    private func openAppSupportFolder() {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        
        let folder = appSupport.appendingPathComponent("Dragover")
        
        // Ensure folder exists
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        
        // Open directly
        NSWorkspace.shared.open(folder)
    }
    
    private func resetAllSettings() {
        // Reset AppStorage properties directly first
        showInMenuBar = true
        showInDock = false
        launchAtLogin = false
        offlineModeEnabled = true
        
        // Call PreferencesManager reset for everything else
        PreferencesManager.shared.resetToDefaults()
        
        // Force update dock visibility
        NSApp.setActivationPolicy(.accessory)
    }
}

#Preview {
    GeneralSettingsView()
}
