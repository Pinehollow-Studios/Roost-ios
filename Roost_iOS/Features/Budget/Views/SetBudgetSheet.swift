import SwiftUI

struct SetBudgetSheet: View {
    let initialCategory: String
    let initialAmount: Decimal?
    let onSave: (String, Decimal) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var category: String
    @State private var amountText: String
    @State private var isSaving = false
    @State private var hasAnimatedIn = false

    init(initialCategory: String = "", initialAmount: Decimal? = nil, onSave: @escaping (String, Decimal) async -> Void) {
        self.initialCategory = initialCategory
        self.initialAmount = initialAmount
        self.onSave = onSave
        _category = State(initialValue: initialCategory)
        _amountText = State(initialValue: initialAmount.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    formCard
                        .modifier(SetBudgetEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, 110)
            }
            .background(Color.roostBackground.ignoresSafeArea())
            .navigationTitle(initialCategory.isEmpty ? "Set Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.roostForeground)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task {
                        guard let amount = Decimal(string: amountText), amount > 0 else { return }
                        isSaving = true
                        await onSave(category, amount)
                        isSaving = false
                        dismiss()
                    }
                } label: {
                    HStack {
                        Text(isSaving ? "Saving budget…" : "Save budget")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostCard)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 18)
                    .background(canSubmit ? Color.roostPrimary : Color.roostMutedForeground)
                    .clipShape(RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
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
            .task {
                guard !reduceMotion else {
                    hasAnimatedIn = true
                    return
                }
                withAnimation(.roostSmooth) {
                    hasAnimatedIn = true
                }
            }
        }
    }

    private var canSubmit: Bool {
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Decimal(string: amountText) != nil &&
        !isSaving
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(initialCategory.isEmpty ? "Set a limit" : "Adjust the cap")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text("Give each category a clear monthly target.")
                        .font(.roostSection)
                        .foregroundStyle(Color.roostForeground)
                }

                Spacer()

                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostCard)
                    .frame(width: 46, height: 46)
                    .background(Color.roostPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
            }
        }
        .padding(Spacing.lg)
        .background(Color.roostCard)
        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(Color.roostBorderLight, lineWidth: 1)
        )
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Category")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)
                RoostTextField(title: "e.g. Groceries", text: $category)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Budget amount")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)
                RoostTextField(title: "0.00", text: $amountText)
                    .keyboardType(.decimalPad)
            }
        }
        .padding(Spacing.lg)
        .background(Color.roostCard)
        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(Color.roostBorderLight, lineWidth: 1)
        )
    }
}

private struct SetBudgetEntranceModifier: ViewModifier {
    let index: Int
    let hasAnimatedIn: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hasAnimatedIn ? 1 : 0)
            .offset(y: hasAnimatedIn || reduceMotion ? 0 : 18)
            .animation(
                reduceMotion ? nil : .roostSmooth.delay(Double(index) * 0.05),
                value: hasAnimatedIn
            )
    }
}

#Preview("Set Budget") {
    NavigationStack {
        SetBudgetSheet(initialCategory: "Groceries", initialAmount: 300) { _, _ in }
    }
}
