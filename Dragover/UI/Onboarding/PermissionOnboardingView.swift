import SwiftUI
import AppKit

/// Onboarding view for requesting system permissions
struct PermissionOnboardingView: View {
    @State private var accessibilityGranted = false
    
    private let permissionService = PermissionService()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 20)
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text("Welcome to Dragover")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Dragover needs Accessibility permission to detect drag gestures.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Divider()
                .padding(.horizontal, 40)
            
            // Permission status
            HStack(spacing: 16) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accessibility")
                        .font(.headline)
                    
                    Text("Required to detect drag gestures and cursor movements")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if accessibilityGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .padding(.horizontal, 30)
            
            // Instructions
            if !accessibilityGranted {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to enable:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Click \"Open Settings\" button below")
                        Text("2. Click the + button in System Settings")
                        Text("3. Find and add Dragover")
                        Text("4. Toggle it ON")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.1))
                )
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 16) {
                if accessibilityGranted {
                    Label("Permission Granted!", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Button("Get Started") {
                        closeWindow()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Open Settings") {
                        openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            Spacer()
                .frame(height: 30)
        }
        .frame(width: 520, height: 600)
        .onAppear {
            checkPermissions()
            startPolling()
        }
    }
    
    private func checkPermissions() {
        accessibilityGranted = permissionService.isAccessibilityGranted
    }
    
    private func startPolling() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            accessibilityGranted = permissionService.isAccessibilityGranted
            if accessibilityGranted {
                timer.invalidate()
            }
        }
    }
    
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func closeWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "Welcome to Dragover" }) {
            window.close()
        }
    }
}

#Preview {
    PermissionOnboardingView()
}
