import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// View showing instant actions below the shelf
struct InstantActionsView: View {
    let items: [ShelfItem]
    let selectedItemIds: Set<UUID>
    
    @State private var hoveredAction: String?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var actions: [any InstantAction] {
        InstantActionService.shared.getEnabledActions()
    }
    
    /// Get the items to execute action on (selected item or all items)
    private var targetItems: [ShelfItem] {
        if !selectedItemIds.isEmpty {
            return items.filter { selectedItemIds.contains($0.id) }
        }
        return items
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(actions, id: \.id) { action in
                InstantActionButton(
                    action: action,
                    isHovered: hoveredAction == action.id,
                    onExecute: {
                        executeAction(action, with: targetItems)
                    }
                )
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hoveredAction = hovering ? action.id : nil
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .alert("Action Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func executeAction(_ action: any InstantAction, with items: [ShelfItem]) {
        Task {
            do {
                try await action.execute(items: items)
            } catch {
                await MainActor.run {
                    errorMessage = "\(action.name) could not be completed:\n\(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

/// Individual action button
struct InstantActionButton: View {
    let action: any InstantAction
    let isHovered: Bool
    let onExecute: () -> Void
    
    var body: some View {
        Button(action: onExecute) {
            VStack(spacing: 5) {
                Image(nsImage: action.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                
                Text(action.name)
                    .font(.system(size: 10))
                    .foregroundColor(.primary.opacity(0.8))
                    .lineLimit(1)
            }
            .frame(width: 55, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? Color.primary.opacity(0.15) : Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}
