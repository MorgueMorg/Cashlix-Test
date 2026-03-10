import SwiftUI

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Finances",
            description: "Monitor income and expenses in one place. Get a clear picture of your financial health.",
            color: .blue
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Visual Insights",
            description: "Beautiful charts show where your money goes and where it comes from — at a glance.",
            color: .purple
        ),
        OnboardingPage(
            icon: "checkmark.shield.fill",
            title: "Stay in Control",
            description: "Build smart habits, stay on top of spending, and make better financial decisions every day.",
            color: .green
        )
    ]
}
