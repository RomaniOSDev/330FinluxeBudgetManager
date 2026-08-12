import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore()
    @State private var section: MainSection = .tasks

    var body: some View {
        ZStack {
            FinanceDeskCanvas()

            HStack(spacing: 0) {
                ConsoleIconRail(selection: $section)
                    .layoutPriority(1)
                    .zIndex(2)

                sectionContent
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.clear)
                    .clearSystemBackgrounds()
                    .clipped()
                    .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .environmentObject(store)
        .onChange(of: store.pendingExpenseDraft?.id) { _ in
            if store.pendingExpenseDraft != nil {
                section = .expenses
            }
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .tasks:
            TasksView()
        case .focus:
            FocusView()
        case .expenses:
            ExpensesView()
        case .stats:
            StatsView()
        case .settings:
            SettingsView()
        }
    }
}
