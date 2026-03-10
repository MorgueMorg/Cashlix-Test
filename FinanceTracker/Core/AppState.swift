import Foundation
import Combine

enum ModuleChoice: String {
    case undecided, module1, module2
}

final class AppState: ObservableObject {
    static let shared = AppState()

    private enum Keys {
        static let moduleChoice = "moduleChoice"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let savedWebURL = "savedWebURL"
        static let lastWebURL = "lastWebURL"
    }

    @Published var moduleChoice: ModuleChoice {
        didSet { UserDefaults.standard.set(moduleChoice.rawValue, forKey: Keys.moduleChoice) }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }
    @Published var savedWebURL: String? {
        didSet { UserDefaults.standard.set(savedWebURL, forKey: Keys.savedWebURL) }
    }
    @Published var lastWebURL: String? {
        didSet { UserDefaults.standard.set(lastWebURL, forKey: Keys.lastWebURL) }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: Keys.moduleChoice) ?? "undecided"
        moduleChoice = ModuleChoice(rawValue: raw) ?? .undecided
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        savedWebURL = UserDefaults.standard.string(forKey: Keys.savedWebURL)
        lastWebURL = UserDefaults.standard.string(forKey: Keys.lastWebURL)
    }
}
