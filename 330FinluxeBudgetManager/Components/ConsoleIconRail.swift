import SwiftUI

enum MainSection: Int, CaseIterable, Identifiable {
    case tasks
    case focus
    case expenses
    case stats
    case settings

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .tasks: return "checklist"
        case .focus: return "hourglass"
        case .expenses: return "creditcard"
        case .stats: return "chart.xyaxis.line"
        case .settings: return "gearshape"
        }
    }

    var title: String {
        switch self {
        case .tasks: return "Tasks"
        case .focus: return "Focus"
        case .expenses: return "Expenses"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }
}

struct ConsoleIconRail: View {
    @Binding var selection: MainSection

    private let railWidth: CGFloat = 76

    var body: some View {
        VStack(spacing: 10) {
            ForEach(MainSection.allCases) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = section
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: section.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(section.title)
                            .font(.system(size: 9, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .foregroundStyle(selection == section ? Color.white : Color("AppTextSecondary"))
                    .frame(width: 60, height: 56)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(selection == section ? 0.0 : 0.08))
                            if selection == section {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color("AppPrimary"), Color("AppAccent")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color("AppAccent").opacity(0.55), radius: 8, x: 0, y: 0)
                            }
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(selection == section ? 0.28 : 0.12), lineWidth: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(section.title)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .padding(.horizontal, 8)
        .frame(width: railWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.14).opacity(0.92)
                LinearGradient(
                    colors: [
                        Color("AppPrimary").opacity(0.18),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color("AppAccent").opacity(0.35))
                    .frame(width: 1)
            }
        }
    }
}
