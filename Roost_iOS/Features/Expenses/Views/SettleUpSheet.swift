import SwiftUI

struct SettleUpSheet: View {
    let balance: Decimal
    let currencyCode: String
    let myName: String
    let partnerName: String
    let onConfirm: (String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @State private var isSettling = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                if showSuccess {
                    successCard
                } else {
                    summaryCard
                    noteCard
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .background(Color.roostBackground.ignoresSafeArea())
            .navigationTitle("Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(showSuccess ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(Color.roostForeground)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !showSuccess {
                    Button {
                        Task {
                            isSettling = true
                            await onConfirm(note.isEmpty ? nil : note)
                            isSettling = false
                            withAnimation(.roostSmooth) {
                                showSuccess = true
                            }
                        }
                    } label: {
                        HStack {
                            Text(isSettling ? "Settling…" : "Confirm settlement")
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostCard)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 18)
                        .background(Color.roostPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSettling)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.roostBackground.opacity(0),
                                Color.roostBackground.opacity(0.94),
                                Color.roostBackground
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settle the balance")
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(summaryText)
                        .font(.roostHeading)
                        .foregroundStyle(Color.roostForeground)
                }

                Spacer()

                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostPrimary)
            }

            Text(formattedAmount)
                .font(.roostFinancialHero)
                .foregroundStyle(Color.roostPrimary)

            Text("This records the payment and clears the current shared balance.")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.roostCard)
        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(Color.roostBorderLight, lineWidth: 1)
        )
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Note")
                .font(.roostLabel)
                .foregroundStyle(Color.roostForeground)
            RoostTextField(title: "e.g. Bank transfer", text: $note)
        }
        .padding(Spacing.lg)
        .background(Color.roostCard)
        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(Color.roostBorderLight, lineWidth: 1)
        )
    }

    private var successCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.roostHero)
                .foregroundStyle(Color.roostSuccess)

            Text("All settled")
                .font(.roostSection)
                .foregroundStyle(Color.roostForeground)

            Text("The shared balance has been cleared.")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color.roostCard)
        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(Color.roostBorderLight, lineWidth: 1)
        )
    }

    private var summaryText: String {
        if balance > 0 {
            return "\(partnerName) pays \(myName)"
        } else {
            return "\(myName) pays \(partnerName)"
        }
    }

    private var formattedAmount: String {
        let absBalance = abs(balance)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: absBalance as NSDecimalNumber) ?? "\(absBalance)"
    }
}
