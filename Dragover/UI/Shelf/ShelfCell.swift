import Cocoa
import SwiftUI

/// NSCollectionViewItem for displaying shelf items
@objc(ShelfCollectionViewItem)
class ShelfCollectionViewItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("ShelfCollectionViewItem")
    

    // UI Components
    private let thumbnailImageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let selectionView = NSView()
    private let closeButton = NSButton()
    
    // State
    private var trackingArea: NSTrackingArea?
    private var isHovering = false
    
    // Callbacks
    var onRemove: (() -> Void)?
    
    override func loadView() {
        self.view = NSView(frame: .zero)
        self.view.wantsLayer = true
        self.view.layer?.cornerRadius = 12
        self.view.layer?.masksToBounds = true
    }
    
    // Ensure we don't try to load a NIB
    override var nibName: NSNib.Name? {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTrackingArea()
    }
    
    private func setupUI() {
        // Selection View
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.wantsLayer = true
        selectionView.layer?.cornerRadius = 12
        selectionView.layer?.borderWidth = 3
        selectionView.layer?.borderColor = NSColor.clear.cgColor
        selectionView.layer?.backgroundColor = NSColor.clear.cgColor
        view.addSubview(selectionView)
        
        // Constraints for Selection View
        NSLayoutConstraint.activate([
            selectionView.topAnchor.constraint(equalTo: view.topAnchor),
            selectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            selectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Stack View for layout
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 6
        stackView.alignment = .centerX
        stackView.translatesAutoresizingMaskIntoConstraints = false
        // Stack view must be above selection view
        view.addSubview(stackView)
        
        // Thumbnail Container
        let thumbnailContainer = NSView()
        thumbnailContainer.translatesAutoresizingMaskIntoConstraints = false
        thumbnailContainer.wantsLayer = true
        thumbnailContainer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.05).cgColor
        thumbnailContainer.layer?.cornerRadius = 10
        
        // Thumbnail Image
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.imageScaling = .scaleProportionallyUpOrDown
        thumbnailContainer.addSubview(thumbnailImageView)
        
        stackView.addArrangedSubview(thumbnailContainer)
        
        // Title Label
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center
        titleLabel.maximumNumberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)
        
        // Close Button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.bezelStyle = .inline
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Remove")?.withSymbolConfiguration(.init(paletteColors: [.white, .systemRed]))
        closeButton.target = self
        closeButton.action = #selector(removeClicked)
        closeButton.isBordered = false
        closeButton.isHidden = true
        view.addSubview(closeButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            
            thumbnailContainer.widthAnchor.constraint(equalToConstant: 60),
            thumbnailContainer.heightAnchor.constraint(equalToConstant: 60),
            
            thumbnailImageView.topAnchor.constraint(equalTo: thumbnailContainer.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: thumbnailContainer.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: thumbnailContainer.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: thumbnailContainer.bottomAnchor),
            
            titleLabel.widthAnchor.constraint(equalToConstant: 80),
            titleLabel.heightAnchor.constraint(equalToConstant: 28),
            
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),
            closeButton.widthAnchor.constraint(equalToConstant: 18),
            closeButton.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: view.bounds, options: options, owner: self, userInfo: nil)
        view.addTrackingArea(trackingArea!)
    }
    
    func configure(with item: ShelfItem) {
        titleLabel.stringValue = item.displayName
        
        // Load thumbnail async
        if let thumb = item.thumbnail {
            thumbnailImageView.image = thumb
        } else if let url = item.url {
            thumbnailImageView.image = NSWorkspace.shared.icon(forFile: url.path)
            
            // Async load high-res thumbnail if needed
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
                guard imageExtensions.contains(url.pathExtension.lowercased()),
                      let image = NSImage(contentsOf: url) else { return }
                
                // Use safe resizing
                let size = NSSize(width: 128, height: 128)
                let resized = NSImage(size: size, flipped: false) { rect in
                    image.draw(in: rect, from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
                    return true
                }
                
                DispatchQueue.main.async {
                    self?.thumbnailImageView.image = resized
                }
            }
        } else {
            thumbnailImageView.image = NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            updateSelectionState()
        }
    }
    
    private func updateSelectionState() {
        if isSelected {
            selectionView.layer?.borderColor = NSColor.controlAccentColor.cgColor
            selectionView.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
        } else if highlightState == .forSelection {
             selectionView.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.5).cgColor
             selectionView.layer?.backgroundColor = NSColor.clear.cgColor
        } else {
            selectionView.layer?.borderColor = NSColor.clear.cgColor
            selectionView.layer?.backgroundColor = isHovering ? NSColor.labelColor.withAlphaComponent(0.05).cgColor : NSColor.clear.cgColor
        }
    }
    
    // MARK: - Mouse Events
    
    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        updateSelectionState()
        closeButton.isHidden = false
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovering = false
        updateSelectionState()
        closeButton.isHidden = true
    }
    
    @objc private func removeClicked() {
        onRemove?()
    }
}
