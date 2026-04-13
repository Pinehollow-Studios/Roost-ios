import Foundation
import Observation

enum BudgetCarryMode: String, CaseIterable, Identifiable {
    case automatic
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "Carry forward"
        case .manual: return "Manual"
        }
    }

    var subtitle: String {
        switch self {
        case .automatic:
            return "New months inherit the last budget setup automatically."
        case .manual:
            return "Each month starts blank until you set limits yourself."
        }
    }

    var symbolName: String {
        switch self {
        case .automatic: return "arrow.trianglehead.clockwise"
        case .manual: return "slider.horizontal.3"
        }
    }
}

@MainActor
@Observable
final class BudgetCarrySettings {
    private enum StorageKey {
        static let mode = "roost.budget.carry-mode"
    }

    var mode: BudgetCarryMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: StorageKey.mode)
        }
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: StorageKey.mode),
           let mode = BudgetCarryMode(rawValue: stored) {
            self.mode = mode
        } else {
            self.mode = .automatic
        }
    }

    var automaticallyCarriesForward: Bool {
        mode == .automatic
    }
}
