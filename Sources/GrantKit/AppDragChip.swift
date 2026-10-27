#if os(macOS)
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The draggable app card. Dragging provides the app bundle's file URL,
/// which the System Settings permission lists accept as a drop.
struct AppDragChip: NSViewRepresentable {
    let app: AppIdentity

    func makeNSView(context: Context) -> AppDragChipView {
        AppDragChipView(app: app)
    }

    func updateNSView(_ nsView: AppDragChipView, context: Context) {}
}

final class AppDragChipView: NSView, NSDraggingSource, NSPasteboardItemDataProvider {
    private let app: AppIdentity
    private let row = NSView()

    init(app: AppIdentity) {
        self.app = app
        super.init(frame: .zero)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        let item = NSPasteboardItem()
        item.setDataProvider(self, forTypes: [.fileURL])

        let draggingItem = NSDraggingItem(pasteboardWriter: item)
        draggingItem.setDraggingFrame(row.frame, contents: dragImage())

        let session = beginDraggingSession(with: [draggingItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    // MARK: NSPasteboardItemDataProvider

    func pasteboard(
        _ pasteboard: NSPasteboard?,
        item: NSPasteboardItem,
        provideDataForType type: NSPasteboard.PasteboardType
    ) {
        guard type == .fileURL else { return }
        item.setData(app.bundleURL.dataRepresentation, forType: .fileURL)
    }

    // MARK: NSDraggingSource

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        row.isHidden = true
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        row.isHidden = false
    }

    // MARK: Appearance

    private func setUp() {
        wantsLayer = true
        row.wantsLayer = true
        row.layer?.cornerRadius = 8
        row.layer?.borderWidth = 1
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        let iconView = NSImageView(image: app.icon)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(iconView)

        let label = NSTextField(labelWithString: app.displayName)
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(label)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(lessThanOrEqualTo: row.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        updateColors()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    private func updateColors() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        row.layer?.backgroundColor = isDark
            ? NSColor.white.withAlphaComponent(0.06).cgColor
            : NSColor.white.withAlphaComponent(0.65).cgColor
        row.layer?.borderColor = isDark
            ? NSColor.white.withAlphaComponent(0.08).cgColor
            : NSColor.black.withAlphaComponent(0.08).cgColor
    }

    private func dragImage() -> NSImage {
        let image = NSImage(size: row.bounds.size)
        image.lockFocus()
        if let context = NSGraphicsContext.current {
            row.displayIgnoringOpacity(row.bounds, in: context)
        }
        image.unlockFocus()
        return image
    }
}
#endif
