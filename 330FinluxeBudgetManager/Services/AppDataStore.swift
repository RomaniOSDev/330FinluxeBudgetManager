import Foundation
import Combine

@MainActor
final class AppDataStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var expenses: [ExpenseItem] = []
    @Published var focusConfig: FocusConfiguration = FocusConfiguration()
    @Published var budgets: [CategoryBudget] = []
    @Published var recurringExpenses: [RecurringExpense] = []
    @Published var templates: [ExpenseTemplate] = []
    @Published var savingsGoals: [SavingsGoal] = []

    @Published var pendingExpenseDraft: ExpenseItem?

    private let tasksKey = "finluxe.tasks"
    private let expensesKey = "finluxe.expenses"
    private let focusKey = "finluxe.focus"
    private let budgetsKey = "finluxe.budgets"
    private let recurringKey = "finluxe.recurring"
    private let templatesKey = "finluxe.templates"
    private let goalsKey = "finluxe.goals"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        loadAll()
        if templates.isEmpty {
            templates = ExpenseTemplate.defaults
            saveTemplates()
        }
        processDueRecurringExpenses()
    }

    // MARK: - Tasks

    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveTasks()
    }

    func updateTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        saveTasks()
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func completeTask(_ task: TaskItem, spawnExpenseDraft: Bool) {
        var updated = task
        updated.isCompleted = true
        updateTask(updated)
        if spawnExpenseDraft {
            pendingExpenseDraft = ExpenseItem(
                amount: 0,
                category: ExpenseCategory.misc.rawValue,
                project: task.linkedProject.isEmpty ? task.category : task.linkedProject,
                date: Date(),
                note: "From task: \(task.title)",
                tags: task.tags
            )
        }
    }

    func filteredTasks(
        _ filter: TaskListFilter,
        query: String = "",
        tag: String? = nil,
        project: String? = nil
    ) -> [TaskItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base: [TaskItem]
        switch filter {
        case .all: base = tasks
        case .pending: base = tasks.filter { !$0.isCompleted }
        case .completed: base = tasks.filter { $0.isCompleted }
        }
        return base
            .filter { task in
                if let tag, !tag.isEmpty, !task.tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
                    return false
                }
                if let project, !project.isEmpty,
                   task.linkedProject.caseInsensitiveCompare(project) != .orderedSame {
                    return false
                }
                if q.isEmpty { return true }
                return task.title.lowercased().contains(q)
                    || task.category.lowercased().contains(q)
                    || task.linkedProject.lowercased().contains(q)
                    || task.tags.contains { $0.lowercased().contains(q) }
            }
            .sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }
                return lhs.dueDate < rhs.dueDate
            }
    }

    var allTaskTags: [String] {
        Array(Set(tasks.flatMap(\.tags))).sorted()
    }

    var allTaskProjects: [String] {
        Array(Set(tasks.map(\.linkedProject).filter { !$0.isEmpty })).sorted()
    }

    // MARK: - Expenses

    func addExpense(_ expense: ExpenseItem) {
        expenses.append(expense)
        saveExpenses()
    }

    func updateExpense(_ expense: ExpenseItem) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        saveExpenses()
    }

    func deleteExpense(_ expense: ExpenseItem) {
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
    }

    func filteredExpenses(
        query: String = "",
        tag: String? = nil,
        project: String? = nil,
        period: ExpensePeriodFilter = .all
    ) -> [ExpenseItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let calendar = Calendar.current
        let now = Date()
        return expenses
            .filter { expense in
                switch period {
                case .all: break
                case .week:
                    guard let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) else { return false }
                    if expense.date < start { return false }
                case .month:
                    if !calendar.isDate(expense.date, equalTo: now, toGranularity: .month) { return false }
                }
                if let tag, !tag.isEmpty, !expense.tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
                    return false
                }
                if let project, !project.isEmpty,
                   expense.project.caseInsensitiveCompare(project) != .orderedSame {
                    return false
                }
                if q.isEmpty { return true }
                return expense.category.lowercased().contains(q)
                    || expense.project.lowercased().contains(q)
                    || expense.note.lowercased().contains(q)
                    || expense.tags.contains { $0.lowercased().contains(q) }
                    || AmountFormat.string(expense.amount).contains(q)
            }
            .sorted { $0.date > $1.date }
    }

    var allExpenseTags: [String] {
        Array(Set(expenses.flatMap(\.tags))).sorted()
    }

    var allExpenseProjects: [String] {
        Array(Set(expenses.map(\.project).filter { !$0.isEmpty })).sorted()
    }

    func totalsByCategory(in period: ExpensePeriodFilter = .all) -> [(category: String, total: Double)] {
        var map: [String: Double] = [:]
        for expense in filteredExpenses(period: period) {
            map[expense.category, default: 0] += expense.amount
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.total > $1.total }
    }

    func spendingByDay(lastDays: Int = 14) -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(lastDays - 1), to: today) else {
            return []
        }
        var map: [Date: Double] = [:]
        for offset in 0..<lastDays {
            if let day = calendar.date(byAdding: .day, value: offset, to: start) {
                map[day] = 0
            }
        }
        for expense in expenses {
            let day = calendar.startOfDay(for: expense.date)
            if day >= start {
                map[day, default: 0] += expense.amount
            }
        }
        return map.keys.sorted().map { ($0, map[$0] ?? 0) }
    }

    func spendingByProject() -> [(project: String, total: Double)] {
        var map: [String: Double] = [:]
        for expense in expenses {
            let key = expense.project.trimmingCharacters(in: .whitespacesAndNewlines)
            let label = key.isEmpty ? "Unassigned" : key
            map[label, default: 0] += expense.amount
        }
        return map.map { ($0.key, $0.value) }.sorted { $0.total > $1.total }
    }

    func monthSpend(for category: String) -> Double {
        let calendar = Calendar.current
        return expenses
            .filter {
                $0.category == category
                    && calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }

    var totalSpend: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var monthSpend: Double {
        filteredExpenses(period: .month).reduce(0) { $0 + $1.amount }
    }

    var weekSpend: Double {
        filteredExpenses(period: .week).reduce(0) { $0 + $1.amount }
    }

    var pendingTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var completedTaskCount: Int {
        tasks.filter(\.isCompleted).count
    }

    var billableHoursEstimate: Double {
        Double(focusConfig.sessionCount * focusConfig.focusDurationSec) / 3600.0
    }

    var focusEarnedValue: Double {
        billableHoursEstimate * focusConfig.hourlyRate
    }

    // MARK: - Budgets

    func addBudget(_ budget: CategoryBudget) {
        if let index = budgets.firstIndex(where: { $0.category == budget.category }) {
            budgets[index] = budget
        } else {
            budgets.append(budget)
        }
        saveBudgets()
    }

    func updateBudget(_ budget: CategoryBudget) {
        guard let index = budgets.firstIndex(where: { $0.id == budget.id }) else { return }
        budgets[index] = budget
        saveBudgets()
    }

    func deleteBudget(_ budget: CategoryBudget) {
        budgets.removeAll { $0.id == budget.id }
        saveBudgets()
    }

    var budgetStatuses: [BudgetStatus] {
        budgets
            .map { BudgetStatus(budget: $0, spent: monthSpend(for: $0.category)) }
            .sorted { $0.ratio > $1.ratio }
    }

    // MARK: - Recurring

    func addRecurring(_ item: RecurringExpense) {
        recurringExpenses.append(item)
        saveRecurring()
        processDueRecurringExpenses()
    }

    func updateRecurring(_ item: RecurringExpense) {
        guard let index = recurringExpenses.firstIndex(where: { $0.id == item.id }) else { return }
        recurringExpenses[index] = item
        saveRecurring()
    }

    func deleteRecurring(_ item: RecurringExpense) {
        recurringExpenses.removeAll { $0.id == item.id }
        saveRecurring()
    }

    func processDueRecurringExpenses() {
        let now = Date()
        var changed = false
        for index in recurringExpenses.indices {
            guard recurringExpenses[index].isActive else { continue }
            var safety = 0
            while recurringExpenses[index].nextDue <= now, safety < 36 {
                let item = recurringExpenses[index]
                expenses.append(
                    ExpenseItem(
                        amount: item.amount,
                        category: item.category,
                        project: item.project,
                        date: item.nextDue,
                        note: item.title,
                        tags: item.tags.isEmpty ? ["recurring"] : item.tags
                    )
                )
                recurringExpenses[index].nextDue = item.interval.nextDate(after: item.nextDue)
                changed = true
                safety += 1
            }
        }
        if changed {
            saveExpenses()
            saveRecurring()
        }
    }

    // MARK: - Templates

    func addTemplate(_ template: ExpenseTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func deleteTemplate(_ template: ExpenseTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }

    func applyTemplate(_ template: ExpenseTemplate) {
        addExpense(
            ExpenseItem(
                amount: template.amount,
                category: template.category,
                project: template.project,
                date: Date(),
                note: template.note.isEmpty ? template.name : template.note,
                tags: template.tags
            )
        )
    }

    // MARK: - Savings goals

    func addGoal(_ goal: SavingsGoal) {
        savingsGoals.append(goal)
        saveGoals()
    }

    func updateGoal(_ goal: SavingsGoal) {
        guard let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        savingsGoals[index] = goal
        saveGoals()
    }

    func deleteGoal(_ goal: SavingsGoal) {
        savingsGoals.removeAll { $0.id == goal.id }
        saveGoals()
    }

    func contribute(to goal: SavingsGoal, amount: Double) {
        guard amount > 0, let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        savingsGoals[index].savedAmount += amount
        saveGoals()
    }

    // MARK: - Stats helpers

    func periodComparison() -> [PeriodCategoryCompare] {
        let calendar = Calendar.current
        let now = Date()
        guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else { return [] }

        var currentMap: [String: Double] = [:]
        var previousMap: [String: Double] = [:]

        for expense in expenses {
            if calendar.isDate(expense.date, equalTo: now, toGranularity: .month) {
                currentMap[expense.category, default: 0] += expense.amount
            } else if calendar.isDate(expense.date, equalTo: previousMonthDate, toGranularity: .month) {
                previousMap[expense.category, default: 0] += expense.amount
            }
        }

        let keys = Set(currentMap.keys).union(previousMap.keys)
        return keys
            .map {
                PeriodCategoryCompare(
                    category: $0,
                    current: currentMap[$0] ?? 0,
                    previous: previousMap[$0] ?? 0
                )
            }
            .sorted { max($0.current, $0.previous) > max($1.current, $1.previous) }
    }

    func weeklyReview() -> WeeklyReviewSnapshot {
        let weekExpenses = filteredExpenses(period: .week)
        let top = totalsByCategory(in: .week).first?.category
        return WeeklyReviewSnapshot(
            spendTotal: weekExpenses.reduce(0) { $0 + $1.amount },
            focusSessions: focusConfig.sessionCount,
            tasksCompleted: completedTaskCount,
            topCategory: top,
            earnedValue: focusEarnedValue
        )
    }

    // MARK: - Focus

    func recordCompletedFocusSession() {
        var config = focusConfig
        config.sessionCount += 1
        config.lastSessionDate = Date()
        focusConfig = config
        saveFocus()
    }

    func clampFocusMinutes(_ minutes: Int) -> Int {
        min(60, max(1, minutes))
    }

    func setFocusDurationMinutes(_ minutes: Int) {
        var config = focusConfig
        config.focusDurationSec = clampFocusMinutes(minutes) * 60
        focusConfig = config
        saveFocus()
    }

    func setBreakDurationMinutes(_ minutes: Int) {
        var config = focusConfig
        config.breakDurationSec = clampFocusMinutes(minutes) * 60
        focusConfig = config
        saveFocus()
    }

    func setHourlyRate(_ rate: Double) {
        var config = focusConfig
        config.hourlyRate = max(0, rate)
        focusConfig = config
        saveFocus()
    }

    func resetAllData() {
        tasks = []
        expenses = []
        focusConfig = FocusConfiguration()
        budgets = []
        recurringExpenses = []
        templates = ExpenseTemplate.defaults
        savingsGoals = []
        pendingExpenseDraft = nil
        UserDefaults.standard.removeObject(forKey: tasksKey)
        UserDefaults.standard.removeObject(forKey: expensesKey)
        UserDefaults.standard.removeObject(forKey: focusKey)
        UserDefaults.standard.removeObject(forKey: budgetsKey)
        UserDefaults.standard.removeObject(forKey: recurringKey)
        UserDefaults.standard.removeObject(forKey: goalsKey)
        saveTemplates()
    }

    // MARK: - Persistence

    private func loadAll() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? decoder.decode([TaskItem].self, from: data) {
            tasks = decoded
        }
        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? decoder.decode([ExpenseItem].self, from: data) {
            expenses = decoded
        }
        if let data = UserDefaults.standard.data(forKey: focusKey),
           let decoded = try? decoder.decode(FocusConfiguration.self, from: data) {
            focusConfig = decoded
        }
        if let data = UserDefaults.standard.data(forKey: budgetsKey),
           let decoded = try? decoder.decode([CategoryBudget].self, from: data) {
            budgets = decoded
        }
        if let data = UserDefaults.standard.data(forKey: recurringKey),
           let decoded = try? decoder.decode([RecurringExpense].self, from: data) {
            recurringExpenses = decoded
        }
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? decoder.decode([ExpenseTemplate].self, from: data) {
            templates = decoded
        }
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? decoder.decode([SavingsGoal].self, from: data) {
            savingsGoals = decoded
        }
    }

    private func saveTasks() {
        if let data = try? encoder.encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }
    }

    private func saveExpenses() {
        if let data = try? encoder.encode(expenses) {
            UserDefaults.standard.set(data, forKey: expensesKey)
        }
    }

    private func saveFocus() {
        if let data = try? encoder.encode(focusConfig) {
            UserDefaults.standard.set(data, forKey: focusKey)
        }
    }

    private func saveBudgets() {
        if let data = try? encoder.encode(budgets) {
            UserDefaults.standard.set(data, forKey: budgetsKey)
        }
    }

    private func saveRecurring() {
        if let data = try? encoder.encode(recurringExpenses) {
            UserDefaults.standard.set(data, forKey: recurringKey)
        }
    }

    private func saveTemplates() {
        if let data = try? encoder.encode(templates) {
            UserDefaults.standard.set(data, forKey: templatesKey)
        }
    }

    private func saveGoals() {
        if let data = try? encoder.encode(savingsGoals) {
            UserDefaults.standard.set(data, forKey: goalsKey)
        }
    }
}
