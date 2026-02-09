import Foundation
import AppKit

/// Action to compress items into a ZIP archive using NSFileCoordinator
struct CompressAction: InstantAction {
    let id = "compress"
    let name = "Compress"
    let systemImageName = "archivebox.fill"
    
    func execute(items: [ShelfItem]) async throws {
        let urls = items.compactMap { $0.url }
        guard !urls.isEmpty else { throw InstantActionError.noURLs }
        
        // Verify all files exist
        for url in urls {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw InstantActionError.fileNotFound(url)
            }
        }
        
        // Determine output location
        let firstURL = urls[0]
        let parentDirectory = firstURL.deletingLastPathComponent()
        let archiveName: String
        
        if urls.count == 1 {
            archiveName = firstURL.deletingPathExtension().lastPathComponent + ".zip"
        } else {
            archiveName = "Archive.zip"
        }
        
        let archiveURL = parentDirectory.appendingPathComponent(archiveName)
        let finalURL = uniqueURL(for: archiveURL)
        
        // Use Archive utility via NSWorkspace
        await MainActor.run {
            // Create a temporary folder with the files to compress
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                
                // Copy files to temp directory
                for url in urls {
                    let destURL = tempDir.appendingPathComponent(url.lastPathComponent)
                    try FileManager.default.copyItem(at: url, to: destURL)
                }
                
                // Use zip command (more compatible than ditto in sandbox)
                let process = Process()
                process.currentDirectoryURL = tempDir
                process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
                process.arguments = ["-r", finalURL.path] + urls.map { $0.lastPathComponent }
                
                try process.run()
                process.waitUntilExit()
                
                // Clean up temp directory
                try? FileManager.default.removeItem(at: tempDir)
                
                if process.terminationStatus == 0 {
                    // Reveal the created archive
                    NSWorkspace.shared.selectFile(finalURL.path, inFileViewerRootedAtPath: parentDirectory.path)
                }
            } catch {
                try? FileManager.default.removeItem(at: tempDir)
            }
        }
    }
    
    private func uniqueURL(for url: URL) -> URL {
        var finalURL = url
        var counter = 1
        
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let baseName = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            let newName = "\(baseName) \(counter).\(ext)"
            finalURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
        }
        
        return finalURL
    }
}
