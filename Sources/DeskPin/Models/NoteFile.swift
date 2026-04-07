import Foundation

struct NoteFile: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var filename: String
    var content: String
    var modifiedDate: Date

    init(id: UUID = UUID(), filename: String, content: String, modifiedDate: Date = Date()) {
        self.id = id
        self.filename = filename
        self.content = content
        self.modifiedDate = modifiedDate
    }
}
