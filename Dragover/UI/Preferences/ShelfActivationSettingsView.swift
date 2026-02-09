import SwiftUI
import Carbon.HIToolbox

/// Shelf activation settings tab
struct ShelfActivationSettingsView: View {
    @AppStorage("enableCursorShake") private var enableCursorShake = true
    @AppStorage("shakeSensitivity") private var shakeSensitivity = 0.5
    @AppStorage("enableModifierKey") private var enableModifierKey = true
    @AppStorage("modifierKey") private var modifierKey = ModifierKeyOption.shift
    @AppStorage("enableDropToNotch") private var enableDropToNotch = true
    @AppStorage("defaultShelfPosition") private var defaultShelfPosition = ShelfPosition.bottomRight
    
    // Keyboard shortcuts
    @AppStorage("enableNewShelfShortcut") private var enableNewShelfShortcut = true
    @AppStorage("enableClipboardShelfShortcut") private var enableClipboardShelfShortcut = true
    @AppStorage("enableCloseShelfShortcut") private var enableCloseShelfShortcut = true
    @AppStorage("enableQuickLookShortcut") private var enableQuickLookShortcut = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Activate with shake gesture", isOn: $enableCursorShake)
                    .help("Shake the cursor while dragging to activate a shelf")
                
                if enableCursorShake {
                    HStack {
                        Text("Sensitivity")
                        Slider(value: $shakeSensitivity, in: 0...1)
                        Text(sensitivityLabel)
                            .foregroundColor(.secondary)
                            .frame(width: 60)
                    }
                    .padding(.leading)
                }
            } header: {
                Text("Shake Gesture")
            }
            
            Section {
                Toggle("Activate with modifier key", isOn: $enableModifierKey)
                    .help("Hold a modifier key while dragging to activate a shelf")
                
                if enableModifierKey {
                    Picker("Modifier key", selection: $modifierKey) {
                        ForEach(ModifierKeyOption.allCases, id: \.self) { option in
                            Text(option.symbol + " " + option.rawValue).tag(option)
                        }
                    }
                    .padding(.leading)
                }
            } header: {
                Text("Activate from modifier key")
            }
            
            Section {
                Toggle("Drop to notch", isOn: $enableDropToNotch)
                    .help("Drag files to the MacBook notch to activate a shelf")
                
                if enableDropToNotch {
                    Text("Drag files to the MacBook notch area to create a shelf.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading)
                }
            } header: {
                Text("Notch Activation")
            }
            
            Section {
                Picker("Default shelf location", selection: $defaultShelfPosition) {
                    ForEach(ShelfPosition.allCases, id: \.self) { position in
                        Text(position.rawValue).tag(position)
                    }
                }
                .help("Default position for new shelves")
            } header: {
                Text("Default Position")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("These keyboard shortcuts are fixed and cannot be changed. You can disable them if they conflict with other applications.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                
                // Global Shortcuts group
                VStack(alignment: .leading, spacing: 0) {
                    Text("Global Shortcuts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    HStack {
                        Toggle("", isOn: $enableNewShelfShortcut)
                            .labelsHidden()
                        Text("New Shelf")
                        Spacer()
                        ShortcutBadge(text: "⌥⇧␣")
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    HStack {
                        Toggle("", isOn: $enableClipboardShelfShortcut)
                            .labelsHidden()
                        Text("New Clipboard Shelf")
                        Spacer()
                        ShortcutBadge(text: "⌥⇧A")
                    }
                    .padding(.vertical, 4)
                }
                .padding(.bottom, 12)
                
                // Shelf Shortcuts group
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text("Shelf Shortcuts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "questionmark.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .help("These shortcuts are active when a shelf is focused")
                    }
                    .padding(.bottom, 4)
                    
                    HStack {
                        Toggle("", isOn: $enableCloseShelfShortcut)
                            .labelsHidden()
                        Text("Close")
                        Spacer()
                        ShortcutBadge(text: "⌘W")
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    HStack {
                        Toggle("", isOn: $enableQuickLookShortcut)
                            .labelsHidden()
                        Text("Quick Look")
                        Spacer()
                        ShortcutBadge(text: "␣")
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Keyboard shortcuts")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Shelf Activation")
    }
    
    private var sensitivityLabel: String {
        if shakeSensitivity < 0.33 {
            return "Low"
        } else if shakeSensitivity < 0.66 {
            return "Medium"
        } else {
            return "High"
        }
    }
}

/// Badge view for keyboard shortcuts
struct ShortcutBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(6)
    }
}

#Preview {
    ShelfActivationSettingsView()
}
