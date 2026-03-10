import SwiftUI
import Network

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var splashDone = false
    @State private var isOnline = true

    var body: some View {
        ZStack {
            if !splashDone {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        splashDone = true
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .onAppear(perform: checkConnectivity)
    }

    /// One-shot connectivity check. Runs during the splash so the result
    /// is ready before mainContent is shown.
    private func checkConnectivity() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async { isOnline = path.status == .satisfied }
            monitor.cancel()
        }
        monitor.start(queue: DispatchQueue(label: "net.check"))
    }

    @ViewBuilder
    private var mainContent: some View {
        if appState.moduleChoice == .module2 && isOnline {
            WebContainerView()
        } else {
            // Module 2 chosen but offline → fall back to Module 1
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}
