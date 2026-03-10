import SwiftUI

struct FinanceView: View {
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings
    @State private var showAddSheet = false

    // Current-month expenses for budget tracking
    private var monthlyExpenses: Double {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
        return store.transactions
            .filter { $0.type == .expense && $0.date >= start }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        balanceCard
                        if settings.monthlyBudget > 0 { budgetCard }
                        chartCard
                        transactionList
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 96)
                }

                // FAB
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 58, height: 58)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 28)
            }
            .navigationTitle("My Finances")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showAddSheet) {
            AddTransactionSheet()
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Total Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(settings.formatAmount(store.balance))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(store.balance >= 0 ? .green : .red)
            }

            Divider()

            HStack(spacing: 0) {
                summaryItem(label: "Income", value: store.totalIncome, color: .green,
                            icon: "arrow.down.circle.fill")
                Divider().frame(height: 44)
                summaryItem(label: "Expenses", value: store.totalExpenses, color: .red,
                            icon: "arrow.up.circle.fill")
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
    }

    private func summaryItem(label: String, value: Double, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Text(settings.formatAmount(value)).font(.subheadline.bold()).foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Budget Card

    private var budgetCard: some View {
        let budget = settings.monthlyBudget
        let spent = monthlyExpenses
        let ratio = budget > 0 ? min(spent / budget, 1.0) : 0
        let remaining = max(budget - spent, 0)
        let isOverBudget = spent > budget
        let barColor: Color = ratio < 0.75 ? .green : (ratio < 1.0 ? .orange : .red)

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "target").foregroundColor(.orange)
                Text("Monthly Budget").font(.headline)
                Spacer()
                Text(isOverBudget ? "Over budget!" : "\(settings.formatAmount(remaining)) left")
                    .font(.caption.bold())
                    .foregroundColor(isOverBudget ? .red : .green)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 10)
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(ratio), height: 10)
                        .animation(.spring(), value: ratio)
                }
            }
            .frame(height: 10)

            HStack {
                Text("Spent: \(settings.formatAmount(spent))")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("Limit: \(settings.formatAmount(budget))")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Last 7 Days").font(.headline)
                Spacer()
                Text("Daily Net").font(.caption).foregroundColor(.secondary)
            }
            BalanceChartView(data: store.dailyNet(days: 7)).frame(height: 110)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Transactions").font(.headline)
                Spacer()
                Text("\(store.transactions.count) total").font(.caption).foregroundColor(.secondary)
            }

            if store.transactions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(store.transactions) { t in
                        TransactionRow(transaction: t)
                        if t.id != store.transactions.last?.id {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray.fill").font(.system(size: 40)).foregroundColor(.secondary.opacity(0.5))
            Text("No transactions yet").font(.subheadline).foregroundColor(.secondary)
            Text("Tap + to add your first entry").font(.caption).foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
    }
}
