import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @EnvironmentObject var appState: AppState
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotating = false

    private let minDisplayTime: Double = 2.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.08, blue: 0.20),
                         Color(red: 0.08, green: 0.14, blue: 0.32)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 130, height: 130)

                    Circle()
                        .stroke(Color.white.opacity(0.20), lineWidth: 2)
                        .frame(width: 130, height: 130)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotating ? 360 : 0))
                        .animation(
                            .linear(duration: 3).repeatForever(autoreverses: false),
                            value: rotating
                        )
                }
                .scaleEffect(scale)
                .opacity(opacity)

                VStack(spacing: 8) {
                    Text("Cashlix")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("Your money, under control")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.65))
                }
                .opacity(opacity)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.7)))
                    .padding(.top, 8)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            rotating = true
            startLoading()
        }
    }

    private func startLoading() {
        let startTime = Date()

        // Subsequent launches — just show splash for minDisplayTime
        if appState.moduleChoice != .undecided {
            DispatchQueue.main.asyncAfter(deadline: .now() + minDisplayTime) {
                onFinished()
            }
            return
        }

        // First launch — download config while animation plays
        Task {
            do {
                let urlString = try await ConfigLoader.load()
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, minDisplayTime - elapsed)
                if remaining > 0 {
                    try await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                }
                await MainActor.run {
                    appState.savedWebURL = urlString
                    appState.lastWebURL = urlString
                    appState.moduleChoice = .module2
                    onFinished()
                }
            } catch {
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, minDisplayTime - elapsed)
                if remaining > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                }
                await MainActor.run {
                    appState.moduleChoice = .module1
                    onFinished()
                }
            }
        }
    }
}
