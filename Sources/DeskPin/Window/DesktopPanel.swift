import AppKit

/// Custom NSPanel that can become key (keyboard input) at desktop level.
/// Only the title bar area allows window dragging — content area does not move the window.
class DesktopPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        // Desktop level
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // IMPORTANT: false — so dragging inside content doesn't move the window
        // The standard title bar (transparent but present) still handles window dragging
        isMovableByWindowBackground = false
        isMovable = true

        minSize = NSSize(width: 200, height: 200)
    }
}
