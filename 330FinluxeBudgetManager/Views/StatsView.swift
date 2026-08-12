import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showGoalEditor = false
    @State private var editingGoal: SavingsGoal?
    @State private var contributeGoal: SavingsGoal?

    private var categoryRows: [(category: String, total: Double)] {
        store.totalsByCategory()
    }

    private var dailyRows: [(date: Date, total: Double)] {
        store.spendingByDay(lastDays: 14)
    }

    private var projectRows: [(project: String, total: Double)] {
        Array(store.spendingByProject().prefix(6))
    }

    private var comparison: [PeriodCategoryCompare] {
        store.periodComparison()
    }

    private var review: WeeklyReviewSnapshot {
        store.weeklyReview()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Statistics", subtitle: "Review, compare periods, and track goals")

                    summaryCards
                    weeklyReviewCard
                    focusValueCard
                    savingsGoalsCard

                    if !comparison.isEmpty {
                        periodCompareCard
                    }

                    if store.expenses.isEmpty {
                        GlassPanel {
                            Text("Add expenses to unlock charts.")
                                .foregroundStyle(Color("AppTextSecondary"))
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        categoryChart
                        trendChart
                        if !projectRows.isEmpty {
                            projectChart
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .constrainedContentWidth()
            }
            .transparentChrome()
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingGoal = nil
                        showGoalEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
            }
            .sheet(isPresented: $showGoalEditor) {
                GoalEditorSheet(existing: editingGoal)
                    .environmentObject(store)
            }
            .sheet(item: $contributeGoal) { goal in
                ContributeGoalSheet(goal: goal)
                    .environmentObject(store)
            }
        }
        .background(Color.clear)
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(title: "This month", value: AmountFormat.string(store.monthSpend), icon: "calendar")
            metricCard(title: "All time", value: AmountFormat.string(store.totalSpend), icon: "chart.bar")
            metricCard(title: "Open tasks", value: "\(store.pendingTaskCount)", icon: "checklist")
            metricCard(
                title: "Focus hrs",
                value: String(format: "%.1fh", store.billableHoursEstimate),
                icon: "hourglass"
            )
        }
    }

    private var weeklyReviewCard: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Weekly review")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                reviewLine("Spend this week", AmountFormat.string(review.spendTotal))
                reviewLine("Focus sessions", "\(store.focusConfig.sessionCount)")
                reviewLine("Completed tasks", "\(store.completedTaskCount)")
                if let top = review.topCategory {
                    reviewLine("Top category", top)
                }
                reviewLine("Focus value", AmountFormat.string(store.focusEarnedValue))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var focusValueCard: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus value")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Rate / hour: \(AmountFormat.string(store.focusConfig.hourlyRate))")
                    .foregroundStyle(Color("AppTextSecondary"))
                Text("Estimated value: \(AmountFormat.string(store.focusEarnedValue))")
                    .foregroundStyle(Color("AppAccent"))
                    .fontWeight(.semibold)
                Text(String(format: "%.1f hours tracked", store.billableHoursEstimate))
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var savingsGoalsCard: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Savings goals")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Button("Add") {
                        editingGoal = nil
                        showGoalEditor = true
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
                }

                if store.savingsGoals.isEmpty {
                    Text("Track progress toward a target amount.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(store.savingsGoals) { goal in
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressMeter(
                                title: goal.title,
                                subtitle: "\(AmountFormat.string(goal.savedAmount)) / \(AmountFormat.string(goal.targetAmount))",
                                progress: goal.progress
                            )
                            HStack {
                                Button("Contribute") {
                                    contributeGoal = goal
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppAccent"))
                                Spacer()
                                Button("Edit") {
                                    editingGoal = goal
                                    showGoalEditor = true
                                }
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                                Button("Delete", role: .destructive) {
                                    store.deleteGoal(goal)
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }

    private var periodCompareCard: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("This month vs last")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                ForEach(comparison.prefix(8)) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.category)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(deltaLabel(row.delta))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(row.delta > 0 ? Color.orange : (row.delta < 0 ? Color.mint : Color("AppTextSecondary")))
                        }
                        HStack {
                            Text("Now \(AmountFormat.string(row.current))")
                                .font(.caption)
                                .foregroundStyle(Color("AppAccent"))
                            Spacer()
                            Text("Prev \(AmountFormat.string(row.previous))")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                }
            }
        }
    }

    private var categoryChart: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("By category")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                Chart(categoryRows, id: \.category) { row in
                    BarMark(
                        x: .value("Total", row.total),
                        y: .value("Category", row.category)
                    )
                    .foregroundStyle(by: .value("Category", row.category))
                    .cornerRadius(6)
                }
                .chartForegroundStyleScale(range: chartPalette)
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel()
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                }
                .frame(height: CGFloat(max(180, categoryRows.count * 40)))

                ForEach(categoryRows, id: \.category) { row in
                    HStack {
                        Text(row.category)
                            .foregroundStyle(Color("AppTextSecondary"))
                        Spacer()
                        Text(AmountFormat.string(row.total))
                            .foregroundStyle(Color("AppAccent"))
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var trendChart: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 14 days")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                Chart(dailyRows, id: \.date) { row in
                    AreaMark(
                        x: .value("Day", row.date),
                        y: .value("Spend", row.total)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color("AppAccent").opacity(0.45),
                                Color("AppPrimary").opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Day", row.date),
                        y: .value("Spend", row.total)
                    )
                    .foregroundStyle(Color("AppAccent"))
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", row.date),
                        y: .value("Spend", row.total)
                    )
                    .foregroundStyle(Color.white)
                    .symbolSize(row.total > 0 ? 28 : 0)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel()
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                .frame(height: 200)
            }
        }
    }

    private var projectChart: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("By project")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                Chart(projectRows, id: \.project) { row in
                    BarMark(
                        x: .value("Total", row.total),
                        y: .value("Project", row.project)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AppPrimary"), Color("AppAccent")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel()
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                }
                .frame(height: CGFloat(max(160, projectRows.count * 36)))
            }
        }
    }

    private func reviewLine(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer()
            Text(value)
                .foregroundStyle(Color("AppTextPrimary"))
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func deltaLabel(_ delta: Double) -> String {
        if delta > 0 { return "+\(AmountFormat.string(delta))" }
        if delta < 0 { return AmountFormat.string(delta) }
        return AmountFormat.string(0)
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var chartPalette: [Color] {
        [
            Color("AppAccent"),
            Color("AppPrimary"),
            Color.cyan.opacity(0.85),
            Color.mint.opacity(0.85),
            Color.orange.opacity(0.85),
            Color.pink.opacity(0.75),
            Color.purple.opacity(0.75)
        ]
    }
}
