import SwiftUI

/// Shelf interaction settings tab
struct ShelfInteractionSettingsView: View {
    @AppStorage("doubleClickAction") private var doubleClickAction = DoubleClickAction.revealInFinder
    @AppStorage("autoRetract") private var autoRetract = false
    @AppStorage("autoRetractDelay") private var autoRetractDelay = 5.0
    @AppStorage("snapIntoPlace") private var snapIntoPlace = true
    @AppStorage("closeDetailViewAutomatically") private var closeDetailViewAutomatically = false
    
    var body: some View {
        Form {
            Section {
                Picker("Double-click files", selection: $doubleClickAction) {
                    ForEach(DoubleClickAction.allCases, id: \.self) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
                .help("Action to perform when double-clicking an item")
            } header: {
                Text("Click Behavior")
            }
            
            Section {
                Toggle("Automatically retract", isOn: $autoRetract)
                    .help("Automatically close empty shelves after a delay")
                
                if autoRetract {
                    HStack {
                        Text("Delay")
                        Slider(value: $autoRetractDelay, in: 1...30, step: 1)
                        Text("\(Int(autoRetractDelay))s")
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                    }
                    .padding(.leading)
                }
            } header: {
                Text("Auto-Retract")
            }
            
            Section {
                Toggle("Snap into place", isOn: $snapIntoPlace)
                    .help("Shelves snap to the nearest edge when dragged")
                
                Toggle("Close detail view automatically", isOn: $closeDetailViewAutomatically)
                    .help("Close the preview panel when clicking elsewhere")
            } header: {
                Text("Behavior")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Shelf Interaction")
    }
}

#Preview {
    ShelfInteractionSettingsView()
}
