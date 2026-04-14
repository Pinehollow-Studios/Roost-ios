import SwiftUI

struct BalanceCardView: View {
    let balance: Decimal
    let currencyCode: String
    let partnerName: String
    let onSettleUp: () -> Void

    var body: some View {
        RoostHeroCard(tint: balanceTint) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    RoostIconBadge(systemImage: balanceIcon, tint: balanceTint, size: 34)
                    Text("Balance")
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                    Spacer()
                    RoostInlineBadge(title: balanceIconLabel, tint: balanceTint)
                }

                if balance == 0 {
                    Text("All settled up")
                        .font(.roostTitle)
                        .foregroundStyle(Color.roostForeground)
                } else {
                    Text(formattedAmount)
                        .font(.roostFinancialHero)
                        .foregroundStyle(Color.roostForeground)
                    Text(balanceText)
                        .font(.roostSection)
                        .foregroundStyle(balanceTint)
                }

                if balance != 0 {
                    HStack(spacing: Spacing.sm) {
                        RoostStatCard(
                            title: "Status",
                            value: balance > 0 ? "You’re owed" : "You owe",
                            tint: balanceTint
                        )
                        .frame(maxWidth: .infinity)

                        RoostButton(title: "Settle up", variant: .secondary, systemImage: "arrow.left.arrow.right", action: onSettleUp)
                            .frame(maxWidth: 150)
                    }
                }
            }
        }
    }

    private var balanceText: String {
        if balance > 0 {
            return "\(partnerName) owes you"
        } else if balance < 0 {
            return "You owe \(partnerName)"
        } else {
            return "All settled up"
        }
    }

    private var balanceTint: Color {
        if balance > 0 { return .roostSuccess }
        if balance < 0 { return .roostWarning }
        return .roostSecondary
    }

    private var balanceIcon: String {
        if balance > 0 { return "arrow.down.left.circle.fill" }
        if balance < 0 { return "arrow.up.right.circle.fill" }
        return "checkmark.circle.fill"
    }

    private var formattedAmount: String {
        let absBalance = abs(balance)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: absBalance as NSDecimalNumber) ?? "\(absBalance)"
    }
    private var balanceIconLabel: String {
        if balance > 0 { return "You’re ahead" }
        if balance < 0 { return "You owe" }
        return "Settled"
    }
}
