import SwiftUI

struct AddExpenseSheet: View {
    enum Mode {
        case add
        case edit
    }

    let myName: String
    let partnerName: String?
    let myUserId: UUID
    let partnerUserId: UUID?
    let suggestedCategories: [BudgetCategory]
    let defaultSplitType: String
    let mode: Mode
    let onSubmit: (String, Decimal, UUID, String, String?, String?, Date, Bool) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var title = ""
    @State private var amountText = ""
    @State private var paidByMe = true
    @State private var splitType = "equal"
    @State private var category = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var isRecurring = false
    @State private var isSaving = false
    @State private var hasAnimatedIn = false

    init(
        myName: String,
        partnerName: String?,
        myUserId: UUID,
        partnerUserId: UUID?,
        suggestedCategories: [BudgetCategory],
        defaultSplitType: String = "equal",
        mode: Mode = .add,
        initialValue: ExpenseSheetSeed? = nil,
        onSubmit: @escaping (String, Decimal, UUID, String, String?, String?, Date, Bool) async -> Void
    ) {
        self.myName = myName
        self.partnerName = partnerName
        self.myUserId = myUserId
        self.partnerUserId = partnerUserId
        self.suggestedCategories = suggestedCategories
        self.defaultSplitType = defaultSplitType
        self.mode = mode
        self.onSubmit = onSubmit

        _title = State(initialValue: initialValue?.title ?? "")
        _amountText = State(initialValue: initialValue?.amountText ?? "")
        _paidByMe = State(initialValue: initialValue?.paidByUserId != partnerUserId)
        _splitType = State(initialValue: initialValue?.splitType ?? defaultSplitType)
        _category = State(initialValue: initialValue?.category ?? "")
        _notes = State(initialValue: initialValue?.notes ?? "")
        _date = State(initialValue: initialValue?.date ?? Date())
        _isRecurring = State(initialValue: initialValue?.isRecurring ?? false)
    }

    private var hasPartner: Bool { partnerUserId != nil }
    private var parsedAmount: Decimal? { Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) }
    private var canSubmit: Bool {
        !trimmedTitle.isEmpty &&
        (parsedAmount ?? 0) > 0 &&
        !isSaving
    }

    private var headerTitle: String {
        mode == .add ? "Add Expense" : "Edit Expense"
    }

    private var headerSubtitle: String {
        mode == .add
            ? "Log the spend clearly while it is still fresh."
            : "Adjust the details and keep the shared record accurate."
    }

    private var actionTitle: String {
        mode == .add ? "Add expense" : "Save changes"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    RoostSheetHeader(
                        title: headerTitle,
                        subtitle: headerSubtitle
                    ) {
                        dismiss()
                    }

                    RoostAddSection(
                        title: "Expense",
                        helper: "Capture the title and amount exactly as you want them to appear."
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            RoostTextField(title: "e.g. Weekly groceries", text: $title)

                            RoostTextField(title: "0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                        }
                    }
                    .addExpenseEntrance(at: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(title: "Paid by") {
                        HStack(spacing: Spacing.sm) {
                            RoostAddChoiceChip(title: myName, isSelected: paidByMe) {
                                paidByMe = true
                            }

                            if let partnerName {
                                RoostAddChoiceChip(title: partnerName, isSelected: !paidByMe) {
                                    paidByMe = false
                                }
                            }
                        }
                    }
                    .addExpenseEntrance(at: 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    if hasPartner {
                        RoostAddSection(title: "Split") {
                            HStack(spacing: Spacing.sm) {
                                RoostAddChoiceChip(title: "Shared equally", isSelected: splitType == "equal") {
                                    splitType = "equal"
                                }
                                RoostAddChoiceChip(title: "Keep it solo", isSelected: splitType == "solo") {
                                    splitType = "solo"
                                }
                            }
                        }
                        .addExpenseEntrance(at: 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)
                    }

                    RoostAddSection(
                        title: "Category",
                        helper: suggestedCategories.isEmpty
                            ? "Set up your budget to see category suggestions."
                            : "Suggested from your budget lines."
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            RoostTextField(title: "Optional category", text: $category)

                            if !suggestedCategories.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Spacing.sm) {
                                        ForEach(suggestedCategories) { suggestion in
                                            RoostAddCapsuleChip(title: suggestion.name, isSelected: category == suggestion.name) {
                                                category = suggestion.name
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .addExpenseEntrance(at: 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(title: "Date") {
                        DatePicker("Incurred on", selection: $date, displayedComponents: .date)
                            .font(.roostBody)
                            .foregroundStyle(Color.roostForeground)
                            .padding(.horizontal, Spacing.md)
                            .frame(height: DesignSystem.Size.inputHeight)
                            .background(Color.roostInput, in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                    .stroke(Color.roostHairline, lineWidth: 1)
                            )
                            .tint(.roostPrimary)
                    }
                    .addExpenseEntrance(at: 4, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(
                        title: "Recurring",
                        helper: "Mark this as a regular expense so it shows up in your monthly recurring total."
                    ) {
                        HStack(spacing: Spacing.sm) {
                            RoostAddChoiceChip(title: "One-off", isSelected: !isRecurring) {
                                isRecurring = false
                            }
                            RoostAddChoiceChip(title: "Recurring", isSelected: isRecurring) {
                                isRecurring = true
                            }
                        }
                    }
                    .addExpenseEntrance(at: 5, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(title: "Notes", helper: "Optional context if you need it later.") {
                        RoostTextField(title: "Anything worth remembering", text: $notes)
                    }
                    .addExpenseEntrance(at: 6, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddPreviewCard {
                        HStack(alignment: .top, spacing: Spacing.md) {
                            RoostListControl(
                                state: .status,
                                tint: .roostPrimary,
                                symbol: "sterlingsign",
                                size: 40
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(trimmedTitle.isEmpty ? "Your expense title" : trimmedTitle)
                                    .font(.roostLabel)
                                    .foregroundStyle(Color.roostForeground)
                                Text("Paid by \(paidByMe ? myName : (partnerName ?? "Partner"))")
                                    .font(.roostMeta)
                                    .foregroundStyle(Color.roostMutedForeground)
                                if let categoryValue {
                                    Text(categoryValue)
                                        .font(.roostMeta)
                                        .foregroundStyle(Color.roostPrimary)
                                }
                                if isRecurring {
                                    Text("Recurring")
                                        .font(.roostMeta.weight(.medium))
                                        .foregroundStyle(Color.roostSecondary)
                                }
                            }

                            Spacer()

                            Text((parsedAmount ?? 0).formatted(.number.precision(.fractionLength(2))))
                                .font(.roostLabel)
                                .foregroundStyle(Color.roostForeground)
                        }
                        .padding(Spacing.md)
                        .background(Color.roostBackground.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                    }
                    .addExpenseEntrance(at: 7, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, 120)
            }
            .roostDisableVerticalBounce()
            .roostAddDismissOnPullDown {
                dismiss()
            }
            .background(Color.roostBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                RoostAddBottomBar(
                    actionTitle: actionTitle,
                    isSaving: isSaving,
                    isDisabled: !canSubmit
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Money")
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostMutedForeground)
                        Text(trimmedTitle.isEmpty ? "Waiting for an expense" : trimmedTitle)
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostForeground)
                            .lineLimit(1)
                    }
                } action: {
                    guard let amount = parsedAmount else { return }

                    Task {
                        isSaving = true
                        let paidBy = paidByMe ? myUserId : (partnerUserId ?? myUserId)
                        let effectiveSplitType = hasPartner ? splitType : "solo"
                        await onSubmit(
                            trimmedTitle,
                            amount,
                            paidBy,
                            effectiveSplitType,
                            categoryValue,
                            notesValue,
                            date,
                            isRecurring
                        )
                        isSaving = false
                        dismiss()
                    }
                }
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

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var categoryValue: String? {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var notesValue: String? {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct ExpenseSheetSeed {
    let title: String
    let amountText: String
    let paidByUserId: UUID
    let splitType: String
    let category: String
    let notes: String
    let date: Date
    var isRecurring: Bool = false
}

private struct AddExpenseEntranceModifier: ViewModifier {
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

private extension View {
    func addExpenseEntrance(at index: Int, hasAnimatedIn: Bool, reduceMotion: Bool) -> some View {
        modifier(AddExpenseEntranceModifier(index: index, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
    }
}

#Preview("Add Expense") {
    NavigationStack {
        AddExpenseSheet(
            myName: "Tom",
            partnerName: "Alex",
            myUserId: UUID(),
            partnerUserId: UUID(),
            suggestedCategories: [
                BudgetCategory(id: UUID(), name: "Groceries", colour: .red),
                BudgetCategory(id: UUID(), name: "Bills", colour: .blue),
                BudgetCategory(id: UUID(), name: "Dining", colour: .orange)
            ]
        ) { _, _, _, _, _, _, _, _ in }
    }
}
