import Foundation
import SwiftUI

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense

    var title: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        }
    }

    var color: Color {
        switch self {
        case .income: return .green
        case .expense: return .red
        }
    }
}

enum TransactionCategory: String, Codable, CaseIterable {
    case salary = "Salary"
    case food = "Food"
    case transport = "Transport"
    case entertainment = "Entertainment"
    case health = "Health"
    case shopping = "Shopping"
    case utilities = "Utilities"
    case other = "Other"

    var icon: String {
        switch self {
        case .salary: return "dollarsign.circle.fill"
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health: return "heart.fill"
        case .shopping: return "cart.fill"
        case .utilities: return "bolt.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct Transaction: Codable, Identifiable {
    let id: UUID
    var amount: Double
    var type: TransactionType
    var category: TransactionCategory
    var note: String
    var date: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        category: TransactionCategory,
        note: String = "",
        date: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.date = date
    }

    var signedAmount: Double {
        type == .income ? amount : -amount
    }
}
