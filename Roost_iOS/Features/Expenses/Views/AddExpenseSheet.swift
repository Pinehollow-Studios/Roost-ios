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
    let currencySymbol: String
    let mode: Mode
    let hidesTabBar: Bool
    let onSubmit: (String, Decimal, UUID, String, String?, String?, Date, Bool) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?

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
    @State private var showDetails = false

    private enum Field {
        case title
        case amount
        case notes
    }

    init(
        myName: String,
        partnerName: String?,
        myUserId: UUID,
        partnerUserId: UUID?,
        suggestedCategories: [BudgetCategory],
        defaultSplitType: String = "equal",
        currencySymbol: String = "£",
        mode: Mode = .add,
        initialValue: ExpenseSheetSeed? = nil,
        hidesTabBar: Bool = false,
        onSubmit: @escaping (String, Decimal, UUID, String, String?, String?, Date, Bool) async -> Void
    ) {
        self.myName = myName
        self.partnerName = partnerName
        self.myUserId = myUserId
        self.partnerUserId = partnerUserId
        self.suggestedCategories = suggestedCategories
        self.defaultSplitType = defaultSplitType
        self.currencySymbol = currencySymbol
        self.mode = mode
        self.hidesTabBar = hidesTabBar
        self.onSubmit = onSubmit

        _title = State(initialValue: initialValue?.title ?? "")
        _amountText = State(initialValue: initialValue?.amountText ?? "")
        _paidByMe = State(initialValue: initialValue?.paidByUserId != partnerUserId)
        _splitType = State(initialValue: initialValue?.splitType ?? defaultSplitType)
        _category = State(initialValue: initialValue?.category ?? "")
        _notes = State(initialValue: initialValue?.notes ?? "")
        _date = State(initialValue: initialValue?.date ?? Date())
        _isRecurring = State(initialValue: initialValue?.isRecurring ?? false)
        _showDetails = State(initialValue: mode == .edit || initialValue?.isRecurring == true || !(initialValue?.notes ?? "").isEmpty)
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
            ? "Amount, name, category."
            : "Update the saved expense."
    }

    private var actionTitle: String {
        mode == .add ? "Add expense" : "Save changes"
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.roostBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 16)
                        .addExpenseEntrance(at: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    amountBlock
                        .padding(.top, 28)
                        .addExpenseEntrance(at: 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    categoryBlock
                        .padding(.top, 26)
                        .addExpenseEntrance(at: 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    detailsBlock
                        .padding(.top, 24)
                        .addExpenseEntrance(at: 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
                .padding(.bottom, DesignSystem.Spacing.screenBottom + 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.roostBackground.ignoresSafeArea())

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.roostPrimary.opacity(0.72), Color.roostPrimary.opacity(0.30)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .ignoresSafeArea(edges: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if hidesTabBar {
                NotificationCenter.default.post(name: .roostTabBarHiddenChanged, object: true)
            }
            guard !reduceMotion else {
                hasAnimatedIn = true
                return
            }
            withAnimation(.roostSmooth) {
                hasAnimatedIn = true
            }
            try? await Task.sleep(for: .milliseconds(260))
            if mode == .add {
                focusedField = .amount
            }
        }
        .onDisappear {
            if hidesTabBar {
                NotificationCenter.default.post(name: .roostTabBarHiddenChanged, object: false)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Money")
                        .font(.roostLabel)
                }
                .foregroundStyle(Color.roostPrimary)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(Color.roostPrimary.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button {
                submit()
            } label: {
                Text(isSaving ? "Saving" : actionTitle)
                    .font(.roostLabel)
                    .foregroundStyle(canSubmit ? Color.roostCard : Color.roostMutedForeground)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .background(canSubmit ? Color.roostPrimary : Color.roostMuted, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
        }
        .overlay(alignment: .center) {
            VStack(spacing: 1) {
                Text(headerTitle)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)
                Text(headerSubtitle)
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .allowsHitTesting(false)
        }
    }

    private var amountBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AMOUNT")
                    .font(.roostMeta)
                    .tracking(1.0)
                    .foregroundStyle(Color.roostPrimary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(currencySymbol)
                        .font(.custom("DMSans-Medium", size: 34, relativeTo: .largeTitle))
                        .foregroundStyle(Color.roostMutedForeground)

                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        .font(.custom("DMSans-Medium", size: 54, relativeTo: .largeTitle))
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
            }

            TextField("What was it for?", text: $title)
                .focused($focusedField, equals: .title)
                .font(.roostPageTitle)
                .foregroundStyle(Color.roostForeground)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit {
                    if canSubmit {
                        submit()
                    } else {
                        focusedField = nil
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 56)
                .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                        .stroke(focusedField == .title ? Color.roostPrimary.opacity(0.42) : Color.roostHairline, lineWidth: 1)
                )
        }
    }

    private var categoryBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text("Category")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)
                Spacer()
                Text("Lifestyle")
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            if suggestedCategories.isEmpty {
                Text("Add lifestyle budget lines to use categories here.")
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(suggestedCategories) { suggestion in
                        categoryButton(suggestion)
                    }
                }
            }
        }
    }

    private var detailsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                personChoice(title: myName, selected: paidByMe) {
                    paidByMe = true
                }

                if let partnerName {
                    personChoice(title: partnerName, selected: !paidByMe) {
                        paidByMe = false
                    }
                }
            }

            if hasPartner {
                HStack(spacing: 8) {
                    compactChoice(title: "Shared", selected: splitType == "equal") {
                        splitType = "equal"
                    }
                    compactChoice(title: "Solo", selected: splitType == "solo") {
                        splitType = "solo"
                    }
                }
            }

            DatePicker("Date", selection: $date, displayedComponents: .date)
                .font(.roostBody)
                .foregroundStyle(Color.roostForeground)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                        .stroke(Color.roostHairline, lineWidth: 1)
                )
                .tint(.roostPrimary)

            DisclosureGroup(isExpanded: $showDetails) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Recurring", isOn: $isRecurring)
                        .font(.roostBody)
                        .foregroundStyle(Color.roostForeground)
                        .tint(Color.roostPrimary)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .focused($focusedField, equals: .notes)
                        .font(.roostBody)
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(2...4)
                        .padding(14)
                        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                                .stroke(Color.roostHairline, lineWidth: 1)
                        )
                }
                .padding(.top, 10)
            } label: {
                Text("More details")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)
            }
            .tint(Color.roostPrimary)
            .padding(14)
            .background(Color.roostCard.opacity(0.78), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
        }
    }

    private func categoryButton(_ suggestion: BudgetCategory) -> some View {
        let selected = category == suggestion.name
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            category = selected ? "" : suggestion.name
            focusedField = nil
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(suggestion.colour)
                    .frame(width: 8, height: 8)
                Text(suggestion.name)
                    .font(.roostLabel)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(selected ? Color.roostCard : Color.roostForeground)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(selected ? Color.roostPrimary : Color.roostCard, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(selected ? Color.clear : Color.roostHairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func personChoice(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        compactChoice(title: "Paid by \(title)", selected: selected, action: action)
    }

    private func compactChoice(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.roostLabel)
                .foregroundStyle(selected ? Color.roostCard : Color.roostForeground)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(selected ? Color.roostPrimary : Color.roostCard, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(selected ? Color.clear : Color.roostHairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func submit() {
        guard canSubmit, let amount = parsedAmount else { return }
        focusedField = nil
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
