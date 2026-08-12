import SwiftUI

struct TagChip: View {
    let text: String
    var selected: Bool = false

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(selected ? Color.white : Color("AppTextSecondary"))
            .background {
                Capsule()
                    .fill(selected ? Color("AppAccent").opacity(0.85) : Color.white.opacity(0.08))
            }
    }
}

struct ProgressMeter: View {
    let title: String
    let subtitle: String
    let progress: Double
    var warning: Bool = false
    var over: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(over ? Color.red : (warning ? Color.orange : Color("AppAccent")))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(8, geo.size.width * CGFloat(min(1, max(0, progress)))))
                }
            }
            .frame(height: 8)
        }
    }

    private var barColor: Color {
        if over { return .red }
        if warning { return .orange }
        return Color("AppAccent")
    }
}

struct FilterChipRow: View {
    let title: String
    let options: [String]
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selection = nil
                    } label: {
                        TagChip(text: "All", selected: selection == nil)
                    }
                    .buttonStyle(.plain)

                    ForEach(options, id: \.self) { option in
                        Button {
                            selection = option
                        } label: {
                            TagChip(text: option, selected: selection == option)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

enum TagParsing {
    static func parse(_ raw: String) -> [String] {
        raw
            .split(whereSeparator: { $0 == "," || $0 == " " || $0 == "#" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func join(_ tags: [String]) -> String {
        tags.joined(separator: ", ")
    }
}
