import Foundation
import AppKit

/// Service for managing and executing instant actions
class InstantActionService {
    static let shared = InstantActionService()
    
    private(set) var availableActions: [any InstantAction] = []
    
    private init() {
        registerBuiltInActions()
    }
    
    // MARK: - Action Registration
    
    private func registerBuiltInActions() {
        availableActions = [
            AirDropAction(),
            MessagesAction(),
            MailAction(),
            CopyAction(),
            CompressAction(),
            GetInfoAction()
        ]
    }
    
    /// Gets enabled actions based on user preferences
    func getEnabledActions() -> [any InstantAction] {
        let enabledIds = PreferencesManager.shared.enabledActions
        return availableActions.filter { enabledIds.contains($0.id) }
    }
    
    /// Executes an action with the given items
    func executeAction(_ action: any InstantAction, with items: [ShelfItem]) async {
        do {
            try await action.execute(items: items)
        } catch {
            print("Action \(action.name) failed: \(error)")
            await showErrorAlert(for: action, error: error)
        }
    }
    
    // MARK: - Private
    
    @MainActor
    private func showErrorAlert(for action: any InstantAction, error: Error) {
        let alert = NSAlert()
        alert.messageText = "Action Failed"
        alert.informativeText = "\(action.name) could not be completed: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
