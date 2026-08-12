import Foundation

enum RecurrenceInterval: String, Codable, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"

    var id: String { rawValue }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}

struct CategoryBudget: Identifiable, Codable, Equatable {
    var id: UUID
    var category: String
    var monthlyLimit: Double

    init(id: UUID = UUID(), category: String, monthlyLimit: Double) {
        self.id = id
        self.category = category
        self.monthlyLimit = monthlyLimit
    }
}

struct RecurringExpense: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var category: String
    var project: String
    var tags: [String]
    var interval: RecurrenceInterval
    var nextDue: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: String = ExpenseCategory.misc.rawValue,
        project: String = "",
        tags: [String] = [],
        interval: RecurrenceInterval = .monthly,
        nextDue: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.project = project
        self.tags = tags
        self.interval = interval
        self.nextDue = nextDue
        self.isActive = isActive
    }
}

struct ExpenseTemplate: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var amount: Double
    var category: String
    var project: String
    var tags: [String]
    var note: String

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        category: String = ExpenseCategory.misc.rawValue,
        project: String = "",
        tags: [String] = [],
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.project = project
        self.tags = tags
        self.note = note
    }

    static let defaults: [ExpenseTemplate] = [
        ExpenseTemplate(name: "Coffee", amount: 4.50, category: ExpenseCategory.meals.rawValue, tags: ["quick", "food"]),
        ExpenseTemplate(name: "Taxi", amount: 18.00, category: ExpenseCategory.travel.rawValue, tags: ["quick", "transit"]),
        ExpenseTemplate(name: "Lunch", amount: 14.00, category: ExpenseCategory.meals.rawValue, tags: ["quick", "food"]),
        ExpenseTemplate(name: "Supplies", amount: 25.00, category: ExpenseCategory.office.rawValue, tags: ["quick"]),
        ExpenseTemplate(name: "Software", amount: 12.00, category: ExpenseCategory.software.rawValue, tags: ["quick", "tools"])
    ]
}

struct SavingsGoal: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var targetAmount: Double
    var savedAmount: Double

    init(
        id: UUID = UUID(),
        title: String,
        targetAmount: Double,
        savedAmount: Double = 0
    ) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1, max(0, savedAmount / targetAmount))
    }
}

struct BudgetStatus: Identifiable {
    var id: UUID { budget.id }
    var budget: CategoryBudget
    var spent: Double

    var ratio: Double {
        guard budget.monthlyLimit > 0 else { return 0 }
        return spent / budget.monthlyLimit
    }

    var isWarning: Bool { ratio >= 0.8 && ratio < 1 }
    var isOver: Bool { ratio >= 1 }
}

struct PeriodCategoryCompare: Identifiable {
    var id: String { category }
    var category: String
    var current: Double
    var previous: Double

    var delta: Double { current - previous }
}

struct WeeklyReviewSnapshot {
    var spendTotal: Double
    var focusSessions: Int
    var tasksCompleted: Int
    var topCategory: String?
    var earnedValue: Double
}
