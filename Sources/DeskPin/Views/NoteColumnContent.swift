import SwiftUI
import AppKit

/// Focus-driven note editor:
/// - Click rendered markdown → raw editor appears
/// - Click outside editor / press Esc → auto-save and re-render
struct NoteColumnContent: View {
    let columnId: UUID
    @ObservedObject var store: BoardStore
    let themeColor: Color

    @State private var isEditing = false
    @State private var editText: String = ""
    private var content: String {
        store.noteContents[columnId] ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            if isEditing {
                editorView
            } else {
                previewView
            }

            // Bottom bar: file path + clear
            HStack {
                let filename = store.columns.first(where: { $0.id == columnId })?.folderName ?? "note"
                Text("\(filename).md")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.5))
                Spacer()
                if isEditing {
                    Text("editing")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(themeColor.opacity(0.6))
                }


            }
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
        }


    }

    // MARK: - Preview

    private var previewView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                let lines = content.components(separatedBy: "\n")
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    renderLine(line)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 1)
                }

                if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(spacing: 8) {
                        Spacer().frame(height: 20)
                        Text("Click to start writing...")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .onTapGesture {
                editText = content
                isEditing = true
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - Editor

    private var editorView: some View {
        ClickOutsideTextEditor(
            text: $editText,
            onClickOutside: {
                store.saveNoteContent(editText, for: columnId)
                isEditing = false
            },
            onEscape: {
                store.saveNoteContent(editText, for: columnId)
                isEditing = false
            }
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    // MARK: - Line rendering

    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            Spacer().frame(height: 6)
        } else if trimmed.hasPrefix("# ") {
            Text(trimmed.dropFirst(2))
                .font(.system(size: 18, weight: .bold))
        } else if trimmed.hasPrefix("## ") {
            Text(trimmed.dropFirst(3))
                .font(.system(size: 15, weight: .bold))
        } else if trimmed.hasPrefix("### ") {
            Text(trimmed.dropFirst(4))
                .font(.system(size: 13, weight: .semibold))
        } else if trimmed.hasPrefix("- [x] ") {
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                Text(trimmed.dropFirst(6))
                    .font(.system(size: 12))
                    .strikethrough(true, color: .secondary)
                    .foregroundStyle(.secondary)
            }
        } else if trimmed.hasPrefix("- [ ] ") {
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "square")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(trimmed.dropFirst(6))
                    .font(.system(size: 12))
            }
        } else if trimmed.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 4) {
                Text("•")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                inlineText(String(trimmed.dropFirst(2)))
            }
        } else if trimmed.hasPrefix("> ") {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(themeColor.opacity(0.4))
                    .frame(width: 3)
                inlineText(String(trimmed.dropFirst(2)))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 1)
        } else if trimmed.hasPrefix("---") {
            Divider().padding(.vertical, 4)
        } else if trimmed.hasPrefix("```") {
            Text(trimmed)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        } else {
            inlineText(trimmed)
        }
    }

    @ViewBuilder
    private func inlineText(_ text: String) -> some View {
        if let attr = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attr).font(.system(size: 12))
        } else {
            Text(text).font(.system(size: 12))
        }
    }
}

// MARK: - NSTextView that detects clicks outside itself via event monitor

struct ClickOutsideTextEditor: NSViewRepresentable {
    @Binding var text: String
    let onClickOutside: () -> Void
    let onEscape: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        textView.string = text

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
            // Install event monitor to detect clicks outside this text view
            context.coordinator.installEventMonitor()
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text && !context.coordinator.isEditing {
            textView.string = text
        }
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        coordinator.removeEventMonitor()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ClickOutsideTextEditor
        var isEditing = false
        weak var textView: NSTextView?
        private var localMonitor: Any?
        private var globalMonitor: Any?

        init(_ parent: ClickOutsideTextEditor) {
            self.parent = parent
        }

        func installEventMonitor() {
            // Local monitor: clicks inside this app's windows
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
                self?.handleClick(event)
                return event
            }
            // Global monitor: clicks outside this app entirely (e.g. Finder, desktop)
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
                self?.triggerFocusLost()
            }
        }

        func removeEventMonitor() {
            if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
            if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        }

        private func handleClick(_ event: NSEvent) {
            guard let tv = textView else { return }
            // Convert click location to the text view's coordinate space
            guard let eventWindow = event.window else {
                triggerFocusLost()
                return
            }
            let locationInWindow = event.locationInWindow
            let locationInScreen = eventWindow.convertPoint(toScreen: locationInWindow)

            guard let tvWindow = tv.window else { return }
            let locationInTVWindow = tvWindow.convertPoint(fromScreen: locationInScreen)
            let scrollView = tv.enclosingScrollView ?? tv.superview!
            let locationInScrollView = scrollView.convert(locationInTVWindow, from: nil)

            if !scrollView.bounds.contains(locationInScrollView) {
                triggerFocusLost()
            }
        }

        private func triggerFocusLost() {
            DispatchQueue.main.async { [weak self] in
                self?.removeEventMonitor()
                self?.parent.onClickOutside()
            }
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
            // Also trigger on normal focus loss (if it happens)
            removeEventMonitor()
            parent.onClickOutside()
        }

        // Handle Escape key
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                removeEventMonitor()
                parent.onEscape()
                return true
            }
            return false
        }
    }
}
