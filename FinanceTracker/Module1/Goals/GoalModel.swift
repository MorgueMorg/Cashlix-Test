import Foundation
import SwiftUI

// MARK: - Goal Color

enum GoalColor: String, Codable, CaseIterable {
    case blue, green, orange, pink, purple, red, teal, yellow

    var color: Color {
        switch self {
        case .blue:   return Color(red: 0.20, green: 0.47, blue: 1.00)
        case .green:  return Color(red: 0.18, green: 0.76, blue: 0.40)
        case .orange: return Color(red: 1.00, green: 0.58, blue: 0.00)
        case .pink:   return Color(red: 1.00, green: 0.22, blue: 0.57)
        case .purple: return Color(red: 0.55, green: 0.27, blue: 0.91)
        case .red:    return Color(red: 0.96, green: 0.26, blue: 0.21)
        case .teal:   return Color(red: 0.19, green: 0.66, blue: 0.74)
        case .yellow: return Color(red: 0.98, green: 0.80, blue: 0.00)
        }
    }

    var displayName: String { rawValue.capitalized }
}

// MARK: - Goal Icon

enum GoalIcon: String, Codable, CaseIterable {
    case house, car, airplane, gift, bag, laptop
    case heart, star, graduationcap, umbrella, trophy, bicycle

    var sfSymbol: String {
        switch self {
        case .house:        return "house.fill"
        case .car:          return "car.fill"
        case .airplane:     return "airplane"
        case .gift:         return "gift.fill"
        case .bag:          return "bag.fill"
        case .laptop:       return "laptopcomputer"
        case .heart:        return "heart.fill"
        case .star:         return "star.fill"
        case .graduationcap: return "graduationcap.fill"
        case .umbrella:     return "umbrella.fill"
        case .trophy:       return "trophy.fill"
        case .bicycle:      return "bicycle"
        }
    }

    var label: String {
        switch self {
        case .house:        return "Home"
        case .car:          return "Car"
        case .airplane:     return "Travel"
        case .gift:         return "Gift"
        case .bag:          return "Shopping"
        case .laptop:       return "Tech"
        case .heart:        return "Health"
        case .star:         return "Other"
        case .graduationcap: return "Education"
        case .umbrella:     return "Emergency"
        case .trophy:       return "Achievement"
        case .bicycle:      return "Sport"
        }
    }
}

// MARK: - Goal Contribution

struct GoalContribution: Codable, Identifiable {
    var id: UUID = UUID()
    var amount: Double
    var date: Date
    var note: String = ""
}

// MARK: - Financial Goal

struct FinancialGoal: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var targetAmount: Double
    var currentAmount: Double = 0
    var icon: GoalIcon = .star
    var color: GoalColor = .blue
    var deadline: Date? = nil
    var note: String = ""
    var contributions: [GoalContribution] = []
    var createdAt: Date = Date()

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var isCompleted: Bool { currentAmount >= targetAmount }
    var remaining: Double { max(targetAmount - currentAmount, 0) }

    var daysLeft: Int? {
        guard let dl = deadline else { return nil }
        let cal = Calendar.current
        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: Date()),
            to: cal.startOfDay(for: dl)
        ).day ?? 0
        return days
    }

    var monthlyRequired: Double? {
        guard let days = daysLeft, days > 0, remaining > 0 else { return nil }
        let months = Double(days) / 30.0
        return months > 0 ? remaining / months : nil
    }
}
