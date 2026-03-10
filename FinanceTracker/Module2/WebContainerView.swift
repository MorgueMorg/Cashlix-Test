import SwiftUI

/// SwiftUI wrapper for the UIKit-based WebViewController.
struct WebContainerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WebViewController {
        WebViewController()
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        // No dynamic updates needed — WebViewController manages itself.
    }
}
