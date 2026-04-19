import SwiftUI

struct SettleUpSheet: View {
    let balance: Decimal
    let currencyCode: String
    let myName: String
    let partnerName: String
    let partnerPaypalUsername: String?
    let partnerMonzoUsername: String?
    let onConfirm: (String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum SheetState {
        case methodSelection
        case markAsPaid
        case awaitingConfirmation(method: String)
        case success
    }

    @State private var sheetState: SheetState = .methodSelection
    @State private var note = ""
    @State private var isSettling = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.md) {
                    summaryHeader

                    switch sheetState {
                    case .methodSelection:
                        methodSelectionCards
                    case .markAsPaid:
                        markAsPaidCard
                    case .awaitingConfirmation(let method):
                        awaitingConfirmationCard(method: method)
                    case .success:
                        successCard
                    }

                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, 100)
            }
            .background(Color.roostBackground.ignoresSafeArea())
            .navigationTitle("Settle up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isDone ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(Color.roostForeground)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomAction
            }
        }
    }

    // MARK: - Summary header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
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
                .font(.roostHero)
                .foregroundStyle(Color.roostPrimary)
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

    // MARK: - Method selection

    private var methodSelectionCards: some View {
        VStack(spacing: Spacing.sm) {
            Text("How will you pay?")
                .font(.roostLabel)
                .foregroundStyle(Color.roostMutedForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.xs)

            if let monzoUsername = partnerMonzoUsername, !monzoUsername.isEmpty {
                paymentMethodCard(
                    logo: AnyView(
                        Image("MonzoLogo")
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    ),
                    brandColor: Color(hex: 0xFF3C00),
                    title: "Pay via Monzo",
                    subtitle: "@\(monzoUsername) · \(formattedAmount)"
                ) {
                    openMonzoLink(username: monzoUsername)
                }
            }

            if let paypalUsername = partnerPaypalUsername, !paypalUsername.isEmpty {
                paymentMethodCard(
                    logo: AnyView(
                        Image("PayPalLogo")
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    ),
                    brandColor: Color(hex: 0x003087),
                    title: "Pay via PayPal",
                    subtitle: "paypal.me/\(paypalUsername) · \(formattedAmount)"
                ) {
                    openPayPalLink(username: paypalUsername)
                }
            }

            paymentMethodCard(
                logo: AnyView(
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.roostSuccess)
                ),
                brandColor: Color.roostSuccess,
                title: "Mark as paid",
                subtitle: "Log the settlement without a payment app"
            ) {
                withAnimation(.roostSmooth) { sheetState = .markAsPaid }
            }
        }
    }

    private func paymentMethodCard(
        logo: AnyView,
        brandColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                        .fill(brandColor.opacity(0.10))
                        .frame(width: 44, height: 44)
                    logo.frame(width: 28, height: 28)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(Color.roostForeground)
                    Text(subtitle)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .padding(Spacing.md)
            .background(Color.roostCard)
            .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                    .stroke(Color.roostBorderLight, lineWidth: 1)
            )
        }
        .buttonStyle(
            RoostPressableButtonStyle(
                reduceMotion: reduceMotion,
                backgroundColor: .clear,
                foregroundColor: .roostForeground,
                borderColor: .clear,
                borderWidth: 0,
                cornerRadius: RoostTheme.cornerRadius,
                showHighlight: false
            )
        )
    }

    // MARK: - Mark as paid (note flow)

    private var markAsPaidCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                withAnimation(.roostSmooth) { sheetState = .methodSelection }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                    Text("Payment methods")
                        .font(.roostCaption)
                }
                .foregroundStyle(Color.roostMutedForeground)
            }
            .buttonStyle(.plain)

            Text("Add a note (optional)")
                .font(.roostLabel)
                .foregroundStyle(Color.roostForeground)
            RoostTextField(title: "e.g. Bank transfer, cash", text: $note)
        }
        .padding(Spacing.lg)
        .background(Color.roostCard)
        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(Color.roostBorderLight, lineWidth: 1)
        )
    }

    // MARK: - Awaiting confirmation

    private func awaitingConfirmationCard(method: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(Color.roostMoneyTint)

            VStack(spacing: 6) {
                Text("Did you complete the payment?")
                    .font(.roostSection)
                    .foregroundStyle(Color.roostForeground)
                    .multilineTextAlignment(.center)
                Text("Once confirmed, the balance will be cleared in Roost.")
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
                    .multilineTextAlignment(.center)
            }
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

    // MARK: - Success

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

    // MARK: - Bottom action bar

    @ViewBuilder
    private var bottomAction: some View {
        let gradient = LinearGradient(
            colors: [Color.roostBackground.opacity(0), Color.roostBackground.opacity(0.94), Color.roostBackground],
            startPoint: .top,
            endPoint: .bottom
        )

        switch sheetState {
        case .methodSelection, .success:
            EmptyView()

        case .markAsPaid:
            confirmButton(label: isSettling ? "Settling…" : "Confirm settlement") {
                Task {
                    isSettling = true
                    await onConfirm(note.isEmpty ? nil : note)
                    isSettling = false
                    withAnimation(.roostSmooth) { sheetState = .success }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
            .background(gradient)

        case .awaitingConfirmation(let method):
            VStack(spacing: Spacing.sm) {
                confirmButton(label: isSettling ? "Settling…" : "Yes, mark as settled") {
                    Task {
                        isSettling = true
                        await onConfirm(method)
                        isSettling = false
                        withAnimation(.roostSmooth) { sheetState = .success }
                    }
                }
                Button("Not yet — go back") {
                    withAnimation(.roostSmooth) { sheetState = .methodSelection }
                }
                .font(.roostLabel)
                .foregroundStyle(Color.roostMutedForeground)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
            .background(gradient)
        }
    }

    private func confirmButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
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
    }

    // MARK: - Deep link helpers

    private func openMonzoLink(username: String) {
        let amount = abs(balance)
        guard let url = URL(string: "https://monzo.me/\(username)/\(amount)") else { return }
        UIApplication.shared.open(url)
        withAnimation(.roostSmooth) { sheetState = .awaitingConfirmation(method: "Monzo") }
    }

    private func openPayPalLink(username: String) {
        let amount = abs(balance)
        guard let url = URL(string: "https://www.paypal.me/\(username)/\(amount)") else { return }
        UIApplication.shared.open(url)
        withAnimation(.roostSmooth) { sheetState = .awaitingConfirmation(method: "PayPal") }
    }

    // MARK: - Computed helpers

    private var isDone: Bool {
        if case .success = sheetState { return true }
        return false
    }

    private var summaryText: String {
        balance > 0 ? "\(partnerName) pays \(myName)" : "\(myName) pays \(partnerName)"
    }

    private var formattedAmount: String {
        let absBalance = abs(balance)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: absBalance as NSDecimalNumber) ?? "\(absBalance)"
    }
}
