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

    func delete(_ t: Transaction) {
        transactions.removeAll { $0.id == t.id }
        save()
    }

    func clearAll() {
        transactions = []
        save()
    }

    // MARK: - Computed

    var balance: Double { transactions.reduce(0) { $0 + $1.signedAmount } }

    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    /// Returns daily net amount for the last `days` days (oldest first).
    func dailyNet(days: Int) -> [(date: Date, net: Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).map { offset in
            let date = cal.date(byAdding: .day, value: -(days - 1 - offset), to: today)!
            let net = transactions
                .filter { cal.isDate($0.date, inSameDayAs: date) }
                .reduce(0.0) { $0 + $1.signedAmount }
            return (date: date, net: net)
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode([Transaction].self, from: data)
        else { return }
        transactions = saved
    }
}
