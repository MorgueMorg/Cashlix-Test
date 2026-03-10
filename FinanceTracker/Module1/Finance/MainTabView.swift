import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FinanceView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }

            StatsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }

            GoalsView()
                .tabItem { Label("Goals", systemImage: "flag.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
