import SwiftUI

struct ExpenseEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let expense: ExpenseItem?
    let onSave: (ExpenseItem) -> Void

    @State private var amountText = ""
    @State private var category = ExpenseCategory.misc.rawValue
    @State private var project = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var tagsText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
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
                            AppTextField(title: "Project", placeholder: "Client / project", text: $project)
                            AppTextField(title: "Tags", placeholder: "food, tools", text: $tagsText)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(Color("AppAccent"))
                                    .colorScheme(.dark)
                            }
                            AppTextField(
                                title: "Note",
                                placeholder: "Optional note",
                                text: $note,
                                axis: .vertical
                            )
                        }
                    }
                }
                .padding(16)
            }
            .transparentChrome()
            .financeDeskBackground()
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle(expense == nil ? "New Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Keyboard.dismiss()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Keyboard.dismiss()
                        save()
                    }
                    .foregroundStyle(Color("AppAccent"))
                    .disabled(parsedAmount == nil)
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
        guard let expense else { return }
        amountText = expense.amount == 0 ? "" : String(format: "%.2f", expense.amount)
        category = expense.category
        project = expense.project
        date = expense.date
        note = expense.note
        tagsText = TagParsing.join(expense.tags)
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let item = ExpenseItem(
            id: expense?.id ?? UUID(),
            amount: amount,
            category: category,
            project: project,
            date: date,
            note: note,
            tags: TagParsing.parse(tagsText)
        )
        onSave(item)
        dismiss()
    }
}
