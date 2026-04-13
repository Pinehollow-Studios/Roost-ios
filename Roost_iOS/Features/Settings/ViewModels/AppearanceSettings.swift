import Observation
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var subtitle: String {
        switch self {
        case .system:
            return "Follow your iPhone appearance automatically"
        case .light:
            return "Use the warm Roost light palette"
        case .dark:
            return "Use the darker evening palette"
        }
    }

    var symbolName: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max"
        case .dark:
            return "moon.stars"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@MainActor
@Observable
final class AppearanceSettings {
    private enum StorageKey {
        static let selection = "roost.app.appearance"
    }

    var selection: AppAppearance {
        didSet {
            UserDefaults.standard.set(selection.rawValue, forKey: StorageKey.selection)
        }
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: StorageKey.selection),
           let selection = AppAppearance(rawValue: stored) {
            self.selection = selection
        } else {
            self.selection = .system
        }
    }

    var preferredColorScheme: ColorScheme? {
        selection.colorScheme
    }
}
