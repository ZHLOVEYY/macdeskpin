import Foundation

struct TaskItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var comment: String
    var isDone: Bool
    var createdDate: Date

    init(id: UUID = UUID(), title: String = "", comment: String = "", isDone: Bool = false, createdDate: Date = Date()) {
        self.id = id
        self.title = title
        self.comment = comment
        self.isDone = isDone
        self.createdDate = createdDate
    }
}

struct TaskList: Codable {
    var tasks: [TaskItem]

    init(tasks: [TaskItem] = []) {
        self.tasks = tasks
    }
}
