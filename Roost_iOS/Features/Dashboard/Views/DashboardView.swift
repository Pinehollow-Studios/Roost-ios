import SwiftUI

@MainActor
struct DashboardView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(NotificationRouter.self) private var notificationRouter
    @Environment(NotificationsViewModel.self) private var notificationsViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(DashboardViewModel.self) private var sharedViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasAppeared = false
    private let previewViewModel: DashboardViewModel?

    init(viewModel: DashboardViewModel? = nil) {
        previewViewModel = viewModel
    }

    private var viewModel: DashboardViewModel { previewViewModel ?? sharedViewModel }
    private var myUserId: UUID? { homeManager.currentUserId }
    private var partnerUserId: UUID? { homeManager.partner?.userID }
    private var currentUserName: String { homeManager.currentMember?.displayName ?? "You" }
    private var currentMonthBudget: (spent: Decimal, limit: Decimal) { viewModel.budgetSummary(for: .now) }
    private var uncheckedShoppingItems: [ShoppingItem] { viewModel.uncheckedShoppingItems }
    private var dueTodayChores: [Chore] { viewModel.chores.filter(isDueToday(_:)) }
    private var openChoreCount: Int { viewModel.chores.filter { !$0.isCompleted }.count }
    private var balance: Decimal {
        guard let myUserId, let partnerUserId else { return 0 }
        return viewModel.currentBalance(myUserId: myUserId, partnerUserId: partnerUserId)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    headerSection
                        .padding(.top, 16)
                        .modifier(DashEntrance(index: 0, appeared: hasAppeared, reduceMotion: reduceMotion))

                    // Balance + budget card
                    financialBlock
                        .padding(.top, 22)
                        .modifier(DashEntrance(index: 1, appeared: hasAppeared, reduceMotion: reduceMotion))

                    // Shopping + Chores grid
                    statGrid
                        .padding(.top, 10)
                        .modifier(DashEntrance(index: 2, appeared: hasAppeared, reduceMotion: reduceMotion))

                    // Today
                    sectionHeader("Today")
                        .padding(.top, 28)
                        .modifier(DashEntrance(index: 3, appeared: hasAppeared, reduceMotion: reduceMotion))
                    todayContent
                        .padding(.top, 10)
                        .modifier(DashEntrance(index: 3, appeared: hasAppeared, reduceMotion: reduceMotion))

                    // Recently
                    sectionHeader("Recently")
                        .padding(.top, 24)
                        .modifier(DashEntrance(index: 4, appeared: hasAppeared, reduceMotion: reduceMotion))
                    activityContent
                        .padding(.top, 10)
                        .modifier(DashEntrance(index: 4, appeared: hasAppeared, reduceMotion: reduceMotion))

                    // Spending
                    HStack(spacing: 0) {
                        sectionHeader("Spending")
                        Spacer(minLength: 0)
                        if !viewModel.expenses.isEmpty {
                            Button {
                                notificationRouter.selectedTab = .money
                            } label: {
                                Text("See all")
                                    .font(.roostLabel)
                                    .foregroundStyle(Color.roostPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 24)
                    .modifier(DashEntrance(index: 5, appeared: hasAppeared, reduceMotion: reduceMotion))

                    spendingContent
                        .padding(.top, 10)
                        .modifier(DashEntrance(index: 5, appeared: hasAppeared, reduceMotion: reduceMotion))

                    Spacer(minLength: DesignSystem.Spacing.screenBottom + DesignSystem.Spacing.tabContentBottomInset + 12)
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
                .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
                .frame(maxWidth: .infinity)
            }

            // Thin terracotta accent line — the page's signature
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.roostPrimary.opacity(0.55), Color.roostPrimary.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .ignoresSafeArea(edges: .top)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            guard let homeId = homeManager.homeId else { return }
            await viewModel.load(homeId: homeId)
        }
        .task {
            guard !reduceMotion else { hasAppeared = true; return }
            if !hasAppeared {
                withAnimation(DesignSystem.Motion.listAppear) { hasAppeared = true }
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

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(greeting), \(currentUserName)")
                    .font(.roostLargeGreeting)
                    .foregroundStyle(Color.roostForeground)

                Text(todayDateLabel)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            Spacer(minLength: 0)

            Button {
                notificationRouter.selectedTab = .more
                notificationRouter.morePath = [.notifications]
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.roostForeground)
                        .frame(width: 38, height: 38)
                        .background(Color.roostCard)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.roostHairline, lineWidth: 1))

                    if notificationsViewModel.unreadCount > 0 {
                        Circle()
                            .fill(Color.roostPrimary)
                            .frame(width: 9, height: 9)
                            .offset(x: 2, y: 0)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Financial block

    private var financialBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Balance
            VStack(alignment: .leading, spacing: 5) {
                Text(balanceLabel.uppercased())
                    .font(.roostMeta)
                    .foregroundStyle(balanceStatusColor)
                    .tracking(0.9)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(balance == 0 ? "All clear" : formattedCurrency(abs(balance)))
                        .font(.roostHero)
                        .foregroundStyle(balance == 0 ? Color.roostMutedForeground : balanceAmountColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 0)

                    if balance != 0 {
                        Button {
                            notificationRouter.selectedTab = .money
                        } label: {
                            HStack(spacing: 4) {
                                Text("Settle up")
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostPrimary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Color.roostPrimary.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 3 }
                    }
                }

                Text(balanceSupportingText)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            // Divider
            Rectangle()
                .fill(Color.roostHairline)
                .frame(height: 1)
                .padding(.vertical, 14)

            // Budget
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(currentMonthLabel.uppercased())
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                        .tracking(0.6)

                    Spacer(minLength: 8)

                    Group {
                        Text(formattedCurrency(currentMonthBudget.spent))
                            .foregroundStyle(Color.roostForeground) +
                        Text("  /  \(formattedCurrency(currentMonthBudget.limit))")
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                    .font(.roostCaption)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.roostMuted)
                        Capsule()
                            .fill(budgetBarColor)
                            .frame(width: geo.size.width * budgetProgressValue)
                            .animation(DesignSystem.Motion.progressFill, value: budgetProgressValue)
                    }
                }
                .frame(height: 4)

                Text(budgetFootnote)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.roostCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - Stat grid

    private var statGrid: some View {
        HStack(spacing: 10) {
            Button { notificationRouter.selectedTab = .shopping } label: {
                statTile(
                    icon: "cart",
                    count: uncheckedShoppingItems.count,
                    noun: "items",
                    detail: nextShopDetail,
                    tint: Color.roostShoppingTint
                )
            }
            .buttonStyle(TileButtonStyle(reduceMotion: reduceMotion))

            Button { notificationRouter.selectedTab = .life } label: {
                statTile(
                    icon: "checkmark.circle",
                    count: openChoreCount,
                    noun: "chores",
                    detail: choresDetail,
                    tint: choresDetailColor
                )
            }
            .buttonStyle(TileButtonStyle(reduceMotion: reduceMotion))
        }
    }

    private func statTile(
        icon: String,
        count: Int,
        noun: String,
        detail: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(count)")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                    Text(noun)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }
                Text(detail)
                    .font(.roostCaption)
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roostCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 5, x: 0, y: 2)
    }

    // MARK: - Section header (editorial style: label + extending line)

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            Text(title.uppercased())
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .tracking(1.0)
                .fixedSize()

            Rectangle()
                .fill(Color.roostHairline)
                .frame(height: 1)
        }
    }

    // MARK: - Today

    @ViewBuilder
    private var todayContent: some View {
        if viewModel.isLoading && viewModel.chores.isEmpty {
            VStack(spacing: 10) {
                skeletonRow()
                skeletonRow(fraction: 0.7)
            }
        } else if todayEntries.isEmpty {
            Text("Nothing on the schedule today")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.vertical, 4)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(todayEntries.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(entry.color)
                            .frame(width: 6, height: 6)

                        Text(entry.title)
                            .font(.roostBody)
                            .foregroundStyle(Color.roostForeground)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(entry.detail)
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                    .padding(.vertical, 10)

                    if index < todayEntries.count - 1 {
                        Divider().padding(.leading, 18)
                    }
                }
            }
        }
    }

    // MARK: - Activity

    @ViewBuilder
    private var activityContent: some View {
        if viewModel.isLoading && viewModel.activityItems.isEmpty {
            VStack(spacing: 10) {
                skeletonRow()
                skeletonRow(fraction: 0.85)
                skeletonRow(fraction: 0.6)
            }
        } else if viewModel.recentActivity.isEmpty {
            Text("No activity yet")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.vertical, 4)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentActivity.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 0) {
                        Text(activityLine(for: item))
                            .font(.roostBody)
                            .foregroundStyle(Color.roostForeground)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(relativeTimestamp(item.createdAt))
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                            .fixedSize()
                            .padding(.leading, 12)
                    }
                    .padding(.vertical, 10)

                    if index < viewModel.recentActivity.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Spending

    @ViewBuilder
    private var spendingContent: some View {
        if viewModel.isLoading && viewModel.expenses.isEmpty {
            VStack(spacing: 10) {
                skeletonRow()
                skeletonRow(fraction: 0.8)
            }
        } else if viewModel.expenses.isEmpty {
            Text("No expenses yet this month")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.vertical, 4)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.expenses.prefix(3).enumerated()), id: \.element.id) { index, expense in
                    Button { notificationRouter.selectedTab = .money } label: {
                        HStack(alignment: .center, spacing: 0) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(expense.title)
                                    .font(.roostBody.weight(.medium))
                                    .foregroundStyle(Color.roostForeground)
                                    .lineLimit(1)

                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(categoryColor(for: expense.category))
                                        .frame(width: 5, height: 5)
                                    Text(expense.category ?? "Other")
                                        .font(.roostCaption)
                                        .foregroundStyle(Color.roostMutedForeground)
                                }
                            }

                            Spacer(minLength: 12)

                            Text(formattedCurrency(expense.amount))
                                .font(.roostBody.weight(.medium))
                                .foregroundStyle(Color.roostForeground)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(RowPressStyle(reduceMotion: reduceMotion))

                    if index < min(viewModel.expenses.count, 3) - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Skeleton

    private func skeletonRow(fraction: CGFloat = 1) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.roostMuted)
                .frame(height: 13)
                .frame(maxWidth: .infinity)
                .opacity(fraction)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
        .shimmer()
    }

    // MARK: - Helpers

    private func memberName(for userId: UUID) -> String {
        homeManager.members.first(where: { $0.userID == userId })?.displayName ?? "Housemate"
    }

    private func myShare(for expense: ExpenseWithSplits) -> Decimal {
        guard let myUserId else { return 0 }
        return expense.expenseSplits.first(where: { $0.userID == myUserId })?.amount ?? expense.amount
    }

    private func activityLine(for item: ActivityFeedItem) -> String {
        let name = memberName(for: item.userID)
        let trimmed = item.action.replacingOccurrences(of: "\(name) ", with: "")
        return "\(name) \(trimmed)"
    }

    private func relativeTimestamp(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: .now)
    }

    private func formattedCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsViewModel.userPreferences.currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private func categoryColor(for category: String?) -> Color {
        switch category?.lowercased() {
        case "groceries": return .roostSecondary
        case "bills": return .roostPrimary
        case "transport": return .roostWarning
        case "subscriptions": return Color(hex: 0x7A9199)
        default: return .roostMutedForeground
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private var todayDateLabel: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private var balanceLabel: String {
        if balance > 0 { return "You're owed" }
        if balance < 0 { return "You owe" }
        return "All settled up"
    }

    private var balanceStatusColor: Color {
        if balance > 0 { return .roostSuccess }
        if balance < 0 { return .roostDestructive }
        return .roostMutedForeground
    }

    private var balanceAmountColor: Color {
        if balance > 0 { return .roostSuccess }
        if balance < 0 { return .roostDestructive }
        return .roostMutedForeground
    }

    private var balanceSupportingText: String {
        let partnerName = homeManager.partner?.displayName ?? "your partner"
        if balance > 0 { return "\(partnerName) owes you \(formattedCurrency(abs(balance)))" }
        if balance < 0 { return "You owe \(partnerName) \(formattedCurrency(abs(balance)))" }
        return "You're all settled up with \(partnerName)"
    }

    private var nextShopDetail: String {
        guard let date = homeManager.home?.nextShopDateParsed else { return "No date set" }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: date)
        ).day ?? 0
        if days <= 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "In \(days) days"
    }

    private var choresDetail: String {
        if viewModel.overdueChores.count > 0 { return "\(viewModel.overdueChores.count) overdue" }
        if dueTodayChores.count > 0 {
            return dueTodayChores.count == 1 ? "Due today" : "\(dueTodayChores.count) due today"
        }
        return "All on track"
    }

    private var choresDetailColor: Color {
        if viewModel.overdueChores.count > 0 { return .roostDestructive }
        if dueTodayChores.count > 0 { return .roostWarning }
        return .roostSecondary
    }

    private var currentMonthLabel: String {
        Date.now.formatted(.dateTime.month(.wide))
    }

    private var budgetProgressValue: Double {
        guard currentMonthBudget.limit > 0 else { return 0 }
        let spent = NSDecimalNumber(decimal: currentMonthBudget.spent).doubleValue
        let limit = NSDecimalNumber(decimal: currentMonthBudget.limit).doubleValue
        return min(max(spent / limit, 0), 1)
    }

    private var budgetBarColor: Color {
        if budgetProgressValue > 0.9 { return .roostDestructive }
        if budgetProgressValue > 0.7 { return .roostWarning }
        return .roostPrimary
    }

    private var budgetFootnote: String {
        guard currentMonthBudget.limit > 0 else { return "No budget set for \(currentMonthLabel)" }
        let remaining = max(currentMonthBudget.limit - currentMonthBudget.spent, 0)
        let used = Int(budgetProgressValue * 100)
        return "\(used)% used · \(formattedCurrency(remaining)) remaining"
    }

    private var todayEntries: [TodayEntry] {
        var entries: [TodayEntry] = dueTodayChores.prefix(3).map {
            TodayEntry(title: $0.title, detail: "Chore", color: .roostSecondary)
        }
        if entries.count < 3,
           let date = homeManager.home?.nextShopDateParsed,
           Calendar.current.isDateInToday(date) {
            entries.append(TodayEntry(title: "Groceries run", detail: "Shopping", color: .roostPrimary))
        }
        return entries
    }

    private func isDueToday(_ chore: Chore) -> Bool {
        guard let dueDate = chore.dueDate, !chore.isCompleted else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
}

// MARK: - Shimmer modifier

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.roostBackground.opacity(0.35), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: geo.size.width * phase)
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Button styles

private struct TileButtonStyle: ButtonStyle {
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(reduceMotion ? nil : DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}

private struct RowPressStyle: ButtonStyle {
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(reduceMotion ? nil : DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Entrance animation

private struct DashEntrance: ViewModifier {
    let index: Int
    let appeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 14)
            .animation(
                reduceMotion ? nil : DesignSystem.Motion.listAppear.delay(Double(index) * 0.06),
                value: appeared
            )
    }
}

// MARK: - Supporting types

private struct TodayEntry: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let color: Color
}
