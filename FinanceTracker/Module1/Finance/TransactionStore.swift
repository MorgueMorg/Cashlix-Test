import Foundation
import Combine

final class TransactionStore: ObservableObject {
    static let shared = TransactionStore()

    @Published var transactions: [Transaction] = []

    private let storageKey = "ft_transactions"

    private init() { load() }

    // MARK: - CRUD

    func add(_ t: Transaction) {
        transactions.insert(t, at: 0)
        save()
    }

    func update(_ t: Transaction) {
        if let idx = transactions.firstIndex(where: { $0.id == t.id }) {
            transactions[idx] = t
            save()
        }
    }

    func delete(_ t: Transaction) {
        transactions.removeAll { $0.id == t.id }
        save()
    }

    func clearAll() {
        transactions = []
        save()
    }

    // MARK: - Basic Aggregates

    var balance: Double       { transactions.reduce(0) { $0 + $1.signedAmount } }
    var totalIncome: Double   { transactions.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount } }
    var totalExpenses: Double { transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }

    // MARK: - Period Helpers

    func transactions(in period: DateInterval) -> [Transaction] {
        transactions.filter { period.contains($0.date) }
    }

    func income(in period: DateInterval) -> Double {
        transactions(in: period).filter { $0.type == .income  }.reduce(0) { $0 + $1.amount }
    }

    func expenses(in period: DateInterval) -> Double {
        transactions(in: period).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    func balance(in period: DateInterval) -> Double {
        income(in: period) - expenses(in: period)
    }

    // MARK: - Current Month

    var currentMonthInterval: DateInterval {
        let cal   = Calendar.current
        let now   = Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let end   = cal.date(byAdding: DateComponents(month: 1, second: -1), to: start)!
        return DateInterval(start: start, end: end)
    }

    var monthlyIncome:   Double { income(in: currentMonthInterval) }
    var monthlyExpenses: Double { expenses(in: currentMonthInterval) }
    var monthlySavings:  Double { monthlyIncome - monthlyExpenses }

    var savingsRate: Double {
        guard monthlyIncome > 0 else { return 0 }
        return max(monthlySavings / monthlyIncome, 0)
    }

    // MARK: - Category Breakdown

    func expensesByCategory(in period: DateInterval? = nil) -> [(category: TransactionCategory, amount: Double)] {
        let source: [Transaction]
        if let p = period {
            source = transactions.filter { $0.type == .expense && p.contains($0.date) }
        } else {
            source = transactions.filter { $0.type == .expense }
        }
        let grouped = Dictionary(grouping: source, by: { $0.category })
        return grouped
            .map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Monthly Trend (last N months)

    struct MonthlySnapshot {
        let label: String
        let income: Double
        let expenses: Double
        var net: Double { income - expenses }
    }

    func monthlyTrend(months: Int = 6) -> [MonthlySnapshot] {
        let cal = Calendar.current
        let now = Date()
        return (0..<months).reversed().map { offset in
            let monthDate = cal.date(byAdding: .month, value: -offset, to: now)!
            let comps  = cal.dateComponents([.year, .month], from: monthDate)
            let start  = cal.date(from: comps)!
            let end    = cal.date(byAdding: DateComponents(month: 1, second: -1), to: start)!
            let period = DateInterval(start: start, end: end)
            let label  = monthDate.formatted(.dateTime.month(.abbreviated))
            return MonthlySnapshot(
                label:    label,
                income:   income(in: period),
                expenses: expenses(in: period)
            )
        }
    }

    // MARK: - Daily Net

    func dailyNet(days: Int) -> [(date: Date, net: Double)] {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).map { offset in
            let date = cal.date(byAdding: .day, value: -(days - 1 - offset), to: today)!
            let net  = transactions
                .filter { cal.isDate($0.date, inSameDayAs: date) }
                .reduce(0.0) { $0 + $1.signedAmount }
            return (date: date, net: net)
        }
    }

    // MARK: - Top Expenses

    func topExpenses(limit: Int = 5, in period: DateInterval? = nil) -> [Transaction] {
        let source: [Transaction]
        if let p = period {
            source = transactions.filter { $0.type == .expense && p.contains($0.date) }
        } else {
            source = transactions.filter { $0.type == .expense }
        }
        return Array(source.sorted { $0.amount > $1.amount }.prefix(limit))
    }

    // MARK: - Averages

    var dailyAverageExpense: Double {
        guard !transactions.isEmpty else { return 0 }
        let cal  = Calendar.current
        let dates = Set(transactions.filter { $0.type == .expense }.map { cal.startOfDay(for: $0.date) })
        guard !dates.isEmpty else { return 0 }
        return totalExpenses / Double(dates.count)
    }

    var weeklyAverageExpense: Double { dailyAverageExpense * 7 }

    // MARK: - Smart Insights

    func generateInsights(settings: AppSettings) -> [String] {
        var insights: [String] = []

        // Savings rate
        if monthlyIncome > 0 {
            let rate = Int(savingsRate * 100)
            if rate >= 20 {
                insights.append("Great job! You saved \(rate)% of your income this month. 🎉")
            } else if rate > 0 {
                insights.append("You saved \(rate)% this month. Aim for 20% to build wealth.")
            } else if monthlyExpenses > monthlyIncome {
                insights.append("⚠️ You spent more than you earned this month. Review your expenses.")
            }
        }

        // Top spending category
        let cats = expensesByCategory(in: currentMonthInterval)
        if let top = cats.first, top.amount > 0 {
            let pct = monthlyExpenses > 0 ? Int(top.amount / monthlyExpenses * 100) : 0
            insights.append("\(top.category.displayName) is your top expense at \(pct)% of spending.")
        }

        // Budget tip
        if settings.monthlyBudget > 0 {
            let used = monthlyExpenses / settings.monthlyBudget
            if used >= 1.0 {
                insights.append("🔴 You've exceeded your monthly budget!")
            } else if used >= 0.8 {
                insights.append("⚠️ You've used \(Int(used*100))% of your monthly budget.")
            }
        }

        // Generic tips (rotate by day of month)
        let tips = [
            "Track every expense, even small ones — they add up fast.",
            "The 50/30/20 rule: 50% needs, 30% wants, 20% savings.",
            "Review subscriptions monthly and cancel unused ones.",
            "Build a 3–6 month emergency fund before investing.",
            "Pay yourself first: save before you spend.",
            "Small daily savings compound into significant wealth.",
        ]
        let dayOfMonth = Calendar.current.component(.day, from: Date())
        insights.append(tips[dayOfMonth % tips.count])

        return insights
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard
            let data  = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode([Transaction].self, from: data)
        else { return }
        transactions = saved
    }
}
