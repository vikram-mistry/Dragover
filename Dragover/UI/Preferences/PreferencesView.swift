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
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Dragover")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    + Text(" version 3.2")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow).ignoresSafeArea())
            }
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

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
