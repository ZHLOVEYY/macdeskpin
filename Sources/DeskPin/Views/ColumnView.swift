import SwiftUI
import AppKit

struct ColumnView: View {
    let columnId: UUID
    @ObservedObject var store: BoardStore
    @State private var isTargeted = false
    @State private var showSettings = false
    @State private var showClearConfirm = false

    /// Always read fresh from store
    private var config: ColumnConfig {
        store.columns.first(where: { $0.id == columnId }) ?? ColumnConfig(name: "?", type: .todo, colorHex: "#999999", order: 0)
    }

    private var themeColor: Color { Color(hex: config.colorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar: [resize 1/4] [drag 2/4] [resize 1/4]
            TopBar()
                .frame(height: 22)

            headerView
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            Divider().padding(.horizontal, 8)

            switch config.type {
            case .todo, .done:
                TodoColumnContent(columnId: config.id, columnType: config.type, store: store, themeColor: themeColor)
            case .note:
                NoteColumnContent(columnId: config.id, store: store, themeColor: themeColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .opacity(0.92)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isTargeted ? themeColor.opacity(0.7) : Color.white.opacity(0.1),
                    lineWidth: isTargeted ? 2 : 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .dropDestination(for: String.self) { items, _ in
            guard config.type == .todo || config.type == .done else { return false }
            guard let payload = items.first else { return false }
            let parts = payload.split(separator: ":")
            guard parts.count == 2,
                  let taskId = UUID(uuidString: String(parts[0])),
                  let sourceId = UUID(uuidString: String(parts[1])) else { return false }
            store.moveTask(taskId, from: sourceId, to: config.id)
            return true
        } isTargeted: { t in
            isTargeted = t
        }
        .sheet(isPresented: $showSettings) {
            ColumnSettingsView(config: config, store: store, isPresented: $showSettings)
        }
    }

    private var hasContent: Bool {
        switch config.type {
        case .todo, .done:
            return !(store.taskLists[columnId]?.tasks.isEmpty ?? true)
        case .note:
            return !(store.noteContents[columnId] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var headerView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(themeColor)
                .frame(width: 10, height: 10)

            Text(config.name)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(themeColor)

            Spacer()

            if hasContent {
                Button(action: { showClearConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.red.opacity(0.4))
                }
                .buttonStyle(.plain)
                .help("Clear all")
            }

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .alert("Clear all content?", isPresented: $showClearConfirm) {
            Button("Clear", role: .destructive) {
                switch config.type {
                case .todo, .done:
                    store.clearTasks(for: columnId)
                case .note:
                    store.saveNoteContent("", for: columnId)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }
}

// MARK: - Top bar: three zones

struct TopBar: NSViewRepresentable {
    func makeNSView(context: Context) -> TopBarView { TopBarView() }
    func updateNSView(_ nsView: TopBarView, context: Context) {}
}

/// Three-zone top bar:
///   Left 1/4  → resize (vertical cursor, triggers window resize from top-left)
///   Center 2/4 → drag (hand cursor, moves window)
///   Right 1/4  → resize (vertical cursor, triggers window resize from top-right)
class TopBarView: NSView {
    private var trackingArea: NSTrackingArea?
    private var zone: Zone = .drag

    enum Zone { case resizeLeft, drag, resizeRight }

    override var mouseDownCanMoveWindow: Bool { false }

    private func currentZone(at point: NSPoint) -> Zone {
        let quarter = bounds.width / 4
        if point.x < quarter { return .resizeLeft }
        else if point.x > bounds.width - quarter { return .resizeRight }
        else { return .drag }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw center drag dots
        let centerX = bounds.width / 2
        let y = bounds.height / 2
        let dotColor = NSColor.secondaryLabelColor.withAlphaComponent(0.25)
        dotColor.setFill()

        let dotSize: CGFloat = 3
        let spacing: CGFloat = 5
        for i in -1...1 {
            let x = centerX + CGFloat(i) * (dotSize + spacing) - dotSize / 2
            NSBezierPath(ovalIn: NSRect(x: x, y: y - dotSize / 2, width: dotSize, height: dotSize)).fill()
        }

        // Draw corner resize indicators (small triangles)
        let edgeColor = NSColor.secondaryLabelColor.withAlphaComponent(0.18)
        edgeColor.setFill()
        // Left corner: two small lines forming an angle
        let path1 = NSBezierPath()
        path1.move(to: NSPoint(x: 4, y: bounds.height - 4))
        path1.line(to: NSPoint(x: 4, y: bounds.height - 10))
        path1.move(to: NSPoint(x: 4, y: bounds.height - 4))
        path1.line(to: NSPoint(x: 10, y: bounds.height - 4))
        edgeColor.setStroke()
        path1.lineWidth = 1.5
        path1.stroke()
        // Right corner
        let path2 = NSBezierPath()
        path2.move(to: NSPoint(x: bounds.width - 4, y: bounds.height - 4))
        path2.line(to: NSPoint(x: bounds.width - 4, y: bounds.height - 10))
        path2.move(to: NSPoint(x: bounds.width - 4, y: bounds.height - 4))
        path2.line(to: NSPoint(x: bounds.width - 10, y: bounds.height - 4))
        path2.lineWidth = 1.5
        path2.stroke()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea { removeTrackingArea(ta) }
        trackingArea = NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways], owner: self)
        addTrackingArea(trackingArea!)
    }

    override func mouseMoved(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        zone = currentZone(at: pt)
        updateCursor()
    }

    override func mouseEntered(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        zone = currentZone(at: pt)
        updateCursor()
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        zone = currentZone(at: pt)

        switch zone {
        case .drag:
            NSCursor.closedHand.set()
            window?.performDrag(with: event)
        case .resizeLeft:
            handleDiagonalResize(with: event, anchorRight: true)
        case .resizeRight:
            handleDiagonalResize(with: event, anchorRight: false)
        }
    }

    override func mouseUp(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        zone = currentZone(at: pt)
        updateCursor()
    }

    private func updateCursor() {
        switch zone {
        case .resizeLeft:
            // Top-left corner: diagonal NW-SE resize
            NSCursor(image: NSCursor.arrow.image, hotSpot: NSPoint(x: 8, y: 8)).set()
            NSCursor.crosshair.set()
        case .resizeRight:
            // Top-right corner: diagonal NE-SW resize
            NSCursor.crosshair.set()
        case .drag:
            NSCursor.openHand.set()
        }
    }

    /// Diagonal resize: both width+height change, one corner stays anchored
    private func handleDiagonalResize(with startEvent: NSEvent, anchorRight: Bool) {
        guard let win = window else { return }
        let startFrame = win.frame
        let startScreenPt = win.convertPoint(toScreen: startEvent.locationInWindow)

        var isDragging = true
        while isDragging {
            guard let event = NSApp.nextEvent(matching: [.leftMouseDragged, .leftMouseUp], until: .distantFuture, inMode: .eventTracking, dequeue: true) else { continue }

            switch event.type {
            case .leftMouseDragged:
                let currentScreenPt = win.convertPoint(toScreen: event.locationInWindow)
                let deltaX = currentScreenPt.x - startScreenPt.x
                let deltaY = currentScreenPt.y - startScreenPt.y

                var newFrame = startFrame

                // Vertical: extend upward (top edge moves up = height increases)
                newFrame.size.height += deltaY
                // Don't move origin.y — the bottom stays fixed, top extends

                // Horizontal: depends on which corner
                if anchorRight {
                    // Left corner dragged: origin.x moves, width changes inversely
                    newFrame.origin.x += deltaX
                    newFrame.size.width -= deltaX
                } else {
                    // Right corner dragged: width increases
                    newFrame.size.width += deltaX
                }

                // Enforce minimums
                if newFrame.size.width < win.minSize.width {
                    if anchorRight {
                        newFrame.origin.x = startFrame.maxX - win.minSize.width
                    }
                    newFrame.size.width = win.minSize.width
                }
                if newFrame.size.height < win.minSize.height {
                    newFrame.size.height = win.minSize.height
                }

                win.setFrame(newFrame, display: true)
            case .leftMouseUp:
                isDragging = false
            default:
                break
            }
        }
    }
}
