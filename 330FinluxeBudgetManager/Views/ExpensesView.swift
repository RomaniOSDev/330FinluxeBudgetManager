import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showEditor = false
    @State private var editingExpense: ExpenseItem?
    @State private var query = ""
    @State private var selectedTag: String?
    @State private var selectedProject: String?
    @State private var period: ExpensePeriodFilter = .all
    @State private var showBudgetEditor = false
    @State private var editingBudget: CategoryBudget?
    @State private var showRecurringEditor = false
    @State private var editingRecurring: RecurringExpense?

    private var displayed: [ExpenseItem] {
        store.filteredExpenses(
            query: query,
            tag: selectedTag,
            project: selectedProject,
            period: period
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Expense Log", subtitle: "Templates, budgets, recurring, and search")
                    ClippedBannerImage(name: "bannerChartGlow", height: 100)

                    quickTemplates
                    searchAndFilters
                    budgetsSection
                    recurringSection

                    if displayed.isEmpty {
                        GlassPanel {
                            Text("No expenses match these filters.")
                                .foregroundStyle(Color("AppTextSecondary"))
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        ForEach(displayed) { expense in
                            expenseRow(expense)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .constrainedContentWidth()
            }
            .transparentChrome()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add expense") {
                            editingExpense = nil
                            showEditor = true
                        }
                        Button("Add budget") {
                            editingBudget = nil
                            showBudgetEditor = true
                        }
                        Button("Add recurring") {
                            editingRecurring = nil
                            showRecurringEditor = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                ExpenseEditorView(expense: editingExpense) { saved in
                    if store.expenses.contains(where: { $0.id == saved.id }) {
                        store.updateExpense(saved)
                    } else {
                        store.addExpense(saved)
                    }
                }
            }
            .sheet(isPresented: $showBudgetEditor) {
                BudgetEditorSheet(existing: editingBudget)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showRecurringEditor) {
                RecurringEditorSheet(existing: editingRecurring)
                    .environmentObject(store)
            }
            .onChange(of: store.pendingExpenseDraft?.id) { _ in
                if let draft = store.pendingExpenseDraft {
                    editingExpense = draft
                    showEditor = true
                    store.pendingExpenseDraft = nil
                }
            }
            .onAppear {
                store.processDueRecurringExpenses()
                if let draft = store.pendingExpenseDraft {
                    editingExpense = draft
                    showEditor = true
                    store.pendingExpenseDraft = nil
                }
            }
        }
        .background(Color.clear)
    }

    private var quickTemplates: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick templates")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.templates) { template in
                            Button {
                                store.applyTemplate(template)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Text(AmountFormat.string(template.amount))
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppAccent"))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.black.opacity(0.35))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var searchAndFilters: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                AppTextField(title: "Search", placeholder: "Note, project, tag…", text: $query)
                Picker("Period", selection: $period) {
                    ForEach(ExpensePeriodFilter.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)

                if !store.allExpenseTags.isEmpty {
                    FilterChipRow(title: "Tag", options: store.allExpenseTags, selection: $selectedTag)
                }
                if !store.allExpenseProjects.isEmpty {
                    FilterChipRow(title: "Project", options: store.allExpenseProjects, selection: $selectedProject)
                }
            }
        }
    }

    private var budgetsSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Category budgets")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Button("Add") {
                        editingBudget = nil
                        showBudgetEditor = true
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
                }

                if store.budgetStatuses.isEmpty {
                    Text("Set monthly limits to track overspending.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(store.budgetStatuses) { status in
                        VStack(alignment: .leading, spacing: 6) {
                            ProgressMeter(
                                title: status.budget.category,
                                subtitle: "\(AmountFormat.string(status.spent)) / \(AmountFormat.string(status.budget.monthlyLimit))",
                                progress: status.ratio,
                                warning: status.isWarning,
                                over: status.isOver
                            )
                            if status.isOver {
                                Text("Limit reached")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.red)
                            } else if status.isWarning {
                                Text("Near limit (80%+)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.orange)
                            }
                            HStack {
                                Button("Edit") {
                                    editingBudget = status.budget
                                    showBudgetEditor = true
                                }
                                .font(.caption)
                                .foregroundStyle(Color("AppAccent"))
                                Spacer()
                                Button("Delete", role: .destructive) {
                                    store.deleteBudget(status.budget)
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }

    private var recurringSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recurring")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Button("Add") {
                        editingRecurring = nil
                        showRecurringEditor = true
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
                }

                if store.recurringExpenses.isEmpty {
                    Text("Auto-create rent or subscriptions on schedule.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(store.recurringExpenses) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .font(.subheadline.weight(.semibold))
                                Text("\(AmountFormat.string(item.amount)) · \(item.interval.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Text("Next: \(item.nextDue.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundStyle(item.isActive ? Color("AppAccent") : Color("AppTextSecondary"))
                            }
                            Spacer()
                            Menu {
                                Button("Edit") {
                                    editingRecurring = item
                                    showRecurringEditor = true
                                }
                                Button(item.isActive ? "Pause" : "Resume") {
                                    var copy = item
                                    copy.isActive.toggle()
                                    store.updateRecurring(copy)
                                }
                                Button("Delete", role: .destructive) {
                                    store.deleteRecurring(item)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func expenseRow(_ expense: ExpenseItem) -> some View {
        GlassPanel {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AmountFormat.string(expense.amount))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(expense.category)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    if !expense.project.isEmpty {
                        Text(expense.project)
                            .font(.caption)
                            .foregroundStyle(Color("AppAccent"))
                    }
                    if !expense.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(expense.tags, id: \.self) { tag in
                                TagChip(text: tag)
                            }
                        }
                    }
                    Text(expense.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                Spacer()
                Menu {
                    Button("Edit") {
                        editingExpense = expense
                        showEditor = true
                    }
                    Button("Delete", role: .destructive) {
                        store.deleteExpense(expense)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }
}
