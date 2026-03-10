import Foundation
import Combine

final class GoalStore: ObservableObject {
    static let shared = GoalStore()
    private let key = "cashlix_goals_v1"

    @Published var goals: [FinancialGoal] = [] {
        didSet { save() }
    }

    private init() { load() }

    // MARK: - CRUD

    func add(_ goal: FinancialGoal) {
        goals.insert(goal, at: 0)
    }

    func update(_ goal: FinancialGoal) {
        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[idx] = goal
        }
    }

    func delete(_ goal: FinancialGoal) {
        goals.removeAll { $0.id == goal.id }
    }

    func addContribution(to goalID: UUID, amount: Double, note: String = "") {
        guard let idx = goals.firstIndex(where: { $0.id == goalID }) else { return }
        let c = GoalContribution(amount: amount, date: Date(), note: note)
        goals[idx].contributions.append(c)
        goals[idx].currentAmount = min(goals[idx].currentAmount + amount, goals[idx].targetAmount)
    }

    // MARK: - Aggregates

    var totalSaved: Double  { goals.reduce(0) { $0 + $1.currentAmount } }
    var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }
    var completedCount: Int { goals.filter { $0.isCompleted }.count }

    var activeGoals: [FinancialGoal]    { goals.filter { !$0.isCompleted } }
    var completedGoals: [FinancialGoal] { goals.filter {  $0.isCompleted } }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard
            let data    = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([FinancialGoal].self, from: data)
        else { return }
        goals = decoded
    }

    func clearAll() { goals = [] }
}
