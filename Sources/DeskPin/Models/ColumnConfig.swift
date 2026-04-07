import Foundation

enum ColumnType: String, Codable {
    case todo
    case done
    case note
}

struct ColumnConfig: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var type: ColumnType
    var colorHex: String
    var order: Int
    var folderName: String  // human-readable folder name on disk
    var windowFrame: WindowFrame?

    init(id: UUID = UUID(), name: String, type: ColumnType, colorHex: String, order: Int, folderName: String? = nil, windowFrame: WindowFrame? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.colorHex = colorHex
        self.order = order
        self.folderName = folderName ?? Self.sanitize(name)
        self.windowFrame = windowFrame
    }

    static func sanitize(_ name: String) -> String {
        let cleaned = name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        return cleaned.isEmpty ? "column" : cleaned
    }

    static var defaultColumns: [ColumnConfig] {
        [
            ColumnConfig(name: "TODO", type: .todo, colorHex: "#FF9500", order: 0, folderName: "todo"),
            ColumnConfig(name: "DONE", type: .done, colorHex: "#34C759", order: 1, folderName: "done"),
            ColumnConfig(name: "NOTE", type: .note, colorHex: "#007AFF", order: 2, folderName: "note"),
        ]
    }
}

struct WindowFrame: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct BoardConfig: Codable {
    var columns: [ColumnConfig]
}
