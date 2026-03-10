import SwiftUI

struct FinanceView: View {
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var goalStore: GoalStore

    @State private var showAddSheet        = false
    @State private var showAllTransactions = false
    @State private var addType: TransactionType = .expense
    @State private var insightIndex        = 0
    @State private var insightTimer: Timer?

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    greetingHeader
                    balanceHeroCard
                    quickActionRow
                    insightsCard
                    if !goalStore.activeGoals.isEmpty { goalsWidget }
                    if settings.monthlyBudget > 0     { budgetWidget }
                    weeklyChartCard
                    recentTransactionsCard
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAllTransactions = true } label: {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTransactionSheet(presetType: addType)
                    .environmentObject(store)
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showAllTransactions) {
                NavigationView {
                    AllTransactionsView()
                        .environmentObject(store)
                        .environmentObject(settings)
                }
            }
            .onAppear  { startInsightTimer() }
            .onDisappear { insightTimer?.invalidate() }
        }
    }

    // MARK: Greeting Header

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(Date().formatted(.dateTime.month(.abbreviated)))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(8)
        }
        .padding(.top, 4)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning 👋" }
        if h < 17 { return "Good afternoon 👋" }
        return "Good evening 👋"
    }

    // MARK: Balance Hero Card

    private var balanceHeroCard: some View {
        ZStack {
            LinearGradient(
                colors: store.balance >= 0
                    ? [Color(red: 0.10, green: 0.45, blue: 0.95),
                       Color(red: 0.05, green: 0.28, blue: 0.78)]
                    : [Color(red: 0.85, green: 0.20, blue: 0.20),
                       Color(red: 0.60, green: 0.10, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Total Balance")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Text(settings.formatAmount(store.balance))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                HStack(spacing: 0) {
                    miniStat("arrow.down.circle.fill", "Income",   settings.formatAmount(store.monthlyIncome),    .white.opacity(0.95))
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 36)
                    miniStat("arrow.up.circle.fill",   "Expenses", settings.formatAmount(store.monthlyExpenses),  .white.opacity(0.95))
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 36)
                    let netColor: Color = store.monthlySavings >= 0
                        ? Color(red: 0.6, green: 1.0, blue: 0.6)
                        : Color(red: 1.0, green: 0.6, blue: 0.6)
                    miniStat("plusminus", "Net", settings.formatAmount(store.monthlySavings), netColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12))
                .cornerRadius(14)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    private func miniStat(_ icon: String, _ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.caption2).foregroundColor(color)
                Text(label).font(.caption2).foregroundColor(.white.opacity(0.7))
            }
            Text(value).font(.caption).fontWeight(.semibold).foregroundColor(color)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Quick Actions

    private var quickActionRow: some View {
        HStack(spacing: 12) {
            quickAction("plus.circle.fill",  "Add Income",  .green)  { addType = .income;  showAddSheet = true }
            quickAction("minus.circle.fill", "Add Expense", .red)    { addType = .expense; showAddSheet = true }
            quickAction("list.bullet",       "History",     .blue)   { showAllTransactions = true }
            quickAction("flag.fill",         "Goals",       .orange) { }
        }
    }

    private func quickAction(_ icon: String, _ label: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: Insights Card

    private var insights: [String] {
        store.generateInsights(settings: settings)
    }

    private var insightsCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                insightIndex = (insightIndex + 1) % max(insights.count, 1)
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label("Smart Insight", systemImage: "lightbulb.fill")
                        .font(Font.subheadline.weight(.semibold))
                        .foregroundColor(.orange)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<min(insights.count, 5), id: \.self) { i in
                            Circle()
                                .fill(i == insightIndex % max(insights.count, 1)
                                      ? Color.orange : Color(.systemGray4))
                                .frame(width: 5, height: 5)
                                .animation(.easeInOut, value: insightIndex)
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

                Text(insights.isEmpty ? "Add transactions to see insights." : insights[insightIndex % max(insights.count, 1)])
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private func startInsightTimer() {
        insightTimer?.invalidate()
        guard !insights.isEmpty else { return }
        insightTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                insightIndex = (insightIndex + 1) % insights.count
            }
        }
    }

    // MARK: Goals Widget

    private var goalsWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Goals", systemImage: "flag.fill")
                    .font(.headline)
                Spacer()
                Text("\(goalStore.completedCount)/\(goalStore.goals.count) done")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ForEach(goalStore.activeGoals.prefix(2)) { goal in
                GoalMiniRow(goal: goal)
                    .environmentObject(settings)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: Budget Widget

    private var budgetWidget: some View {
        let used    = store.monthlyExpenses
        let budget  = settings.monthlyBudget
        let ratio   = min(used / max(budget, 1), 1.0)
        let over    = used > budget
        let barColor: Color = ratio < 0.75 ? .green : ratio < 1.0 ? .orange : .red

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Monthly Budget", systemImage: "target")
                    .font(.headline)
                Spacer()
                Text(over ? "Over budget!" : "\(Int((1 - ratio) * 100))% left")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(over ? .red : .secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(ratio), height: 10)
                        .animation(.spring(), value: ratio)
                }
            }
            .frame(height: 10)
            HStack {
                Text(settings.formatAmount(used) + " spent")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Text(settings.formatAmount(budget) + " budget")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: Weekly Chart Card

    private var weeklyChartCard: some View {
        let data    = store.dailyNet(days: 7)
        let weekNet = data.reduce(0) { $0 + $1.net }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Last 7 Days", systemImage: "chart.bar.fill")
                    .font(.headline)
                Spacer()
                Text((weekNet >= 0 ? "+" : "") + settings.formatAmount(weekNet))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(weekNet >= 0 ? .green : .red)
            }
            BalanceChartView(dailyData: data)
                .frame(height: 90)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: Recent Transactions

    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Recent", systemImage: "clock.fill")
                    .font(.headline)
                Spacer()
                Button { showAllTransactions = true } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if store.transactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No transactions yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button { addType = .expense; showAddSheet = true } label: {
                        Text("Add first transaction")
                            .font(.subheadline).foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.transactions.prefix(5))) { tx in
                        TxRowCompact(transaction: tx)
                            .environmentObject(settings)
                        if tx.id != store.transactions.prefix(5).last?.id {
                            Divider().padding(.leading, 64)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Goal Mini Row

struct GoalMiniRow: View {
    let goal: FinancialGoal
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(goal.color.color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: goal.icon.sfSymbol)
                    .font(.system(size: 14))
                    .foregroundColor(goal.color.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(goal.name)
                    .font(.subheadline).fontWeight(.medium).lineLimit(1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5)).frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(goal.color.color)
                            .frame(width: geo.size.width * CGFloat(goal.progress), height: 5)
                    }
                }
                .frame(height: 5)
            }
            Spacer()
            Text("\(Int(goal.progress * 100))%")
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(goal.color.color)
        }
    }
}
