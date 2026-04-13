import SwiftUI

// MARK: - MoneyHomeView

struct MoneyHomeView: View {

    @Environment(HomeManager.self) private var homeManager
    @Environment(ExpensesViewModel.self) private var expensesVM
    @Environment(BudgetTemplateViewModel.self) private var budgetVM
    @Environment(MonthlyMoneyViewModel.self) private var summaryVM
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(MemberNamesHelper.self) private var memberNames
    @Environment(ScrambleModeEnvironment.self) private var scramble
    @Environment(HazelViewModel.self) private var hazelVM
    @Environment(SettingsViewModel.self) private var settingsViewModel

    @State private var showAddExpense = false
    @State private var showSettleUp = false
    @State private var arcProgress: CGFloat = 0
    @State private var hideBalances = false
    @State private var temporarilyRevealed = false
    @State private var countdown = 5
    @State private var countdownTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Scramble banner — outside scroll so it stays fixed
                if scramble.isScrambled {
                    scrambleBanner
                }
                scrollContent
            }

            FigmaFloatingActionButton(systemImage: "plus") {
                showAddExpense = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 16)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: homeManager.homeId) {
            guard let homeId = homeManager.homeId else { return }
            await summaryVM.loadSummary(homeId: homeId)
            withAnimation(.easeOut(duration: 0.8)) {
                arcProgress = pctSpentProgress
            }
        }
        .onAppear {
            // Animate ring for data already in cache
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(.easeOut(duration: 0.8)) {
                    arcProgress = pctSpentProgress
                }
            }
            hideBalances = UserDefaults.standard.bool(forKey: "roost-hide-balances")
        }
        .sheet(isPresented: $showAddExpense) {
            if let myUserId = homeManager.currentUserId {
                AddExpenseSheet(
                    myName: memberNames.names.me,
                    partnerName: memberNames.names.hasPartner ? memberNames.names.partner : nil,
                    myUserId: myUserId,
                    partnerUserId: homeManager.partner?.userID,
                    suggestedCategories: budgetVM.categories,
                    defaultSplitType: settingsVM.settings.defaultExpenseSplit == 50.0 ? "equal" : "solo"
                ) { title, amount, paidBy, splitType, category, notes, date, recurring in
                    guard let homeId = homeManager.homeId else { return }
                    await expensesVM.addExpense(
                        title: title, amount: amount, paidByUserId: paidBy,
                        splitType: splitType, category: category, notes: notes,
                        incurredOn: date, homeId: homeId,
                        myUserId: myUserId,
                        partnerUserId: homeManager.partner?.userID ?? myUserId,
                        isRecurring: recurring,
                        hazelEnabled: hazelVM.expensesEnabled,
                        isNest: homeManager.home?.hasProAccess ?? false,
                        budgetCategoryNames: budgetVM.categories.map(\.name)
                    )
                }
            }
        }
        .sheet(isPresented: $showSettleUp) {
            if let myUserId = homeManager.currentUserId,
               let partnerUserId = homeManager.partner?.userID,
               let homeId = homeManager.homeId {
                SettleUpSheet(
                    balance: abs(partnerBalance),
                    currencyCode: settingsViewModel.userPreferences.currency,
                    myName: memberNames.names.me,
                    partnerName: memberNames.names.partner
                ) { note in
                    let fromId = partnerBalance < 0 ? myUserId : partnerUserId
                    let toId = partnerBalance < 0 ? partnerUserId : myUserId
                    await expensesVM.settleUp(
                        homeId: homeId,
                        fromUserId: fromId,
                        toUserId: toId,
                        amount: abs(partnerBalance),
                        note: note,
                        myUserId: myUserId
                    )
                }
            }
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {

                FigmaPageHeader(title: "Money")
                    .padding(.horizontal, DesignSystem.Spacing.page)

                VStack(alignment: .leading, spacing: Spacing.lg) {

                    // Section 1 — Ring arc summary card
                    ringCard

                    // Section 2 — Balance card (conditional)
                    if partnerBalance != 0 {
                        balanceStrip
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Empty state (no income, no expenses, no budget)
                    if showEmptyState {
                        emptyStateCard
                    }

                    // Section 3 — Four nav cards
                    navCardsSection

                    // Section 4 — Spending bars (conditional)
                    if !thisMonthExpenses.isEmpty {
                        spendingBarsSection
                    }

                    // Section 5 — Upcoming bills (conditional)
                    if !budgetVM.fixedLines.isEmpty {
                        upcomingBillsSection
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
                .animation(.easeOut(duration: 0.25), value: partnerBalance == 0)
            }
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom + DesignSystem.Spacing.tabContentBottomInset + 72)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    // MARK: - Section 1: Ring card

    private var ringCard: some View {
        RoostCard {
            if let error = summaryVM.error, summaryVM.summary == nil {
                ringErrorState(error: error)
            } else {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .center, spacing: Spacing.lg) {
                    ringArc
                    if hideBalances && !temporarilyRevealed {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amounts hidden")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.roostMutedForeground)
                            Text("Tap the ring to reveal for 5 seconds.")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        statRows
                    }
                }

                if temporarilyRevealed {
                    Text("Hiding in \(countdown)s")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                if let insight = hazelInsight, !hideBalances || temporarilyRevealed {
                    Text(insight)
                        .font(.system(size: 12))
                        .italic()
                        .foregroundStyle(Color.roostMutedForeground)
                        .padding(.top, 4)
                }
            }
            } // end error/content branch
        }
    }

    private func ringErrorState(error: Error) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: 0xE6A563))
            VStack(alignment: .leading, spacing: 4) {
                Text("Couldn't load summary")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                Button("Try again") {
                    Task {
                        guard let homeId = homeManager.homeId else { return }
                        await summaryVM.loadSummary(homeId: homeId)
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0xD4795E))
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ringArc: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color(.systemFill), lineWidth: 8)
                .frame(width: 80, height: 80)

            // Fill arc
            Circle()
                .trim(from: 0, to: arcProgress)
                .stroke(
                    arcColour,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 80, height: 80)
                .animation(.easeOut(duration: 0.8), value: arcProgress)

            // Center label
            if hideBalances && !temporarilyRevealed {
                VStack(spacing: 4) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                    Text("Tap to\nreveal")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else if let summary = summaryVM.summary, summary.hasIncome {
                VStack(spacing: 1) {
                    Text("\(Int(NSDecimalNumber(decimal: summary.pctSpent).doubleValue))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                    Text("spent")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.roostMutedForeground)
                }
            } else {
                Text("Set\nincome")
                    .font(.system(size: 10, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(hex: 0xD4795E))
            }
        }
        .frame(width: 80, height: 80)
        .contentShape(Circle())
        .onTapGesture {
            guard hideBalances && !temporarilyRevealed else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            temporarilyRevealed = true
            countdown = 5
            countdownTask?.cancel()
            countdownTask = Task {
                for remaining in stride(from: 4, through: 0, by: -1) {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    countdown = remaining
                }
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                temporarilyRevealed = false
            }
        }
    }

    private var statRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Income row — special case for "Not set"
            HStack(alignment: .top) {
                Text("Income")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.roostMutedForeground)
                Spacer()
                if let summary = summaryVM.summary, summary.hasIncome {
                    Text(scramble.format(summary.income, symbol: sym))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                } else {
                    HStack(spacing: 4) {
                        Text("Not set")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: 0xD4795E))
                        NavigationLink { MoneyOverviewView() } label: {
                            Text("Set →")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(hex: 0xD4795E))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Spent
            HStack(alignment: .top) {
                Text("Spent")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.roostMutedForeground)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(summaryVM.summary.map { scramble.format($0.actualSpend, symbol: sym) } ?? "—")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                    Text("\(thisMonthExpenses.count) expenses")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }

            // Remaining
            HStack(alignment: .top) {
                Text("Remaining")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.roostMutedForeground)
                Spacer()
                Text(remainingDisplay)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(remainingColour)
            }

            // Est. surplus
            HStack(alignment: .top) {
                Text("Est. surplus")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.roostMutedForeground)
                Spacer()
                HStack(spacing: 2) {
                    if let prefix = surplusPrefix {
                        Text(prefix)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(surplusColour)
                    }
                    Text(surplusDisplay)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(surplusColour)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Section 2: Balance strip

    private var balanceStrip: some View {
        let owed = partnerBalance > 0
        let balanceText = owed
            ? "\(memberNames.names.partner) owes you \(scramble.format(abs(partnerBalance), symbol: sym))"
            : "You owe \(memberNames.names.partner) \(scramble.format(abs(partnerBalance), symbol: sym))"

        return HStack(spacing: Spacing.sm) {
            Circle()
                .fill(owed ? Color(hex: 0x3B6D11) : Color(hex: 0x854F0B))
                .frame(width: 8, height: 8)

            Text(balanceText)
                .font(.system(size: 13))
                .foregroundStyle(Color.roostForeground)
                .lineLimit(1)

            Spacer(minLength: 4)

            Button("Settle up") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showSettleUp = true
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(hex: 0xD4795E))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(hex: 0xD4795E), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(owed ? Color(hex: 0xEAF3DE) : Color(hex: 0xFAEEDA))
        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    // MARK: - Section 3: Nav cards

    private var navCardsSection: some View {
        VStack(spacing: 8) {
            NavigationLink { MoneyOverviewView() } label: {
                MoneyNavCard(
                    icon: "chart.bar.fill",
                    iconBg: Color(hex: 0xE6F1FB),
                    iconColour: Color(hex: 0x185FA5),
                    title: "Overview",
                    subtitle: overviewSubtitle
                )
            }
            .buttonStyle(.plain)

            NavigationLink { MoneySpendingView() } label: {
                MoneyNavCard(
                    icon: "cart.fill",
                    iconBg: Color(hex: 0xE1F5EE),
                    iconColour: Color(hex: 0x0F6E56),
                    title: "Spending",
                    subtitle: spendingSubtitle
                )
            }
            .buttonStyle(.plain)

            NavigationLink { MoneyBudgetsView() } label: {
                MoneyNavCard(
                    icon: "list.bullet.rectangle.fill",
                    iconBg: Color(hex: 0xFAEEDA),
                    iconColour: Color(hex: 0x854F0B),
                    title: "Budgets",
                    subtitle: budgetsSubtitle,
                    subtitleColour: budgetVM.activeLines.isEmpty
                        ? Color(hex: 0xD4795E)
                        : Color.roostMutedForeground
                )
            }
            .buttonStyle(.plain)

            NavigationLink { MoneyGoalsView() } label: {
                MoneyNavCard(
                    icon: "target",
                    iconBg: Color(hex: 0xFAECE7),
                    iconColour: Color(hex: 0x993C1D),
                    title: "Goals",
                    subtitle: "What are you saving toward?"
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section 4: Spending bars

    private var spendingBarsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SPENDING THIS MONTH")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Color.roostMutedForeground)

            RoostCard(padding: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    let bars = topSpendingItems

                    ForEach(Array(bars.prefix(4).enumerated()), id: \.offset) { _, item in
                        spendingBar(item: item)
                    }

                    if bars.count > 4 {
                        NavigationLink { MoneySpendingView() } label: {
                            Text("\(bars.count - 4) more categories →")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: 0xD4795E))
                        }
                        .buttonStyle(.plain)
                    }

                    HStack {
                        Spacer()
                        Button("+ Add expense") {
                            showAddExpense = true
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.roostMutedForeground)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func spendingBar(item: SpendingItem) -> some View {
        let fillRatio = barFillRatio(spent: item.spent, budgeted: item.budgeted)
        let colour = barColour(fillRatio: fillRatio, hasBudget: item.budgeted > 0)

        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Circle()
                    .fill(item.colour)
                    .frame(width: 8, height: 8)
                Text(item.name)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.roostForeground)
                Spacer()
                Text(scramble.format(item.spent, symbol: sym))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color(.systemFill))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(colour)
                        .frame(width: geo.size.width * fillRatio, height: 5)
                        .animation(DesignSystem.Motion.progressFill, value: fillRatio)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: - Section 5: Upcoming bills

    private var upcomingBillsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("COMING UP")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Color.roostMutedForeground)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(upcomingBills) { bill in
                        BillDayCard(
                            bill: bill,
                            isImminent: bill.id == mostImminentBillId,
                            scramble: scramble,
                            currencySymbol: sym
                        )
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Empty state

    private var emptyStateCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Set up your finances")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                Text("Add your income and budget to see your complete financial picture.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
                NavigationLink { MoneyBudgetsView() } label: {
                    Text("Get started →")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: 0xD4795E))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Scramble banner

    private var scrambleBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.roostForeground)
            Text("Scramble mode on — amounts hidden")
                .font(.system(size: 12))
                .foregroundStyle(Color.roostForeground)
            Spacer()
            Button("Turn off") {
                Task {
                    guard let homeId = homeManager.homeId else { return }
                    try? await settingsVM.toggleScrambleMode(homeId: homeId)
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.roostForeground)
        }
        .padding(.horizontal, DesignSystem.Spacing.page)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0xFAEEDA))
    }

    // MARK: - Computed: data

    private var sym: String { settingsVM.settings.currencySymbol }

    private var myUserId: UUID? { homeManager.currentUserId }
    private var partnerUserId: UUID? { homeManager.partner?.userID }

    private var partnerBalance: Decimal {
        guard let myId = myUserId, let partnerId = partnerUserId else { return 0 }
        return BalanceCalculator.calculate(
            expenses: expensesVM.expenses,
            myUserId: myId,
            partnerUserId: partnerId
        )
    }

    private var currentMonth: Date { summaryVM.selectedMonth }

    private var thisMonthExpenses: [ExpenseWithSplits] {
        let cal = Calendar.current
        return expensesVM.expenses.filter { ews in
            guard let date = ews.incurredOnDate else { return false }
            return cal.isDate(date, equalTo: currentMonth, toGranularity: .month)
        }
    }

    private var thisMonthExpensesAsExpense: [Expense] {
        thisMonthExpenses.map(\.expense)
    }

    private var thisMonthTotalSpend: Decimal {
        thisMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var showEmptyState: Bool {
        guard !summaryVM.isLoading, !budgetVM.isLoading else { return false }
        let noIncome = summaryVM.summary.map { !$0.hasIncome } ?? true
        return noIncome && thisMonthExpenses.isEmpty && budgetVM.activeLines.isEmpty
    }

    // MARK: - Computed: ring

    private var pctSpentDouble: Double {
        guard let s = summaryVM.summary, s.hasIncome else { return 0 }
        return NSDecimalNumber(decimal: s.pctSpent).doubleValue
    }

    private var pctSpentProgress: CGFloat {
        CGFloat(min(1.0, max(0.0, pctSpentDouble / 100.0)))
    }

    private var arcColour: Color {
        guard summaryVM.summary?.hasIncome == true else { return Color(.systemFill) }
        switch pctSpentDouble {
        case ..<70:   return Color(hex: 0x9DB19F)
        case 70..<90: return Color(hex: 0xE6A563)
        default:      return Color(hex: 0xC75146)
        }
    }

    // MARK: - Computed: stat values

    private var remainingDisplay: String {
        guard let s = summaryVM.summary, s.hasIncome else { return "—" }
        return scramble.format(s.income - s.actualSpend, symbol: sym)
    }

    private var remainingColour: Color {
        guard let s = summaryVM.summary, s.hasIncome, s.income > 0 else { return .roostForeground }
        let remaining = s.income - s.actualSpend
        if remaining < 0 { return Color(hex: 0xC75146) }
        let ratio = NSDecimalNumber(decimal: remaining / s.income).doubleValue
        if ratio < 0.10 { return Color(hex: 0xC75146) }
        if ratio < 0.30 { return Color(hex: 0xE6A563) }
        return Color(hex: 0x9DB19F)
    }

    private var surplusDisplay: String {
        guard let projected = summaryVM.projectedSurplus else { return "—" }
        return scramble.format(abs(projected), symbol: sym)
    }

    private var surplusPrefix: String? {
        guard let projected = summaryVM.projectedSurplus else { return nil }
        return projected >= 0 ? "↑" : "↓"
    }

    private var surplusColour: Color {
        guard let projected = summaryVM.projectedSurplus else { return .roostMutedForeground }
        return projected >= 0 ? Color(hex: 0x3B6D11) : Color(hex: 0xC75146)
    }

    // MARK: - Computed: nav card subtitles

    private var overviewSubtitle: String {
        guard let s = summaryVM.summary, s.hasIncome else {
            return "Income, fixed costs, surplus"
        }
        return "\(scramble.format(s.income, symbol: sym)) income · \(scramble.format(s.actualSpend, symbol: sym)) spent"
    }

    private var spendingSubtitle: String {
        if thisMonthExpenses.isEmpty { return "Log and review your spending" }
        if let top = topSpendingItems.first {
            return "\(top.name) · \(thisMonthExpenses.count) expenses"
        }
        return "\(thisMonthExpenses.count) expenses this month"
    }

    private var budgetsSubtitle: String {
        guard !budgetVM.activeLines.isEmpty else { return "Set up your budget" }
        let unallocated: Decimal
        if let s = summaryVM.summary, s.hasIncome {
            unallocated = max(0, s.income - budgetVM.totalBudgeted)
        } else {
            unallocated = 0
        }
        return "\(scramble.format(budgetVM.totalBudgeted, symbol: sym)) budgeted · \(scramble.format(unallocated, symbol: sym)) free"
    }

    // MARK: - Computed: spending bars

    private struct SpendingItem {
        let name: String
        let colour: Color
        let spent: Decimal
        let budgeted: Decimal
    }

    private var topSpendingItems: [SpendingItem] {
        let expenses = thisMonthExpensesAsExpense

        // Group all this-month expenses by category name
        var spend: [String: Decimal] = [:]
        for e in expenses {
            guard let cat = e.category?.trimmingCharacters(in: .whitespacesAndNewlines), !cat.isEmpty else { continue }
            spend[cat, default: 0] += e.amount
        }

        return spend.map { catName, spent -> SpendingItem in
            // Match to a budget category for colour & budgeted amount
            let budgetCat = budgetVM.categories.first {
                $0.name.caseInsensitiveCompare(catName) == .orderedSame
            }
            let colour = budgetCat?.colour ?? stableColour(for: catName)
            let line = budgetVM.lifestyleLines.first {
                $0.name.caseInsensitiveCompare(catName) == .orderedSame
            }
            let budgeted = line.map { budgetVM.getEffectiveAmount(lineId: $0.id, month: currentMonth) } ?? 0
            return SpendingItem(name: catName, colour: colour, spent: spent, budgeted: budgeted)
        }
        .filter { $0.spent > 0 }
        .sorted { $0.spent > $1.spent }
    }

    private func stableColour(for name: String) -> Color {
        let palette: [Color] = [
            Color(hex: 0xD4815E), Color(hex: 0x8EA882), Color(hex: 0xC99952),
            Color(hex: 0x7CB7A3), Color(hex: 0x7A8FA1), Color(hex: 0xD98695), Color(hex: 0xA08AB8)
        ]
        let hash = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }

    private func barFillRatio(spent: Decimal, budgeted: Decimal) -> CGFloat {
        if budgeted > 0 {
            return CGFloat(min(1.0, max(0, NSDecimalNumber(decimal: spent / budgeted).doubleValue)))
        } else if thisMonthTotalSpend > 0 {
            return CGFloat(min(1.0, max(0, NSDecimalNumber(decimal: spent / thisMonthTotalSpend).doubleValue)))
        }
        return 0
    }

    private func barColour(fillRatio: CGFloat, hasBudget: Bool) -> Color {
        guard hasBudget else { return Color(hex: 0xD4795E) }
        switch fillRatio {
        case ..<0.70: return Color(hex: 0x9DB19F)
        case 0.70..<0.90: return Color(hex: 0xE6A563)
        default: return Color(hex: 0xC75146)
        }
    }

    // MARK: - Computed: bills

    private var upcomingBills: [BudgetTemplateLine] {
        Array(
            budgetVM.fixedLines
                .sorted { ($0.dayOfMonth ?? 99) < ($1.dayOfMonth ?? 99) }
                .prefix(6)
        )
    }

    private var mostImminentBillId: UUID? {
        let today = Calendar.current.component(.day, from: Date())
        let isCurrentMonth = Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
        if isCurrentMonth {
            return upcomingBills.first { ($0.dayOfMonth ?? 0) >= today }?.id
                ?? upcomingBills.first?.id
        }
        return upcomingBills.first?.id
    }

    // MARK: - Hazel insight (static fallback)

    private var hazelInsight: String? {
        let expenses = thisMonthExpensesAsExpense

        // 1. Any lifestyle category over budget
        for cat in budgetVM.categories {
            guard let line = budgetVM.lifestyleLines.first(where: {
                $0.name.caseInsensitiveCompare(cat.name) == .orderedSame
            }) else { continue }
            let budgeted = budgetVM.getEffectiveAmount(lineId: line.id, month: currentMonth)
            guard budgeted > 0 else { continue }
            let spent = budgetVM.getSpent(category: cat.name, month: currentMonth, expenses: expenses)
            if spent > budgeted {
                return "\(cat.name) is over budget — you've spent \(sym)\(compact(spent)) of \(sym)\(compact(budgeted))."
            }
        }

        // 2. Projected surplus negative
        if let surplus = summaryVM.projectedSurplus, surplus < 0 {
            return "At your current pace you'll overspend by \(sym)\(compact(abs(surplus))) this month."
        }

        // 3. Projected surplus positive and > 100
        if let surplus = summaryVM.projectedSurplus, surplus > 100 {
            return "You're on track for a \(sym)\(compact(surplus)) surplus."
        }

        // 4. Early in the month
        let day = Calendar.current.component(.day, from: Date())
        let isCurrentMonth = Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
        if isCurrentMonth && day <= 7 {
            let monthName = currentMonth.formatted(.dateTime.month(.wide))
            return "Early days in \(monthName) — check back as the month goes on."
        }

        // 5. Default
        guard let s = summaryVM.summary, s.hasIncome else { return nil }
        let pct = Int(NSDecimalNumber(decimal: s.pctSpent).doubleValue)
        let daysLeft = summaryVM.daysInMonth - summaryVM.daysElapsed
        return "Your spending is \(pct)% of your budget with \(daysLeft) day\(daysLeft == 1 ? "" : "s") to go."
    }

    private func compact(_ value: Decimal) -> String {
        let n = value as NSDecimalNumber
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 0
        return fmt.string(from: n) ?? n.stringValue
    }
}

// MARK: - MoneyNavCard

private struct MoneyNavCard: View {
    let icon: String
    let iconBg: Color
    let iconColour: Color
    let title: String
    let subtitle: String
    var subtitleColour: Color = .roostMutedForeground

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconColour)
                .frame(width: 36, height: 36)
                .background(iconBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(subtitleColour)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.roostMutedForeground)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(DesignSystem.Palette.border, lineWidth: 1)
        )
    }
}

// MARK: - BillDayCard

private struct BillDayCard: View {
    let bill: BudgetTemplateLine
    let isImminent: Bool
    let scramble: ScrambleModeEnvironment
    let currencySymbol: String

    var body: some View {
        VStack(spacing: 3) {
            Text(dateLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isImminent ? Color(hex: 0xF2EBE0) : Color.roostMutedForeground)
            Text(bill.name)
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(isImminent ? Color(hex: 0xF2EBE0) : Color.roostForeground)
            Text(scramble.format(bill.displayAmount, symbol: currencySymbol))
                .font(.system(size: 9))
                .foregroundStyle(isImminent ? Color(hex: 0xF2EBE0).opacity(0.8) : Color.roostMutedForeground)
        }
        .frame(width: 70)
        .padding(8)
        .background(isImminent ? Color(hex: 0xD4795E) : DesignSystem.Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private var dateLabel: String {
        guard let day = bill.dayOfMonth else { return "—" }
        let today = Calendar.current.component(.day, from: Date())
        if day == today { return "Today" }
        if day == today + 1 { return "Tomorrow" }
        let suffix: String
        switch day % 10 {
        case 1 where day != 11: suffix = "st"
        case 2 where day != 12: suffix = "nd"
        case 3 where day != 13: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }
}

