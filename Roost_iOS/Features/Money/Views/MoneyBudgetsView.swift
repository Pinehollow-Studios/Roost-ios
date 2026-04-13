import SwiftUI

// MARK: - Section definition

private struct BudgetSectionDef: Identifiable {
    let id: String
    let label: String
    let isFixed: Bool

    var headerBorderColour: Color {
        isFixed ? Color(hex: 0xc75146) : Color(hex: 0x534ab7)
    }
    var headerBgColour: Color {
        isFixed ? Color(hex: 0xc75146).opacity(0.04) : Color(hex: 0x534ab7).opacity(0.04)
    }
    var allocationColour: Color {
        switch id {
        case "housing-bills":       return Color(hex: 0xc75146)
        case "subscriptions-leisure": return Color(hex: 0x854f0b)
        case "transport":           return Color(hex: 0x185fa5)
        case "food-drink":          return Color(hex: 0x3b6d11)
        case "household":           return Color(hex: 0x0f6e56)
        case "personal":            return Color(hex: 0x534ab7)
        case "savings":             return Color(hex: 0x993356)
        default:                    return Color.roostMutedForeground
        }
    }
    var suggestions: [String] {
        switch id {
        case "housing-bills":         return ["Rent", "Mortgage", "Council Tax", "Gas & Electricity", "Water", "Broadband", "Contents Insurance", "TV Licence"]
        case "subscriptions-leisure": return ["Netflix", "Spotify", "Disney+", "Amazon Prime", "Gym", "Game Pass", "iCloud", "Other subscriptions"]
        case "transport":             return ["Public transport", "Fuel", "Car insurance", "Parking", "Taxi/Uber", "Rail season ticket"]
        case "food-drink":            return ["Groceries", "Eating out", "Takeaways", "Coffee & cafés", "Work lunches"]
        case "household":             return ["Cleaning & toiletries", "Small home items", "Household repairs"]
        case "personal":              return ["Personal spending", "Clothing", "Haircuts", "Gifts", "Health & wellbeing"]
        case "savings":               return ["Emergency fund", "Holiday fund", "ISA savings", "Other savings"]
        default:                      return []
        }
    }
    static let all: [BudgetSectionDef] = [
        .init(id: "housing-bills",         label: "Housing & bills",         isFixed: true),
        .init(id: "subscriptions-leisure", label: "Subscriptions & leisure", isFixed: true),
        .init(id: "transport",             label: "Transport",                isFixed: true),
        .init(id: "food-drink",            label: "Food & drink",             isFixed: false),
        .init(id: "household",             label: "Household",                isFixed: false),
        .init(id: "personal",              label: "Personal",                 isFixed: false),
        .init(id: "savings",               label: "Savings allocation",       isFixed: false),
    ]
}

// MARK: - MoneyBudgetsView

struct MoneyBudgetsView: View {

    @Environment(HomeManager.self) private var homeManager
    @Environment(ExpensesViewModel.self) private var expensesVM
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

    // Add line sheet
    @State private var showAddSheet = false
    @State private var addSheetSection: BudgetSectionDef? = nil

    // Note editor
    @State private var showNoteEditor = false
    @State private var noteTarget: BudgetTemplateLine? = nil
    @State private var editingNoteText = ""

    // Remove
    @State private var removeTarget: BudgetTemplateLine? = nil

    // Bill clash dismissal
    @State private var dismissedClashIds: Set<UUID> = []

    // Carry-forward
    @State private var showCarryForwardPrompt = false

    // Pro upsell
    @State private var showHistoryUpsell = false

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

    private var income: Decimal { summaryVM.summary?.income ?? 0 }
    private var totalBudgeted: Decimal { budgetVM.totalBudgeted }
    private var unallocated: Decimal { income - totalBudgeted }
    private var actualSpend: Decimal { summaryVM.summary?.actualSpend ?? 0 }
    private var spentPct: Double {
        guard totalBudgeted > 0 else { return 0 }
        return NSDecimalNumber(decimal: actualSpend / totalBudgeted).doubleValue * 100
    }
    private var healthScore: Int {
        budgetVM.calculateHealthScore(income: income, hasGoals: false)
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
        case 80...100: return Color(hex: 0x3b6d11)
        case 60..<80:  return Color(hex: 0x3b6d11)
        case 40..<60:  return Color(hex: 0x854f0b)
        default:       return Color(hex: 0xa32d2d)
        }
    }
    private var unallocatedColour: Color {
        if unallocated > 50 { return Color(hex: 0x3b6d11) }
        if unallocated >= 0 { return Color(hex: 0x854f0b) }
        return Color(hex: 0xa32d2d)
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

                    FigmaBackHeader(title: "Budgets") {
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
                                    .background(Color(.systemFill))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.page)

                    // Edit mode banner
                    if editMode {
                        editingBanner
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Carry-forward prompt
                    if showCarryForwardPrompt {
                        carryForwardPromptCard
                            .padding(.horizontal, DesignSystem.Spacing.page)
                            .padding(.top, Spacing.md)
                    }

                    VStack(alignment: .leading, spacing: Spacing.lg) {

                        // Summary cards
                        summaryCardsSection

                        // Income allocation bar
                        if income > 0 && !budgetVM.activeLines.isEmpty {
                            incomeAllocationBar(scrollProxy: scrollProxy)
                        }

                        // Bill clash cards
                        let clashes = budgetVM.detectBillClashes().filter { !dismissedClashIds.contains($0.id) }
                        if !clashes.isEmpty {
                            billClashSection(clashes: clashes)
                        }

                        // Month navigator
                        monthNavigatorRow
                    }
                    .padding(.horizontal, DesignSystem.Spacing.page)

                    // Budget table
                    if budgetVM.activeLines.isEmpty && !budgetVM.isLoading {
                        emptyState
                            .padding(.horizontal, DesignSystem.Spacing.page)
                            .padding(.top, Spacing.xxl)
                    } else {
                        budgetTable(scrollProxy: scrollProxy)
                            .padding(.top, Spacing.lg)
                    }

                    Spacer(minLength: DesignSystem.Spacing.screenBottom)
                }
            }
            .background(Color.roostBackground.ignoresSafeArea())
        }
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task(id: homeManager.homeId) {
            guard let homeId = homeManager.homeId else { return }
            await summaryVM.loadSummary(homeId: homeId)
            await checkCarryForward(homeId: homeId)
        }
        .onAppear {
            loadCollapsedSections()
            loadDismissedClashes()
        }
        .sheet(isPresented: $showAddSheet) {
            if let section = addSheetSection {
                AddBudgetLineSheet(
                    sectionId: section.id,
                    sectionLabel: section.label,
                    isFixed: section.isFixed,
                    suggestions: section.suggestions,
                    currencySymbol: sym
                ) { line, _ in
                    try await budgetVM.addLine(line)
                }
            }
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
        .nestUpsell(isPresented: $showHistoryUpsell, feature: .budgetHistory)
    }
}

// MARK: - Edit mode banner

private extension MoneyBudgetsView {

    var editingBanner: some View {
        Text("Editing — changes save automatically")
            .font(.system(size: 11))
            .foregroundStyle(Color.roostMutedForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(hex: 0xFAEEDA))
    }
}

// MARK: - Summary cards

private extension MoneyBudgetsView {

    var summaryCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                metricCard(
                    label: "INCOME",
                    value: income > 0 ? scramble.format(income, symbol: sym) : "Not set",
                    valueColour: income > 0 ? Color.roostForeground : Color.roostPrimary,
                    subtext: memberNames.names.hasPartner
                        ? "\(memberNames.names.me) + \(memberNames.names.partner)"
                        : memberNames.names.me
                )
                metricCard(
                    label: "BUDGETED",
                    value: scramble.format(totalBudgeted, symbol: sym)
                )
                metricCard(
                    label: "UNALLOCATED",
                    value: scramble.format(unallocated, symbol: sym),
                    valueColour: unallocatedColour,
                    subtext: unallocated >= 0 ? "Available for savings" : "Over-allocated"
                )
                metricCard(
                    label: "SPENT SO FAR",
                    value: scramble.format(actualSpend, symbol: sym),
                    subtext: actualSpend > 0 ? "\(Int(spentPct))% of budget" : nil
                )
                metricCard(
                    label: "BUDGET HEALTH",
                    value: healthRating,
                    valueColour: healthColour,
                    subtext: "\(healthScore)/100"
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
        }
        .padding(.horizontal, -DesignSystem.Spacing.page)
    }

    func metricCard(label: String, value: String, valueColour: Color = Color.roostForeground, subtext: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Color.roostMutedForeground)
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(valueColour)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let sub = subtext {
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.roostMutedForeground)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(width: 130, alignment: .leading)
        .background(DesignSystem.Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DesignSystem.Palette.border, lineWidth: 1)
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
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.roostMutedForeground)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.systemFill))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Bill clashes

private extension MoneyBudgetsView {

    func billClashSection(clashes: [BillClash]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(clashes) { clash in
                billClashCard(clash: clash)
            }
        }
    }

    func billClashCard(clash: BillClash) -> some View {
        let names = clash.lines.prefix(2).map(\.name)
        let extra = clash.lines.count - 2
        let nameList = extra > 0
            ? names.joined(separator: ", ") + " and \(extra) more"
            : names.joined(separator: ", ")
        let text = "\(sym)\(compact(clash.totalAmount)) goes out between the \(ordinal(clash.earliestDay)) and \(ordinal(clash.latestDay)) — \(nameList)"

        return HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: 0xE6A563))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("×") {
                dismissedClashIds.insert(clash.id)
                persistDismissedClashes()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.roostMutedForeground)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(hex: 0xFAEEDA))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(hex: 0xE6A563).opacity(0.5), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Month navigator

private extension MoneyBudgetsView {

    var monthNavigatorRow: some View {
        HStack {
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
            Spacer()
            BudgetViewPicker(showSplit: $showSplit)
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

    func budgetTable(scrollProxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
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
            // Section header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if collapsed {
                        collapsedSections.remove(section.id)
                        UserDefaults.standard.set(true, forKey: "roost-budget-section-\(section.id)")
                    } else {
                        collapsedSections.insert(section.id)
                        UserDefaults.standard.set(false, forKey: "roost-budget-section-\(section.id)")
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.roostMutedForeground)
                        .animation(.easeInOut(duration: 0.2), value: collapsed)

                    Text(section.label)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.roostForeground)

                    Spacer()

                    // Type badge
                    Text(section.isFixed ? "Fixed" : "Lifestyle")
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(section.isFixed
                            ? Color(hex: 0xfaece7)
                            : Color(hex: 0xf0eafa))
                        .foregroundStyle(section.isFixed
                            ? Color(hex: 0x712b13)
                            : Color(hex: 0x3c3489))
                        .clipShape(Capsule())
                }
                .padding(.vertical, 10)
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

                // Add row (edit mode only)
                if editMode {
                    addRow(section: section)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Section total
                sectionTotalRow(section: section, lines: lines)
                    .transition(.opacity)
            }
        }
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
        .padding(.horizontal, 14)
        .background(Color(.systemBackground).opacity(0.6))
        .overlay(
            Rectangle()
                .fill(DesignSystem.Palette.border)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: Add row

    func addRow(section: BudgetSectionDef) -> some View {
        Button {
            addSheetSection = section
            showAddSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x9DB19F))
                Text("Add \(section.isFixed ? "fixed cost" : section.label.lowercased() + " line")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x9DB19F))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(
                    style: StrokeStyle(lineWidth: 0.5, dash: [4])
                )
                .foregroundStyle(Color(hex: 0x9DB19F).opacity(0.4))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
        )
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
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.roostMutedForeground)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showSplit {
                Text(scramble.format(totalMe, symbol: sym))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 65, alignment: .trailing)
                Text(scramble.format(totalPartner, symbol: sym))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 65, alignment: .trailing)
            } else if section.isFixed {
                Text(scramble.format(totalBudgetedSection, symbol: sym))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 72, alignment: .trailing)
            } else {
                Text(scramble.format(totalBudgetedSection, symbol: sym))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 70, alignment: .trailing)
                Text(scramble.format(totalRemainingSection, symbol: sym))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(totalRemainingSection >= 0
                        ? Color(hex: 0x3b6d11)
                        : Color(hex: 0xa32d2d))
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Color(.systemFill).opacity(0.5))
        .overlay(
            Rectangle()
                .fill(DesignSystem.Palette.border)
                .frame(height: 0.5),
            alignment: .top
        )
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
            Text("Total budgeted")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roostForeground)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showSplit {
                Text(scramble.format(totalMe, symbol: sym))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 65, alignment: .trailing)
                Text(scramble.format(totalPartner, symbol: sym))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 65, alignment: .trailing)
            } else {
                Text(scramble.format(budgetVM.totalBudgeted, symbol: sym))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 70, alignment: .trailing)
                Text(scramble.format(totalRemaining, symbol: sym))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(totalRemaining >= 0
                        ? Color(hex: 0x3b6d11)
                        : Color(hex: 0xa32d2d))
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Palette.border)
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Empty state & carry-forward

private extension MoneyBudgetsView {

    var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "list.bullet.rectangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.roostPrimary.opacity(0.4))
            Text("Set up your budget")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.roostForeground)
            Text("Add your fixed costs and lifestyle budgets. They carry forward every month automatically.")
                .font(.system(size: 14))
                .foregroundStyle(Color.roostMutedForeground)
                .multilineTextAlignment(.center)
            Button("Set up budget") {
                withAnimation(.easeInOut(duration: 0.25)) { editMode = true }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.roostPrimary)
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
    }

    var carryForwardPromptCard: some View {
        RoostCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Carry forward last month's budget?")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)
                Text("Your previous budget has rollover-enabled lines. Would you like to carry forward underspend?")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                HStack(spacing: Spacing.sm) {
                    Button("Yes, carry forward") {
                        showCarryForwardPrompt = false
                        Task {
                            guard let homeId = homeManager.homeId else { return }
                            await budgetVM.processMonthRollover(
                                homeId: homeId,
                                month: currentMonth,
                                expenses: thisMonthExpenses
                            )
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roostPrimary)

                    Button("Set up fresh") {
                        showCarryForwardPrompt = false
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Color.roostMutedForeground)
                }
            }
        }
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

    func loadDismissedClashes() {
        let ids = (UserDefaults.standard.array(forKey: "roost-dismissed-clashes") as? [String]) ?? []
        dismissedClashIds = Set(ids.compactMap { UUID(uuidString: $0) })
    }

    func persistDismissedClashes() {
        UserDefaults.standard.set(
            Array(dismissedClashIds.map(\.uuidString)),
            forKey: "roost-dismissed-clashes"
        )
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
        } else {
            showCarryForwardPrompt = true
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
                                    .fill(Color(hex: 0x9DB19F))
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
                    // DATE column
                    Text(line.dayOfMonth.map { ordinal($0) } ?? "—")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roostMutedForeground)
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
                                        ? Color(hex: 0x854f0b)
                                        : Color(hex: 0x3b6d11))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 72, alignment: .trailing)
                    }
                }
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 14)

            // Split slider (edit mode, shared ownership only)
            if editMode && line.ownership == "shared" && memberNames.hasPartner {
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
            Divider()
                .padding(.leading, 14)
        }
        .background(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { onRemove() } label: {
                Label("Remove", systemImage: "trash")
            }
            Button { onNote() } label: {
                Label("Note", systemImage: "note.text")
            }
            .tint(.blue)
        }
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
        if budget <= 0 { return Color(hex: 0x7fa087) }
        let pct = (spent / budget) * 100
        if pct > 100 { return Color(hex: 0xa32d2d) }
        if pct >= 80 { return Color(hex: 0x854f0b) }
        return Color(hex: 0x3b6d11)
    }
    private var remainingColour: Color {
        if remaining < 0 { return Color(hex: 0xa32d2d) }
        if effectiveBudget > 0, remaining / effectiveBudget <= 0.2 { return Color(hex: 0x854f0b) }
        return Color(hex: 0x3b6d11)
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
                                        .foregroundStyle(rolloverAmount > 0
                                            ? Color(hex: 0x3b6d11)
                                            : Color(hex: 0xa32d2d))
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
            .padding(.vertical, 9)
            .padding(.horizontal, 14)

            // Progress bar (read mode, household view only)
            if !editMode && !showSplit {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color(.systemFill))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(barColour)
                            .frame(width: geo.size.width * fillRatio, height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
            }

            // Edit mode: ownership pills + split slider
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
                                .background(active ? Color.roostPrimary : Color(.systemFill))
                                .foregroundStyle(active ? Color.white : Color.roostForeground)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))

                // Split slider (shared only)
                if line.ownership == "shared" && memberNames.hasPartner {
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
            }

            // Separator
            Divider().padding(.leading, 14)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { onRemove() } label: {
                Label("Remove", systemImage: "trash")
            }
            Button { onNote() } label: {
                Label("Note", systemImage: "note.text")
            }
            .tint(.blue)
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
                Slider(value: $value, in: 0...100, step: 5)
                    .tint(Color.roostPrimary)
                    .onChange(of: value) { _, v in onCommit(v) }
                Text("\(Int(100 - value))%")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 30, alignment: .leading)
                avatarCircle(initials: partnerInitials, colour: partnerColour)
            }
            if let label = labelText {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: 0x9DB19F))
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .onAppear { value = initialValue }
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
