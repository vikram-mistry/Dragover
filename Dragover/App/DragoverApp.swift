import SwiftUI

@main
struct DragoverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            PreferencesView()
                .environmentObject(PreferencesManager.shared)
        }
    }
}
