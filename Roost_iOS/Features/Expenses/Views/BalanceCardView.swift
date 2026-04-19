import SwiftUI

struct BalanceCardView: View {
    let balance: Decimal
    let currencyCode: String
    let partnerName: String
    let hasSharedAccount: Bool
    let onSettleUp: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                        .font(.roostHero)
                        .foregroundStyle(Color.roostForeground)
                    Text(balanceText)
                        .font(.roostSection)
                        .foregroundStyle(balanceTint)
                }

                if balance != 0 && !hasSharedAccount {
                    HStack(spacing: Spacing.sm) {
                        RoostStatCard(
                            title: "Status",
                            value: balance > 0 ? "You’re owed" : "You owe",
                            tint: balanceTint
                        )
                        .frame(maxWidth: .infinity)

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onSettleUp()
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.roostLabel)
                                Text("Settle up")
                                    .font(.roostLabel)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: DesignSystem.Size.buttonHeight)
                            .padding(.horizontal, DesignSystem.Spacing.card)
                        }
                        .buttonStyle(
                            RoostPressableButtonStyle(
                                reduceMotion: reduceMotion,
                                backgroundColor: balanceTint,
                                foregroundColor: .roostWarmWhite,
                                borderColor: .clear,
                                borderWidth: 0,
                                cornerRadius: RoostTheme.controlCornerRadius,
                                showHighlight: true
                            )
                        )
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
