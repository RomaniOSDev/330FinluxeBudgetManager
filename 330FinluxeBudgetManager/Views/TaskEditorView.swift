import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem?
    let onSave: (TaskItem) -> Void

    @State private var title = ""
    @State private var priority: TaskPriority = .medium
    @State private var category = "General"
    @State private var dueDate = Date()
    @State private var linkedProject = ""
    @State private var isCompleted = false
    @State private var tagsText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            AppTextField(title: "Title", placeholder: "Task title", text: $title)
                            AppLabeledPicker(title: "Priority", selection: $priority) {
                                ForEach(TaskPriority.allCases) { p in
                                    Text(p.rawValue).tag(p)
                                }
                            }
                            AppTextField(title: "Category", placeholder: "General", text: $category)
                            AppTextField(
                                title: "Linked project",
                                placeholder: "Optional project",
                                text: $linkedProject
                            )
                            AppTextField(title: "Tags", placeholder: "urgent, client", text: $tagsText)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Due date")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(Color("AppAccent"))
                                    .colorScheme(.dark)
                            }
                            Toggle(isOn: $isCompleted) {
                                Text("Completed")
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                            .tint(Color("AppAccent"))
                        }
                    }
                }
                .padding(16)
            }
            .transparentChrome()
            .financeDeskBackground()
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
        .preferredColorScheme(.dark)
    }

    private func load() {
        guard let task else { return }
        title = task.title
        priority = task.priority
        category = task.category
        dueDate = task.dueDate
        linkedProject = task.linkedProject
        isCompleted = task.isCompleted
        tagsText = TagParsing.join(task.tags)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = TaskItem(
            id: task?.id ?? UUID(),
            title: trimmed,
            priority: priority,
            category: category.isEmpty ? "General" : category,
            isCompleted: isCompleted,
            dueDate: dueDate,
            linkedProject: linkedProject,
            tags: TagParsing.parse(tagsText)
        )
        onSave(item)
        dismiss()
    }
}
