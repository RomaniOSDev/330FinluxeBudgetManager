import SwiftUI

struct BudgetEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppDataStore

    var existing: CategoryBudget?
    @State private var category = ExpenseCategory.meals.rawValue
    @State private var limitText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        AppLabeledPicker(title: "Category", selection: $category) {
                            ForEach(ExpenseCategory.allCases) { cat in
                                Text(cat.rawValue).tag(cat.rawValue)
                            }
                        }
                        AppTextField(
                            title: "Monthly limit",
                            placeholder: "0.00",
                            text: $limitText,
                            keyboardType: .decimalPad
                        )
                    }
                }
                .padding(16)
            }
            .transparentChrome()
            .financeDeskBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existing == nil ? "New Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppAccent"))
                        .disabled(parsedLimit == nil)
                }
            }
            .onAppear {
                if let existing {
                    category = existing.category
                    limitText = String(format: "%.2f", existing.monthlyLimit)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var parsedLimit: Double? {
        Double(limitText.replacingOccurrences(of: ",", with: "."))
    }

    private func save() {
        guard let limit = parsedLimit, limit > 0 else { return }
        let item = CategoryBudget(id: existing?.id ?? UUID(), category: category, monthlyLimit: limit)
        if existing == nil {
            store.addBudget(item)
        } else {
            store.updateBudget(item)
        }
        dismiss()
    }
}

struct RecurringEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppDataStore

    var existing: RecurringExpense?
    @State private var title = ""
    @State private var amountText = ""
    @State private var category = ExpenseCategory.misc.rawValue
    @State private var project = ""
    @State private var tagsText = ""
    @State private var interval: RecurrenceInterval = .monthly
    @State private var nextDue = Date()
    @State private var isActive = true

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        AppTextField(title: "Title", placeholder: "Rent, subscription…", text: $title)
                        AppTextField(
                            title: "Amount",
                            placeholder: "0.00",
                            text: $amountText,
                            keyboardType: .decimalPad
                        )
                        AppLabeledPicker(title: "Category", selection: $category) {
                            ForEach(ExpenseCategory.allCases) { cat in
                                Text(cat.rawValue).tag(cat.rawValue)
                            }
                        }
                        AppLabeledPicker(title: "Interval", selection: $interval) {
                            ForEach(RecurrenceInterval.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        AppTextField(title: "Project", placeholder: "Optional", text: $project)
                        AppTextField(title: "Tags", placeholder: "home, bills", text: $tagsText)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Next due")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            DatePicker("", selection: $nextDue, displayedComponents: .date)
                                .labelsHidden()
                                .tint(Color("AppAccent"))
                                .colorScheme(.dark)
                        }
                        Toggle(isOn: $isActive) {
                            Text("Active")
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                        .tint(Color("AppAccent"))
                    }
                }
                .padding(16)
            }
            .transparentChrome()
            .financeDeskBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existing == nil ? "New Recurring" : "Edit Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppAccent"))
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedAmount == nil)
                }
            }
            .onAppear(perform: load)
        }
        .preferredColorScheme(.dark)
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private func load() {
        guard let existing else { return }
        title = existing.title
        amountText = String(format: "%.2f", existing.amount)
        category = existing.category
        project = existing.project
        tagsText = TagParsing.join(existing.tags)
        interval = existing.interval
        nextDue = existing.nextDue
        isActive = existing.isActive
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = RecurringExpense(
            id: existing?.id ?? UUID(),
            title: trimmed,
            amount: amount,
            category: category,
            project: project,
            tags: TagParsing.parse(tagsText),
            interval: interval,
            nextDue: nextDue,
            isActive: isActive
        )
        if existing == nil {
            store.addRecurring(item)
        } else {
            store.updateRecurring(item)
        }
        dismiss()
    }
}

struct GoalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppDataStore

    var existing: SavingsGoal?
    @State private var title = ""
    @State private var targetText = ""
    @State private var savedText = "0"

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        AppTextField(title: "Goal", placeholder: "Laptop, trip…", text: $title)
                        AppTextField(
                            title: "Target amount",
                            placeholder: "0.00",
                            text: $targetText,
                            keyboardType: .decimalPad
                        )
                        AppTextField(
                            title: "Already saved",
                            placeholder: "0.00",
                            text: $savedText,
                            keyboardType: .decimalPad
                        )
                    }
                }
                .padding(16)
            }
            .transparentChrome()
            .financeDeskBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existing == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppAccent"))
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedTarget == nil)
                }
            }
            .onAppear {
                if let existing {
                    title = existing.title
                    targetText = String(format: "%.2f", existing.targetAmount)
                    savedText = String(format: "%.2f", existing.savedAmount)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var parsedTarget: Double? {
        Double(targetText.replacingOccurrences(of: ",", with: "."))
    }

    private var parsedSaved: Double {
        Double(savedText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func save() {
        guard let target = parsedTarget, target > 0 else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = SavingsGoal(
            id: existing?.id ?? UUID(),
            title: trimmed,
            targetAmount: target,
            savedAmount: max(0, parsedSaved)
        )
        if existing == nil {
            store.addGoal(item)
        } else {
            store.updateGoal(item)
        }
        dismiss()
    }
}

struct ContributeGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppDataStore
    let goal: SavingsGoal
    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassPanel {
                    AppTextField(
                        title: "Add to \(goal.title)",
                        placeholder: "0.00",
                        text: $amountText,
                        keyboardType: .decimalPad
                    )
                }
                .padding(16)
            }
            .transparentChrome()
            .financeDeskBackground()
            .navigationTitle("Contribute")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let value = Double(amountText.replacingOccurrences(of: ",", with: ".")), value > 0 {
                            store.contribute(to: goal, amount: value)
                            dismiss()
                        }
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
