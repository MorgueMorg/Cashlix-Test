import SwiftUI

/// A bar chart showing daily net amounts. Positive bars are green, negative red.
/// Built entirely with SwiftUI for iOS 15 compatibility (no Charts framework needed).
struct BalanceChartView: View {
    /// Pass either `data` or `dailyData` — both refer to the same array.
    var dailyData: [(date: Date, net: Double)]

    init(data: [(date: Date, net: Double)]) {
        self.dailyData = data
    }

    init(dailyData: [(date: Date, net: Double)]) {
        self.dailyData = dailyData
    }

    private var maxAbs: Double {
        dailyData.map { abs($0.net) }.max() ?? 1
    }

    var body: some View {
        GeometryReader { geo in
            let barWidth  = (geo.size.width - CGFloat(dailyData.count + 1) * 4) / CGFloat(max(dailyData.count, 1))
            let chartHeight = geo.size.height - 22

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(dailyData.indices, id: \.self) { i in
                    let item       = dailyData[i]
                    let isPositive = item.net >= 0
                    let ratio      = maxAbs > 0 ? CGFloat(abs(item.net) / maxAbs) : 0
                    let barH       = max(ratio * (chartHeight * 0.88), item.net == 0 ? 0 : 3)

                    VStack(spacing: 4) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: isPositive
                                        ? [Color.green.opacity(0.9), Color.green.opacity(0.55)]
                                        : [Color.red.opacity(0.9),   Color.red.opacity(0.55)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: barWidth, height: barH)
                        Text(dayLabel(item.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(2))
    }
}
