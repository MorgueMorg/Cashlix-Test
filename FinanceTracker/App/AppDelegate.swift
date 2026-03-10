import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // Module 2 (WebView) allows all orientations; Module 1 is portrait only
        AppState.shared.moduleChoice == .module2 ? .allButUpsideDown : .portrait
    }
}
