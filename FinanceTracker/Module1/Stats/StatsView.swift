import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings

    @State private var selectedPeriod = 0
    private let periods = ["This Month", "30 Days", "All Time"]

    // MARK: - Filtered data

    private var filtered: [Transaction] {
        let cal = Calendar.current
        switch selectedPeriod {
        case 0:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
            return store.transactions.filter { $0.date >= start }
        case 1:
            let cutoff = cal.date(byAdding: .day, value: -30, to: Date())!
            return store.transactions.filter { $0.date >= cutoff }
        default:
            return store.transactions
        }
    }

    private var income: Double { filtered.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    private var expenses: Double { filtered.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var savingsRate: Double { income > 0 ? max(0, (income - expenses) / income) : 0 }

    private var categoryData: [(cat: TransactionCategory, amount: Double)] {
        var totals: [TransactionCategory: Double] = [:]
        for t in filtered where t.type == .expense { totals[t.category, default: 0] += t.amount }
        return totals.map { (cat: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    periodPicker
                    summaryCard
                    if !categoryData.isEmpty { categoryCard }
                    else { emptyState }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Analytics")
        }
    }

    // MARK: - Period picker

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(periods.indices, id: \.self) { Text(periods[$0]).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                metricBox(title: "Income", value: income, color: .green, icon: "arrow.down.circle.fill")
                metricBox(title: "Expenses", value: expenses, color: .red, icon: "arrow.up.circle.fill")
            }

            Divider()

            VStack(spacing: 8) {
                HStack {
                    Text("Savings Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", savingsRate * 100))
                        .font(.subheadline.bold())
                        .foregroundColor(savingsRate > 0 ? .green : .secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 8)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.green.opacity(0.8), .green],
                                startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(min(savingsRate, 1)), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        .padding(.horizontal, 16)
    }

    private func metricBox(title: String, value: Double, color: Color, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(settings.formatAmount(value)).font(.subheadline.bold()).foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Category card

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.headline)

            ForEach(categoryData.prefix(6), id: \.cat) { item in
                categoryRow(item)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        .padding(.horizontal, 16)
    }

    private func categoryRow(_ item: (cat: TransactionCategory, amount: Double)) -> some View {
        let ratio = expenses > 0 ? CGFloat(item.amount / expenses) : 0
        return VStack(spacing: 6) {
            HStack {
                Image(systemName: item.cat.icon)
                    .font(.subheadline).foregroundColor(.red).frame(width: 24)
                Text(item.cat.rawValue).font(.subheadline)
                Spacer()
                Text(String(format: "%.0f%%", ratio * 100))
                    .font(.caption).foregroundColor(.secondary)
                Text(settings.formatAmount(item.amount))
                    .font(.subheadline.bold()).foregroundColor(.red)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.red.opacity(0.10)).frame(height: 5)
                    Capsule().fill(Color.red.opacity(0.65))
                        .frame(width: geo.size.width * ratio, height: 5)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.pie").font(.system(size: 40)).foregroundColor(.secondary.opacity(0.4))
            Text("No expense data for this period").foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        .padding(.horizontal, 16)
    }
}
