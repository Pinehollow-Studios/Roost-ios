import Charts
import SwiftUI

struct BudgetView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case analytics = "Analytics"
        case categories = "Categories"

        var id: String { rawValue }
    }

    @Environment(HomeManager.self) private var homeManager
    @Environment(NotificationRouter.self) private var notificationRouter
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(BudgetCarrySettings.self) private var budgetCarrySettings
    @Environment(BudgetViewModel.self) private var sharedViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingBudgetSheet = false
    @State private var editingRow: BudgetViewModel.BudgetRowModel?
    @State private var hasAnimatedIn = false
    @State private var selection: Section = .analytics
    @State private var hazelInsight: HazelBudgetInsight?
    @State private var hazelLoading = false
    @State private var hazelRequestKey = ""
    @State private var expandedCategoryId: String?
    @State private var showingProUpsell = false
    private let embeddedInParentScroll: Bool
    private let previewViewModel: BudgetViewModel?
    private let budgetInsightsService = BudgetInsightsService()

    @MainActor
    init(viewModel: BudgetViewModel? = nil, embeddedInParentScroll: Bool = false) {
        previewViewModel = viewModel
        self.embeddedInParentScroll = embeddedInParentScroll
    }

    private var viewModel: BudgetViewModel { previewViewModel ?? sharedViewModel }
    private var isFreeTier: Bool { !(homeManager.home?.hasProAccess ?? false) }
    private var hasBudgetHistory: Bool { homeManager.home?.hasProAccess ?? false }
    private var canGoForward: Bool { hasBudgetHistory && monthsAhead < 12 }
    private var carryForwardTaskKey: String {
        [
            homeManager.homeId?.uuidString ?? "no-home",
            homeManager.currentUserId?.uuidString ?? "no-user",
            budgetCarrySettings.mode.rawValue,
            viewModel.selectedMonth.formatted(.dateTime.year().month())
        ].joined(separator: "|")
    }
    private var monthsAhead: Int {
        let currentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
        let selectedMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: viewModel.selectedMonth)) ?? viewModel.selectedMonth
        return Calendar.current.dateComponents([.month], from: currentMonth, to: selectedMonth).month ?? 0
    }

    var body: some View {
        Group {
            if embeddedInParentScroll {
                content
            } else {
                ScrollView(showsIndicators: false) {
                    content
                        .padding(.bottom, DesignSystem.Spacing.screenBottom)
                }
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingBudgetSheet) {
            SetBudgetSheet(
                initialCategory: editingRow?.category ?? "",
                initialAmount: editingRow?.budget?.amount
            ) { category, amount in
                guard let homeId = homeManager.homeId,
                      let userId = homeManager.currentUserId else { return }
                _ = await viewModel.saveBudget(category: category, amount: amount, homeId: homeId, userId: userId)
            }
        }
        .refreshable {
            guard let homeId = homeManager.homeId else { return }
            await viewModel.load(homeId: homeId)
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
        .task(id: hazelRefreshKey) {
            await refreshHazelInsights()
        }
        .task(id: carryForwardTaskKey) {
            await applyAutomaticCarryForwardIfNeeded()
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
        .nestUpsell(isPresented: $showingProUpsell, feature: .budgetHistory)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
            if !embeddedInParentScroll {
                FigmaPageHeader(title: "Budget", accent: .roostMoneyTint)
                    .padding(.horizontal, DesignSystem.Spacing.page)
            }

            monthNavigator
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(BudgetEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            subtabPicker
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(BudgetEntranceModifier(index: 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            if viewModel.isLoading && viewModel.rows.isEmpty && viewModel.customCategories.isEmpty {
                loadingState
            } else if selection == .analytics {
                analyticsContent
            } else {
                categoriesContent
            }
        }
        .padding(.top, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenTop)
        .padding(.bottom, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenBottom)
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                if isFreeTier {
                    showingProUpsell = true
                } else {
                    viewModel.changeMonth(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(hasBudgetHistory ? Color.roostForeground : Color.roostMutedForeground.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Text(viewModel.monthTitle)
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)

                if isFreeTier {
                    FigmaChip(title: "Pro only", systemImage: "lock.fill")
                }
            }

            Spacer(minLength: 0)

            Button {
                viewModel.changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(canGoForward ? Color.roostForeground : Color.roostMutedForeground.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
    }

    private var subtabPicker: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { section in
                Button {
                    selection = section
                } label: {
                    Text(section.rawValue)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(selection == section ? Color.roostCard : Color.roostMutedForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            Capsule()
                                .fill(selection == section ? Color.roostPrimary : .clear)
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.roostMuted, in: Capsule())
    }

    private var analyticsContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
            spendSummaryCard
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(BudgetEntranceModifier(index: 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            quickStatsRow
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(BudgetEntranceModifier(index: 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            sixMonthChartCard
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(BudgetEntranceModifier(index: 4, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            monthComparisonCard
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(BudgetEntranceModifier(index: 5, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            plainEnglishCard
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(BudgetEntranceModifier(index: 6, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            if !needsAttentionRows.isEmpty {
                needsAttentionCard
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .modifier(BudgetEntranceModifier(index: 7, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
            }

            if !topSpendingRows.isEmpty {
                topCategoriesCard
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .modifier(BudgetEntranceModifier(index: 8, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
            }

            hazelInsightsCard
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(BudgetEntranceModifier(index: 9, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
        }
    }

    private var categoriesContent: some View {
        VStack(spacing: 8) {
            budgetSetupCard
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(BudgetEntranceModifier(index: 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            if viewModel.rows.isEmpty {
                emptyStateCard
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .modifier(BudgetEntranceModifier(index: 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
            } else {
                ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                    categoryCard(row)
                        .padding(.horizontal, DesignSystem.Spacing.page)
                        .modifier(BudgetEntranceModifier(index: index + 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                }
            }
        }
    }

    private var spendSummaryCard: some View {
        RoostHeroCard(tint: summaryTint) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.roostMutedForeground)
                            .frame(width: 28, height: 28)
                            .background(Color.roostAccent, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))

                        Text("This month")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    Spacer(minLength: 0)

                    Text(dayDescriptor)
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                (
                    Text(formatted(viewModel.totalSpent))
                        .font(.roostHero)
                        .foregroundStyle(Color.roostForeground)
                    +
                    Text(" of \(formatted(viewModel.totalBudget)) budget")
                        .font(.roostBody)
                        .foregroundStyle(Color.roostMutedForeground)
                )

                ProgressBarView(progress: budgetProgress)
                    .frame(height: 8)

                Text(summaryText)
                    .font(.roostBody)
                    .foregroundStyle(summaryTint)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remaining")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                        Text(formatted(max(viewModel.totalBudget - viewModel.totalSpent, 0)))
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Projected")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                        Text(formatted(projectedSpend))
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(projectedSpend <= viewModel.totalBudget ? Color.roostSuccess : Color.roostDestructive)
                    }
                }
            }
        }
    }

    private var monthComparisonCard: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: monthChange <= 0 ? "trending.down" : "trending.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 28, height: 28)
                        .background(Color.roostAccent, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))

                    Text("Month over month")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                HStack {
                    Text("Last month: \(formatted(previousMonthSpent))")
                        .font(.roostBody)
                        .foregroundStyle(Color.roostMutedForeground)

                    Spacer(minLength: 0)

                    FigmaChip(
                        title: "\(monthChangePrefix) \(abs(monthChange).formatted(.number.precision(.fractionLength(1))))%",
                        variant: monthChange <= 0 ? .success : .warning
                    )
                }

                HStack(alignment: .bottom, spacing: 16) {
                    comparisonBar(title: "Last", amount: previousMonthSpent, color: Color.roostPrimary.opacity(0.7))
                    comparisonBar(title: "This", amount: viewModel.totalSpent, color: Color.roostSecondary)
                }
                .frame(height: 128)
            }
        }
    }

    private func comparisonBar(title: String, amount: Decimal, color: Color) -> some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color)
                .frame(height: max(6, 100 * barHeightRatio(for: amount)))

            Text(title)
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
        }
        .frame(maxWidth: .infinity)
    }

    private var hazelInsightsCard: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.roostSecondary.opacity(0.16))
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.roostSecondary)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hazel’s Forecast")
                            .font(.roostBody.weight(.semibold))
                            .foregroundStyle(Color.roostForeground)

                        Text(isFreeTier ? "A calmer read on how this month is shaping up." : "Live from this month’s spend and category pace.")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    Spacer(minLength: 0)

                    if !isFreeTier {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(hazelStatusColor)
                                .frame(width: 7, height: 7)
                            Text(hazelStatusLabel)
                                .font(.roostCaption.weight(.medium))
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.roostCard.opacity(0.7), in: Capsule())
                    }
                }

                if isFreeTier {
                    hazelUpgradeContent
                } else if let displayedHazelInsight {
                    hazelLiveContent(displayedHazelInsight)
                } else if hazelLoading {
                    hazelLoadingContent
                } else {
                    hazelUnavailableContent
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.roostSecondary.opacity(0.10),
                    Color.roostAccent.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous)
        )
    }

    private func categoryCard(_ row: BudgetViewModel.BudgetRowModel) -> some View {
        let isExpanded = expandedCategoryId == row.id
        let progress = row.progress
        let remaining = max(row.limit - row.spent, 0)
        let expenses = monthExpenses(for: row.category)

        return RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(BudgetCategoryCatalog.tint(for: row.definition.colorKey))
                            .frame(width: 10, height: 10)

                        Text(row.category)
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                    }

                    Spacer(minLength: 0)

                    (
                        Text(formatted(row.spent))
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                        +
                        Text(" / \(formatted(row.limit))")
                            .font(.roostBody)
                            .foregroundStyle(Color.roostMutedForeground)
                    )

                    if !expenses.isEmpty {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.roostMutedForeground)
                            .padding(.leading, 4)
                    }
                }

                ProgressBarView(progress: progress)

                HStack {
                    Text("\((progress * 100).rounded())% used")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)

                    Spacer(minLength: 0)

                    Text("\(formatted(remaining)) remaining")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                if isExpanded && !expenses.isEmpty {
                    Divider()
                        .background(Color.roostHairline)

                    VStack(spacing: 0) {
                        ForEach(expenses) { expense in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(expense.title)
                                        .font(.roostBody)
                                        .foregroundStyle(Color.roostForeground)

                                    if let date = expense.incurredOnDate {
                                        Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                            .font(.roostCaption)
                                            .foregroundStyle(Color.roostMutedForeground)
                                    }
                                }

                                Spacer(minLength: 0)

                                Text(formatted(expense.amount))
                                    .font(.roostBody.weight(.medium))
                                    .foregroundStyle(Color.roostForeground)
                            }
                            .padding(.vertical, 8)

                            if expense.id != expenses.last?.id {
                                Divider()
                                    .background(Color.roostHairline)
                            }
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.roostSmooth) {
                expandedCategoryId = expandedCategoryId == row.id ? nil : row.id
            }
        }
        .contextMenu {
            Button {
                editingRow = row
                showingBudgetSheet = true
            } label: {
                Label("Edit limit", systemImage: "pencil")
            }

            if let budget = row.budget,
               let homeId = homeManager.homeId,
               let userId = homeManager.currentUserId {
                Button(role: .destructive) {
                    Task { _ = await viewModel.deleteBudget(budget, homeId: homeId, userId: userId) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            Button {
                openBudgetSetup()
            } label: {
                Label("Manage categories", systemImage: "tag")
            }
        }
    }

    private var budgetSetupCard: some View {
        Button {
            openBudgetSetup()
        } label: {
            RoostSectionSurface(emphasis: .subtle) {
                HStack(spacing: 12) {
                    RoostIconBadge(systemImage: "slider.horizontal.3", tint: .roostPrimary)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Manage limits & categories")
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                        Text("Set this month’s limits, add more categories, and carry good setups forward.")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            EmptyStateView(
                icon: "chart.bar",
                title: "No budgets set",
                message: viewModel.canCarryForwardBudgets(into: viewModel.selectedMonth)
                    ? "Carry last month’s limits forward or set up fresh ones for this month."
                    : "Create a budget for this month to start tracking category spend."
            )

            if budgetCarrySettings.mode == .manual && viewModel.canCarryForwardBudgets(into: viewModel.selectedMonth) {
                Button {
                    guard let homeId = homeManager.homeId,
                          let userId = homeManager.currentUserId else { return }
                    Task {
                        await viewModel.copyBudgetsFromPreviousMonth(into: viewModel.selectedMonth, homeId: homeId, userId: userId)
                    }
                } label: {
                    Label("Carry last month forward", systemImage: "arrow.trianglehead.clockwise")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.roostPrimary, in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button {
                openBudgetSetup()
            } label: {
                Label("Manage limits & categories", systemImage: "slider.horizontal.3")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.roostCard, in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                            .stroke(Color.roostHairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var loadingState: some View {
        RoostLoadingView(message: "Loading budgets…", logoSize: DesignSystem.Size.miniLogoMark * 2)
    }

    private var budgetProgress: Double {
        guard viewModel.totalBudget > 0 else { return 0 }
        return NSDecimalNumber(decimal: viewModel.totalSpent / viewModel.totalBudget).doubleValue
    }

    private var hazelUpgradeContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Budget insights with Roost Pro")
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)

            Text("Hazel reads your category spend, recurring costs, and monthly pace to explain how things are looking and where to keep an eye.")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            RoostButton(title: "Upgrade to Pro", systemImage: "sparkles") {
                showingProUpsell = true
            }
        }
    }

    private var displayedHazelInsight: HazelBudgetInsight? {
        hazelInsight ?? fallbackHazelInsight
    }

    private var hazelStatusLabel: String {
        if hazelLoading && hazelInsight == nil {
            return "Reading"
        }
        if hazelInsight != nil {
            return "Live"
        }
        return "Early read"
    }

    private var hazelStatusColor: Color {
        if hazelLoading && hazelInsight == nil {
            return .roostWarning
        }
        if hazelInsight != nil {
            return .roostSuccess
        }
        return .roostPrimary
    }

    private var hazelLoadingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            roundedPlaceholder(height: 28, width: 0.78)
            roundedPlaceholder(height: 17, width: 0.92)

            RoostSectionSurface(emphasis: .subtle) {
                VStack(alignment: .leading, spacing: 10) {
                    roundedPlaceholder(height: 12, width: 0.22)
                    roundedPlaceholder(height: 16, width: 0.88)
                    roundedPlaceholder(height: 16, width: 0.72)
                }
            }

            VStack(spacing: 8) {
                roundedPlaceholder(height: 40, width: 1.0)
                roundedPlaceholder(height: 40, width: 1.0)
                roundedPlaceholder(height: 40, width: 1.0)
            }
        }
        .redacted(reason: .placeholder)
    }

    private func hazelLiveContent(_ insight: HazelBudgetInsight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(insight.summary)
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)
                .fixedSize(horizontal: false, vertical: true)

            RoostSectionSurface(emphasis: .subtle) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Outlook")
                        .font(.roostCaption.weight(.semibold))
                        .foregroundStyle(Color.roostMutedForeground)

                    Text(insight.outlook)
                        .font(.roostBody)
                        .foregroundStyle(Color.roostForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Focus areas")
                    .font(.roostLabel.weight(.medium))
                    .foregroundStyle(Color.roostForeground)

                ForEach(Array(insight.focus.enumerated()), id: \.offset) { _, focus in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.roostPrimary.opacity(0.16))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.roostPrimary)
                            }

                        Text(focus)
                            .font(.roostBody)
                            .foregroundStyle(Color.roostForeground)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.roostCard.opacity(0.72), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
                }
            }
        }
    }

    private var hazelUnavailableContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hazel needs a bit more to read.")
                .font(.roostBody.weight(.medium))
                .foregroundStyle(Color.roostForeground)

            Text(
                analyticsTopCategories.isEmpty
                    ? "Log a few expenses this month and Hazel will start spotting the pattern."
                    : "Hazel couldn’t read this month just now. Pull to refresh and try again."
            )
            .font(.roostBody)
            .foregroundStyle(Color.roostMutedForeground)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var fallbackHazelInsight: HazelBudgetInsight? {
        let expenseCount = currentMonthExpenses.count
        let hasBudget = viewModel.totalBudget > 0
        let topCategory = analyticsTopCategories.first?.name

        if expenseCount == 0 && !hasBudget {
            return HazelBudgetInsight(
                summary: "It’s a quiet start so far.",
                outlook: "Nothing is logged for \(viewModel.monthTitle) yet, so Hazel hasn’t got a spending pattern to read just yet.",
                focus: [
                    "Set a few category budgets",
                    "Log your first shared expense",
                    "Check back after a few entries"
                ]
            )
        }

        if expenseCount == 0 && hasBudget {
            return HazelBudgetInsight(
                summary: "Your month is wide open.",
                outlook: "No spend is logged yet, so you’re fully inside budget with the whole month ahead of you.",
                focus: [
                    "Log recurring bills early",
                    "Keep groceries in view",
                    "Use categories to shape the month"
                ]
            )
        }

        if !hasBudget {
            return HazelBudgetInsight(
                summary: "You’ve started logging, but there’s no budget set yet.",
                outlook: "Hazel can read the month more clearly once you add a few category limits alongside your spend.",
                focus: [
                    "Set limits for top categories",
                    "Keep logging as you spend",
                    "Revisit once the month takes shape"
                ]
            )
        }

        if budgetProgress < 0.7 {
            return HazelBudgetInsight(
                summary: topCategory.map { "\($0) is your main spend area so far, but the month still looks calm." }
                    ?? "You’re moving through the month calmly so far.",
                outlook: "At this pace you still have comfortable room inside the budget, so the next few entries matter more than any single purchase.",
                focus: [
                    "Keep everyday spending steady",
                    "Watch your top category",
                    "Log recurring costs as they land"
                ]
            )
        }

        if budgetProgress < 1.0 {
            return HazelBudgetInsight(
                summary: topCategory.map { "\($0) is putting the most pressure on the month." }
                    ?? "The month is starting to tighten up.",
                outlook: "You’re still inside budget, but the pace is firming up enough that the next stretch needs a slightly closer eye.",
                focus: [
                    "Slow the highest spend area",
                    "Check what’s still to come",
                    "Keep an eye on recurring costs"
                ]
            )
        }

        return HazelBudgetInsight(
            summary: topCategory.map { "You’re over budget now, with \($0) carrying most of the weight." }
                ?? "You’re over budget for the month now.",
            outlook: "The strongest win from here is not perfection, just slowing the categories doing the most work before the month closes.",
            focus: [
                "Pause non-essential spending",
                "Review the biggest category first",
                "Trim the next few purchases"
            ]
        )
    }

    private func roundedPlaceholder(height: CGFloat, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
            .fill(Color.roostCard.opacity(0.88))
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                    .fill(Color.roostCard.opacity(0.88))
                    .frame(width: UIScreen.main.bounds.width * width * 0.72, height: height)
            }
            .frame(height: height)
    }

    private var summaryTint: Color {
        switch budgetProgress {
        case ..<0.7:
            return .roostSuccess
        case ..<1.0:
            return .roostWarning
        default:
            return .roostDestructive
        }
    }

    private var summaryText: String {
        if budgetProgress < 0.7 {
            return "You’re on track"
        }
        if budgetProgress < 1.0 {
            return "Getting close to your limit"
        }
        return "Over budget by \(formatted(viewModel.totalSpent - viewModel.totalBudget))"
    }

    private var projectedSpend: Decimal {
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(viewModel.selectedMonth, equalTo: .now, toGranularity: .month)
        let elapsed = isCurrentMonth ? max(calendar.component(.day, from: .now), 1) : max(daysInMonth, 1)
        let projected = viewModel.totalSpent / Decimal(elapsed) * Decimal(daysInMonth)
        return projected
    }

    private var dayDescriptor: String {
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(viewModel.selectedMonth, equalTo: .now, toGranularity: .month)
        if isCurrentMonth {
            return "Day \(calendar.component(.day, from: .now)) of \(daysInMonth)"
        }
        return "\(daysInMonth) days total"
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: viewModel.selectedMonth)?.count ?? 30
    }

    private var previousMonthSpent: Decimal {
        guard let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: viewModel.selectedMonth) else {
            return 0
        }

        return viewModel.expenses.reduce(Decimal.zero) { partialResult, expense in
            guard let date = expense.incurredOnDate,
                  Calendar.current.isDate(date, equalTo: previousMonth, toGranularity: .month) else {
                return partialResult
            }
            return partialResult + expense.amount
        }
    }

    private var currentMonthExpenses: [ExpenseWithSplits] {
        viewModel.expenses.filter { expense in
            guard let date = expense.incurredOnDate else { return false }
            return Calendar.current.isDate(date, equalTo: viewModel.selectedMonth, toGranularity: .month)
        }
    }

    private var monthChange: Double {
        guard previousMonthSpent > 0 else { return 0 }
        let delta = (viewModel.totalSpent - previousMonthSpent) / previousMonthSpent
        return NSDecimalNumber(decimal: delta).doubleValue * 100
    }

    private var monthChangePrefix: String {
        monthChange <= 0 ? "▼" : "▲"
    }

    private func barHeightRatio(for amount: Decimal) -> CGFloat {
        let maxAmount = max(viewModel.totalSpent, previousMonthSpent, 1)
        return CGFloat(NSDecimalNumber(decimal: amount / maxAmount).doubleValue)
    }

    private func formatted(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsViewModel.userPreferences.currency
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private var analyticsTopCategories: [HazelBudgetInsightInput.TopCategory] {
        viewModel.rows
            .filter { $0.spent > 0 }
            .sorted { $0.spent > $1.spent }
            .prefix(5)
            .map { row in
                HazelBudgetInsightInput.TopCategory(
                    name: row.category,
                    spend: decimalValue(row.spent),
                    limit: row.budget.map { decimalValue($0.amount) },
                    pct: row.progress * 100,
                    recurringTotal: decimalValue(recurringTotal(for: row.category))
                )
            }
    }

    private var hazelRefreshKey: String {
        let categoryKey = analyticsTopCategories
            .map {
                "\($0.name):\($0.spend.rounded(toPlaces: 2)):\(($0.limit ?? 0).rounded(toPlaces: 2)):\($0.pct.rounded(toPlaces: 1))"
            }
            .joined(separator: ",")

        return [
            selection.rawValue,
            homeManager.homeId?.uuidString ?? "no-home",
            isFreeTier ? "free" : "pro",
            viewModel.selectedMonth.formatted(.dateTime.year().month()),
            decimalValue(viewModel.totalSpent).rounded(toPlaces: 2).description,
            decimalValue(viewModel.totalBudget).rounded(toPlaces: 2).description,
            categoryKey
        ].joined(separator: "|")
    }

    @MainActor
    private func refreshHazelInsights() async {
        guard selection == .analytics else { return }
        guard !isFreeTier else {
            hazelInsight = nil
            hazelLoading = false
            return
        }
        guard let homeId = homeManager.homeId else {
            hazelInsight = nil
            hazelLoading = false
            return
        }
        guard !viewModel.isLoading else { return }

        let cacheKey = hazelRefreshKey
        hazelRequestKey = cacheKey

        if let cached = budgetInsightsService.cachedInsight(for: cacheKey) {
            hazelInsight = cached
            hazelLoading = false
            return
        }

        hazelInsight = nil
        hazelLoading = true

        let input = HazelBudgetInsightInput(
            monthLabel: viewModel.monthTitle,
            totalSpent: decimalValue(viewModel.totalSpent),
            totalBudget: decimalValue(viewModel.totalBudget),
            projectedMonthEnd: decimalValue(projectedSpend),
            remaining: decimalValue(max(viewModel.totalBudget - viewModel.totalSpent, 0)),
            overspend: decimalValue(max(viewModel.totalSpent - viewModel.totalBudget, 0)),
            topCategories: analyticsTopCategories
        )

        do {
            let insight = try await budgetInsightsService.fetchInsights(homeId: homeId, input: input)
            budgetInsightsService.cache(insight, for: cacheKey)

            guard hazelRequestKey == cacheKey else { return }
            hazelInsight = insight
            hazelLoading = false
        } catch {
            guard hazelRequestKey == cacheKey else { return }
            hazelInsight = nil
            hazelLoading = false
        }
    }

    private func recurringTotal(for category: String) -> Decimal {
        viewModel.expenses
            .filter { ($0.isRecurring ?? false) && ($0.category ?? "Other") == category }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private func decimalValue(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    private func openBudgetSetup() {
        notificationRouter.selectedTab = .more
        notificationRouter.morePath = [.money]
    }

    @MainActor
    private func applyAutomaticCarryForwardIfNeeded() async {
        guard budgetCarrySettings.automaticallyCarriesForward,
              let homeId = homeManager.homeId,
              let userId = homeManager.currentUserId else { return }
        await viewModel.ensureBudgetsCarriedForward(into: viewModel.selectedMonth, homeId: homeId, userId: userId)
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            RoostSectionSurface(emphasis: .subtle) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total spent")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(formatted(viewModel.totalSpent))
                        .font(.roostBody.weight(.semibold))
                        .foregroundStyle(Color.roostForeground)
                    Text("\(monthExpenseCount) expense\(monthExpenseCount == 1 ? "" : "s")")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            RoostSectionSurface(emphasis: .subtle) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recurring")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(formatted(recurringMonthTotal))
                        .font(.roostBody.weight(.semibold))
                        .foregroundStyle(Color.roostForeground)
                    Text("this month")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Six Month Chart

    private struct MonthTrendPoint: Identifiable {
        let id = UUID()
        let label: String
        let type: String
        let amount: Double
    }

    private var sixMonthTrendPoints: [MonthTrendPoint] {
        let calendar = Calendar.current
        var points: [MonthTrendPoint] = []
        for i in stride(from: -5, through: 0, by: 1) {
            guard let month = calendar.date(byAdding: .month, value: i, to: viewModel.selectedMonth) else { continue }
            let label = month.formatted(.dateTime.month(.abbreviated))
            let spent = viewModel.expenses.filter { expense in
                guard let date = expense.incurredOnDate else { return false }
                return calendar.isDate(date, equalTo: month, toGranularity: .month)
            }.reduce(Decimal.zero) { $0 + $1.amount }
            let budget = viewModel.budgets.filter { b in
                calendar.isDate(b.month, equalTo: month, toGranularity: .month)
            }.reduce(Decimal.zero) { $0 + $1.amount }
            points.append(MonthTrendPoint(label: label, type: "Spent", amount: NSDecimalNumber(decimal: spent).doubleValue))
            points.append(MonthTrendPoint(label: label, type: "Budget", amount: NSDecimalNumber(decimal: budget).doubleValue))
        }
        return points
    }

    private var sixMonthChartCard: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 28, height: 28)
                        .background(Color.roostAccent, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))

                    Text("Six month rhythm")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)

                    Spacer(minLength: 0)

                    HStack(spacing: 12) {
                        chartLegendDot(color: Color.roostPrimary, label: "Spent")
                        chartLegendDot(color: Color.roostPrimary.opacity(0.3), label: "Budget")
                    }
                }

                Chart(sixMonthTrendPoints) { point in
                    BarMark(
                        x: .value("Month", point.label),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(point.type == "Spent" ? Color.roostPrimary : Color.roostPrimary.opacity(0.3))
                    .position(by: .value("Type", point.type))
                    .cornerRadius(4)
                }
                .frame(height: 140)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                            .foregroundStyle(Color.roostHairline)
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(compactFormatted(amount))
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                        }
                    }
                }
            }
        }
    }

    private func chartLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
        }
    }

    private func compactFormatted(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }

    // MARK: - Plain English Card

    private var plainEnglishCard: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 28, height: 28)
                        .background(Color.roostAccent, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))

                    Text("This month, in plain English")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                VStack(spacing: 0) {
                    plainEnglishRow(label: "Pacing", value: pacingLabel, valueColor: pacingColor)
                    Divider().background(Color.roostHairline)
                    plainEnglishRow(
                        label: "Biggest pressure",
                        value: biggestPressureName ?? "—",
                        valueColor: Color.roostForeground
                    )
                    Divider().background(Color.roostHairline)
                    plainEnglishRow(
                        label: "Coverage",
                        value: totalCategoryCount > 0
                            ? "\(categoryCoverage) of \(totalCategoryCount) categories budgeted"
                            : "No categories yet",
                        valueColor: Color.roostMutedForeground
                    )
                }
                .background(Color.roostCard.opacity(0.5), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                        .stroke(Color.roostHairline, lineWidth: 1)
                )
            }
        }
    }

    private func plainEnglishRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
            Spacer(minLength: 0)
            Text(value)
                .font(.roostBody.weight(.medium))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Needs Attention Card

    private var needsAttentionCard: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostWarning)
                        .frame(width: 28, height: 28)
                        .background(Color.roostWarning.opacity(0.14), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))

                    Text("Needs attention")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                VStack(spacing: 8) {
                    ForEach(needsAttentionRows) { row in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(BudgetCategoryCatalog.tint(for: row.definition.colorKey))
                                .frame(width: 8, height: 8)

                            Text(row.category)
                                .font(.roostBody)
                                .foregroundStyle(Color.roostForeground)

                            Spacer(minLength: 0)

                            FigmaChip(
                                title: row.progress >= 1.0 ? "Over limit" : "\(Int((row.progress * 100).rounded()))%",
                                variant: row.progress >= 1.0 ? .warning : .warning
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Top Categories Card

    private var topCategoriesCard: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "list.number")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 28, height: 28)
                        .background(Color.roostAccent, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))

                    Text("Top categories this month")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                VStack(spacing: 12) {
                    ForEach(topSpendingRows) { row in
                        topCategoryRow(row)
                    }
                }
            }
        }
    }

    private func topCategoryRow(_ row: BudgetViewModel.BudgetRowModel) -> some View {
        let maxSpent = topSpendingRows.first?.spent ?? 1
        let barRatio = maxSpent > 0 ? NSDecimalNumber(decimal: row.spent / maxSpent).doubleValue : 0

        return VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(BudgetCategoryCatalog.tint(for: row.definition.colorKey))
                        .frame(width: 8, height: 8)

                    Text(row.category)
                        .font(.roostBody)
                        .foregroundStyle(Color.roostForeground)
                }

                Spacer(minLength: 0)

                Text(formatted(row.spent))
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.roostAccent)
                        .frame(maxWidth: .infinity)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(BudgetCategoryCatalog.tint(for: row.definition.colorKey))
                        .frame(width: geo.size.width * CGFloat(barRatio))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Analytics Computed Properties

    private var monthExpenseCount: Int {
        currentMonthExpenses.count
    }

    private var recurringMonthTotal: Decimal {
        currentMonthExpenses
            .filter { $0.isRecurring ?? false }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var pacingLabel: String {
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(viewModel.selectedMonth, equalTo: .now, toGranularity: .month)
        guard isCurrentMonth, daysInMonth > 0 else {
            return budgetProgress >= 1.0 ? "Over budget" : "Under budget"
        }
        let dayOfMonth = Double(calendar.component(.day, from: .now))
        let monthFraction = dayOfMonth / Double(daysInMonth)
        if budgetProgress <= monthFraction * 1.1 {
            return "On track"
        } else if budgetProgress <= monthFraction * 1.3 {
            return "Slightly ahead"
        } else {
            return "Running hot"
        }
    }

    private var pacingColor: Color {
        switch pacingLabel {
        case "On track", "Under budget": return .roostSuccess
        case "Slightly ahead": return .roostWarning
        default: return .roostDestructive
        }
    }

    private var biggestPressureName: String? {
        viewModel.rows
            .filter { $0.spent > 0 }
            .sorted { $0.spent > $1.spent }
            .first?
            .category
    }

    private var categoryCoverage: Int {
        viewModel.rows.filter { $0.budget != nil }.count
    }

    private var totalCategoryCount: Int {
        viewModel.rows.filter { $0.spent > 0 || $0.budget != nil }.count
    }

    private var needsAttentionRows: [BudgetViewModel.BudgetRowModel] {
        viewModel.rows
            .filter { $0.budget != nil && $0.progress >= 0.8 }
            .sorted { $0.progress > $1.progress }
    }

    private var topSpendingRows: [BudgetViewModel.BudgetRowModel] {
        Array(
            viewModel.rows
                .filter { $0.spent > 0 }
                .sorted { $0.spent > $1.spent }
                .prefix(5)
        )
    }

    private func monthExpenses(for category: String) -> [ExpenseWithSplits] {
        currentMonthExpenses
            .filter { ($0.category ?? "Other") == category }
            .sorted { ($0.incurredOnDate ?? .distantPast) > ($1.incurredOnDate ?? .distantPast) }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

private struct BudgetEntranceModifier: ViewModifier {
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

#Preview("Budget") {
    let homeManager = HomeManager.previewDashboard()
    let settingsViewModel: SettingsViewModel = {
        let viewModel = SettingsViewModel()
        viewModel.userPreferences.currency = "GBP"
        return viewModel
    }()
    let month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now

    let budgets = [
        Budget(id: UUID(), homeID: homeManager.homeId ?? UUID(), category: "Groceries", amount: 300, month: month),
        Budget(id: UUID(), homeID: homeManager.homeId ?? UUID(), category: "Bills", amount: 180, month: month)
    ]

    let expenses = [
        ExpenseWithSplits(id: UUID(), homeID: homeManager.homeId ?? UUID(), title: "Weekly groceries", amount: 86.40, paidBy: UUID(), splitType: "equal", category: "Groceries", notes: nil, incurredOn: "2026-03-10", isRecurring: false, createdAt: .now, expenseSplits: []),
        ExpenseWithSplits(id: UUID(), homeID: homeManager.homeId ?? UUID(), title: "Electric bill", amount: 64.10, paidBy: UUID(), splitType: "equal", category: "Bills", notes: nil, incurredOn: "2026-03-12", isRecurring: false, createdAt: .now, expenseSplits: [])
    ]

    let categories = [
        CustomCategory(id: UUID(), homeID: homeManager.homeId ?? UUID(), name: "Pets", emoji: "🐾", color: "rose", createdAt: .now)
    ]

    NavigationStack {
        BudgetView(
            viewModel: BudgetViewModel(
                budgets: budgets,
                customCategories: categories,
                expenses: expenses,
                selectedMonth: month
            )
        )
        .environment(homeManager)
        .environment(settingsViewModel)
    }
}
