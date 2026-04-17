import SwiftUI
import UIKit

struct ExpensesView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(NotificationRouter.self) private var notificationRouter
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(ExpensesViewModel.self) private var sharedViewModel
    @Environment(BudgetViewModel.self) private var budgetViewModel
    @Environment(HazelViewModel.self) private var hazelViewModel
    @Environment(BudgetTemplateViewModel.self) private var budgetTemplateViewModel
    @Environment(MoneySettingsViewModel.self) private var moneySettingsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingAddSheet = false
    @State private var showingSettleSheet = false
    @State private var editingExpense: ExpenseWithSplits?
    @State private var actionExpense: ExpenseWithSplits?
    @State private var deleteCandidate: ExpenseWithSplits?
    @State private var showingCategoryFilterSheet = false
    @State private var showingPayerFilterSheet = false
    @State private var hasAnimatedIn = false
    @State private var isHazelProcessing = false
    @State private var selectedCategoryFilter = "All categories"
    @State private var selectedPayerFilter = "All payers"
    @State private var showingProUpsell = false
    private let embeddedInParentScroll: Bool
    private let previewViewModel: ExpensesViewModel?

    @MainActor
    init(viewModel: ExpensesViewModel? = nil, embeddedInParentScroll: Bool = false) {
        previewViewModel = viewModel
        self.embeddedInParentScroll = embeddedInParentScroll
    }

    private var viewModel: ExpensesViewModel { previewViewModel ?? sharedViewModel }
    private var myUserId: UUID? { homeManager.currentUserId }
    private var partnerUserId: UUID? { homeManager.partner?.userID }
    private var myName: String { homeManager.currentMember?.displayName ?? "You" }
    private var partnerName: String { homeManager.partner?.displayName ?? "Partner" }
    private var currencyCode: String { settingsViewModel.userPreferences.currency }
    private var isFreeTier: Bool { !(homeManager.home?.hasProAccess ?? false) }
    private var currentBalance: Decimal {
        guard let myUserId, let partnerUserId else { return 0 }
        return BalanceCalculator.calculate(
            expenses: filteredExpenses,
            myUserId: myUserId,
            partnerUserId: partnerUserId
        )
    }

    var body: some View {
        Group {
            if embeddedInParentScroll {
                content
            } else {
                ScrollView(showsIndicators: false) {
                    content
                        .padding(.bottom, 120)
                }
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .nestUpsell(isPresented: $showingProUpsell, feature: .advancedBudgeting)
        .sheet(isPresented: $showingAddSheet) {
            if let myId = myUserId {
                AddExpenseSheet(
                    myName: myName,
                    partnerName: partnerUserId != nil ? partnerName : nil,
                    myUserId: myId,
                    partnerUserId: partnerUserId,
                    suggestedCategories: budgetTemplateViewModel.categories,
                    defaultSplitType: defaultSplitType
                ) { title, amount, paidBy, splitType, category, notes, date, recurring in
                    guard let homeId = homeManager.homeId else { return }
                    isHazelProcessing = true
                    await viewModel.addExpense(
                        title: title,
                        amount: amount,
                        paidByUserId: paidBy,
                        splitType: splitType,
                        category: category,
                        notes: notes,
                        incurredOn: date,
                        homeId: homeId,
                        myUserId: myId,
                        partnerUserId: partnerUserId ?? myId,
                        isRecurring: recurring,
                        hazelEnabled: hazelViewModel.expensesEnabled,
                        isPro: homeManager.home?.hasProAccess ?? false,
                        budgetCategoryNames: budgetTemplateViewModel.categories.map(\.name)
                    )
                    isHazelProcessing = false
                }
            }
        }
        .sheet(item: $editingExpense, onDismiss: {
            viewModel.errorMessage = nil
        }) { expense in
            if let myId = myUserId, let homeId = homeManager.homeId {
                AddExpenseSheet(
                    myName: myName,
                    partnerName: partnerUserId != nil ? partnerName : nil,
                    myUserId: myId,
                    partnerUserId: partnerUserId,
                    suggestedCategories: budgetTemplateViewModel.categories,
                    mode: .edit,
                    initialValue: expenseSheetSeed(for: expense)
                ) { title, amount, paidBy, splitType, category, notes, date, recurring in
                    await viewModel.updateExpense(
                        expense,
                        title: title,
                        amount: amount,
                        paidByUserId: paidBy,
                        splitType: splitType,
                        category: category,
                        notes: notes,
                        incurredOn: date,
                        homeId: homeId,
                        myUserId: myId,
                        partnerUserId: partnerUserId ?? myId,
                        isRecurring: recurring
                    )
                }
            }
        }
        .sheet(isPresented: $showingSettleSheet) {
            if let myId = myUserId, let partnerId = partnerUserId {
                let balance = viewModel.balance(myUserId: myId, partnerUserId: partnerId)
                SettleUpSheet(
                    balance: balance,
                    currencyCode: currencyCode,
                    myName: myName,
                    partnerName: partnerName
                ) { note in
                    guard let homeId = homeManager.homeId else { return }
                    let fromId = balance < 0 ? myId : partnerId
                    let toId = balance < 0 ? partnerId : myId
                    await viewModel.settleUp(
                        homeId: homeId,
                        fromUserId: fromId,
                        toUserId: toId,
                        amount: abs(balance),
                        note: note,
                        myUserId: myId
                    )
                }
            }
        }
        .sheet(item: $deleteCandidate) { expense in
            ExpenseDeleteConfirmationSheet(expenseTitle: expense.title) {
                deleteCandidate = nil
            } onConfirm: {
                guard let homeId = homeManager.homeId, let userId = myUserId else { return }
                triggerWarningHaptic()
                Task {
                    await viewModel.deleteExpense(expense, homeId: homeId, userId: userId)
                    deleteCandidate = nil
                }
            }
        }
        .sheet(item: $actionExpense) { expense in
            ExpenseActionsSheet(expenseTitle: expense.title) {
                actionExpense = nil
            } onEdit: {
                triggerLightImpact()
                viewModel.errorMessage = nil
                actionExpense = nil
                editingExpense = expense
            } onDelete: {
                triggerWarningHaptic()
                actionExpense = nil
                deleteCandidate = expense
            }
        }
        .sheet(isPresented: $showingCategoryFilterSheet) {
            ExpenseFilterSheet(
                title: "Category",
                options: ["All categories"] + filterCategories,
                selected: selectedCategoryFilter
            ) { value in
                selectedCategoryFilter = value
                showingCategoryFilterSheet = false
            }
        }
        .sheet(isPresented: $showingPayerFilterSheet) {
            ExpenseFilterSheet(
                title: "Payer",
                options: ["All payers"] + filterPayers,
                selected: selectedPayerFilter
            ) { value in
                selectedPayerFilter = value
                showingPayerFilterSheet = false
            }
        }
        .conditionalRefreshable(
            !showingAddSheet &&
            editingExpense == nil &&
            deleteCandidate == nil &&
            !showingSettleSheet &&
            !showingCategoryFilterSheet &&
            !showingPayerFilterSheet
        ) {
            guard let homeId = await homeManager.homeId else { return }
            await viewModel.loadExpenses(homeId: homeId)
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
        .overlay(alignment: .bottom) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostCard)
                    .padding(Spacing.md)
                    .background(Color.roostDestructive, in: Capsule())
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, DesignSystem.Size.toastBottomOffset)
                    .onTapGesture { viewModel.errorMessage = nil }
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
            if !embeddedInParentScroll {
                FigmaPageHeader(title: "Expenses", accent: .roostMoneyTint) {
                    RoostAddPageButton {
                        showingAddSheet = true
                    }
                }
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .modifier(ExpensesEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
            }

            statsGrid
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(ExpensesEntranceModifier(index: embeddedInParentScroll ? 0 : 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            filtersRow
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(ExpensesEntranceModifier(index: embeddedInParentScroll ? 1 : 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            if isHazelProcessing {
                hazelBanner
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .modifier(ExpensesEntranceModifier(index: embeddedInParentScroll ? 2 : 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
            }

            if viewModel.isLoading && viewModel.expenses.isEmpty {
                loadingState
            } else if viewModel.expenses.isEmpty {
                emptyStateCard
            } else if filteredExpenses.isEmpty {
                filteredEmptyStateCard
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(filteredExpenses.enumerated()), id: \.element.id) { index, expense in
                        ExpenseRow(
                            expense: expense,
                            payer: member(for: expense.paidBy),
                            paidByName: memberName(for: expense.paidBy),
                            yourShareAmount: yourShareAmount(for: expense),
                            currencyCode: currencyCode,
                            onActions: {
                                triggerLightImpact()
                                viewModel.errorMessage = nil
                                actionExpense = expense
                            }
                        )
                        .modifier(ExpensesEntranceModifier(index: index + 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.page)

                if isFreeTier {
                    freeTierCard
                        .padding(.horizontal, DesignSystem.Spacing.page)
                        .modifier(ExpensesEntranceModifier(index: viewModel.expenses.count + 4, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                }
            }
        }
        .padding(.top, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenTop)
        .padding(.bottom, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenBottom)
    }

    private var statsGrid: some View {
        VStack(spacing: 8) {
            balanceStatCard
            HStack(spacing: 8) {
                statCard(
                    title: "Total Spent",
                    value: formatCurrency(totalSpent),
                    detail: "\(filteredExpenses.count) \(filteredExpenses.count == 1 ? "expense" : "expenses")",
                    tint: .roostAccent,
                    metadata: activeFilterSummary
                )
                statCard(
                    title: "Your Share",
                    value: formatCurrency(yourShareTotal),
                    detail: yourSharePercentageText,
                    tint: .roostPrimary.opacity(0.16),
                    metadata: "Personal: \(formatCurrency(personalTotal))"
                )
            }
        }
    }

    private var balanceStatCard: some View {
        RoostSectionSurface(emphasis: .raised, padding: DesignSystem.Spacing.cardLarge) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.row) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Balance")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)

                        Text(balanceHeadline)
                            .font(.roostHero)
                            .foregroundStyle(balanceAccent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)

                        Text(balanceSupportingText)
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    Spacer(minLength: DesignSystem.Spacing.row)

                    RoostIconBadge(
                        systemImage: balanceSystemImage,
                        tint: balanceAccent,
                        size: 42
                    )
                }

                HStack(spacing: 8) {
                    RoostStatusPill(title: balanceStatusTitle, tint: balanceAccent)

                    if selectedCategoryFilter != "All categories" || selectedPayerFilter != "All payers" {
                        RoostStatusPill(title: activeFilterSummary, tint: .roostMutedForeground)
                    }
                }

                if partnerUserId != nil && currentBalance != 0 {
                    RoostButton(title: "Settle up", variant: .primary, fullWidth: false) {
                        triggerLightImpact()
                        showingSettleSheet = true
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        }
        .background(balanceBackground, in: RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous)
                .stroke(balanceAccent.opacity(0.14), lineWidth: 1)
        )
    }

    private func statCard(title: String, value: String, detail: String, tint: Color, metadata: String) -> some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)

                    Text(value)
                        .font(.roostSection)
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(detail)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(metadata)
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        }
        .background(tint, in: RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous))
    }

    private var filtersRow: some View {
        HStack(spacing: 8) {
            Button {
                triggerLightImpact()
                showingCategoryFilterSheet = true
            } label: {
                ExpenseFilterPill(
                    title: selectedCategoryFilter,
                    isActive: selectedCategoryFilter != "All categories"
                )
            }
            .buttonStyle(.plain)

            Button {
                triggerLightImpact()
                showingPayerFilterSheet = true
            } label: {
                ExpenseFilterPill(
                    title: selectedPayerFilter,
                    isActive: selectedPayerFilter != "All payers"
                )
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
    }

    private var hazelBanner: some View {
        HStack(spacing: DesignSystem.Spacing.inline) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.roostSecondary)

            Text("Hazel is categorizing...")
                .font(.roostLabel)
                .foregroundStyle(Color.roostSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roostSecondary.opacity(0.15), in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
    }

    private var freeTierCard: some View {
        RoostCard {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.roostSecondary.opacity(0.2))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.roostSecondary)
                }
                .frame(width: 48, height: 48)

                Text("Full history with Roost Pro")
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)

                Text("You’re seeing the last 30 days. Upgrade to see all time.")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostMutedForeground)
                    .multilineTextAlignment(.center)

                RoostButton(title: "Upgrade to Pro", systemImage: "sparkles") {
                    showingProUpsell = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .background(Color.roostSecondary.opacity(0.10), in: RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous))
    }

    private var balanceAccent: Color {
        if currentBalance == 0 { return .roostSuccess }
        if currentBalance > 0 { return .roostPrimary }
        return .roostWarning
    }

    private var balanceBackground: Color {
        if currentBalance == 0 { return Color.roostSuccess.opacity(0.12) }
        if currentBalance > 0 { return Color.roostPrimary.opacity(0.12) }
        if currentBalance < 0 { return Color.roostWarning.opacity(0.12) }
        return Color.roostCard
    }

    private var totalSpent: Decimal {
        filteredExpenses.reduce(Decimal.zero) { partialResult, expense in
            partialResult + expense.amount
        }
    }

    private var defaultSplitType: String {
        moneySettingsViewModel.settings.defaultExpenseSplit == 50.0 ? "equal" : "solo"
    }

    private var yourShareTotal: Decimal {
        filteredExpenses.reduce(Decimal.zero) { partialResult, expense in
            partialResult + (yourShareAmount(for: expense) ?? 0)
        }
    }

    private var personalTotal: Decimal {
        filteredExpenses.reduce(Decimal.zero) { partialResult, expense in
            guard expense.splitType?.lowercased() == "solo" else { return partialResult }
            return partialResult + (yourShareAmount(for: expense) ?? 0)
        }
    }

    private var filteredExpenses: [ExpenseWithSplits] {
        viewModel.expenses.filter { expense in
            let matchesCategory = selectedCategoryFilter == "All categories"
                || (expense.category?.trimmingCharacters(in: .whitespacesAndNewlines) == selectedCategoryFilter)

            let matchesPayer = selectedPayerFilter == "All payers"
                || memberName(for: expense.paidBy) == selectedPayerFilter

            return matchesCategory && matchesPayer
        }
    }

    private var filterCategories: [String] {
        Array(
            Set(
                viewModel.expenses
                    .compactMap(\.category)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }

    private var filterPayers: [String] {
        Array(
            Set(
                viewModel.expenses.map { memberName(for: $0.paidBy) }
            )
        )
        .sorted()
    }

    private var yourSharePercentageText: String {
        let total = NSDecimalNumber(decimal: totalSpent).doubleValue
        guard total > 0 else { return "0% of total" }
        let share = NSDecimalNumber(decimal: yourShareTotal).doubleValue
        return "\(Int((share / total * 100).rounded()))% of total"
    }

    private var balanceHeadline: String {
        if currentBalance == 0 { return "You’re even" }
        return formatCurrency(abs(currentBalance))
    }

    private var balanceSupportingText: String {
        if currentBalance == 0 {
            return "Everything logged here is settled between you both."
        }
        return currentBalance > 0 ? "\(partnerName) owes you" : "You owe \(partnerName)"
    }

    private var balanceStatusTitle: String {
        if currentBalance == 0 { return "Settled" }
        return currentBalance > 0 ? "You’re owed" : "You owe"
    }

    private var balanceSystemImage: String {
        if currentBalance == 0 { return "checkmark.circle.fill" }
        return currentBalance > 0 ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill"
    }

    private var activeFilterSummary: String {
        let category = selectedCategoryFilter == "All categories" ? nil : selectedCategoryFilter
        let payer = selectedPayerFilter == "All payers" ? nil : selectedPayerFilter

        switch (category, payer) {
        case let (category?, payer?):
            return "\(category) · \(payer)"
        case let (category?, nil):
            return category
        case let (nil, payer?):
            return payer
        default:
            return "All expenses"
        }
    }

    private func yourShareAmount(for expense: ExpenseWithSplits) -> Decimal? {
        if let myUserId, let split = expense.expenseSplits.first(where: { $0.userID == myUserId }) {
            return split.amount
        }

        if expense.splitType?.lowercased() == "solo", expense.paidBy == myUserId {
            return expense.amount
        }

        return nil
    }

    private func memberName(for userId: UUID) -> String {
        if userId == myUserId { return "You" }
        if userId == partnerUserId { return partnerName }
        return member(for: userId)?.displayName ?? "Housemate"
    }

    private func member(for userId: UUID) -> HomeMember? {
        homeManager.members.first(where: { $0.userID == userId })
    }

    private var emptyStateCard: some View {
        EmptyStateView(
            icon: "sterlingsign.circle",
            title: "No shared expenses yet",
            message: "Track groceries, bills, and little shared spends so the balance always feels clear.",
            eyebrow: "Expenses",
            actionTitle: "Add first expense"
        ) {
            showingAddSheet = true
        }
        .padding(.horizontal, DesignSystem.Spacing.page)
    }

    private var filteredEmptyStateCard: some View {
        EmptyStateView(
            icon: "line.3.horizontal.decrease.circle",
            title: "No expenses match these filters",
            message: "Try a different category or payer to bring the list back into view.",
            eyebrow: "Filtered",
            actionTitle: "Clear filters"
        ) {
            selectedCategoryFilter = "All categories"
            selectedPayerFilter = "All payers"
        }
        .padding(.horizontal, DesignSystem.Spacing.page)
    }

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<4, id: \.self) { _ in
                LoadingSkeletonView()
                    .frame(height: 92)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.page)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    private func expenseSheetSeed(for expense: ExpenseWithSplits) -> ExpenseSheetSeed {
        ExpenseSheetSeed(
            title: expense.title,
            amountText: decimalText(for: expense.amount),
            paidByUserId: expense.paidBy,
            splitType: expense.splitType?.lowercased() == "solo" ? "solo" : "equal",
            category: expense.category ?? "",
            notes: expense.notes ?? "",
            date: expense.incurredOnDate ?? Date(),
            isRecurring: expense.isRecurring ?? false
        )
    }

    private func decimalText(for amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    private func triggerLightImpact() {
#if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }

    private func triggerWarningHaptic() {
#if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
#endif
    }
}

private struct ExpenseFilterPill: View {
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.roostLabel)
                .lineLimit(1)

            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(isActive ? Color.roostCard : Color.roostMutedForeground)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(
            Capsule(style: .continuous)
                .fill(isActive ? Color.roostPrimary : Color.roostMuted.opacity(0.75))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(isActive ? Color.clear : Color.roostHairline, lineWidth: 1)
        )
        .contentShape(Capsule())
    }
}

private struct ExpenseFilterSheet: View {
    let title: String
    let options: [String]
    let selected: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                RoostSheetHeader(
                    title: title,
                    subtitle: "Choose which expenses you want to focus on."
                ) {
                    dismiss()
                }

                VStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onSelect(option)
                        } label: {
                            HStack(spacing: 12) {
                                Text(option)
                                    .font(.roostBody.weight(.medium))
                                    .foregroundStyle(Color.roostForeground)

                                Spacer(minLength: 0)

                                if option == selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(Color.roostPrimary)
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                    .fill(option == selected ? Color.roostPrimary.opacity(0.10) : Color.roostInput)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                    .stroke(option == selected ? Color.roostPrimary.opacity(0.22) : Color.roostHairline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .background(Color.roostBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

private struct ExpenseActionsSheet: View {
    let expenseTitle: String
    let onCancel: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                RoostSheetHeader(
                    title: "Expense Actions",
                    subtitle: expenseTitle
                ) {
                    onCancel()
                }

                VStack(spacing: 10) {
                    actionButton(
                        title: "Edit Expense",
                        systemImage: "square.and.pencil",
                        tint: .roostSecondary,
                        action: onEdit
                    )

                    actionButton(
                        title: "Delete Expense",
                        systemImage: "trash",
                        tint: .roostDestructive,
                        action: onDelete
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .background(Color.roostBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.hidden)
    }

    private func actionButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 18)

                Text(title)
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                    .fill(Color.roostInput)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                    .stroke(tint.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ExpenseDeleteConfirmationSheet: View {
    let expenseTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                RoostSheetHeader(
                    title: "Remove Expense",
                    subtitle: "Remove this expense? This can't be undone."
                ) {
                    onCancel()
                }

                RoostSectionSurface(emphasis: .subtle) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(expenseTitle)
                            .font(.roostCardTitle)
                            .foregroundStyle(Color.roostForeground)

                        Text("This will remove it from the shared history and rebalance the page immediately.")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, 120)
            .background(Color.roostBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                        .overlay(Color.roostPrimary.opacity(0.12))

                    HStack(spacing: Spacing.md) {
                        RoostButton(title: "Cancel", variant: .outline) {
                            onCancel()
                        }

                        RoostButton(title: "Remove expense", variant: .destructive) {
                            onConfirm()
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.md)
                    .background(Color.roostBackground)
                }
            }
        }
        .presentationDetents([.height(310)])
        .presentationDragIndicator(.hidden)
    }
}

private struct ExpensesEntranceModifier: ViewModifier {
    let index: Int
    let hasAnimatedIn: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hasAnimatedIn ? 1 : 0)
            .offset(y: hasAnimatedIn || reduceMotion ? 0 : 20)
            .scaleEffect(hasAnimatedIn || reduceMotion ? 1 : 0.98)
            .animation(
                reduceMotion ? nil : .roostSmooth.delay(Double(index) * 0.04),
                value: hasAnimatedIn
            )
    }
}

#Preview("Expenses") {
    let homeManager = HomeManager.previewDashboard()
    let settingsViewModel = SettingsViewModel()
    settingsViewModel.userPreferences.currency = "GBP"

    let myId = homeManager.currentUserId ?? UUID()
    let partnerId = homeManager.partner?.userID ?? UUID()
    let homeId = homeManager.homeId ?? UUID()

    let previewExpenses = [
        ExpenseWithSplits(
            id: UUID(),
            homeID: homeId,
            title: "Weekly groceries",
            amount: 86.40,
            paidBy: myId,
            splitType: "equal",
            category: "Groceries",
            notes: "Fruit, pasta, and pantry top-up",
            incurredOn: "2026-04-18",
            isRecurring: false,
            createdAt: .now,
            expenseSplits: [
                ExpenseSplit(id: UUID(), expenseID: UUID(), userID: myId, amount: 43.20, settledAt: .now, settled: true),
                ExpenseSplit(id: UUID(), expenseID: UUID(), userID: partnerId, amount: 43.20, settledAt: nil, settled: false)
            ]
        ),
        ExpenseWithSplits(
            id: UUID(),
            homeID: homeId,
            title: "Electric bill",
            amount: 64.10,
            paidBy: partnerId,
            splitType: "equal",
            category: "Bills",
            notes: nil,
            incurredOn: "2026-04-12",
            isRecurring: false,
            createdAt: .now,
            expenseSplits: [
                ExpenseSplit(id: UUID(), expenseID: UUID(), userID: partnerId, amount: 32.05, settledAt: .now, settled: true),
                ExpenseSplit(id: UUID(), expenseID: UUID(), userID: myId, amount: 32.05, settledAt: nil, settled: false)
            ]
        )
    ]

    return NavigationStack {
        ExpensesView(viewModel: ExpensesViewModel(expenses: previewExpenses))
            .environment(homeManager)
            .environment(settingsViewModel)
            .environment(BudgetViewModel())
    }
}
