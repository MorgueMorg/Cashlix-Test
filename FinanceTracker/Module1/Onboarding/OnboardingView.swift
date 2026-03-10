import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background color transitions with page
            pages[currentPage].color
                .opacity(0.10)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack(spacing: 0) {
                // Swipeable pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageContent(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Dots + button
                bottomBar
                    .padding(.bottom, 48)
            }
        }
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 36) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 170, height: 170)

                Circle()
                    .stroke(page.color.opacity(0.25), lineWidth: 2)
                    .frame(width: 170, height: 170)

                Image(systemName: page.icon)
                    .font(.system(size: 68, weight: .semibold))
                    .foregroundColor(page.color)
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
            }

            Spacer()
            Spacer()
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 24) {
            // Animated page dots
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage
                              ? pages[currentPage].color
                              : Color.secondary.opacity(0.3))
                        .frame(width: index == currentPage ? 28 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                }
            }

            // Action button
            Button(action: handleButton) {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(pages[currentPage].color)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 28)
            .animation(.easeInOut, value: currentPage)
        }
    }

    private func handleButton() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            appState.hasCompletedOnboarding = true
        }
    }
}
