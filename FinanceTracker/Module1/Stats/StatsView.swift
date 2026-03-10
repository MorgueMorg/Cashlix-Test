import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings

    @State private var selectedPeriod: Period = .thisMonth
    @State private var chartMode: ChartMode   = .net

    enum Period: String, CaseIterable {
        case thisMonth = "This Month"
        case month30   = "30 Days"
        case allTime   = "All Time"
    }

    enum ChartMode: String, CaseIterable {
        case net      = "Net"
        case income   = "Income"
        case expenses = "Expenses"
    }

    // MARK: Period interval

    private var interval: DateInterval? {
        let cal = Calendar.current
        let now = Date()
        switch selectedPeriod {
        case .thisMonth:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let end   = cal.date(byAdding: DateComponents(month: 1, second: -1), to: start)!
            return DateInterval(start: start, end: end)
        case .month30:
            let start = cal.date(byAdding: .day, value: -30, to: now)!
            return DateInterval(start: start, end: now)
        case .allTime:
            return nil
        }
    }

    private var income:   Double { interval.map { store.income(in: $0) }   ?? store.totalIncome }
    private var expenses: Double { interval.map { store.expenses(in: $0) } ?? store.totalExpenses }
    private var net:      Double { income - expenses }
    private var savingsRate: Double { income > 0 ? max(net / income, 0) : 0 }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(Period.allCases, id: \.rawValue) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 4)

                    summaryCards
                    savingsRateCard
                    monthlyTrendCard
                    categoryBreakdownCard
                    topExpensesCard
                    averagesCard
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCell(title: "Income",   value: settings.formatAmount(income),   icon: "arrow.down.circle.fill", color: .green)
            summaryCell(title: "Expenses", value: settings.formatAmount(expenses), icon: "arrow.up.circle.fill",   color: .red)
            summaryCell(title: "Net",      value: settings.formatAmount(net),      icon: "plusminus",              color: net >= 0 ? .green : .red)
        }
        .padding(.horizontal)
    }

    private func summaryCell(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Savings Rate Card

    private var savingsRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Savings Rate", systemImage: "percent")
                    .font(.headline)
                Spacer()
                Text("\(Int(savingsRate * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(savingsRateColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [savingsRateColor.opacity(0.7), savingsRateColor],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(savingsRate), height: 14)
                        .animation(.spring(), value: savingsRate)
                }
            }
            .frame(height: 14)
            Text(savingsRateLabel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var savingsRateColor: Color {
        if savingsRate >= 0.20 { return .green }
        if savingsRate >= 0.10 { return .orange }
        return .red
    }

    private var savingsRateLabel: String {
        if income == 0 { return "No income recorded in this period." }
        if savingsRate >= 0.20 { return "Excellent! You're saving \(Int(savingsRate*100))% — well above the 20% target." }
        if savingsRate >= 0.10 { return "Getting there. Aim to save at least 20% of your income." }
        if savingsRate > 0     { return "Low savings rate. Try to reduce unnecessary expenses." }
        return "You spent more than you earned this period."
    }

    // MARK: - Monthly Trend Chart

    private var monthlyTrendCard: some View {
        let trend = store.monthlyTrend(months: 6)
        let maxVal = trend.map { max($0.income, $0.expenses) }.max() ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("6-Month Trend", systemImage: "chart.bar.xaxis")
                    .font(.headline)
                Spacer()
                Picker("", selection: $chartMode) {
                    ForEach(ChartMode.allCases, id: \.rawValue) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(trend, id: \.label) { snap in
                    let value: Double = {
                        switch chartMode {
                        case .income:   return snap.income
                        case .expenses: return snap.expenses
                        case .net:      return snap.net
                        }
                    }()
                    let barColor: Color = {
                        switch chartMode {
                        case .income:   return .green
                        case .expenses: return .red
                        case .net:      return value >= 0 ? .blue : .red
                        }
                    }()
                    let height = maxVal > 0 ? max(abs(value) / maxVal, 0.05) : 0.05

                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(barColor.opacity(0.85))
                                    .frame(height: geo.size.height * CGFloat(height))
                            }
                        }
                        .frame(height: 80)
                        Text(snap.label)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Legend
            HStack(spacing: 16) {
                if chartMode == .net {
                    legendDot(.blue,  "Positive")
                    legendDot(.red,   "Negative")
                } else if chartMode == .income {
                    legendDot(.green, "Income")
                } else {
                    legendDot(.red,   "Expenses")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownCard: some View {
        let cats  = store.expensesByCategory(in: interval)
        let total = cats.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 14) {
            Label("Spending by Category", systemImage: "chart.pie.fill")
                .font(.headline)
                .padding(.bottom, 2)

            if cats.isEmpty {
                emptyPlaceholder("No expenses in this period.")
            } else {
                ForEach(cats.prefix(6), id: \.category.rawValue) { item in
                    let pct = total > 0 ? item.amount / total : 0
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(item.category.color.opacity(0.15))
                                .frame(width: 34, height: 34)
                            Image(systemName: item.category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(item.category.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.category.displayName)
                                    .font(.subheadline)
                                Spacer()
                                Text(settings.formatAmount(item.amount))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("(\(Int(pct * 100))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 36, alignment: .trailing)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 5)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(item.category.color)
                                        .frame(width: geo.size.width * CGFloat(pct), height: 5)
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Top Expenses

    private var topExpensesCard: some View {
        let tops = store.topExpenses(limit: 5, in: interval)

        return VStack(alignment: .leading, spacing: 12) {
            Label("Top Expenses", systemImage: "arrow.up.circle.fill")
                .font(.headline)

            if tops.isEmpty {
                emptyPlaceholder("No expenses in this period.")
            } else {
                ForEach(Array(tops.enumerated()), id: \.element.id) { idx, tx in
                    HStack(spacing: 10) {
                        Text("#\(idx + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        ZStack {
                            Circle()
                                .fill(tx.category.color.opacity(0.15))
                                .frame(width: 34, height: 34)
                            Image(systemName: tx.category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(tx.category.color)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(tx.category.displayName)
                                .font(.subheadline)
                            if let n = tx.note, !n.isEmpty {
                                Text(n).font(.caption).foregroundColor(.secondary).lineLimit(1)
                            } else {
                                Text(tx.date, style: .date).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text(settings.formatAmount(tx.amount))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    if idx < tops.count - 1 {
                        Divider().padding(.leading, 30)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Averages Card

    private var averagesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Averages", systemImage: "function")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                averageCell(
                    title: "Daily Spending",
                    value: settings.formatAmount(store.dailyAverageExpense),
                    icon: "calendar.day.timeline.left",
                    color: .blue
                )
                averageCell(
                    title: "Weekly Spending",
                    value: settings.formatAmount(store.weeklyAverageExpense),
                    icon: "calendar",
                    color: .purple
                )
                averageCell(
                    title: "Transactions",
                    value: "\(store.transactions.count)",
                    icon: "list.bullet",
                    color: .orange
                )
                averageCell(
                    title: "Avg. Transaction",
                    value: store.transactions.isEmpty ? "—"
                        : settings.formatAmount(store.totalExpenses / Double(store.transactions.filter { $0.type == .expense }.count.nonZero)),
                    icon: "arrow.left.arrow.right",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func averageCell(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper

    private func emptyPlaceholder(_ message: String) -> some View {
        HStack {
            Spacer()
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 12)
            Spacer()
        }
    }
}

// MARK: - Int.nonZero helper

private extension Int {
    var nonZero: Int { self == 0 ? 1 : self }
}
