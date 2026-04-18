import SwiftUI

// MARK: - MonthNavigator

/// Warm styled month navigator used across Overview, Spending, and Budgets.
struct MonthNavigator: View {
    let label: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let canGoNext: Bool
    let isPro: Bool
    let onProGate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if isPro {
                    onPrevious()
                } else {
                    onProGate()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isPro
                        ? Color.roostForeground
                        : Color.roostMutedForeground)
                    .frame(width: 32, height: 32)
                    .background(Color.roostInput)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.roostHairline, lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.roostForeground)
                .frame(minWidth: 120)

            Button {
                onNext()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(canGoNext
                        ? Color.roostForeground
                        : Color.roostMutedForeground.opacity(0.4))
                    .frame(width: 32, height: 32)
                    .background(Color.roostInput)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.roostHairline, lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canGoNext)
        }
    }
}

// MARK: - BudgetViewPicker

/// Warm pill-style Household / Split toggle used in MoneyBudgetsView.
struct BudgetViewPicker: View {
    @Binding var showSplit: Bool

    var body: some View {
        HStack(spacing: 3) {
            pickerButton(title: "Home", isSelected: !showSplit) {
                withAnimation(.easeInOut(duration: 0.18)) { showSplit = false }
            }

            pickerButton(title: "Split", isSelected: showSplit) {
                withAnimation(.easeInOut(duration: 0.18)) { showSplit = true }
            }
        }
        .padding(3)
        .background(Color.roostMuted.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private func pickerButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(isSelected ? Color.roostCard : Color.roostMutedForeground)
                .frame(width: 48, height: 28)
                .background(
                    isSelected ? Color.roostMoneyTint : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}
