import Foundation
import Combine

class BoardStore: ObservableObject {
    @Published var columns: [ColumnConfig] = []
    @Published var taskLists: [UUID: TaskList] = [:]
    @Published var noteContents: [UUID: String] = [:]  // columnId -> single md content

    let baseURL: URL
    private let configURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        baseURL = appSupport.appendingPathComponent("DeskPin", isDirectory: true)
        configURL = baseURL.appendingPathComponent("config.json")
        ensureBaseDir()
        migrateUUIDFolders()
        loadConfig()
        loadAllData()
    }

    private func ensureBaseDir() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseURL.path) {
            try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
    }

    func columnDir(_ columnId: UUID) -> URL {
        guard let col = columns.first(where: { $0.id == columnId }) else {
            return baseURL.appendingPathComponent(columnId.uuidString, isDirectory: true)
        }
        return baseURL.appendingPathComponent(col.folderName, isDirectory: true)
    }

    /// Note columns store a single .md file
    func noteFileURL(_ columnId: UUID) -> URL {
        guard let col = columns.first(where: { $0.id == columnId }) else {
            return baseURL.appendingPathComponent("note.md")
        }
        return baseURL.appendingPathComponent("\(col.folderName).md")
    }

    private func migrateUUIDFolders() {
        let fm = FileManager.default
        if let data = try? Data(contentsOf: configURL),
           var config = try? JSONDecoder().decode(BoardConfig.self, from: data) {
            var changed = false
            for i in config.columns.indices {
                let oldUUIDDir = baseURL.appendingPathComponent(config.columns[i].id.uuidString, isDirectory: true)
                let newName = config.columns[i].folderName.isEmpty
                    ? ColumnConfig.sanitize(config.columns[i].name)
                    : config.columns[i].folderName
                let newDir = baseURL.appendingPathComponent(newName, isDirectory: true)
                if fm.fileExists(atPath: oldUUIDDir.path) && !fm.fileExists(atPath: newDir.path) {
                    try? fm.moveItem(at: oldUUIDDir, to: newDir)
                    config.columns[i].folderName = newName
                    changed = true
                } else if config.columns[i].folderName.isEmpty {
                    config.columns[i].folderName = newName
                    changed = true
                }
            }
            if changed {
                if let newData = try? JSONEncoder().encode(config) {
                    try? newData.write(to: configURL, options: .atomic)
                }
            }

            // Clean orphaned UUID folders
            let knownFolders = Set(config.columns.map(\.folderName))
            if let entries = try? fm.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: [.isDirectoryKey]) {
                for entry in entries {
                    let name = entry.lastPathComponent
                    let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    if isDir && UUID(uuidString: name) != nil && !knownFolders.contains(name) {
                        // Remove all orphaned UUID folders (old version artifacts)
                        try? fm.removeItem(at: entry)
                    }
                }
            }
        }
    }

    // MARK: - Config

    func loadConfig() {
        if let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(BoardConfig.self, from: data) {
            columns = config.columns.sorted { $0.order < $1.order }
            for i in columns.indices {
                if columns[i].folderName.isEmpty {
                    columns[i].folderName = ColumnConfig.sanitize(columns[i].name)
                }
            }
        } else {
            columns = ColumnConfig.defaultColumns
            saveConfig()
        }
        // Ensure task dirs exist (todo/done need folders, note just needs a file)
        let fm = FileManager.default
        for col in columns {
            if col.type == .todo || col.type == .done {
                let dir = baseURL.appendingPathComponent(col.folderName, isDirectory: true)
                if !fm.fileExists(atPath: dir.path) {
                    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
                }
            }
        }
    }

    func saveConfig() {
        let config = BoardConfig(columns: columns)
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: configURL, options: .atomic)
        }
    }

    // MARK: - Load All

    func loadAllData() {
        for col in columns {
            switch col.type {
            case .todo, .done:
                loadTasks(for: col.id)
            case .note:
                loadNote(for: col.id)
            }
        }
    }

    // MARK: - Tasks

    private func tasksURL(_ columnId: UUID) -> URL {
        columnDir(columnId).appendingPathComponent("tasks.json")
    }

    func loadTasks(for columnId: UUID) {
        let url = tasksURL(columnId)
        if let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode(TaskList.self, from: data) {
            taskLists[columnId] = list
        } else {
            taskLists[columnId] = TaskList()
        }
    }

    func saveTasks(for columnId: UUID) {
        guard let list = taskLists[columnId] else { return }
        if let data = try? JSONEncoder().encode(list) {
            try? data.write(to: tasksURL(columnId), options: .atomic)
        }
    }

    func addTask(to columnId: UUID) {
        let isDone = columns.first(where: { $0.id == columnId })?.type == .done
        let task = TaskItem(isDone: isDone)
        if taskLists[columnId] == nil { taskLists[columnId] = TaskList() }
        taskLists[columnId]?.tasks.insert(task, at: 0)
        saveTasks(for: columnId)
    }

    func updateTask(_ task: TaskItem, in columnId: UUID) {
        guard let idx = taskLists[columnId]?.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        taskLists[columnId]?.tasks[idx] = task
        saveTasks(for: columnId)
    }

    func deleteTask(_ taskId: UUID, from columnId: UUID) {
        taskLists[columnId]?.tasks.removeAll { $0.id == taskId }
        saveTasks(for: columnId)
    }

    func clearTasks(for columnId: UUID) {
        taskLists[columnId]?.tasks.removeAll()
        saveTasks(for: columnId)
    }

    func exportTasksAsMarkdown(for columnId: UUID) -> String {
        let tasks = taskLists[columnId]?.tasks ?? []
        let colName = columns.first(where: { $0.id == columnId })?.name ?? "Tasks"
        var lines: [String] = ["## \(colName)", ""]
        for task in tasks {
            let check = task.isDone ? "x" : " "
            lines.append("- [\(check)] \(task.title)")
            if !task.comment.isEmpty {
                // Indent comment lines under the task
                let commentLines = task.comment.components(separatedBy: "\n")
                for cl in commentLines {
                    lines.append("  > \(cl)")
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    func moveTask(_ taskId: UUID, from sourceId: UUID, to destId: UUID) {
        guard sourceId != destId else { return }
        guard var task = taskLists[sourceId]?.tasks.first(where: { $0.id == taskId }) else { return }

        let destType = columns.first(where: { $0.id == destId })?.type
        if destType == .done { task.isDone = true }
        else if destType == .todo { task.isDone = false }

        taskLists[sourceId]?.tasks.removeAll { $0.id == taskId }
        if taskLists[destId] == nil { taskLists[destId] = TaskList() }
        taskLists[destId]?.tasks.insert(task, at: 0)

        saveTasks(for: sourceId)
        saveTasks(for: destId)
    }

    // MARK: - Notes (single file per column)

    func loadNote(for columnId: UUID) {
        let url = noteFileURL(columnId)
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            noteContents[columnId] = content
        } else {
            noteContents[columnId] = ""
        }
    }

    func saveNoteContent(_ content: String, for columnId: UUID) {
        noteContents[columnId] = content
        let url = noteFileURL(columnId)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Column Management

    func addColumn(name: String, type: ColumnType, colorHex: String) {
        let order = (columns.map(\.order).max() ?? -1) + 1
        let folder = uniqueFolderName(for: name)
        let col = ColumnConfig(name: name, type: type, colorHex: colorHex, order: order, folderName: folder)
        columns.append(col)
        if type == .todo || type == .done {
            let dir = baseURL.appendingPathComponent(folder, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            taskLists[col.id] = TaskList()
        } else {
            noteContents[col.id] = ""
            let url = baseURL.appendingPathComponent("\(folder).md")
            try? "".write(to: url, atomically: true, encoding: .utf8)
        }
        saveConfig()
    }

    private func uniqueFolderName(for name: String) -> String {
        let base = ColumnConfig.sanitize(name)
        var candidate = base
        var counter = 2
        let existingNames = Set(columns.map(\.folderName))
        while existingNames.contains(candidate) {
            candidate = "\(base)-\(counter)"
            counter += 1
        }
        return candidate
    }

    func removeColumn(_ columnId: UUID) {
        guard let col = columns.first(where: { $0.id == columnId }) else { return }
        columns.removeAll { $0.id == columnId }
        taskLists.removeValue(forKey: columnId)
        noteContents.removeValue(forKey: columnId)
        if col.type == .todo || col.type == .done {
            let dir = baseURL.appendingPathComponent(col.folderName, isDirectory: true)
            try? FileManager.default.removeItem(at: dir)
        } else {
            let url = baseURL.appendingPathComponent("\(col.folderName).md")
            try? FileManager.default.removeItem(at: url)
        }
        saveConfig()
    }

    func updateColumn(_ config: ColumnConfig) {
        if let idx = columns.firstIndex(where: { $0.id == config.id }) {
            let oldFolder = columns[idx].folderName
            let oldType = columns[idx].type
            columns[idx] = config
            // Rename on disk if folder name changed
            if config.folderName != oldFolder {
                if oldType == .note {
                    let oldFile = baseURL.appendingPathComponent("\(oldFolder).md")
                    let newFile = baseURL.appendingPathComponent("\(config.folderName).md")
                    if FileManager.default.fileExists(atPath: oldFile.path) && !FileManager.default.fileExists(atPath: newFile.path) {
                        try? FileManager.default.moveItem(at: oldFile, to: newFile)
                    }
                } else {
                    let oldDir = baseURL.appendingPathComponent(oldFolder, isDirectory: true)
                    let newDir = baseURL.appendingPathComponent(config.folderName, isDirectory: true)
                    if FileManager.default.fileExists(atPath: oldDir.path) && !FileManager.default.fileExists(atPath: newDir.path) {
                        try? FileManager.default.moveItem(at: oldDir, to: newDir)
                    }
                }
            }
            saveConfig()
        }
    }

    func saveWindowFrame(_ frame: WindowFrame, for columnId: UUID) {
        if let idx = columns.firstIndex(where: { $0.id == columnId }) {
            columns[idx].windowFrame = frame
            saveConfig()
        }
    }
}
