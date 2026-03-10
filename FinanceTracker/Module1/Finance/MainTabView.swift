import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FinanceView(selectedTab: $selectedTab)
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)

            StatsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
                .tag(1)

            GoalsView()
                .tabItem { Label("Goals", systemImage: "flag.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
    }
}
