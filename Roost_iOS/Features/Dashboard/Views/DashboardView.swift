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

                    moneyStatusPanel
                        .padding(.top, 22)
                        .modifier(DashEntrance(index: 1, appeared: hasAppeared, reduceMotion: reduceMotion))

                    householdActionRail
                        .padding(.top, 12)
                        .modifier(DashEntrance(index: 2, appeared: hasAppeared, reduceMotion: reduceMotion))

                    householdBriefing
                        .padding(.top, 24)
                        .modifier(DashEntrance(index: 3, appeared: hasAppeared, reduceMotion: reduceMotion))

                    nextMovePanel
                        .padding(.top, 14)
                        .modifier(DashEntrance(index: 4, appeared: hasAppeared, reduceMotion: reduceMotion))

                    dashboardDigest
                        .padding(.top, 14)
                        .modifier(DashEntrance(index: 5, appeared: hasAppeared, reduceMotion: reduceMotion))

                    Spacer(minLength: DesignSystem.Spacing.screenBottom + DesignSystem.Spacing.tabContentBottomInset + 12)
                }
                .padding(.horizontal, dashboardPageInset)
                .frame(maxWidth: .infinity, alignment: .top)
            }

            // Tab accent line — terracotta signature stripe
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.roostPrimary.opacity(0.75), Color.roostPrimary.opacity(0.30)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
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

    // MARK: - Money status

    private var moneyStatusPanel: some View {
        Button {
            notificationRouter.selectedTab = .money
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("MONEY STATUS")
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostPrimary)
                            .tracking(1.0)

                        Text(moneyStatusHeadline)
                            .font(.roostHero)
                            .foregroundStyle(Color.roostForeground)
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                    }

                    Spacer(minLength: 0)

                    budgetDial
                        .frame(width: 72, height: 72)
                }

                moneyStatusBar

                HStack(spacing: 8) {
                    moneyMiniStatus(
                        title: "Spent",
                        value: formattedCurrency(currentMonthBudget.spent),
                        tint: Color.roostPrimary
                    )

                    moneyMiniStatus(
                        title: "Left",
                        value: formattedCurrency(remainingBudget),
                        tint: remainingBudget <= 0 ? Color.roostDestructive : Color.roostSecondary
                    )
                }

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: balanceStatusIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(balanceStatusColor)
                        .frame(width: 28, height: 28)
                        .background(balanceStatusColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(balanceLabel)
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostForeground)

                    Spacer(minLength: 0)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                        .fill(Color.roostCard)

                    Circle()
                        .fill(Color.roostAccent.opacity(0.32))
                        .frame(width: 118, height: 118)
                        .blur(radius: 34)
                        .offset(x: 34, y: -48)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.045), radius: 12, x: 0, y: 5)
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
        }
        .buttonStyle(TileButtonStyle(reduceMotion: reduceMotion))
    }

    private var budgetDial: some View {
        ZStack {
            Circle()
                .stroke(Color.roostMuted, lineWidth: 8)

            Circle()
                .trim(from: 0, to: budgetProgressValue)
                .stroke(
                    budgetBarColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Motion.progressFill, value: budgetProgressValue)

            VStack(spacing: 1) {
                Text("\(Int(budgetProgressValue * 100))%")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)

                Text("used")
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
            }
        }
    }

    private var moneyStatusBar: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(currentMonthLabel)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)

                Spacer(minLength: 8)

                Text(budgetFootnote)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.roostMuted)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(budgetBarColor)
                        .frame(width: geo.size.width * budgetProgressValue)
                        .animation(DesignSystem.Motion.progressFill, value: budgetProgressValue)
                }
            }
            .frame(height: 7)
        }
    }

    private func moneyMiniStatus(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .tracking(0.7)

            Text(value)
                .font(.roostLabel)
                .foregroundStyle(Color.roostForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    // MARK: - Household rail

    private var householdActionRail: some View {
        HStack(spacing: 10) {
            Button {
                notificationRouter.selectedTasksSection = .shopping
                notificationRouter.selectedTab = .shopping
            } label: {
                householdTile(
                    eyebrow: "Shop",
                    title: "\(uncheckedShoppingItems.count) open",
                    icon: "cart",
                    tint: Color.roostShoppingTint
                )
            }
            .buttonStyle(TileButtonStyle(reduceMotion: reduceMotion))

            Button {
                notificationRouter.selectedTasksSection = .chores
                notificationRouter.selectedTab = .chores
            } label: {
                householdTile(
                    eyebrow: "Home",
                    title: "\(openChoreCount) chores",
                    icon: "checkmark.circle",
                    tint: choresDetailColor
                )
            }
            .buttonStyle(TileButtonStyle(reduceMotion: reduceMotion))
        }
    }

    private func householdTile(
        eyebrow: String,
        title: String,
        icon: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text(eyebrow.uppercased())
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
                    .tracking(0.8)

                Spacer(minLength: 0)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
            }

            Text(title)
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .frame(minHeight: 68, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roostCard.opacity(0.82), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    // MARK: - Briefing

    private var householdBriefing: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("HOUSEHOLD RHYTHM")
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                        .tracking(1.0)

                    Text(householdRhythmHeadline)
                        .font(.roostTitle)
                        .foregroundStyle(Color.roostForeground)
                }

                Spacer(minLength: 0)

                rhythmMark
                    .frame(width: 52, height: 52)
            }

            HStack(spacing: 8) {
                briefingMetric(title: "Budget", value: "\(Int(budgetProgressValue * 100))%", tint: budgetBarColor)
                briefingMetric(title: "Chores", value: "\(openChoreCount)", tint: choresDetailColor)
                briefingMetric(title: "Shop", value: "\(uncheckedShoppingItems.count)", tint: Color.roostShoppingTint)
            }
        }
        .padding(16)
        .background(Color.roostSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private var rhythmMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.roostAccent.opacity(0.28))

            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(rhythmColors[index])
                    .frame(width: 6, height: CGFloat(16 + (index * 7)))
                    .offset(x: CGFloat(index - 1) * 10, y: CGFloat(2 - index))
            }
        }
    }

    private func briefingMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .tracking(0.7)

            Text(value)
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)
                .lineLimit(1)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))
    }

    // MARK: - Next move

    private var nextMovePanel: some View {
        Button {
            if let tasksSection = nextMove.tasksSection {
                notificationRouter.selectedTasksSection = tasksSection
            }
            notificationRouter.selectedTab = nextMove.destination
        } label: {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(nextMove.tint.opacity(0.14))
                    Image(systemName: nextMove.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(nextMove.tint)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT BEST MOVE")
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                        .tracking(1.0)

                    Text(nextMove.title)
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 0)

                Text(nextMove.action)
                    .font(.roostLabel)
                    .foregroundStyle(nextMove.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(nextMove.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        }
        .buttonStyle(TileButtonStyle(reduceMotion: reduceMotion))
    }

    // MARK: - Digest

    private var dashboardDigest: some View {
        VStack(spacing: 14) {
            spendingDigest
            activityDigest
        }
    }

    private var spendingDigest: some View {
        VStack(alignment: .leading, spacing: 14) {
            digestHeader(
                eyebrow: "SPEND SIGNALS",
                title: spendingDigestTitle,
                tint: Color.roostPrimary
            )

            if viewModel.isLoading && viewModel.expenses.isEmpty {
                VStack(spacing: 8) {
                    skeletonRow()
                    skeletonRow(fraction: 0.72)
                }
            } else if topSpendingCategories.isEmpty {
                EmptyView()
            } else {
                VStack(spacing: 8) {
                    ForEach(topSpendingCategories) { category in
                        categorySignal(category)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.roostCard.opacity(0.9), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private var activityDigest: some View {
        VStack(alignment: .leading, spacing: 14) {
            digestHeader(
                eyebrow: "RECENT RHYTHM",
                title: activityDigestTitle,
                tint: Color.roostSecondary
            )

            if viewModel.isLoading && viewModel.activityItems.isEmpty {
                VStack(spacing: 8) {
                    skeletonRow()
                    skeletonRow(fraction: 0.62)
                }
            } else if viewModel.recentActivity.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(viewModel.recentActivity.prefix(3))) { item in
                        activitySignal(item)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.roostSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private func digestHeader(eyebrow: String, title: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.roostMeta)
                    .foregroundStyle(tint)
                    .tracking(1.0)

                Text(title)
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private func categorySignal(_ category: SpendingCategorySignal) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(category.name)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(formattedCurrency(category.amount))
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.roostMuted)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(category.tint)
                            .frame(width: geo.size.width * category.share)
                    }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(category.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))
    }

    private func activitySignal(_ item: ActivityFeedItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(activityTint(for: item).opacity(0.18))
                .frame(width: 24, height: 24)
                .overlay {
                    Circle()
                        .fill(activityTint(for: item))
                        .frame(width: 7, height: 7)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(activityLine(for: item))
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
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

    private func activityTint(for item: ActivityFeedItem) -> Color {
        let type = item.entityType?.lowercased() ?? item.action.lowercased()
        if type.contains("expense") || type.contains("budget") { return .roostPrimary }
        if type.contains("shopping") || type.contains("shop") { return .roostShoppingTint }
        if type.contains("chore") || type.contains("calendar") { return .roostSecondary }
        return .roostMutedForeground
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
        return "Balanced together"
    }

    private var balanceStatusColor: Color {
        if balance > 0 { return .roostSuccess }
        if balance < 0 { return .roostDestructive }
        return .roostMutedForeground
    }

    private var balanceStatusIcon: String {
        if balance > 0 { return "arrow.down.left" }
        if balance < 0 { return "arrow.up.right" }
        return "checkmark"
    }

    private var balanceSupportingText: String {
        let partnerName = homeManager.partner?.displayName ?? "your partner"
        if balance > 0 { return "\(partnerName) is \(formattedCurrency(abs(balance))) behind your share." }
        if balance < 0 { return "You're \(formattedCurrency(abs(balance))) behind \(partnerName)'s share." }
        return "Shared spending is even with \(partnerName)."
    }

    private var remainingBudget: Decimal {
        guard currentMonthBudget.limit > 0 else { return 0 }
        return max(currentMonthBudget.limit - currentMonthBudget.spent, 0)
    }

    private var moneyStatusHeadline: String {
        guard currentMonthBudget.limit > 0 else { return "Set a calm monthly plan" }
        if remainingBudget <= 0 { return "Budget needs a reset" }
        if budgetProgressValue > 0.9 { return "\(formattedCurrency(remainingBudget)) left" }
        if budgetProgressValue > 0.7 { return "Keep an eye on spend" }
        return "\(formattedCurrency(remainingBudget)) left"
    }

    private var moneyStatusCopy: String {
        guard currentMonthBudget.limit > 0 else {
            return "Add a monthly budget so Roost can turn spending into a shared household signal."
        }
        if remainingBudget <= 0 {
            return "This month is over plan. Open Money to adjust categories before it becomes noise."
        }
        if budgetProgressValue > 0.9 {
            return "You're close to the limit. Small choices now will keep the household plan steady."
        }
        if budgetProgressValue > 0.7 {
            return "Most of the plan is used. Roost is watching the month with you."
        }
        return "Your household budget has room. Recent spending and shared balance are in one place."
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

    private var householdRhythmHeadline: String {
        if viewModel.overdueChores.count > 0 { return "Needs a little attention" }
        if budgetProgressValue > 0.9 { return "Money is the thing today" }
        if dueTodayChores.count > 0 || uncheckedShoppingItems.count > 0 { return "A few things are moving" }
        return "Quiet and on track"
    }

    private var householdRhythmCopy: String {
        if viewModel.overdueChores.count > 0 {
            return "\(viewModel.overdueChores.count) overdue chore\(viewModel.overdueChores.count == 1 ? "" : "s") could unblock the day."
        }
        if budgetProgressValue > 0.9 {
            return "The monthly plan is nearly used, so spend decisions matter more right now."
        }
        if dueTodayChores.count > 0 {
            return "\(dueTodayChores.count) chore\(dueTodayChores.count == 1 ? "" : "s") due today, with money and shopping nearby."
        }
        if uncheckedShoppingItems.count > 0 {
            return "\(uncheckedShoppingItems.count) shopping item\(uncheckedShoppingItems.count == 1 ? "" : "s") waiting for the next run."
        }
        return "No urgent signals. Roost will surface the next household decision when it matters."
    }

    private var rhythmColors: [Color] {
        [budgetBarColor, choresDetailColor, Color.roostShoppingTint]
    }

    private var nextMove: DashboardNextMove {
        if let chore = viewModel.overdueChores.first {
            return DashboardNextMove(
                title: chore.title,
                detail: "Overdue chore. Clear it before the household queue grows.",
                action: "Open",
                icon: "exclamationmark",
                tint: .roostDestructive,
                destination: .chores,
                tasksSection: .chores
            )
        }

        if budgetProgressValue > 0.9, currentMonthBudget.limit > 0 {
            return DashboardNextMove(
                title: "Review this month's spend",
                detail: "\(budgetFootnote). A quick look now prevents end-of-month surprises.",
                action: "Review",
                icon: "chart.line.uptrend.xyaxis",
                tint: .roostPrimary,
                destination: .money,
                tasksSection: nil
            )
        }

        if let chore = dueTodayChores.first {
            return DashboardNextMove(
                title: chore.title,
                detail: "Due today\(assigneeText(for: chore)).",
                action: "Open",
                icon: "checkmark",
                tint: .roostSecondary,
                destination: .chores,
                tasksSection: .chores
            )
        }

        if uncheckedShoppingItems.count > 0 {
            return DashboardNextMove(
                title: "\(uncheckedShoppingItems.count) shopping item\(uncheckedShoppingItems.count == 1 ? "" : "s") waiting",
                detail: "Next shop: \(nextShopDetail.lowercased()). Add or clear the list before you go.",
                action: "Shop",
                icon: "cart",
                tint: .roostShoppingTint,
                destination: .shopping,
                tasksSection: .shopping
            )
        }

        return DashboardNextMove(
            title: "Check the shared budget",
            detail: "Money, chores, and shopping are calm. A quick budget glance keeps it that way.",
            action: "Money",
            icon: "leaf",
            tint: .roostPrimary,
            destination: .money,
            tasksSection: nil
        )
    }

    private func assigneeText(for chore: Chore) -> String {
        guard let assignedTo = chore.assignedTo else { return "" }
        return " for \(memberName(for: assignedTo))"
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

    private var currentMonthExpenses: [ExpenseWithSplits] {
        viewModel.expenses.filter {
            guard let date = $0.incurredOnDate else { return false }
            return Calendar.current.isDate(date, equalTo: .now, toGranularity: .month)
        }
    }

    private var topSpendingCategories: [SpendingCategorySignal] {
        let grouped = Dictionary(grouping: currentMonthExpenses) { expense in
            expense.category?.isEmpty == false ? expense.category! : "Other"
        }

        let total = currentMonthExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        guard total > 0 else { return [] }

        return grouped.map { name, expenses in
            let amount = expenses.reduce(Decimal(0)) { $0 + $1.amount }
            let amountNumber = NSDecimalNumber(decimal: amount).doubleValue
            let totalNumber = NSDecimalNumber(decimal: total).doubleValue
            return SpendingCategorySignal(
                name: name,
                amount: amount,
                share: min(max(amountNumber / totalNumber, 0), 1),
                tint: categoryColor(for: name)
            )
        }
        .sorted {
            NSDecimalNumber(decimal: $0.amount).compare(NSDecimalNumber(decimal: $1.amount)) == .orderedDescending
        }
        .prefix(3)
        .map { $0 }
    }

    private var spendingDigestTitle: String {
        guard !currentMonthExpenses.isEmpty else { return "No spend pattern yet" }
        return "\(currentMonthExpenses.count) purchase\(currentMonthExpenses.count == 1 ? "" : "s") this month"
    }

    private var spendingDigestDetail: String {
        guard let topCategory = topSpendingCategories.first else {
            return "Add expenses and Roost will turn them into a simpler household signal."
        }
        return "\(topCategory.name) is leading at \(formattedCurrency(topCategory.amount))."
    }

    private var activityDigestTitle: String {
        guard let item = viewModel.recentActivity.first else { return "Nothing new yet" }
        return "\(memberName(for: item.userID)) moved things forward"
    }

    private var activityDigestDetail: String {
        guard let item = viewModel.recentActivity.first else {
            return "Shared actions will appear here when the household starts moving."
        }
        return relativeTimestamp(item.createdAt)
    }

    private func isDueToday(_ chore: Chore) -> Bool {
        guard let dueDate = chore.dueDate, !chore.isCompleted else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
}

private let dashboardPageInset: CGFloat = 12

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

private struct SpendingCategorySignal: Identifiable {
    let id = UUID()
    let name: String
    let amount: Decimal
    let share: Double
    let tint: Color
}

private struct DashboardNextMove {
    let title: String
    let detail: String
    let action: String
    let icon: String
    let tint: Color
    let destination: NotificationRouter.AppTab
    let tasksSection: NotificationRouter.TasksSection?
}
