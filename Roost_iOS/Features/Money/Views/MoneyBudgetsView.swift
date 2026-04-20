import SwiftUI

// MARK: - MoneyBudgetsView

struct MoneyBudgetsView: View {

    @Environment(HomeManager.self) private var homeManager
    @Environment(ExpensesViewModel.self) private var expensesVM
    @Environment(BudgetViewModel.self) private var monthlyBudgetVM
    @Environment(BudgetTemplateViewModel.self) private var budgetVM
    @Environment(MonthlyMoneyViewModel.self) private var summaryVM
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(MemberNamesHelper.self) private var memberNames
    @Environment(ScrambleModeEnvironment.self) private var scramble

    // Edit + view mode
    @State private var editMode = false
    @State private var showSplit = false

    // Section collapse (persisted to UserDefaults)
    @State private var collapsedSections: Set<String> = []

    // Inline editing
    @State private var editingAmountId: UUID? = nil
    @State private var editingNameId: UUID? = nil

    // Split slider debounce
    @State private var sliderDebounceTasks: [UUID: Task<Void, Never>] = [:]

    // Inline add
    @State private var inlineAddSection: String? = nil
    @State private var inlineAddName = ""
    @State private var inlineAddAmount = ""
    @State private var inlineAddDay: Int = 1
    @State private var inlineAddSaving = false

    // Note editor
    @State private var showNoteEditor = false
    @State private var noteTarget: BudgetTemplateLine? = nil
    @State private var editingNoteText = ""

    // Remove
    @State private var removeTarget: BudgetTemplateLine? = nil
    @State private var showBreakdown = false

    // MARK: - Derived

    private var sym: String { settingsVM.settings.currencySymbol }
    private var isFreeTier: Bool { !(homeManager.home?.hasProAccess ?? false) }
    private var currentMonth: Date { summaryVM.selectedMonth }
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
    }

    private var thisMonthExpenses: [Expense] {
        let cal = Calendar.current
        return expensesVM.expenses
            .filter { ews in
                guard let d = ews.incurredOnDate else { return false }
                return cal.isDate(d, equalTo: currentMonth, toGranularity: .month)
            }
            .map(\.expense)
    }

    private var historicalBudgets: [Budget] {
        monthlyBudgetVM.budgetRows(in: currentMonth)
    }

    private var income: Decimal { summaryVM.summary?.income ?? 0 }
    private var totalBudgeted: Decimal {
        if isCurrentMonth { return budgetVM.totalBudgeted }
        return historicalBudgets.reduce(0) { $0 + $1.amount }
    }
    private var unallocated: Decimal { income - totalBudgeted }
    private var actualSpend: Decimal { summaryVM.summary?.actualSpend ?? 0 }
    private var spentPct: Double {
        guard totalBudgeted > 0 else { return 0 }
        return NSDecimalNumber(decimal: actualSpend / totalBudgeted).doubleValue * 100
    }
    private var healthScore: Int {
        guard isCurrentMonth else {
            guard totalBudgeted > 0 else { return 0 }
            if actualSpend <= totalBudgeted { return 82 }
            let overspendRatio = NSDecimalNumber(decimal: (actualSpend - totalBudgeted) / totalBudgeted).doubleValue
            return max(20, 72 - Int(overspendRatio * 100))
        }
        return budgetVM.calculateHealthScore(income: income, hasGoals: false)
    }
    private var healthRating: String {
        switch healthScore {
        case 80...100: return "Healthy"
        case 60..<80:  return "Good"
        case 40..<60:  return "Fair"
        default:       return "Needs work"
        }
    }
    private var healthColour: Color {
        switch healthScore {
        case 80...100: return Color.roostSuccess
        case 60..<80:  return Color.roostSecondary
        case 40..<60:  return Color.roostWarning
        default:       return Color.roostDestructive
        }
    }
    private var unallocatedColour: Color {
        if unallocated > 50 { return Color.roostSuccess }
        if unallocated >= 0 { return Color.roostWarning }
        return Color.roostDestructive
    }

    // Income allocation bar segments
    private struct AllocationSegment: Identifiable {
        let id = UUID()
        let label: String
        let shortLabel: String
        let colour: Color
        let amount: Decimal
        let pct: Double
    }

    private var allocationSegments: [AllocationSegment] {
        guard income > 0 else { return [] }
        var result: [AllocationSegment] = []
        for section in BudgetSectionDef.all {
            let total = budgetVM.activeLines
                .filter { $0.sectionGroup == section.id }
                .reduce(Decimal(0)) { $0 + $1.displayAmount }
            guard total > 0 else { continue }
            let pct = NSDecimalNumber(decimal: total / income).doubleValue * 100
            result.append(AllocationSegment(
                label: section.label,
                shortLabel: section.label.components(separatedBy: " ").first ?? section.label,
                colour: section.allocationColour,
                amount: total,
                pct: pct
            ))
        }
        if unallocated > 0 {
            let pct = NSDecimalNumber(decimal: unallocated / income).doubleValue * 100
            result.append(AllocationSegment(
                label: "Unallocated",
                shortLabel: "Free",
                colour: Color.roostForeground.opacity(0.15),
                amount: unallocated,
                pct: pct
            ))
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    FigmaBackHeader(title: "Budgets", accent: .roostMoneyTint) {
                        if isCurrentMonth {
                            Button {
                                let entering = !editMode
                                if entering {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } else {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    editMode.toggle()
                                    if !editMode {
                                        editingAmountId = nil
                                        editingNameId = nil
                                    }
                                }
                            } label: {
                                if editMode {
                                    Text("Done")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.roostPrimary)
                                } else {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.roostForeground)
                                        .padding(8)
                                        .background(Color.roostMuted.opacity(0.65), in: Circle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.page)

                    VStack(alignment: .leading, spacing: 14) {
                        controlRow

                        summaryCardsSection

                        if showBreakdown && isCurrentMonth && income > 0 && !budgetVM.activeLines.isEmpty {
                            incomeAllocationBar(scrollProxy: scrollProxy)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .padding(.top, 18)

                    // Budget table
                    if isCurrentMonth {
                        if budgetVM.activeLines.isEmpty && !budgetVM.isLoading && !editMode {
                            emptyState
                                .padding(.horizontal, DesignSystem.Spacing.page)
                                .padding(.top, Spacing.xxl)
                        } else {
                            budgetTable(scrollProxy: scrollProxy)
                                .padding(.top, Spacing.lg)
                                .padding(.horizontal, DesignSystem.Spacing.page)
                        }
                    } else if historicalBudgets.isEmpty {
                        historicalEmptyState
                            .padding(.horizontal, DesignSystem.Spacing.page)
                            .padding(.top, Spacing.xl)
                    } else {
                        historicalBudgetTable
                            .padding(.top, Spacing.lg)
                            .padding(.horizontal, DesignSystem.Spacing.page)
                    }

                    Spacer(minLength: DesignSystem.Size.tabBarHeight + DesignSystem.Spacing.screenBottom + 18)
                }
            }
            .background(Color.roostBackground.ignoresSafeArea())
        }
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task(id: homeManager.homeId) {
            guard let homeId = homeManager.homeId else { return }
            async let summary: Void = summaryVM.loadSummary(homeId: homeId)
            async let monthlyBudgets: Void = monthlyBudgetVM.load(homeId: homeId)
            async let carryForward: Void = checkCarryForward(homeId: homeId)
            _ = await (summary, monthlyBudgets, carryForward)
        }
        .onAppear {
            loadCollapsedSections()
        }
        .sheet(isPresented: $showNoteEditor) {
            if let target = noteTarget {
                NoteEditorSheet(
                    lineName: target.name,
                    initialNote: editingNoteText
                ) { note in
                    Task {
                        try? await budgetVM.updateLine(
                            id: target.id,
                            updates: UpdateBudgetLine(note: note.isEmpty ? nil : note)
                        )
                    }
                }
            }
        }
        .confirmationDialog(
            "Remove \(removeTarget?.name ?? "")?",
            isPresented: Binding(
                get: { removeTarget != nil },
                set: { if !$0 { removeTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove from budget", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                if let t = removeTarget {
                    Task { try? await budgetVM.removeLine(id: t.id) }
                    removeTarget = nil
                }
            }
            Button("Cancel", role: .cancel) { removeTarget = nil }
        } message: {
            Text("This removes it from your budget permanently.")
        }
    }
}

// MARK: - Summary cards

private extension MoneyBudgetsView {

    var summaryCardsSection: some View {
        RoostCard(prominence: .hero(accent: .roostMoneyTint)) {
            VStack(alignment: .leading, spacing: 14) {

                // Eyebrow + health pill
                HStack(alignment: .center) {
                    Text("BUDGETS")
                        .font(.roostMeta)
                        .tracking(1.2)
                        .foregroundStyle(Color.roostMoneyTint)
                    Spacer()
                    Text("\(healthRating)  \(healthScore)/100")
                        .font(.roostMeta)
                        .foregroundStyle(healthColour)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(healthColour.opacity(0.14), in: Capsule())
                        .overlay(Capsule().stroke(healthColour.opacity(0.22), lineWidth: 1))
                }

                // Hero figure — total budgeted
                Text(scramble.format(totalBudgeted, symbol: sym))
                    .font(.roostHero)
                    .foregroundStyle(Color.roostMoneyTint)
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                // Stat chips
                HStack(spacing: 6) {
                    budgetStatChip(
                        label: "INCOME",
                        value: income > 0 ? scramble.format(income, symbol: sym) : "Not set",
                        tint: income > 0 ? Color.roostMoneyTint : Color.roostPrimary
                    )
                    budgetStatChip(
                        label: "SPENT",
                        value: scramble.format(actualSpend, symbol: sym),
                        tint: spentPct > 100 ? Color.roostDestructive : spentPct >= 80 ? Color.roostWarning : Color.roostForeground
                    )
                    budgetStatChip(
                        label: "FREE",
                        value: scramble.format(unallocated, symbol: sym),
                        tint: unallocatedColour
                    )
                }

                // Progress bar
                if totalBudgeted > 0 {
                    let progress = min(spentPct / 100.0, 1.0)
                    let barColour: Color = spentPct > 100 ? .roostDestructive : spentPct >= 80 ? .roostWarning : .roostSuccess
                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.roostMuted.opacity(0.55))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(barColour)
                                    .frame(width: geo.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("\(Int(spentPct))% of budget spent")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                            Spacer()
                            if isCurrentMonth && income > 0 && !budgetVM.activeLines.isEmpty {
                                Button {
                                    withAnimation(.roostSnappy) { showBreakdown.toggle() }
                                } label: {
                                    HStack(spacing: 3) {
                                        Text(showBreakdown ? "Hide" : "Breakdown")
                                            .font(.roostCaption)
                                            .foregroundStyle(Color.roostMoneyTint)
                                        Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(Color.roostMoneyTint)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    func budgetStatChip(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
            Text(value)
                .font(.roostLabel)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Income allocation bar

private extension MoneyBudgetsView {

    func incomeAllocationBar(scrollProxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let segments = allocationSegments
            if !segments.isEmpty {
                // Stacked bar
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ForEach(segments) { seg in
                            let width = geo.size.width * (seg.pct / 100.0)
                            Rectangle()
                                .fill(seg.colour)
                                .frame(width: max(width, 0))
                        }
                    }
                }
                .frame(height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                // Legend chips — tap to scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(segments) { seg in
                            Button {
                                withAnimation {
                                    // Find matching section and scroll to it
                                    let matchingSection = BudgetSectionDef.all.first {
                                        $0.label == seg.label || $0.label.hasPrefix(seg.shortLabel)
                                    }
                                    if let sec = matchingSection {
                                        scrollProxy.scrollTo("section-\(sec.id)", anchor: .top)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(seg.colour)
                                        .frame(width: 6, height: 6)
                                    Text("\(seg.label) \(Int(seg.pct))%")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Color.roostMutedForeground)
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 24)
                                .background(seg.colour.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(seg.colour.opacity(0.22), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(12)
        .moneyBudgetPanel()
    }
}

// MARK: - Control row (month navigator + view mode)

private extension MoneyBudgetsView {

    var controlRow: some View {
        HStack(spacing: 10) {
            MonthNavigator(
                label: monthLabel,
                onPrevious: { navigateBudgetMonth(direction: -1) },
                onNext: { navigateBudgetMonth(direction: 1) },
                canGoNext: !isCurrentMonth,
                isPro: true,
                onProGate: {}
            )
            Spacer(minLength: 0)
            if isCurrentMonth {
                BudgetViewPicker(showSplit: $showSplit)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .moneyBudgetPanel()
    }

    func navigateBudgetMonth(direction: Int) {
        summaryVM.navigateMonth(direction: direction)
        let targetMonth = summaryVM.selectedMonth
        if !Calendar.current.isDate(targetMonth, equalTo: Date(), toGranularity: .month) {
            editMode = false
            editingAmountId = nil
            editingNameId = nil
        }
        Task {
            guard let homeId = homeManager.homeId else { return }
            async let summary: Void = summaryVM.loadSummary(homeId: homeId)
            async let rollover: Void = budgetVM.loadRolloverHistory(homeId: homeId, month: targetMonth)
            async let monthlyBudgets: Void = monthlyBudgetVM.load(homeId: homeId)
            _ = await (summary, rollover, monthlyBudgets)
        }
    }

    var monthLabel: String {
        if isCurrentMonth { return "This month" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: currentMonth)
    }
}

// MARK: - Budget table

private extension MoneyBudgetsView {

    var historicalBudgetTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SAVED MONTH")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1.0)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(monthLabel)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                }

                Spacer()

                Text(scramble.format(totalBudgeted, symbol: sym))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color.roostMuted.opacity(0.22))

            historicalColumnHeader

            ForEach(historicalBudgets) { budget in
                historicalBudgetRow(budget)
            }

            historicalTotalRow
        }
        .moneyBudgetPanel()
    }

    var historicalColumnHeader: some View {
        HStack(spacing: 0) {
            Text("CATEGORY")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("BUDGETED")
                .frame(width: 78, alignment: .trailing)
            Text("REMAINING")
                .frame(width: 78, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .medium))
        .tracking(1.0)
        .foregroundStyle(Color.roostMutedForeground)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.roostMuted.opacity(0.24))
        .overlay(moneyHairline, alignment: .bottom)
    }

    func historicalBudgetRow(_ budget: Budget) -> some View {
        let spent = historicalSpent(for: budget.category)
        let remaining = budget.amount - spent

        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(budget.category)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                if spent > 0 {
                    Text("\(scramble.format(spent, symbol: sym)) spent")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.roostMutedForeground)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(scramble.format(budget.amount, symbol: sym))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.roostForeground)
                .frame(width: 78, alignment: .trailing)

            Text(scramble.format(remaining, symbol: sym))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(remaining >= 0 ? Color.roostSuccess : Color.roostDestructive)
                .frame(width: 78, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(moneyHairline, alignment: .bottom)
    }

    var historicalTotalRow: some View {
        let spent = historicalBudgets.reduce(Decimal(0)) { $0 + historicalSpent(for: $1.category) }
        let remaining = totalBudgeted - spent

        return HStack(spacing: 0) {
            Text("Month total")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roostForeground)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(scramble.format(totalBudgeted, symbol: sym))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roostForeground)
                .frame(width: 78, alignment: .trailing)

            Text(scramble.format(remaining, symbol: sym))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(remaining >= 0 ? Color.roostSuccess : Color.roostDestructive)
                .frame(width: 78, alignment: .trailing)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .background(Color.roostMuted.opacity(0.30))
    }

    func historicalSpent(for category: String) -> Decimal {
        thisMonthExpenses
            .filter { ($0.category ?? "Other").caseInsensitiveCompare(category) == .orderedSame }
            .reduce(0) { $0 + $1.amount }
    }

    func budgetTable(scrollProxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(BudgetSectionDef.all) { section in
                let lines = budgetVM.activeLines
                    .filter { $0.sectionGroup == section.id }
                    .sorted { $0.sortOrder < $1.sortOrder }

                // In read mode, hide empty sections
                if editMode || !lines.isEmpty {
                    sectionGroup(section: section, lines: lines)
                        .id("section-\(section.id)")
                }
            }

            // Grand total row
            if !budgetVM.activeLines.isEmpty {
                grandTotalRow
            }
        }
    }

    // MARK: Section group

    @ViewBuilder
    func sectionGroup(section: BudgetSectionDef, lines: [BudgetTemplateLine]) -> some View {
        let collapsed = collapsedSections.contains(section.id)

        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.roostSnappy) {
                    if collapsed {
                        collapsedSections.remove(section.id)
                        UserDefaults.standard.set(true, forKey: "roost-budget-section-\(section.id)")
                    } else {
                        collapsedSections.insert(section.id)
                        UserDefaults.standard.set(false, forKey: "roost-budget-section-\(section.id)")
                    }
                }
            } label: {
                let sectionBudgeted = lines.reduce(Decimal(0)) { acc, line in
                    acc + budgetVM.getEffectiveAmount(lineId: line.id, month: currentMonth)
                }
                HStack(spacing: 10) {
                    // Colored icon circle
                    RoostIconContainer(
                        systemImage: section.sfSymbol,
                        tint: section.allocationColour,
                        size: .custom(30, iconSize: 14)
                    )

                    // Label + type badge
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.label)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.roostForeground)
                        Text(section.isFixed ? "Fixed" : "Lifestyle")
                            .font(.roostMeta)
                            .foregroundStyle(section.allocationColour)
                    }

                    Spacer()

                    // Section total (shown when collapsed or always)
                    if sectionBudgeted > 0 {
                        Text(scramble.format(sectionBudgeted, symbol: sym))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(section.allocationColour)
                    }

                    // Chevron
                    Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.roostMutedForeground)
                        .animation(.roostSnappy, value: collapsed)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(section.headerBgColour)
                .overlay(
                    Rectangle()
                        .fill(section.headerBorderColour)
                        .frame(width: 3),
                    alignment: .leading
                )
            }
            .buttonStyle(.plain)

            // Column header + rows (collapsed/expanded)
            if !collapsed {
                // Column header
                columnHeader(section: section)
                    .transition(.opacity)

                // Budget rows
                ForEach(lines) { line in
                    let spentAmount = budgetVM.getSpent(
                        category: line.name,
                        month: currentMonth,
                        expenses: thisMonthExpenses
                    )
                    let rolloverAmount = line.rolloverEnabled
                        ? (budgetVM.getRolloverAmount(lineId: line.id) ?? 0)
                        : Decimal(0)
                    let effectiveBudget = budgetVM.getEffectiveAmount(lineId: line.id, month: currentMonth)

                    if section.isFixed {
                        FixedBudgetRow(
                            line: line,
                            effectiveBudget: effectiveBudget,
                            showSplit: showSplit,
                            editMode: editMode,
                            isEditingAmount: editingAmountId == line.id,
                            isEditingName: editingNameId == line.id,
                            scramble: scramble,
                            sym: sym,
                            memberNames: memberNames.names,
                            onAmountTap: { editingAmountId = line.id; editingNameId = nil },
                            onNameTap: { editingNameId = line.id; editingAmountId = nil },
                            onAmountCommit: { val in
                                editingAmountId = nil
                                Task { try? await budgetVM.updateLine(id: line.id, updates: UpdateBudgetLine(amount: val)) }
                            },
                            onAmountCancel: { editingAmountId = nil },
                            onNameCommit: { val in
                                editingNameId = nil
                                Task { try? await budgetVM.updateLine(id: line.id, updates: UpdateBudgetLine(name: val)) }
                            },
                            onNameCancel: { editingNameId = nil },
                            onSplitCommit: { pct in
                                sliderDebounceTasks[line.id]?.cancel()
                                sliderDebounceTasks[line.id] = Task {
                                    try? await Task.sleep(for: .milliseconds(400))
                                    guard !Task.isCancelled else { return }
                                    try? await budgetVM.updateLine(id: line.id, updates: UpdateBudgetLine(member1Percentage: Decimal(pct)))
                                }
                            },
                            onRemove: { removeTarget = line },
                            onNote: { editingNoteText = line.note ?? ""; noteTarget = line; showNoteEditor = true }
                        )
                    } else {
                        LifestyleBudgetRow(
                            line: line,
                            spentAmount: spentAmount,
                            effectiveBudget: effectiveBudget,
                            rolloverAmount: rolloverAmount,
                            showSplit: showSplit,
                            editMode: editMode,
                            isEditingAmount: editingAmountId == line.id,
                            isEditingName: editingNameId == line.id,
                            scramble: scramble,
                            sym: sym,
                            memberNames: memberNames.names,
                            onAmountTap: { editingAmountId = line.id; editingNameId = nil },
                            onNameTap: { editingNameId = line.id; editingAmountId = nil },
                            onAmountCommit: { val in
                                editingAmountId = nil
                                Task { try? await budgetVM.updateLine(id: line.id, updates: UpdateBudgetLine(amount: val)) }
                            },
                            onAmountCancel: { editingAmountId = nil },
                            onNameCommit: { val in
                                editingNameId = nil
                                Task { try? await budgetVM.updateLine(id: line.id, updates: UpdateBudgetLine(name: val)) }
                            },
                            onNameCancel: { editingNameId = nil },
                            onSplitCommit: { pct in
                                sliderDebounceTasks[line.id]?.cancel()
                                sliderDebounceTasks[line.id] = Task {
                                    try? await Task.sleep(for: .milliseconds(400))
                                    guard !Task.isCancelled else { return }
                                    try? await budgetVM.updateLine(id: line.id, updates: UpdateBudgetLine(member1Percentage: Decimal(pct)))
                                }
                            },
                            onOwnershipChange: { ownership in
                                Task { try? await budgetVM.updateLine(id: line.id, updates: UpdateBudgetLine(ownership: ownership)) }
                            },
                            onRemove: { removeTarget = line },
                            onNote: { editingNoteText = line.note ?? ""; noteTarget = line; showNoteEditor = true }
                        )
                    }
                }

                // Add row or inline add form (edit mode only)
                if editMode {
                    if inlineAddSection == section.id {
                        inlineAddRow(section: section)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        addRow(section: section)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Section total
                sectionTotalRow(section: section, lines: lines)
                    .transition(.opacity)
            }
        }
        .moneyBudgetPanel()
    }

    // MARK: Column header

    func columnHeader(section: BudgetSectionDef) -> some View {
        HStack(spacing: 0) {
            Text("LINE ITEM")
                .frame(maxWidth: .infinity, alignment: .leading)
            if showSplit {
                Text(memberNames.names.me.uppercased())
                    .frame(width: 65, alignment: .trailing)
                Text(memberNames.names.partner.uppercased())
                    .frame(width: 65, alignment: .trailing)
            } else if section.isFixed {
                Text("DATE")
                    .frame(width: 52, alignment: .trailing)
                Text("BUDGETED")
                    .frame(width: 72, alignment: .trailing)
            } else {
                Text("BUDGETED")
                    .frame(width: 70, alignment: .trailing)
                Text("REMAINING")
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .font(.system(size: 9, weight: .medium))
        .tracking(1.0)
        .foregroundStyle(Color.roostMutedForeground)
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(Color.roostMuted.opacity(0.24))
        .overlay(moneyHairline, alignment: .bottom)
    }

    // MARK: Add row

    func addRow(section: BudgetSectionDef) -> some View {
        Button {
            inlineAddName = ""
            inlineAddAmount = ""
            inlineAddDay = 1
            inlineAddSaving = false
            withAnimation(.roostSnappy) { inlineAddSection = section.id }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(section.allocationColour)
                Text("Add \(section.isFixed ? "fixed cost" : section.label.lowercased() + " line")")
                    .font(.roostLabel)
                    .foregroundStyle(section.allocationColour)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundStyle(section.allocationColour.opacity(0.35))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
        )
    }

    // MARK: Inline add form

    @ViewBuilder
    func inlineAddRow(section: BudgetSectionDef) -> some View {
        let canSave = !inlineAddName.trimmingCharacters(in: .whitespaces).isEmpty && !inlineAddAmount.isEmpty && !inlineAddSaving

        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {

                // Row 1: name field
                VStack(alignment: .leading, spacing: 4) {
                    Text("NAME")
                        .font(.roostMeta)
                        .tracking(0.8)
                        .foregroundStyle(Color.roostMutedForeground)
                    TextField("e.g. \(section.suggestions.first ?? "Line item")", text: $inlineAddName)
                        .font(.roostBody)
                        .foregroundStyle(Color.roostForeground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(Color.roostMuted.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(inlineAddName.isEmpty ? Color.clear : section.allocationColour.opacity(0.4), lineWidth: 1)
                        )
                }

                // Row 2: amount + (fixed: day of month)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AMOUNT")
                            .font(.roostMeta)
                            .tracking(0.8)
                            .foregroundStyle(Color.roostMutedForeground)
                        HStack(spacing: 4) {
                            Text(sym)
                                .font(.roostBody)
                                .foregroundStyle(Color.roostMutedForeground)
                            TextField("0.00", text: $inlineAddAmount)
                                .keyboardType(.decimalPad)
                                .font(.roostBody)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button {
                                            UIApplication.shared.sendAction(
                                                #selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil
                                            )
                                        } label: {
                                            Text("Done")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 6)
                                                .background(section.allocationColour, in: Capsule())
                                        }
                                    }
                                }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(Color.roostMuted.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(inlineAddAmount.isEmpty ? Color.clear : section.allocationColour.opacity(0.4), lineWidth: 1)
                        )
                    }

                    if section.isFixed {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DAY")
                                .font(.roostMeta)
                                .tracking(0.8)
                                .foregroundStyle(Color.roostMutedForeground)
                            HStack(spacing: 0) {
                                Button {
                                    if inlineAddDay > 1 { inlineAddDay -= 1 }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(inlineAddDay > 1 ? Color.roostForeground : Color.roostMutedForeground)
                                        .frame(width: 36, height: 38)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Text(ordinal(inlineAddDay))
                                    .font(.roostLabel)
                                    .foregroundStyle(Color.roostForeground)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Button {
                                    if inlineAddDay < 31 { inlineAddDay += 1 }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(inlineAddDay < 31 ? Color.roostForeground : Color.roostMutedForeground)
                                        .frame(width: 36, height: 38)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .background(Color.roostMuted.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.roostHairline, lineWidth: 1))
                        }
                        .frame(width: 130)
                    }
                }

                // Row 3: save / cancel buttons
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.roostSnappy) { inlineAddSection = nil }
                    } label: {
                        Text("Cancel")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.roostMuted.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        commitInlineAdd(section: section)
                    } label: {
                        if inlineAddSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        } else {
                            Text("Save")
                                .font(.roostLabel)
                                .foregroundStyle(canSave ? Color.white : Color.roostMutedForeground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(canSave ? section.allocationColour : Color.roostMuted.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(section.allocationColour.opacity(0.05))

            BudgetHairline()
        }
    }

    private func commitInlineAdd(section: BudgetSectionDef) {
        let name = inlineAddName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let amount = Decimal(string: inlineAddAmount), amount > 0 else { return }
        inlineAddSaving = true
        let day = section.isFixed ? inlineAddDay : nil
        let line = CreateBudgetLine(
            homeId: homeManager.homeId ?? UUID(),
            name: name,
            amount: amount,
            budgetType: section.isFixed ? "fixed" : "envelope",
            sectionGroup: section.id,
            dayOfMonth: day,
            isAnnual: false,
            annualAmount: nil,
            rolloverEnabled: !section.isFixed,
            ownership: "shared",
            member1Percentage: 50,
            note: nil,
            sortOrder: 0,
            isActive: true
        )
        Task {
            try? await budgetVM.addLine(line)
            await MainActor.run {
                inlineAddSaving = false
                withAnimation(.roostSnappy) { inlineAddSection = nil }
            }
        }
    }

    // MARK: Section total

    func sectionTotalRow(section: BudgetSectionDef, lines: [BudgetTemplateLine]) -> some View {
        let expenses = thisMonthExpenses
        let totalBudgetedSection = lines.reduce(Decimal(0)) { acc, line in
            acc + budgetVM.getEffectiveAmount(lineId: line.id, month: currentMonth)
        }
        let totalSpentSection = lines.reduce(Decimal(0)) { acc, line in
            acc + budgetVM.getSpent(category: line.name, month: currentMonth, expenses: expenses)
        }
        let totalRemainingSection = totalBudgetedSection - totalSpentSection
        let totalMe = lines.reduce(Decimal(0)) { acc, line in
            acc + line.displayAmount * line.member1Percentage / 100
        }
        let totalPartner = totalBudgetedSection - totalMe

        return HStack(spacing: 0) {
            Text("\(section.label) total")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.roostMutedForeground)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showSplit {
                Text(scramble.format(totalMe, symbol: sym))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(section.allocationColour)
                    .frame(width: 65, alignment: .trailing)
                Text(scramble.format(totalPartner, symbol: sym))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(section.allocationColour)
                    .frame(width: 65, alignment: .trailing)
            } else if section.isFixed {
                Text(scramble.format(totalBudgetedSection, symbol: sym))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(section.allocationColour)
                    .frame(width: 72, alignment: .trailing)
            } else {
                Text(scramble.format(totalBudgetedSection, symbol: sym))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(section.allocationColour)
                    .frame(width: 70, alignment: .trailing)
                Text(scramble.format(totalRemainingSection, symbol: sym))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(totalRemainingSection >= 0 ? Color.roostSuccess : Color.roostDestructive)
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.roostMuted.opacity(0.32))
        .overlay(moneyHairline, alignment: .top)
    }

    // MARK: Grand total

    var grandTotalRow: some View {
        let expenses = thisMonthExpenses
        let totalRemaining = budgetVM.activeLines.reduce(Decimal(0)) { acc, line in
            let eff = budgetVM.getEffectiveAmount(lineId: line.id, month: currentMonth)
            let spent = line.isLifestyle
                ? budgetVM.getSpent(category: line.name, month: currentMonth, expenses: expenses)
                : Decimal(0)
            return acc + (eff - spent)
        }
        let totalMe = budgetVM.activeLines.reduce(Decimal(0)) { acc, line in
            acc + line.displayAmount * line.member1Percentage / 100
        }
        let totalPartner = budgetVM.totalBudgeted - totalMe

        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("TOTAL BUDGETED")
                    .font(.roostMeta)
                    .tracking(0.8)
                    .foregroundStyle(Color.roostMutedForeground)
                Text(scramble.format(budgetVM.totalBudgeted, symbol: sym))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.roostForeground)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showSplit {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("ME")
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(scramble.format(totalMe, symbol: sym))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.roostForeground)
                }
                .frame(width: 65, alignment: .trailing)
                VStack(alignment: .trailing, spacing: 1) {
                    Text("PARTNER")
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(scramble.format(totalPartner, symbol: sym))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.roostForeground)
                }
                .frame(width: 65, alignment: .trailing)
            } else {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("REMAINING")
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(scramble.format(totalRemaining, symbol: sym))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(totalRemaining >= 0 ? Color.roostSuccess : Color.roostDestructive)
                }
                .frame(width: 80, alignment: .trailing)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .moneyBudgetPanel()
    }
}

// MARK: - Empty state & carry-forward

private extension MoneyBudgetsView {

    var emptyState: some View {
        RoostCard(prominence: .elevated) {
            VStack(spacing: 16) {
                RoostIconContainer(
                    systemImage: "list.bullet.rectangle.fill",
                    tint: .roostMoneyTint,
                    size: .custom(52, iconSize: 24)
                )
                VStack(spacing: 6) {
                    Text("Set up your budget")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                    Text("Add your fixed costs and lifestyle budgets. They carry forward every month automatically.")
                        .font(.roostBody)
                        .foregroundStyle(Color.roostMutedForeground)
                        .multilineTextAlignment(.center)
                }
                NavigationLink {
                    CreateBudgetView()
                } label: {
                    Text("Set up budget")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMoneyTint)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.roostMoneyTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.roostMoneyTint.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    var historicalEmptyState: some View {
        VStack(spacing: Spacing.sm) {
            Text("No budget saved")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.roostForeground)
            Text(monthLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roostMutedForeground)
            Text("This month has no budget records.")
                .font(.system(size: 12))
                .foregroundStyle(Color.roostMutedForeground)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .moneyBudgetPanel()
    }

}

// MARK: - Helpers & persistence

private extension MoneyBudgetsView {

    func loadCollapsedSections() {
        for section in BudgetSectionDef.all {
            let key = "roost-budget-section-\(section.id)"
            // If key doesn't exist, default expanded (not in collapsed set)
            if UserDefaults.standard.object(forKey: key) != nil {
                if UserDefaults.standard.bool(forKey: key) == false {
                    collapsedSections.insert(section.id)
                }
            }
        }
    }

    func checkCarryForward(homeId: UUID) async {
        let cal = Calendar.current
        guard let prevMonth = cal.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        let hasPrevRollover = budgetVM.rolloverHistory.contains {
            cal.isDate($0.month, equalTo: prevMonth, toGranularity: .month)
        }
        let hasCurrentRollover = budgetVM.rolloverHistory.contains {
            cal.isDate($0.month, equalTo: currentMonth, toGranularity: .month)
        }
        guard hasPrevRollover && !hasCurrentRollover else { return }

        if settingsVM.settings.budgetCarryForward == "auto" {
            await budgetVM.processMonthRollover(
                homeId: homeId,
                month: currentMonth,
                expenses: thisMonthExpenses
            )
        }
    }

    func compact(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }

    func ordinal(_ n: Int) -> String {
        switch n % 10 {
        case 1 where n != 11: return "\(n)st"
        case 2 where n != 12: return "\(n)nd"
        case 3 where n != 13: return "\(n)rd"
        default: return "\(n)th"
        }
    }

    var moneyHairline: some View {
        BudgetHairline()
    }
}

private struct BudgetHairline: View {
    var body: some View {
        Rectangle()
            .fill(Color.roostHairline)
            .frame(height: 1)
            .opacity(0.72)
    }
}

private extension View {
    func moneyBudgetPanel() -> some View {
        self
            .background(DesignSystem.Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DesignSystem.Palette.border, lineWidth: 1)
            )
    }
}

// MARK: - FixedBudgetRow

private struct FixedBudgetRow: View {

    let line: BudgetTemplateLine
    let effectiveBudget: Decimal
    let showSplit: Bool
    let editMode: Bool
    let isEditingAmount: Bool
    let isEditingName: Bool
    let scramble: ScrambleModeEnvironment
    let sym: String
    let memberNames: MemberNames

    var onAmountTap: () -> Void
    var onNameTap: () -> Void
    var onAmountCommit: (Decimal) -> Void
    var onAmountCancel: () -> Void
    var onNameCommit: (String) -> Void
    var onNameCancel: () -> Void
    var onSplitCommit: (Double) -> Void
    var onRemove: () -> Void
    var onNote: () -> Void

    @State private var amountText: String = ""
    @State private var nameText: String = ""
    @State private var sliderValue: Double = 50
    @FocusState private var amountFocused: Bool
    @FocusState private var nameFocused: Bool

    private var meAmount: Decimal {
        effectiveBudget * line.member1Percentage / 100
    }
    private var partnerAmount: Decimal {
        effectiveBudget - meAmount
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 0) {

                // Delete button (edit mode)
                if editMode {
                    Button { onRemove() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.roostDestructive)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                // Line item name
                Group {
                    if isEditingName {
                        TextField("", text: $nameText)
                            .font(.system(size: 13))
                            .focused($nameFocused)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(DesignSystem.Palette.card)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.roostPrimary, lineWidth: 1.5)
                            )
                            .onSubmit { commitName() }
                            .onAppear { nameText = line.name; nameFocused = true }
                    } else {
                        HStack(spacing: 5) {
                            Text(line.name)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.roostForeground)
                                .lineLimit(1)
                                .onTapGesture { if editMode { onNameTap() } }
                            if line.note != nil {
                                Circle()
                                    .fill(Color.roostSecondary)
                                    .frame(width: 5, height: 5)
                            }
                            if line.ownership == "member1" {
                                avatarCircle(initials: memberNames.meInitials, colour: memberNames.meColour)
                            } else if line.ownership == "member2" {
                                avatarCircle(initials: memberNames.partnerInitials, colour: memberNames.partnerColour)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showSplit {
                    Text(scramble.format(meAmount, symbol: sym))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 65, alignment: .trailing)
                    Text(scramble.format(partnerAmount, symbol: sym))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 65, alignment: .trailing)
                } else {
                    // DATE column — styled as a compact chip
                    Group {
                        if let day = line.dayOfMonth {
                            Text(ordinal(day))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.roostMutedForeground)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.roostMuted.opacity(0.6), in: Capsule())
                        } else {
                            Text("—")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                    }
                    .frame(width: 52, alignment: .trailing)

                    // BUDGETED column
                    if isEditingAmount {
                        HStack(spacing: 2) {
                            Text(sym)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.roostMutedForeground)
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 12))
                                .multilineTextAlignment(.trailing)
                                .focused($amountFocused)
                                .onSubmit { commitAmount() }
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button { commitAmount() } label: {
                                            Text("Done")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 6)
                                                .background(Color.roostPrimary, in: Capsule())
                                        }
                                    }
                                }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)
                        .background(DesignSystem.Palette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.roostPrimary, lineWidth: 1.5))
                        .frame(width: 72)
                        .onAppear {
                            amountText = formatDecimal(line.amount)
                            amountFocused = true
                        }
                    } else {
                        Button {
                            if editMode { onAmountTap() }
                        } label: {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(scramble.format(effectiveBudget, symbol: sym))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.roostForeground)
                                if line.isAnnual, let annual = line.annualAmount {
                                    Text(scramble.format(annual, symbol: sym) + "/yr")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color.roostMutedForeground)
                                }
                                // Month comparison indicator
                                if let last = line.lastAmount,
                                   let changedAt = line.amountChangedAt,
                                   last != line.amount,
                                   changedAt > Date().addingTimeInterval(-60 * 24 * 3600) {
                                    HStack(spacing: 2) {
                                        Image(systemName: line.amount > last ? "arrow.up" : "arrow.down")
                                            .font(.system(size: 8))
                                        Text(scramble.format(abs(line.amount - last), symbol: ""))
                                            .font(.system(size: 9))
                                    }
                                    .foregroundStyle(line.amount > last
                                        ? Color.roostWarning
                                        : Color.roostSuccess)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 72, alignment: .trailing)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)

            // Split slider — only when actively editing this row's amount or name
            if (isEditingAmount || isEditingName) && line.ownership == "shared" && memberNames.hasPartner {
                SplitSliderRow(
                    initialValue: NSDecimalNumber(decimal: line.member1Percentage).doubleValue,
                    meInitials: memberNames.meInitials,
                    meColour: memberNames.meColour,
                    partnerInitials: memberNames.partnerInitials,
                    partnerColour: memberNames.partnerColour,
                    meName: memberNames.me,
                    partnerName: memberNames.partner,
                    onCommit: onSplitCommit
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Separator
            BudgetHairline()
                .padding(.leading, 12)
        }
        .background(Color.clear)
    }

    private func commitAmount() {
        let parsed = Decimal(string: amountText.trimmingCharacters(in: .whitespaces)) ?? 0
        if parsed > 0 {
            onAmountCommit(parsed)
        } else {
            onAmountCancel()
        }
    }

    private func commitName() {
        let trimmed = nameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && trimmed != line.name {
            onNameCommit(trimmed)
        } else {
            onNameCancel()
        }
    }

    private func ordinal(_ n: Int) -> String {
        switch n % 10 {
        case 1 where n != 11: return "\(n)st"
        case 2 where n != 12: return "\(n)nd"
        case 3 where n != 13: return "\(n)rd"
        default: return "\(n)th"
        }
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        return fmt.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    private func avatarCircle(initials: String, colour: Color) -> some View {
        ZStack {
            Circle().fill(colour)
            Text(initials)
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 16, height: 16)
    }
}

// MARK: - LifestyleBudgetRow

private struct LifestyleBudgetRow: View {

    let line: BudgetTemplateLine
    let spentAmount: Decimal
    let effectiveBudget: Decimal
    let rolloverAmount: Decimal
    let showSplit: Bool
    let editMode: Bool
    let isEditingAmount: Bool
    let isEditingName: Bool
    let scramble: ScrambleModeEnvironment
    let sym: String
    let memberNames: MemberNames

    var onAmountTap: () -> Void
    var onNameTap: () -> Void
    var onAmountCommit: (Decimal) -> Void
    var onAmountCancel: () -> Void
    var onNameCommit: (String) -> Void
    var onNameCancel: () -> Void
    var onSplitCommit: (Double) -> Void
    var onOwnershipChange: (String) -> Void
    var onRemove: () -> Void
    var onNote: () -> Void

    @State private var amountText: String = ""
    @State private var nameText: String = ""
    @FocusState private var amountFocused: Bool
    @FocusState private var nameFocused: Bool

    private var remaining: Decimal { effectiveBudget - spentAmount }
    private var fillRatio: Double {
        guard effectiveBudget > 0 else { return spentAmount > 0 ? 1 : 0 }
        return min(NSDecimalNumber(decimal: spentAmount / effectiveBudget).doubleValue, 1)
    }
    private var barColour: Color {
        let spent = NSDecimalNumber(decimal: spentAmount).doubleValue
        let budget = NSDecimalNumber(decimal: effectiveBudget).doubleValue
        if budget <= 0 { return Color.roostSuccess }
        let pct = (spent / budget) * 100
        if pct > 100 { return Color.roostDestructive }
        if pct >= 80 { return Color.roostWarning }
        return Color.roostSuccess
    }
    private var remainingColour: Color {
        if remaining < 0 { return Color.roostDestructive }
        if effectiveBudget > 0, remaining / effectiveBudget <= 0.2 { return Color.roostWarning }
        return Color.roostSuccess
    }
    private var meAmount: Decimal {
        effectiveBudget * line.member1Percentage / 100
    }
    private var partnerAmount: Decimal {
        effectiveBudget - meAmount
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 0) {

                // Delete button (edit mode)
                if editMode {
                    Button { onRemove() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.roostDestructive)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                // Line item name
                Group {
                    if isEditingName {
                        TextField("", text: $nameText)
                            .font(.system(size: 13))
                            .focused($nameFocused)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(DesignSystem.Palette.card)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.roostPrimary, lineWidth: 1.5))
                            .onSubmit { commitName() }
                            .onAppear { nameText = line.name; nameFocused = true }
                    } else {
                        HStack(spacing: 5) {
                            Text(line.name)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.roostForeground)
                                .lineLimit(1)
                                .onTapGesture { if editMode { onNameTap() } }
                            if line.note != nil {
                                Circle().fill(Color(hex: 0x9DB19F)).frame(width: 5, height: 5)
                            }
                            if line.ownership == "member1" {
                                avatarCircle(initials: memberNames.meInitials, colour: memberNames.meColour)
                            } else if line.ownership == "member2" {
                                avatarCircle(initials: memberNames.partnerInitials, colour: memberNames.partnerColour)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showSplit {
                    Text(scramble.format(meAmount, symbol: sym))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 65, alignment: .trailing)
                    Text(scramble.format(partnerAmount, symbol: sym))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 65, alignment: .trailing)
                } else {
                    // BUDGETED column
                    if isEditingAmount {
                        HStack(spacing: 2) {
                            Text(sym)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.roostMutedForeground)
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 12))
                                .multilineTextAlignment(.trailing)
                                .focused($amountFocused)
                                .onSubmit { commitAmount() }
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button { commitAmount() } label: {
                                            Text("Done")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 6)
                                                .background(Color.roostPrimary, in: Capsule())
                                        }
                                    }
                                }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)
                        .background(DesignSystem.Palette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.roostPrimary, lineWidth: 1.5))
                        .frame(width: 70)
                        .onAppear {
                            amountText = formatDecimal(line.amount)
                            amountFocused = true
                        }
                    } else {
                        Button {
                            if editMode { onAmountTap() }
                        } label: {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(scramble.format(effectiveBudget, symbol: sym))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.roostForeground)
                                if rolloverAmount != 0 {
                                    Text((rolloverAmount > 0 ? "+" : "") + scramble.format(rolloverAmount, symbol: sym) + " rollover")
                                        .font(.system(size: 9))
                                        .foregroundStyle(rolloverAmount > 0 ? Color.roostSuccess : Color.roostDestructive)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 70, alignment: .trailing)
                    }

                    // REMAINING column
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(scramble.format(remaining, symbol: sym))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(remainingColour)
                    }
                    .frame(width: 70, alignment: .trailing)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)

            // Progress bar (read mode, household view only)
            if !editMode && !showSplit {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.roostMuted.opacity(0.55))
                            .frame(height: 5)
                        Capsule()
                            .fill(barColour)
                            .frame(width: geo.size.width * fillRatio, height: 5)
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }

            // Edit mode: ownership pills
            if editMode {
                // Ownership pills
                HStack(spacing: 5) {
                    ForEach(["shared", "member1", "member2"], id: \.self) { opt in
                        let label: String = opt == "shared" ? "Shared"
                            : opt == "member1" ? memberNames.me
                            : memberNames.partner
                        let active = line.ownership == opt

                        Button {
                            onOwnershipChange(opt)
                        } label: {
                            Text(label)
                                .font(.system(size: 11))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(active ? Color.roostPrimary : Color.roostMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .foregroundStyle(active ? Color.roostCard : Color.roostForeground)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Split slider — only when actively editing this row's amount or name
            if (isEditingAmount || isEditingName) && line.ownership == "shared" && memberNames.hasPartner {
                SplitSliderRow(
                    initialValue: NSDecimalNumber(decimal: line.member1Percentage).doubleValue,
                    meInitials: memberNames.meInitials,
                    meColour: memberNames.meColour,
                    partnerInitials: memberNames.partnerInitials,
                    partnerColour: memberNames.partnerColour,
                    meName: memberNames.me,
                    partnerName: memberNames.partner,
                    onCommit: onSplitCommit
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Separator
            BudgetHairline().padding(.leading, 12)
        }
    }

    private func commitAmount() {
        let parsed = Decimal(string: amountText.trimmingCharacters(in: .whitespaces)) ?? 0
        if parsed > 0 { onAmountCommit(parsed) } else { onAmountCancel() }
    }

    private func commitName() {
        let trimmed = nameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && trimmed != line.name { onNameCommit(trimmed) } else { onNameCancel() }
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let fmt = NumberFormatter()
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        return fmt.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    private func avatarCircle(initials: String, colour: Color) -> some View {
        ZStack {
            Circle().fill(colour)
            Text(initials).font(.system(size: 7, weight: .semibold)).foregroundStyle(.white)
        }
        .frame(width: 16, height: 16)
    }
}

// MARK: - Split slider row

private struct SplitSliderRow: View {

    let initialValue: Double
    let meInitials: String
    let meColour: Color
    let partnerInitials: String
    let partnerColour: Color
    let meName: String
    let partnerName: String
    var onCommit: (Double) -> Void

    @State private var value: Double

    init(initialValue: Double, meInitials: String, meColour: Color,
         partnerInitials: String, partnerColour: Color, meName: String, partnerName: String,
         onCommit: @escaping (Double) -> Void) {
        self.initialValue = initialValue
        self.meInitials = meInitials
        self.meColour = meColour
        self.partnerInitials = partnerInitials
        self.partnerColour = partnerColour
        self.meName = meName
        self.partnerName = partnerName
        self.onCommit = onCommit
        _value = State(initialValue: initialValue)
    }

    private var labelText: String? {
        if value == 50 { return "Equal" }
        if value == 100 { return "\(meName) pays all" }
        if value == 0 { return "\(partnerName) pays all" }
        return nil
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                avatarCircle(initials: meInitials, colour: meColour)
                Text("\(Int(value))%")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 30, alignment: .trailing)
                splitTrack
                Text("\(Int(100 - value))%")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 30, alignment: .leading)
                avatarCircle(initials: partnerInitials, colour: partnerColour)
            }
            if let label = labelText {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.roostSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .onAppear { value = initialValue }
    }

    private var splitTrack: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let x = width * (value / 100)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.roostMuted.opacity(0.78))
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [meColour.opacity(0.9), partnerColour.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)

                Circle()
                    .fill(Color.roostCard)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.roostPrimary.opacity(0.7), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                    .offset(x: min(max(x - 9, 0), width - 18))
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let raw = min(max(gesture.location.x / width, 0), 1) * 100
                        value = (raw / 5).rounded() * 5
                        onCommit(value)
                    }
            )
        }
        .frame(height: 24)
    }

    private func avatarCircle(initials: String, colour: Color) -> some View {
        ZStack {
            Circle().fill(colour)
            Text(initials).font(.system(size: 7, weight: .semibold)).foregroundStyle(.white)
        }
        .frame(width: 20, height: 20)
    }
}

// MARK: - Note editor sheet

private struct NoteEditorSheet: View {
    let lineName: String
    let initialNote: String
    var onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(lineName: String, initialNote: String, onSave: @escaping (String) -> Void) {
        self.lineName = lineName
        self.initialNote = initialNote
        self.onSave = onSave
        _text = State(initialValue: initialNote)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(DesignSystem.Palette.muted.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .frame(height: 100)
                    .onChange(of: text) { _, v in
                        if v.count > 120 { text = String(v.prefix(120)) }
                    }
                Text("\(120 - text.count) characters left")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.roostMutedForeground)
                Spacer()
            }
            .padding(DesignSystem.Spacing.page)
            .background(Color.roostBackground.ignoresSafeArea())
            .navigationTitle("Note for \(lineName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.roostMutedForeground)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(text.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .foregroundStyle(Color.roostPrimary)
                }
            }
        }
    }
}
