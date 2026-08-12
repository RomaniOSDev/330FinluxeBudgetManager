import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var filter: TaskListFilter = .all
    @State private var showEditor = false
    @State private var editingTask: TaskItem?
    @State private var completePromptTask: TaskItem?
    @State private var query = ""
    @State private var selectedTag: String?
    @State private var selectedProject: String?

    private var displayed: [TaskItem] {
        store.filteredTasks(filter, query: query, tag: selectedTag, project: selectedProject)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Task Priority", subtitle: "Rank work, search by tag or project")
                    ClippedBannerImage(name: "bannerReceipts", height: 100)

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            AppTextField(title: "Search", placeholder: "Title, tag, project…", text: $query)
                            Picker("Filter", selection: $filter) {
                                ForEach(TaskListFilter.allCases) { item in
                                    Text(item.rawValue).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                            .colorScheme(.dark)

                            if !store.allTaskTags.isEmpty {
                                FilterChipRow(title: "Tag", options: store.allTaskTags, selection: $selectedTag)
                            }
                            if !store.allTaskProjects.isEmpty {
                                FilterChipRow(title: "Project", options: store.allTaskProjects, selection: $selectedProject)
                            }
                        }
                    }

                    if displayed.isEmpty {
                        GlassPanel {
                            Text("No tasks in this view.")
                                .foregroundStyle(Color("AppTextSecondary"))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    } else {
                        ForEach(displayed) { task in
                            taskRow(task)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .constrainedContentWidth()
            }
            .transparentChrome()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingTask = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                TaskEditorView(task: editingTask) { saved in
                    if store.tasks.contains(where: { $0.id == saved.id }) {
                        store.updateTask(saved)
                    } else {
                        store.addTask(saved)
                    }
                }
            }
            .confirmationDialog(
                "Mark complete?",
                isPresented: Binding(
                    get: { completePromptTask != nil },
                    set: { if !$0 { completePromptTask = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Complete & draft expense") {
                    if let task = completePromptTask {
                        store.completeTask(task, spawnExpenseDraft: true)
                    }
                    completePromptTask = nil
                }
                Button("Complete only") {
                    if let task = completePromptTask {
                        store.completeTask(task, spawnExpenseDraft: false)
                    }
                    completePromptTask = nil
                }
                Button("Cancel", role: .cancel) {
                    completePromptTask = nil
                }
            } message: {
                Text("Link a suggested expense draft or finish without logging.")
            }
        }
        .background(Color.clear)
    }

    @ViewBuilder
    private func taskRow(_ task: TaskItem) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Button {
                        if task.isCompleted {
                            var copy = task
                            copy.isCompleted = false
                            store.updateTask(copy)
                        } else {
                            completePromptTask = task
                        }
                    } label: {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(task.isCompleted ? Color("AppAccent") : Color("AppTextSecondary"))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .strikethrough(task.isCompleted)
                        HStack(spacing: 8) {
                            priorityBadge(task.priority)
                            Text(task.category)
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        Text(task.dueDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                        if !task.linkedProject.isEmpty {
                            Label(task.linkedProject, systemImage: "folder")
                                .font(.caption)
                                .foregroundStyle(Color("AppAccent"))
                        }
                        if !task.tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(task.tags, id: \.self) { tag in
                                    TagChip(text: tag)
                                }
                            }
                        }
                    }
                    Spacer()
                    Menu {
                        Button("Edit") {
                            editingTask = task
                            showEditor = true
                        }
                        Button("Delete", role: .destructive) {
                            store.deleteTask(task)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }
        }
    }

    private func priorityBadge(_ priority: TaskPriority) -> some View {
        Text(priority.rawValue)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(priorityColor(priority).opacity(0.25))
            }
            .foregroundStyle(priorityColor(priority))
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return Color.red.opacity(0.9)
        case .medium: return Color("AppAccent")
        case .low: return Color("AppTextSecondary")
        }
    }
}
