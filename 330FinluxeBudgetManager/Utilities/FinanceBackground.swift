import SwiftUI
import UIKit

/// Walks up the UIKit hierarchy and clears opaque system backgrounds
/// that SwiftUI NavigationStack paints over our desk image.
struct SystemBackgroundClearer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = PassThroughView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            clearAncestors(of: uiView)
        }
    }

    private func clearAncestors(of view: UIView) {
        var node: UIView? = view
        while let current = node {
            current.backgroundColor = .clear
            if let effects = current as? UIVisualEffectView {
                effects.isHidden = true
            }
            node = current.superview
        }
    }
}

private final class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        backgroundColor = .clear
        var node: UIView? = self
        while let current = node {
            current.backgroundColor = .clear
            node = current.superview
        }
    }
}

/// Background layer that NEVER participates in parent sizing.
struct FinanceDeskCanvas: View {
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Color(red: 0.08, green: 0.12, blue: 0.22)

                Image("bgFinanceDesk")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.18),
                        Color.black.opacity(0.05),
                        Color.black.opacity(0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                LinearGradient(
                    colors: [
                        Color("AppPrimary").opacity(0.14),
                        Color.clear,
                        Color("AppAccent").opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct FinanceDeskBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                FinanceDeskCanvas()
            }
            .background {
                SystemBackgroundClearer()
            }
    }
}

struct TransparentChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(Color.clear)
            .background {
                SystemBackgroundClearer()
            }
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            )
    }
}

extension View {
    func financeDeskBackground() -> some View {
        modifier(FinanceDeskBackground())
    }

    func transparentChrome() -> some View {
        modifier(TransparentChrome())
    }

    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }

    func constrainedContentWidth() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
    }

    func clearSystemBackgrounds() -> some View {
        background { SystemBackgroundClearer() }
    }
}

enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
