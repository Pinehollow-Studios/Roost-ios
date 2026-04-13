import SwiftUI

struct ExpenseRow: View {
    @Environment(SettingsViewModel.self) private var settingsViewModel

    let expense: ExpenseWithSplits
    let payer: HomeMember?
    let paidByName: String
    let yourShareAmount: Decimal?
    var currencyCode: String? = nil
    var onActions: (() -> Void)? = nil

    var body: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.inline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(expense.title)
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                            .fixedSize(horizontal: false, vertical: true)

                        if let category = expense.category, !category.isEmpty {
                            Text(category)
                                .font(.roostMeta.weight(.medium))
                                .foregroundStyle(categoryAccent)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: DesignSystem.Spacing.inline)

                    VStack(alignment: .trailing, spacing: 8) {
                        if let onActions {
                            Button(action: onActions) {
                                HStack(spacing: 6) {
                                    Text("Edit")
                                        .font(.roostMeta.weight(.medium))
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(Color.roostMutedForeground)
                                .padding(.horizontal, 10)
                                .frame(height: 32)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.roostMuted.opacity(0.72))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color.roostHairline, lineWidth: 1)
                                )
                                .contentShape(Rectangle().inset(by: -6))
                            }
                            .buttonStyle(.plain)
                        }

                        Text(formattedAmount)
                            .font(.roostCardTitle)
                            .foregroundStyle(Color.roostForeground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }

                HStack(alignment: .center, spacing: DesignSystem.Spacing.inline) {
                    MemberAvatar(member: payer, fallbackLabel: paidByName, size: .sm)

                    Text("Paid by \(paidByName)")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)

                    Spacer(minLength: DesignSystem.Spacing.inline)

                    if let yourShareLabel {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Your share")
                                .font(.roostMeta)
                                .foregroundStyle(Color.roostMutedForeground)

                            Text(yourShareLabel)
                                .font(.roostLabel)
                                .foregroundStyle(yourShareTint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                    }
                }

                HStack(alignment: .center, spacing: 8) {
                    if let date = expense.incurredOnDate {
                        Text(humanDate(date))
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    if let recurringLabel {
                        FigmaChip(title: recurringLabel, variant: .secondary, systemImage: "arrow.triangle.2.circlepath")
                    }

                    Spacer(minLength: DesignSystem.Spacing.inline)

                    FigmaChip(title: splitTypeLabel, variant: splitTypeVariant)
                }
            }
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(categoryAccent)
                .frame(width: 3)
                .padding(.vertical, 12)
        }
    }

    private var categoryVariant: FigmaChip.Variant {
        let name = expense.category?.lowercased() ?? ""
        if name.contains("bill") { return .warning }
        if name.contains("grocer") || name.contains("food") { return .success }
        if name.contains("transport") || name.contains("travel") { return .secondary }
        if name.contains("subscription") { return .primary }
        return .default
    }

    private var categoryAccent: Color {
        let name = expense.category?.lowercased() ?? ""
        if name.contains("rent") || name.contains("bill") || name.contains("utilit") { return .roostPrimary }
        if name.contains("grocer") || name.contains("food") { return .roostSecondary }
        if name.contains("house") || name.contains("clean") { return .roostAccent }
        if name.contains("transport") || name.contains("travel") { return .roostWarning }
        if name.contains("subscription") { return .roostSuccess }
        return .roostMutedForeground
    }

    private var splitTypeLabel: String {
        switch expense.splitType?.lowercased() {
        case "solo":
            return "Personal"
        case "equal":
            return "Shared"
        default:
            return expense.splitType?.capitalized ?? "Shared"
        }
    }

    private var splitTypeVariant: FigmaChip.Variant {
        switch splitTypeLabel {
        case "Shared":
            return .success
        case "Personal":
            return .default
        default:
            return .secondary
        }
    }

    private var formattedAmount: String {
        currencyFormatter.string(from: expense.amount as NSDecimalNumber) ?? "\(expense.amount)"
    }

    private var yourShareLabel: String? {
        guard let yourShareAmount else { return nil }
        return currencyFormatter.string(from: yourShareAmount as NSDecimalNumber) ?? "\(yourShareAmount)"
    }

    private var recurringLabel: String? {
        guard expense.isRecurring == true else { return nil }
        return "Recurring"
    }

    private var yourShareTint: Color {
        splitTypeLabel == "Shared" ? .roostPrimary : .roostSecondary
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? settingsViewModel.userPreferences.currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private func humanDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}
