import UIKit
import SwiftUI

extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        clearChrome()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearChrome()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        clearChrome()
    }

    private func clearChrome() {
        view.backgroundColor = .clear
        navigationBar.isTranslucent = true
        for child in children {
            child.view.backgroundColor = .clear
        }
        for subview in view.subviews {
            subview.backgroundColor = .clear
        }
    }
}

final class ClearHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.backgroundColor = .clear
        view.isOpaque = false
    }
}
