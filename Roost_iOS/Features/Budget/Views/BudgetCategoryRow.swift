import SwiftUI

struct BudgetCategoryRow: View {
    @Environment(SettingsViewModel.self) private var settingsViewModel

    let title: String
    let spent: Decimal
    let limit: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(title)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)

                Spacer()

                Text("\(formatted(spent)) / \(formatted(limit))")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.roostMuted.opacity(0.8))

                    Capsule()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 12)
        }
        .padding(.vertical, 12)
    }

    private var progress: Double {
        guard limit > 0 else { return spent > 0 ? 1 : 0 }
        return NSDecimalNumber(decimal: spent / limit).doubleValue
    }

    private var progressColor: Color {
        switch progress {
        case ..<0.6:
            return .roostSuccess
        case ..<0.8:
            return .roostWarning.opacity(0.55)
        case ..<1.0:
            return .roostWarning
        default:
            return .roostDestructive
        }
    }

    private func formatted(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsViewModel.userPreferences.currency
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
