import Foundation
import SwiftUI

// MARK: - Transaction Type

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense

    var title: String {
        switch self {
        case .income:  return "Income"
        case .expense: return "Expense"
        }
    }

    var color: Color {
        switch self {
        case .income:  return .green
        case .expense: return .red
        }
    }
}

// MARK: - Transaction Category

enum TransactionCategory: String, Codable, CaseIterable {
    case salary, freelance, investment
    case food, dining, transport, housing
    case entertainment, health, shopping
    case utilities, subscription, education
    case travel, gym, gifts, other

    var icon: String {
        switch self {
        case .salary:       return "dollarsign.circle.fill"
        case .freelance:    return "laptopcomputer"
        case .investment:   return "chart.bar.fill"
        case .food:         return "cart.fill"
        case .dining:       return "fork.knife"
        case .transport:    return "car.fill"
        case .housing:      return "house.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health:       return "heart.fill"
        case .shopping:     return "bag.fill"
        case .utilities:    return "bolt.fill"
        case .subscription: return "repeat"
        case .education:    return "book.fill"
        case .travel:       return "airplane"
        case .gym:          return "flame.fill"
        case .gifts:        return "gift.fill"
        case .other:        return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .salary:       return Color(red: 0.18, green: 0.76, blue: 0.40)
        case .freelance:    return Color(red: 0.20, green: 0.47, blue: 1.00)
        case .investment:   return Color(red: 0.00, green: 0.70, blue: 0.55)
        case .food:         return Color(red: 1.00, green: 0.58, blue: 0.00)
        case .dining:       return Color(red: 1.00, green: 0.42, blue: 0.20)
        case .transport:    return Color(red: 0.20, green: 0.60, blue: 1.00)
        case .housing:      return Color(red: 0.40, green: 0.60, blue: 0.90)
        case .entertainment: return Color(red: 0.55, green: 0.27, blue: 0.91)
        case .health:       return Color(red: 0.96, green: 0.26, blue: 0.21)
        case .shopping:     return Color(red: 1.00, green: 0.22, blue: 0.57)
        case .utilities:    return Color(red: 0.98, green: 0.80, blue: 0.00)
        case .subscription: return Color(red: 0.60, green: 0.40, blue: 1.00)
        case .education:    return Color(red: 0.10, green: 0.70, blue: 0.90)
        case .travel:       return Color(red: 0.10, green: 0.55, blue: 0.85)
        case .gym:          return Color(red: 1.00, green: 0.35, blue: 0.00)
        case .gifts:        return Color(red: 1.00, green: 0.40, blue: 0.60)
        case .other:        return Color(red: 0.55, green: 0.55, blue: 0.60)
        }
    }

    var displayName: String {
        switch self {
        case .salary:       return "Salary"
        case .freelance:    return "Freelance"
        case .investment:   return "Investment"
        case .food:         return "Groceries"
        case .dining:       return "Dining Out"
        case .transport:    return "Transport"
        case .housing:      return "Housing"
        case .entertainment: return "Entertainment"
        case .health:       return "Health"
        case .shopping:     return "Shopping"
        case .utilities:    return "Utilities"
        case .subscription: return "Subscription"
        case .education:    return "Education"
        case .travel:       return "Travel"
        case .gym:          return "Gym & Sport"
        case .gifts:        return "Gifts"
        case .other:        return "Other"
        }
    }
}

// MARK: - Transaction

struct Transaction: Codable, Identifiable {
    var id: UUID
    var amount: Double
    var type: TransactionType
    var category: TransactionCategory
    var note: String?
    var date: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        category: TransactionCategory,
        note: String? = nil,
        date: Date = Date()
    ) {
        self.id       = id
        self.amount   = amount
        self.type     = type
        self.category = category
        self.note     = note
        self.date     = date
    }

    var signedAmount: Double {
        type == .income ? amount : -amount
    }
}
