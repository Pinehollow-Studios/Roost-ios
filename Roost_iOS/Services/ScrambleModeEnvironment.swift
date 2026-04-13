import Foundation
import Observation
import SwiftUI

/// Injected at the app root and accessed by every Money view.
/// When scrambleMode is on, format() returns "•••" instead of amounts.
@MainActor
@Observable
final class ScrambleModeEnvironment {

    var isScrambled: Bool = false

    /// Format a Decimal as a currency string, or "•••" when scrambled.
    /// Returns "—" when amount is nil regardless of scramble state.
    func format(_ amount: Decimal?, symbol: String = "£") -> String {
        guard let amount else { return "—" }
        if isScrambled { return "•••" }
        return symbol + formatted(amount)
    }

    /// Sync scramble state from the current MoneySettings.
    func sync(from settings: MoneySettings) {
        isScrambled = settings.scrambleMode
    }

    // MARK: - Private

    private func formatted(_ amount: Decimal) -> String {
        let nsAmount = amount as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: nsAmount) ?? nsAmount.stringValue
    }
}
