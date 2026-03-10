import Foundation
import SwiftUI

// MARK: - Color Scheme Preference

enum ColorSchemePreference: String, CaseIterable, Identifiable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Currency Option

struct CurrencyOption: Identifiable {
    let id: String      // ISO code, e.g. "USD"
    let symbol: String
    let name: String
}

// MARK: - AppSettings

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let colorScheme   = "ft_colorScheme"
        static let currencyCode  = "ft_currencyCode"
        static let monthlyBudget = "ft_monthlyBudget"
    }

    @Published var colorScheme: ColorSchemePreference {
        didSet { UserDefaults.standard.set(colorScheme.rawValue, forKey: Keys.colorScheme) }
    }
    @Published var currencyCode: String {
        didSet { UserDefaults.standard.set(currencyCode, forKey: Keys.currencyCode) }
    }
    @Published var monthlyBudget: Double {
        didSet { UserDefaults.standard.set(monthlyBudget, forKey: Keys.monthlyBudget) }
    }

    static let currencies: [CurrencyOption] = [
        CurrencyOption(id: "USD", symbol: "$",  name: "US Dollar"),
        CurrencyOption(id: "EUR", symbol: "€",  name: "Euro"),
        CurrencyOption(id: "GBP", symbol: "£",  name: "British Pound"),
        CurrencyOption(id: "RUB", symbol: "₽",  name: "Russian Ruble"),
        CurrencyOption(id: "UAH", symbol: "₴",  name: "Ukrainian Hryvnia"),
        CurrencyOption(id: "KZT", symbol: "₸",  name: "Kazakhstani Tenge"),
        CurrencyOption(id: "JPY", symbol: "¥",  name: "Japanese Yen"),
        CurrencyOption(id: "CNY", symbol: "¥",  name: "Chinese Yuan"),
    ]

    private init() {
        let raw = UserDefaults.standard.string(forKey: Keys.colorScheme) ?? "System"
        colorScheme   = ColorSchemePreference(rawValue: raw) ?? .system
        currencyCode  = UserDefaults.standard.string(forKey: Keys.currencyCode) ?? "USD"
        monthlyBudget = UserDefaults.standard.double(forKey: Keys.monthlyBudget)
    }

    func formatAmount(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}
