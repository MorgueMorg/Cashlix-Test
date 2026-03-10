import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var splashDone = false

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
    }

    @ViewBuilder
    private var mainContent: some View {
        switch appState.moduleChoice {
        case .module2:
            WebContainerView()
        default:
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}
