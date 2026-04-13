import Charts
import SwiftUI

// MARK: - CategoryGroup

private struct CategoryGroup: Identifiable {
    let id: String          // category name (or "__uncategorised__")
    let name: String
    let spent: Decimal
    let budgeted: Decimal   // 0 for Uncategorised / no matching template line
    let colour: Color
    let expenses: [ExpenseWithSplits] // sorted date DESC

    var isOverspent: Bool { budgeted > 0 && spent > budgeted }

    var spendPct: Double {
        guard budgeted > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent / budgeted).doubleValue * 100
    }

    var barColour: Color {
        if budgeted == 0 { return Color(hex: 0xd4795e) }
        if spendPct < 70  { return Color(hex: 0x9db19f) }
        if spendPct < 90  { return Color(hex: 0xe6a563) }
        return Color(hex: 0xc75146)
    }
}

// MARK: - MoneySpendingView

struct MoneySpendingView: View {

    @Environment(HomeManager.self) private var homeManager
    @Environment(ExpensesViewModel.self) private var expensesVM
    @Environment(BudgetTemplateViewModel.self) private var budgetVM
    @Environment(MonthlyMoneyViewModel.self) private var summaryVM
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(MemberNamesHelper.self) private var memberNames
    @Environment(ScrambleModeEnvironment.self) private var scramble
    @Environment(HazelViewModel.self) private var hazelVM

    @State private var expandedCategory: String? = nil
    @State private var showAllForCategories: Set<String> = []
    @State private var showAddExpense = false
    @State private var editingExpense: ExpenseWithSplits? = nil
    @State private var deleteCandidate: ExpenseWithSplits? = nil
    @State private var showHistoryUpsell = false

    // MARK: - Derived helpers

    private var sym: String { settingsVM.settings.currencySymbol }
    private var isFreeTier: Bool { !(homeManager.home?.hasProAccess ?? false) }
    private var currentMonth: Date { summaryVM.selectedMonth }
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
    }
    private var defaultSplitType: String {
        settingsVM.settings.defaultExpenseSplit == 50.0 ? "equal" : "solo"
    }
    private var historyCutoff: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }

    private var thisMonthExpenses: [ExpenseWithSplits] {
        let cal = Calendar.current
        return expensesVM.expenses.filter { ews in
            guard let d = ews.incurredOnDate else { return false }
            return cal.isDate(d, equalTo: currentMonth, toGranularity: .month)
        }
    }

    private var expensesByDateDesc: [ExpenseWithSplits] {
        thisMonthExpenses.sorted {
            ($0.incurredOnDate ?? Date.distantPast) > ($1.incurredOnDate ?? Date.distantPast)
        }
    }

    // MARK: - Category groups

    private var categoryGroups: [CategoryGroup] {
        let expenses = thisMonthExpenses

        // Map expense category → canonical lifestyle line name (case-insensitive)
        let lifestyleByLower: [(lower: String, line: BudgetTemplateLine)] =
            budgetVM.lifestyleLines.map { ($0.name.lowercased(), $0) }

        // Bucket expenses by normalised key
        var buckets: [String: [ExpenseWithSplits]] = [:]
        for exp in expenses {
            let raw = exp.category?.trimmingCharacters(in: .whitespaces) ?? ""
            if raw.isEmpty {
                buckets["__uncategorised__", default: []].append(exp)
            } else {
                let lower = raw.lowercased()
                let canonical = lifestyleByLower.first { $0.lower == lower }?.line.name.lowercased() ?? lower
                buckets[canonical, default: []].append(exp)
            }
        }

        let matchedLowers = Set(budgetVM.lifestyleLines.map { $0.name.lowercased() })

        // Build a group for every lifestyle line (even zero-spend so empty bars show)
        var groups: [CategoryGroup] = budgetVM.lifestyleLines.map { line in
            let key = line.name.lowercased()
            let bucket = buckets[key] ?? []
            let spent = bucket.reduce(Decimal(0)) { $0 + $1.amount }
            let budgeted = budgetVM.getEffectiveAmount(lineId: line.id, month: currentMonth)
            let colour = budgetVM.categories
                .first { $0.name.lowercased() == key }?.colour ?? Color(hex: 0x9db19f)
            return CategoryGroup(
                id: line.name,
                name: line.name,
                spent: spent,
                budgeted: budgeted,
                colour: colour,
                expenses: bucket.sorted {
                    ($0.incurredOnDate ?? Date.distantPast) > ($1.incurredOnDate ?? Date.distantPast)
                }
            )
        }

        // Collect orphan expenses (category doesn't match any lifestyle line)
        var orphans: [ExpenseWithSplits] = []
        for (key, exps) in buckets {
            if key == "__uncategorised__" || !matchedLowers.contains(key) {
                orphans.append(contentsOf: exps)
            }
        }
        if !orphans.isEmpty {
            let spent = orphans.reduce(Decimal(0)) { $0 + $1.amount }
            groups.append(CategoryGroup(
                id: "__uncategorised__",
                name: "Uncategorised",
                spent: spent,
                budgeted: 0,
                colour: Color.roostMutedForeground.opacity(0.45),
                expenses: orphans.sorted {
                    ($0.incurredOnDate ?? Date.distantPast) > ($1.incurredOnDate ?? Date.distantPast)
                }
            ))
        }

        // Filter: hide lines with both zero spend and zero budget
        groups = groups.filter { $0.spent > 0 || $0.budgeted > 0 }

        // Sort: overspent first, then spend% desc, then alphabetical
        return groups.sorted { a, b in
            if a.isOverspent != b.isOverspent { return a.isOverspent }
            if a.spendPct != b.spendPct { return a.spendPct > b.spendPct }
            return a.name < b.name
        }
    }

    // Only categories with spend > 0, sorted by spent desc (for the pie chart)
    private var chartGroups: [CategoryGroup] {
        categoryGroups.filter { $0.spent > 0 }.sorted { $0.spent > $1.spent }
    }

    private var totalSpent: Decimal {
        chartGroups.reduce(0) { $0 + $1.spent }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    FigmaBackHeader(title: "Spending")
                        .padding(.horizontal, DesignSystem.Spacing.page)

                    // Month navigator + pie chart + insight
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        monthNavigatorRow
                        pieChartSection
                        if let insight = hazelInsight, !thisMonthExpenses.isEmpty {
                            Text(insight)
                                .font(.system(size: 13).italic())
                                .foregroundStyle(Color.roostMutedForeground)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.page)

                    // Category bars + all expenses
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        categoryBarsSection
                        allExpensesSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .padding(.top, Spacing.xl)

                    Spacer(minLength: DesignSystem.Spacing.screenBottom + 64)
                }
            }
            .background(Color.roostBackground.ignoresSafeArea())

            // FAB
            FigmaFloatingActionButton(systemImage: "plus") {
                showAddExpense = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 16)
        }
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .sheet(isPresented: $showAddExpense) {
            addExpenseSheetView(defaultCategory: expandedCategory)
        }
        .sheet(item: $editingExpense) { expense in
            editExpenseSheetView(expense: expense)
        }
        .confirmationDialog(
            "Delete \"\(deleteCandidate?.title ?? "this expense")\"?",
            isPresented: Binding(
                get: { deleteCandidate != nil },
                set: { if !$0 { deleteCandidate = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                guard let exp = deleteCandidate,
                      let homeId = homeManager.homeId,
                      let userId = homeManager.currentUserId else { return }
                Task { await expensesVM.deleteExpense(exp, homeId: homeId, userId: userId) }
                deleteCandidate = nil
            }
            Button("Cancel", role: .cancel) { deleteCandidate = nil }
        } message: {
            Text("This can't be undone.")
        }
        .nestUpsell(isPresented: $showHistoryUpsell, feature: .budgetHistory)
    }
}

// MARK: - Month navigator

private extension MoneySpendingView {

    var monthNavigatorRow: some View {
        MonthNavigator(
            label: monthLabel,
            onPrevious: {
                summaryVM.navigateMonth(direction: -1)
                Task {
                    guard let homeId = homeManager.homeId else { return }
                    await summaryVM.loadSummary(homeId: homeId)
                }
            },
            onNext: {
                summaryVM.navigateMonth(direction: 1)
                Task {
                    guard let homeId = homeManager.homeId else { return }
                    await summaryVM.loadSummary(homeId: homeId)
                }
            },
            canGoNext: !isCurrentMonth,
            isPro: !isFreeTier,
            onProGate: { showHistoryUpsell = true }
        )
    }

    var monthLabel: String {
        if isCurrentMonth { return "This month" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: currentMonth)
    }
}

// MARK: - Pie chart

private extension MoneySpendingView {

    var pieChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if chartGroups.isEmpty {
                emptyChartCard
            } else {
                Chart(chartGroups) { group in
                    SectorMark(
                        angle: .value("Spent",
                            NSDecimalNumber(decimal: group.spent).doubleValue),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(group.colour)
                    .cornerRadius(4)
                }
                .chartBackground { _ in
                    VStack(spacing: 2) {
                        Text(scramble.format(totalSpent, symbol: sym))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.roostForeground)
                        Text("spent")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }
                .frame(height: 200)

                // Legend
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(chartGroups) { group in
                            HStack(spacing: 5) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(group.colour)
                                    .frame(width: 8, height: 8)
                                Text(group.name)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.roostForeground)
                                Text(scramble.format(group.spent, symbol: sym))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.roostForeground)
                            }
                        }
                    }
                }
            }
        }
    }

    var emptyChartCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: 0xd4795e).opacity(0.4))
            Text("Nothing logged yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.roostForeground)
            Text("Start adding expenses to see your spending breakdown.")
                .font(.system(size: 13))
                .foregroundStyle(Color.roostMutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(DesignSystem.Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DesignSystem.Palette.border, lineWidth: 1)
        )
    }
}

// MARK: - Hazel insight

private extension MoneySpendingView {

    var hazelInsight: String? {
        let groups = categoryGroups
        guard !groups.isEmpty else { return nil }

        // 1. Any category over 100% budget
        if let overspent = groups.first(where: { $0.isOverspent }) {
            return "\(overspent.name) is over budget — \(sym)\(decimalString(overspent.spent)) of \(sym)\(decimalString(overspent.budgeted)) spent."
        }

        // 2. Top category > 50% of total spend
        if let top = chartGroups.first, totalSpent > 0 {
            let pct = NSDecimalNumber(decimal: top.spent / totalSpent).doubleValue * 100
            if pct > 50 {
                return "\(top.name) makes up \(Int(pct))% of your spending this month."
            }
        }

        // 3. Well within budget (< 30% spent and day > 10)
        let totalLifestyle = budgetVM.totalLifestyle
        if totalLifestyle > 0, totalSpent > 0 {
            let ratio = NSDecimalNumber(decimal: totalSpent / totalLifestyle).doubleValue
            let dayOfMonth = Calendar.current.component(.day, from: Date())
            if ratio < 0.30 && dayOfMonth > 10 {
                return "You're well within budget this month."
            }
        }

        // 4. Default
        if let top = chartGroups.first {
            return "\(top.name) is your biggest category so far this month."
        }
        return nil
    }
}

// MARK: - Category bars

private extension MoneySpendingView {

    var categoryBarsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR BUDGETS")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Color.roostMutedForeground)

            if budgetVM.lifestyleLines.isEmpty {
                noBudgetsCard
            } else {
                budgetCard

                NavigationLink {
                    MoneyBudgetsView()
                } label: {
                    Text("Manage budgets →")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.roostMutedForeground)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 4)
            }
        }
    }

    var noBudgetsCard: some View {
        VStack(spacing: 8) {
            Text("No lifestyle budgets set up")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.roostForeground)
            Text("Head to Budgets to add categories and track spending.")
                .font(.system(size: 12))
                .foregroundStyle(Color.roostMutedForeground)
                .multilineTextAlignment(.center)
            NavigationLink {
                MoneyBudgetsView()
            } label: {
                Text("Go to Budgets →")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roostPrimary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(DesignSystem.Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DesignSystem.Palette.border, lineWidth: 1)
        )
    }

    var budgetCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            let groups = categoryGroups
            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                categoryRow(group: group)
                if index < groups.count - 1 {
                    Divider()
                        .padding(.horizontal, 14)
                }
            }
        }
        .background(DesignSystem.Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DesignSystem.Palette.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func categoryRow(group: CategoryGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — always visible, tappable
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if expandedCategory == group.id {
                        expandedCategory = nil
                    } else {
                        expandedCategory = group.id
                        showAllForCategories.remove(group.id)
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(group.colour)
                            .frame(width: 8, height: 8)

                        Text(group.name)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.roostForeground)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if group.budgeted > 0 {
                            Text(scramble.format(group.spent, symbol: sym)
                                 + " / "
                                 + scramble.format(group.budgeted, symbol: sym))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.roostMutedForeground)
                        } else {
                            Text(scramble.format(group.spent, symbol: sym))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.roostMutedForeground)
                        }

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.roostMutedForeground)
                            .rotationEffect(.degrees(expandedCategory == group.id ? 180 : 0))
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color(.systemFill))
                                .frame(height: 5)

                            let fillWidth: CGFloat = {
                                if group.budgeted > 0 {
                                    let ratio = min(
                                        NSDecimalNumber(decimal: group.spent / group.budgeted).doubleValue,
                                        1.0)
                                    return geo.size.width * CGFloat(ratio)
                                } else if totalSpent > 0 {
                                    let ratio = NSDecimalNumber(decimal: group.spent / totalSpent).doubleValue
                                    return geo.size.width * CGFloat(ratio)
                                }
                                return 0
                            }()

                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(group.barColour)
                                .frame(width: max(fillWidth, 0), height: 5)

                            if group.isOverspent {
                                Rectangle()
                                    .fill(Color(hex: 0xa32d2d))
                                    .frame(width: 4, height: 10)
                                    .offset(x: geo.size.width - 2)
                            }
                        }
                    }
                    .frame(height: 5)
                    .padding(.bottom, 4)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded expense rows
            if expandedCategory == group.id {
                expandedExpenseList(group: group)
            }
        }
    }

    @ViewBuilder
    private func expandedExpenseList(group: CategoryGroup) -> some View {
        let expenses = group.expenses
        let showAll = showAllForCategories.contains(group.id)
        let visible = showAll ? expenses : Array(expenses.prefix(5))
        let hasFreeGate = isFreeTier && expenses.contains { exp in
            (exp.incurredOnDate ?? Date()) < historyCutoff
        }

        VStack(alignment: .leading, spacing: 4) {
            Divider().padding(.horizontal, 14)

            ForEach(visible, id: \.id) { exp in
                let isOld = isFreeTier && (exp.incurredOnDate ?? Date()) < historyCutoff
                inlineExpenseRow(expense: exp, isLocked: isOld)
                    .padding(.horizontal, 14)
            }

            if hasFreeGate && !showAll {
                Button {
                    showHistoryUpsell = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("See full history with Roost Pro")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }

            if expenses.count > 5 && !showAll {
                Button {
                    _ = showAllForCategories.insert(group.id)
                } label: {
                    Text("\(expenses.count - 5) more")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0xd4795e))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.bottom, 2)
            }
        }
        .padding(.bottom, 10)
        .background(Color(.secondarySystemBackground))
    }
}

// MARK: - All expenses

private extension MoneySpendingView {

    var allExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALL EXPENSES")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Color.roostMutedForeground)

            if expensesByDateDesc.isEmpty {
                Text("No expenses this month.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .background(DesignSystem.Palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(DesignSystem.Palette.border, lineWidth: 1)
                    )
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    let expenses = expensesByDateDesc
                    ForEach(Array(expenses.enumerated()), id: \.element.id) { index, exp in
                        let isOld = isFreeTier && (exp.incurredOnDate ?? Date()) < historyCutoff
                        inlineExpenseRow(expense: exp, isLocked: isOld)
                            .padding(.horizontal, 14)

                        if index < expenses.count - 1 {
                            Divider().padding(.horizontal, 14)
                        }
                    }

                    // Pro gate footer
                    if isFreeTier && expenses.contains(where: { ($0.incurredOnDate ?? Date()) < historyCutoff }) {
                        Divider().padding(.horizontal, 14)
                        HStack {
                            Text("See full history with Roost Pro")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.roostMutedForeground)
                            Spacer()
                            Button("Try Pro →") {
                                showHistoryUpsell = true
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: 0xd4795e))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                }
                .background(DesignSystem.Palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DesignSystem.Palette.border, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Inline expense row

private extension MoneySpendingView {

    @ViewBuilder
    private func inlineExpenseRow(expense: ExpenseWithSplits, isLocked: Bool) -> some View {
        if isLocked {
            // Locked placeholder for free tier
            HStack {
                Text("Older expense")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.roostForeground.opacity(0.35))
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.roostMutedForeground.opacity(0.4))
            }
            .padding(.vertical, 10)
        } else {
            let payerName = expense.paidBy == homeManager.currentUserId
                ? memberNames.names.me
                : memberNames.names.partner

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.title)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if let date = expense.incurredOnDate {
                            Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                        if expense.isRecurring == true {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(scramble.format(expense.amount, symbol: sym))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                    Text("Paid by \(payerName)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    editingExpense = expense
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    deleteCandidate = expense
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Sheet builders + helpers

private extension MoneySpendingView {

    @ViewBuilder
    func addExpenseSheetView(defaultCategory: String?) -> some View {
        if let myId = homeManager.currentUserId {
            AddExpenseSheet(
                myName: memberNames.names.me,
                partnerName: memberNames.names.hasPartner ? memberNames.names.partner : nil,
                myUserId: myId,
                partnerUserId: homeManager.partner?.userID,
                suggestedCategories: budgetVM.categories,
                defaultSplitType: defaultSplitType
            ) { title, amount, paidBy, splitType, category, notes, date, recurring in
                guard let homeId = homeManager.homeId else { return }
                await expensesVM.addExpense(
                    title: title,
                    amount: amount,
                    paidByUserId: paidBy,
                    splitType: splitType,
                    category: category,
                    notes: notes,
                    incurredOn: date,
                    homeId: homeId,
                    myUserId: myId,
                    partnerUserId: homeManager.partner?.userID ?? myId,
                    isRecurring: recurring,
                    hazelEnabled: hazelVM.expensesEnabled,
                    isNest: homeManager.home?.hasProAccess ?? false,
                    budgetCategoryNames: budgetVM.categories.map(\.name)
                )
            }
        }
    }

    @ViewBuilder
    func editExpenseSheetView(expense: ExpenseWithSplits) -> some View {
        if let myId = homeManager.currentUserId,
           let homeId = homeManager.homeId {
            AddExpenseSheet(
                myName: memberNames.names.me,
                partnerName: memberNames.names.hasPartner ? memberNames.names.partner : nil,
                myUserId: myId,
                partnerUserId: homeManager.partner?.userID,
                suggestedCategories: budgetVM.categories,
                defaultSplitType: defaultSplitType,
                mode: .edit,
                initialValue: expenseSheetSeed(for: expense)
            ) { title, amount, paidBy, splitType, category, notes, date, recurring in
                await expensesVM.updateExpense(
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
                    partnerUserId: homeManager.partner?.userID ?? myId,
                    isRecurring: recurring
                )
            }
        }
    }

    private func expenseSheetSeed(for expense: ExpenseWithSplits) -> ExpenseSheetSeed {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        let amountText = formatter.string(from: expense.amount as NSDecimalNumber) ?? "\(expense.amount)"
        return ExpenseSheetSeed(
            title: expense.title,
            amountText: amountText,
            paidByUserId: expense.paidBy,
            splitType: expense.splitType?.lowercased() == "solo" ? "solo" : "equal",
            category: expense.category ?? "",
            notes: expense.notes ?? "",
            date: expense.incurredOnDate ?? Date(),
            isRecurring: expense.isRecurring ?? false
        )
    }

    private func decimalString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }
}
