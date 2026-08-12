import Foundation

struct ExpenseItem: Identifiable, Codable, Equatable {
    var id: UUID
    var amount: Double
    var category: String
    var project: String
    var date: Date
    var note: String
    var tags: [String]

    init(
        id: UUID = UUID(),
        amount: Double,
        category: String = "Misc",
        project: String = "",
        date: Date = Date(),
        note: String = "",
        tags: [String] = []
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.project = project
        self.date = date
        self.note = note
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id, amount, category, project, date, note, tags
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        amount = try c.decode(Double.self, forKey: .amount)
        category = try c.decode(String.self, forKey: .category)
        project = try c.decode(String.self, forKey: .project)
        date = try c.decode(Date.self, forKey: .date)
        note = try c.decode(String.self, forKey: .note)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case software = "Software"
    case hardware = "Hardware"
    case travel = "Travel"
    case meals = "Meals"
    case office = "Office"
    case marketing = "Marketing"
    case misc = "Misc"

    var id: String { rawValue }
}

enum ExpensePeriodFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}
