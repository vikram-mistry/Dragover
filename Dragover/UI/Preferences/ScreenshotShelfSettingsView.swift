import SwiftUI
import UniformTypeIdentifiers

/// Screenshot shelf settings tab
struct ScreenshotShelfSettingsView: View {
    @AppStorage("screenshotShelfEnabled") private var screenshotShelfEnabled = false
    @AppStorage("screenshotFolderPath") private var screenshotFolderPath = "~/Desktop"
    @AppStorage("screenshotCopyToClipboard") private var screenshotCopyToClipboard = false
    @AppStorage("screenshotShowConfirmation") private var screenshotShowConfirmation = true
    @AppStorage("screenshotShowInNewShelf") private var screenshotShowInNewShelf = true
    
    @State private var showFolderPicker = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enabled", isOn: $screenshotShelfEnabled)
                    .help("Automatically display new screenshots in a shelf")
            } header: {
                Text("Screenshot Shelf")
                Text("Automatically display new screenshots in a shelf.")
            }
            
            if screenshotShelfEnabled {
                Section {
                    HStack {
                        Text("Folder")
                        Spacer()
                        
                        Button(action: { showFolderPicker = true }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.yellow)
                                Text(folderDisplayName)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Picker("Show screenshots in", selection: $screenshotShowInNewShelf) {
                        Text("New shelf").tag(true)
                        Text("Existing shelf").tag(false)
                    }
                } header: {
                    Text("Location")
                }
                
                Section {
                    Toggle("Copy screenshot to clipboard", isOn: $screenshotCopyToClipboard)
                        .help("Automatically copy new screenshots to the clipboard")
                    
                    Toggle("Show confirmation message", isOn: $screenshotShowConfirmation)
                        .help("Show a notification when a screenshot is added")
                } header: {
                    Text("Options")
                }
                
                Section {
                    Button("Rerun Setup...") {
                        // Rerun permission setup
                        PermissionService().openScreenRecordingPreferences()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Screenshot Shelf")
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                screenshotFolderPath = url.path
            }
        }
    }
    
    private var folderDisplayName: String {
        let path = screenshotFolderPath as NSString
        return path.lastPathComponent
    }
}

#Preview {
    ScreenshotShelfSettingsView()
}
