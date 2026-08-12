import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

enum TaskListFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"
    case completed = "Completed"

    var id: String { rawValue }
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var priority: TaskPriority
    var category: String
    var isCompleted: Bool
    var dueDate: Date
    var linkedProject: String
    var tags: [String]

    init(
        id: UUID = UUID(),
        title: String,
        priority: TaskPriority = .medium,
        category: String = "General",
        isCompleted: Bool = false,
        dueDate: Date = Date(),
        linkedProject: String = "",
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.linkedProject = linkedProject
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id, title, priority, category, isCompleted, dueDate, linkedProject, tags
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        priority = try c.decode(TaskPriority.self, forKey: .priority)
        category = try c.decode(String.self, forKey: .category)
        isCompleted = try c.decode(Bool.self, forKey: .isCompleted)
        dueDate = try c.decode(Date.self, forKey: .dueDate)
        linkedProject = try c.decode(String.self, forKey: .linkedProject)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
