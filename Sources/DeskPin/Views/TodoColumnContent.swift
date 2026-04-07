import SwiftUI
import AppKit

struct TodoColumnContent: View {
    let columnId: UUID
    let columnType: ColumnType
    @ObservedObject var store: BoardStore
    let themeColor: Color

    @State private var showCopiedToast = false

    var tasks: [TaskItem] {
        store.taskLists[columnId]?.tasks ?? []
    }

    var isDone: Bool { columnType == .done }

    var body: some View {
        VStack(spacing: 0) {
            // Action bar
            HStack(spacing: 6) {
                // New Task
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    store.addTask(to: columnId)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                        Text("New")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(themeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(themeColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)

                // Export (DONE only)
                if isDone {
                    Button(action: exportToClipboard) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 10))
                            Text("Export")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .disabled(tasks.isEmpty)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)

            // Copied toast
            if showCopiedToast {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                    Text("Copied to clipboard!")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 4)
                .transition(.opacity)
            }

            // Task list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(tasks) { task in
                        TaskRowView(
                            task: task,
                            columnId: columnId,
                            store: store,
                            themeColor: themeColor
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    private func exportToClipboard() {
        let md = store.exportTasksAsMarkdown(for: columnId)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(md, forType: .string)
        withAnimation { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showCopiedToast = false }
        }
    }
}

struct TaskRowView: View {
    let task: TaskItem
    let columnId: UUID
    @ObservedObject var store: BoardStore
    let themeColor: Color

    @State private var showComment = false
    @State private var isHovering = false
    @State private var titleText: String = ""
    @State private var commentText: String = ""
    @State private var isEditingTitle = false
    @State private var showTooltip = false
    @State private var hoverTimer: Timer?
    @State private var saveTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                // LEFT: checkbox + title
                HStack(spacing: 6) {
                    Button(action: { toggleDone() }) {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundStyle(task.isDone ? themeColor : .secondary)
                    }
                    .buttonStyle(.plain)

                    if isEditingTitle || task.title.isEmpty {
                        TextField("Enter task...", text: $titleText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .onAppear {
                                titleText = task.title
                                isEditingTitle = true  // lock editing mode so re-render doesn't kill TextField
                                NSApp.activate(ignoringOtherApps: true)
                            }
                            .onSubmit {
                                // Enter: save immediately and exit editing
                                saveTimer?.invalidate()
                                var updated = task
                                updated.title = titleText
                                store.updateTask(updated, in: columnId)
                                if !titleText.isEmpty {
                                    isEditingTitle = false
                                }
                            }
                            .onChange(of: titleText) { _, newVal in
                                // Debounced auto-save (300ms after last keystroke)
                                saveTimer?.invalidate()
                                saveTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    DispatchQueue.main.async {
                                        var updated = task
                                        updated.title = newVal
                                        store.updateTask(updated, in: columnId)
                                    }
                                }
                            }
                    } else {
                        Text(task.title)
                            .font(.system(size: 12))
                            .strikethrough(task.isDone, color: .secondary)
                            .foregroundStyle(task.isDone ? .secondary : .primary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                titleText = task.title
                                isEditingTitle = true
                                NSApp.activate(ignoringOtherApps: true)
                            }
                    }
                }
                .frame(maxWidth: .infinity)

                // RIGHT: comment, delete, drag
                HStack(spacing: 4) {
                    Button(action: {
                        showComment.toggle()
                        if showComment {
                            commentText = task.comment
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }) {
                        Image(systemName: task.comment.isEmpty ? "text.bubble" : "text.bubble.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(task.comment.isEmpty ? .secondary.opacity(0.4) : themeColor)
                    }
                    .buttonStyle(.plain)

                    if isHovering {
                        Button(action: {
                            store.deleteTask(task.id, from: columnId)
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }

                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .frame(width: 20, height: 24)
                        .contentShape(Rectangle())
                        .draggable("\(task.id.uuidString):\(columnId.uuidString)") {
                            HStack(spacing: 4) {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(themeColor)
                                Text(task.title.isEmpty ? "Task" : task.title)
                                    .font(.system(size: 12))
                            }
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial))
                        }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .popover(isPresented: $showTooltip, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 12, weight: .semibold))
                    if !task.comment.isEmpty {
                        Divider()
                        Text(task.comment)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: 220)
            }

            // Comment area
            if showComment {
                VStack(alignment: .leading, spacing: 4) {
                    Divider().opacity(0.3).padding(.horizontal, 8)

                    HStack(alignment: .top, spacing: 0) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .padding(.top, 4)
                            .padding(.leading, 10)

                        TextField("Add a note...", text: $commentText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                            .lineLimit(1...5)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .onAppear { NSApp.activate(ignoringOtherApps: true) }
                            .onChange(of: commentText) { _, newVal in
                                var updated = task
                                updated.comment = newVal
                                store.updateTask(updated, in: columnId)
                            }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .textBackgroundColor).opacity(0.3))
                            .padding(.horizontal, 8)
                    )
                }
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(isHovering ? 0.7 : 0.4))
        )
        .onHover { h in
            isHovering = h
            hoverTimer?.invalidate()
            if h && !isEditingTitle && !showComment && !task.title.isEmpty {
                hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                    DispatchQueue.main.async { showTooltip = true }
                }
            } else {
                showTooltip = false
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showComment)
    }

    private func toggleDone() {
        var updated = task
        updated.isDone.toggle()
        store.updateTask(updated, in: columnId)
    }
}
