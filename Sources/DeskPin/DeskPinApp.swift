import SwiftUI
import AppKit

@main
struct DeskPinApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("DeskPin", systemImage: "pin.fill") {
            Button("Show All") {
                appDelegate.showAll()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Hide All") {
                appDelegate.hideAll()
            }

            Divider()

            // Per-column toggles
            ForEach(appDelegate.store.columns) { col in
                Button("\(col.name) — \(appDelegate.windows[col.id]?.isVisible == true ? "Hide" : "Show")") {
                    appDelegate.toggleWindow(for: col.id)
                }
            }

            Divider()

            Button("Add Column...") {
                appDelegate.showAddColumn()
            }

            Button("Open Storage Folder") {
                NSWorkspace.shared.open(appDelegate.store.baseURL)
            }

            Button("Reload") {
                appDelegate.reload()
            }

            Divider()

            Button("Check for Updates...") {
                UpdateChecker.checkForUpdates(silent: false)
            }

            Text("v\(UpdateChecker.currentVersion)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit DeskPin") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windows: [UUID: DesktopPanel] = [:]
    let store = BoardStore()
    var addColumnPanel: DesktopPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        createWindows()

        // Listen for column deletions
        NotificationCenter.default.addObserver(forName: .columnDeleted, object: nil, queue: .main) { [weak self] notif in
            guard let columnId = notif.object as? UUID else { return }
            self?.windows[columnId]?.close()
            self?.windows.removeValue(forKey: columnId)
        }

        // Check for updates silently on launch (after 5s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            UpdateChecker.checkForUpdates(silent: true)
        }
    }

    func createWindows() {
        // Close existing column windows
        windows.values.forEach { $0.close() }
        windows.removeAll()

        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultWidth: CGFloat = 260
        let defaultHeight: CGFloat = min(500, screen.height - 80)
        let spacing: CGFloat = 16

        for (index, col) in store.columns.enumerated() {
            let frame: NSRect
            if let saved = col.windowFrame {
                frame = NSRect(x: saved.x, y: saved.y, width: saved.width, height: saved.height)
            } else {
                let totalWidth = defaultWidth * CGFloat(store.columns.count) + spacing * CGFloat(store.columns.count - 1)
                let startX = screen.maxX - totalWidth - 30
                let x = startX + CGFloat(index) * (defaultWidth + spacing)
                frame = NSRect(x: x, y: screen.minY + 40, width: defaultWidth, height: defaultHeight)
            }

            let panel = DesktopPanel(contentRect: frame)

            let columnView = ColumnView(columnId: col.id, store: store)
            let hostingView = NSHostingView(rootView: columnView)
            panel.contentView = hostingView

            // Save frame on move/resize
            let colId = col.id
            NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak self] _ in
                self?.saveFrame(for: colId, window: panel)
            }
            NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: panel, queue: .main) { [weak self] _ in
                self?.saveFrame(for: colId, window: panel)
            }

            panel.orderFront(nil)
            windows[col.id] = panel
        }
    }

    private func saveFrame(for columnId: UUID, window: NSWindow) {
        let f = window.frame
        let wf = WindowFrame(x: f.origin.x, y: f.origin.y, width: f.size.width, height: f.size.height)
        store.saveWindowFrame(wf, for: columnId)
    }

    func toggleWindow(for columnId: UUID) {
        guard let win = windows[columnId] else { return }
        if win.isVisible { win.orderOut(nil) } else { win.orderFront(nil) }
    }

    func showAll() {
        windows.values.forEach { $0.orderFront(nil) }
    }

    func hideAll() {
        windows.values.forEach { $0.orderOut(nil) }
    }

    func reload() {
        store.loadConfig()
        store.loadAllData()
        createWindows()
    }

    func showAddColumn() {
        // Reuse DesktopPanel so it doesn't crash with accessory policy
        if let existing = addColumnPanel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let w: CGFloat = 300
        let h: CGFloat = 340
        let x = screen.midX - w / 2
        let y = screen.midY - h / 2

        let panel = DesktopPanel(contentRect: NSRect(x: x, y: y, width: w, height: h))
        // Override level to be above desktop panels so it's visible
        panel.level = .floating
        panel.collectionBehavior = [.ignoresCycle]

        let view = AddColumnView(store: store) { [weak self] in
            self?.addColumnPanel?.close()
            self?.addColumnPanel = nil
            // Recreate windows to include the new column
            self?.createWindows()
        }
        panel.contentView = NSHostingView(rootView: view)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        addColumnPanel = panel
    }
}

struct AddColumnView: View {
    @ObservedObject var store: BoardStore
    var onDone: () -> Void

    @State private var name = ""
    @State private var type: ColumnType = .todo
    @State private var selectedColor = "#FF9500"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New Column")
                .font(.system(size: 15, weight: .bold))
                .padding(.top, 16) // space for title bar drag area

            TextField("Name (e.g. TODO2, Work)", text: $name)
                .textFieldStyle(.roundedBorder)

            Picker("Type", selection: $type) {
                Text("TODO").tag(ColumnType.todo)
                Text("DONE").tag(ColumnType.done)
                Text("NOTE").tag(ColumnType.note)
            }
            .pickerStyle(.segmented)

            Text("Color")
                .font(.system(size: 12, weight: .medium))

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 6), count: 5), spacing: 6) {
                ForEach(ColorOption.all) { opt in
                    Circle()
                        .fill(Color(hex: opt.hex))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle().strokeBorder(Color.white, lineWidth: selectedColor == opt.hex ? 2.5 : 0)
                        )
                        .shadow(color: selectedColor == opt.hex ? Color(hex: opt.hex).opacity(0.5) : .clear, radius: 3)
                        .onTapGesture { selectedColor = opt.hex }
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") { onDone() }
                    .controlSize(.small)
                Button("Create") {
                    let n = name.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty else { return }
                    store.addColumn(name: n, type: type, colorHex: selectedColor)
                    onDone()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
    }
}
