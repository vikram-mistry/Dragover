import SwiftUI

/// Instant actions settings tab
struct InstantActionsSettingsView: View {
    @AppStorage("enableInstantActions") private var enableInstantActions = true
    @State private var enabledActions: [ActionItem] = []
    
    private let allActions = InstantActionService.shared.availableActions
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Instant Actions", isOn: $enableInstantActions)
                    .help("Show instant actions below the shelf when items are added")
            } header: {
                Text("Instant Actions")
                Text("Instant Actions appear below a new shelf when you drag files onto it.")
            }
            
            if enableInstantActions {
                Section {
                    ForEach($enabledActions) { $action in
                        HStack {
                            Image(nsImage: action.icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                            
                            Text(action.name)
                            
                            Spacer()
                            
                            Toggle("", isOn: $action.isEnabled)
                                .labelsHidden()
                            
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onMove(perform: moveAction)
                } header: {
                    Text("Available Actions")
                }
                
                Section {
                    Button("Restore Defaults") {
                        restoreDefaults()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Instant Actions")
        .onAppear {
            loadActions()
        }
        .onChange(of: enabledActions) { _ in
            saveActions()
        }
    }
    
    private func loadActions() {
        let savedIds = PreferencesManager.shared.enabledActions
        enabledActions = allActions.map { action in
            ActionItem(
                id: action.id,
                name: action.name,
                icon: action.icon,
                isEnabled: savedIds.contains(action.id)
            )
        }
    }
    
    private func saveActions() {
        let enabledIds = enabledActions.filter { $0.isEnabled }.map { $0.id }
        PreferencesManager.shared.enabledActions = enabledIds
    }
    
    private func moveAction(from source: IndexSet, to destination: Int) {
        enabledActions.move(fromOffsets: source, toOffset: destination)
    }
    
    private func restoreDefaults() {
        PreferencesManager.shared.enabledActions = ["airdrop", "messages", "mail", "copy", "compress", "getinfo"]
        loadActions()
    }
}

/// Helper model for action list
struct ActionItem: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: NSImage
    var isEnabled: Bool
    
    static func == (lhs: ActionItem, rhs: ActionItem) -> Bool {
        lhs.id == rhs.id && lhs.isEnabled == rhs.isEnabled
    }
}

#Preview {
    InstantActionsSettingsView()
}
