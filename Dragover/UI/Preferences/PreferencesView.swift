import SwiftUI

/// Main preferences window with sidebar navigation
struct PreferencesView: View {
    @EnvironmentObject var preferences: PreferencesManager
    
    @State private var selectedTab: PreferencesTab = .general
    
    var body: some View {
        NavigationSplitView {
            List(PreferencesTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180)
        } detail: {
            selectedTab.view
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        }
        .frame(minWidth: 650, minHeight: 450)
    }
}

/// Preference tabs
enum PreferencesTab: String, CaseIterable {
    case general
    case shelfActivation
    case shelfInteraction
    case instantActions
    case screenshotShelf
    
    var title: String {
        switch self {
        case .general: return "General"
        case .shelfActivation: return "Shelf Activation"
        case .shelfInteraction: return "Shelf Interaction"
        case .instantActions: return "Instant Actions"
        case .screenshotShelf: return "Screenshot Shelf"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "gear"
        case .shelfActivation: return "hand.tap"
        case .shelfInteraction: return "cursorarrow.click.2"
        case .instantActions: return "bolt.fill"
        case .screenshotShelf: return "camera.viewfinder"
        }
    }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .general:
            GeneralSettingsView()
        case .shelfActivation:
            ShelfActivationSettingsView()
        case .shelfInteraction:
            ShelfInteractionSettingsView()
        case .instantActions:
            InstantActionsSettingsView()
        case .screenshotShelf:
            ScreenshotShelfSettingsView()
        }
    }
}

#Preview {
    PreferencesView()
        .environmentObject(PreferencesManager.shared)
}
