import SwiftUI

@main
struct FinanceTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppRoot()
        }
    }
}

/// Thin wrapper that observes AppSettings so `.preferredColorScheme` reacts to changes.
private struct AppRoot: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        RootView()
            .environmentObject(AppState.shared)
            .environmentObject(TransactionStore.shared)
            .environmentObject(GoalStore.shared)
            .environmentObject(settings)
            .preferredColorScheme(settings.colorScheme.colorScheme)
    }
}
