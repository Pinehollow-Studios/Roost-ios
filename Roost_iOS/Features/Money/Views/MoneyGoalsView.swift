import SwiftUI

// MARK: - Goal Design Tokens

private let goalPageInset: CGFloat = DesignSystem.Spacing.page
private let goalCorner: CGFloat = 12

private func goalColour(_ key: String) -> Color {
    switch key {
    case "sage":       return Color(hex: 0x36A873)
    case "amber":      return Color(hex: 0xF2A33A)
    case "blue":       return Color(hex: 0x4D8ECF)
    case "purple":     return Color(hex: 0x8F73D9)
    case "green":      return Color(hex: 0x5BAA50)
    default:           return Color(hex: 0xF06F48)
    }
}

private let goalColourKeys = ["terracotta", "sage", "amber", "blue", "purple", "green"]

// MARK: - MoneyGoalsView

struct MoneyGoalsView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(SavingsGoalsViewModel.self) private var goalsVM
    @Environment(MonthlyMoneyViewModel.self) private var summaryVM
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(ScrambleModeEnvironment.self) private var scramble

    @State private var showAddGoal = false
    @State private var selectedGoalId: UUID?
    @State private var showProUpsell = false
    @State private var completedExpanded = false
    @State private var summaryProgress: Double = 0

    private var isPro: Bool { homeManager.home?.hasProAccess ?? false }
    private var sym: String { settingsVM.settings.currencySymbol }
    private var activeGoals: [SavingsGoal] { goalsVM.activeGoals }
    private var completedGoals: [SavingsGoal] { goalsVM.completedGoals }
    private var visibleGoals: [SavingsGoal] { isPro ? activeGoals : Array(activeGoals.prefix(1)) }
    private var hiddenCount: Int { max(0, activeGoals.count - visibleGoals.count) }

    private var totalSaved: Decimal { activeGoals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Decimal { activeGoals.reduce(0) { $0 + $1.targetAmount } }
    private var totalNeeded: Decimal {
        activeGoals.compactMap(\.monthlyNeeded).reduce(0, +)
    }
    private var totalProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return min(1, max(0, NSDecimalNumber(decimal: totalSaved / totalTarget).doubleValue))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                FigmaBackHeader(title: "Goals", accent: .roostMoneyTint) {
                    addGoalButton
                }
                .padding(.horizontal, goalPageInset)

                VStack(alignment: .leading, spacing: 12) {
                    if goalsVM.isLoading && goalsVM.goals.isEmpty {
                        loadingState
                    } else if goalsVM.error != nil && goalsVM.goals.isEmpty {
                        goalsErrorState
                    } else {
                        summaryPanel

                        if activeGoals.isEmpty {
                            emptyState
                        } else {
                            activeGoalsSection

                            if hiddenCount > 0 {
                                ghostGoalsSection
                            }
                        }

                        if !completedGoals.isEmpty {
                            completedGoalsSection
                        }
                    }
                }
                .padding(.horizontal, goalPageInset)

                Spacer(minLength: DesignSystem.Spacing.screenBottom + 84)
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .navigationDestination(isPresented: $showAddGoal) {
            AddGoalPage()
        }
        .navigationDestination(
            isPresented: Binding(
                get: { selectedGoalId != nil },
                set: { if !$0 { selectedGoalId = nil } }
            )
        ) {
            if let selectedGoalId {
                GoalDetailPage(goalId: selectedGoalId)
            }
        }
        .nestUpsell(isPresented: $showProUpsell, feature: .advancedBudgeting)
        .onAppear { animateSummaryProgress() }
        .onChange(of: totalProgress) { _, _ in animateSummaryProgress() }
    }

    private var addGoalButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if !isPro && activeGoals.count >= 1 {
                showProUpsell = true
            } else {
                showAddGoal = true
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                Text("Add")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Color.roostCard)
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(Color.roostPrimary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var summaryPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Saved")
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(scramble.format(totalSaved, symbol: sym))
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color.roostForeground)
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("Target")
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(totalTarget > 0 ? scramble.format(totalTarget, symbol: sym) : "No goals")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                }
            }

            GoalProgressBar(progress: summaryProgress, tint: Color.roostPrimary, height: 8)

            HStack(spacing: 8) {
                GoalMetricTile(label: "Active", value: "\(activeGoals.count)", tint: Color.roostPrimary)
                GoalMetricTile(label: "Monthly", value: scramble.format(goalsVM.totalMonthlyContribution, symbol: sym), tint: goalColour("sage"))
                GoalMetricTile(label: "Need", value: totalNeeded > 0 ? scramble.format(totalNeeded, symbol: sym) : "-", tint: goalColour("amber"))
            }
        }
        .padding(16)
        .background(Color.roostCard.opacity(0.72), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            MoneySectionTitle(title: "Active goals", count: activeGoals.count)

            VStack(spacing: 0) {
                ForEach(Array(visibleGoals.enumerated()), id: \.element.id) { index, goal in
                    GoalLedgerRow(goal: goal, scramble: scramble, sym: sym) {
                        selectedGoalId = goal.id
                    }

                    if index < visibleGoals.count - 1 {
                        Divider()
                            .padding(.leading, 14)
                    }
                }
            }
            .background(Color.roostCard.opacity(0.74), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
        }
    }

    private var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    completedExpanded.toggle()
                }
            } label: {
                HStack {
                    MoneySectionTitle(title: "Completed", count: completedGoals.count)
                    Spacer()
                    Image(systemName: completedExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }
            .buttonStyle(.plain)

            if completedExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(completedGoals.enumerated()), id: \.element.id) { index, goal in
                        GoalLedgerRow(goal: goal, scramble: scramble, sym: sym, isCompleted: true) {
                            selectedGoalId = goal.id
                        }

                        if index < completedGoals.count - 1 {
                            Divider()
                                .padding(.leading, 14)
                        }
                    }
                }
                .background(Color.roostCard.opacity(0.58), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                        .stroke(Color.roostHairline, lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // Ghost cards for locked goals — blurred placeholder rows that hint at hidden content
    private var ghostGoalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                ForEach(0..<min(hiddenCount, 2), id: \.self) { index in
                    ghostGoalRow(index: index)
                    if index < min(hiddenCount, 2) - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .background(Color.roostCard.opacity(0.74), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                    .fill(.ultraThinMaterial)
            )

            proGateFooter
        }
    }

    private func ghostGoalRow(index: Int) -> some View {
        let tints: [Color] = [goalColour("blue"), goalColour("purple"), goalColour("sage")]
        let tint = tints[index % tints.count]
        return HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(tint.opacity(0.5))
                .frame(width: 5, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.roostMuted)
                    .frame(width: 100, height: 13)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.roostMuted)
                    .frame(width: 70, height: 10)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.roostMuted)
                    .frame(width: 48, height: 13)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.roostMuted)
                    .frame(width: 30, height: 10)
            }
        }
        .padding(13)
    }

    private var proGateFooter: some View {
        Button {
            showProUpsell = true
        } label: {
            HStack(spacing: 10) {
                RoostIconBadge(systemImage: "lock.fill", tint: goalColour("amber"), size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(hiddenCount) more goal\(hiddenCount == 1 ? "" : "s")")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.roostForeground)
                    Text("Upgrade to track every target.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roostMutedForeground)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .padding(12)
            .background(Color.roostCard.opacity(0.64), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var goalsErrorState: some View {
        VStack(spacing: 12) {
            RoostIconBadge(systemImage: "exclamationmark.triangle.fill", tint: goalColour("amber"), size: 42)
            Text("Couldn't load goals")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.roostForeground)
            Button("Try again") {
                Task {
                    guard let homeId = homeManager.homeId else { return }
                    await goalsVM.load(homeId: homeId)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.roostPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 52)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                RoostIconBadge(systemImage: "flag.checkered", tint: Color.roostPrimary, size: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text("No goals yet")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.roostForeground)
                    Text("Set a target amount and monthly contribution.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }

            Button {
                showAddGoal = true
            } label: {
                Text("Add first goal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.roostCard)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.roostPrimary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.roostCard.opacity(0.72), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.roostPrimary)
            Text("Loading goals")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.roostMutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }

    private func animateSummaryProgress() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            summaryProgress = totalProgress
        }
    }
}

// MARK: - Goal Row

private struct GoalLedgerRow: View {
    let goal: SavingsGoal
    let scramble: ScrambleModeEnvironment
    let sym: String
    var isCompleted = false
    let onTap: () -> Void

    @State private var progress: Double = 0

    private var tint: Color { goalColour(goal.colour) }
    private var remaining: Decimal { max(0, goal.targetAmount - goal.savedAmount) }

    private var status: (String, Color) {
        if isCompleted || goal.isCompleted {
            return ("Complete", goalColour("sage"))
        }
        guard let contribution = goal.monthlyContribution else {
            return ("Needs plan", goalColour("amber"))
        }
        guard let needed = goal.monthlyNeeded else {
            return ("Funded monthly", goalColour("blue"))
        }
        return contribution >= needed ? ("On track", goalColour("sage")) : ("Short", goalColour("terracotta"))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(tint)
                        .frame(width: 5, height: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 7) {
                            Text(goal.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.roostForeground)
                                .lineLimit(1)

                            Text(status.0)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(status.1)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(status.1.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                        }

                        Text(subtitle)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color.roostMutedForeground)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(scramble.format(goal.savedAmount, symbol: sym))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.roostForeground)
                        Text("\(Int(goal.progress * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(tint)
                    }
                }

                GoalProgressBar(progress: progress, tint: tint, height: 6)
            }
            .padding(13)
            .opacity(isCompleted ? 0.68 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear { animate() }
        .onChange(of: goal.progress) { _, _ in animate() }
    }

    private var subtitle: String {
        var parts: [String] = [scramble.format(remaining, symbol: sym) + " left"]
        if let monthlyContribution = goal.monthlyContribution {
            parts.append(scramble.format(monthlyContribution, symbol: sym) + "/mo")
        }
        if let targetDate = goal.targetDate {
            parts.append(goalDateFormatter.string(from: targetDate))
        }
        return parts.joined(separator: " · ")
    }

    private func animate() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            progress = goal.progress
        }
    }
}

// MARK: - Goal Detail Page

private struct GoalDetailPage: View {
    let goalId: UUID

    @Environment(SavingsGoalsViewModel.self) private var goalsVM
    @Environment(HomeManager.self) private var homeManager
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(ScrambleModeEnvironment.self) private var scramble
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var addSavingsText = ""
    @State private var contributionText = ""
    @State private var contributionDay = 1
    @State private var showDeleteConfirm = false
    @State private var showCompleteConfirm = false
    @State private var isWorking = false
    @State private var progress = 0.0
    @State private var errorMessage: String?

    private enum Field {
        case addSavings
        case contribution
    }

    private var goal: SavingsGoal? { goalsVM.goals.first(where: { $0.id == goalId }) }
    private var sym: String { settingsVM.settings.currencySymbol }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                FigmaBackHeader(title: goal?.name ?? "Goal")
                    .padding(.horizontal, goalPageInset)

                if let goal {
                    detailContent(goal)
                        .padding(.horizontal, goalPageInset)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                }

                Spacer(minLength: DesignSystem.Spacing.screenBottom + 48)
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { focusedField = nil }
        .onAppear {
            if let goal {
                hydrateContribution(goal)
                animate(goal)
            }
        }
        .onChange(of: goal?.id) { _, _ in
            if let goal {
                hydrateContribution(goal)
                animate(goal)
            }
        }
        .confirmationDialog("Mark as complete?", isPresented: $showCompleteConfirm, titleVisibility: .visible) {
            Button("Mark complete") { completeGoal() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This moves the goal to completed.")
        }
        .confirmationDialog("Delete goal?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteGoal() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private func detailContent(_ goal: SavingsGoal) -> some View {
        let tint = goalColour(goal.colour)
        let remaining = max(0, goal.targetAmount - goal.savedAmount)
        let contribution = goal.monthlyContribution ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Saved")
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostMutedForeground)
                        Text(scramble.format(goal.savedAmount, symbol: sym))
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Color.roostForeground)
                    }

                    Spacer()

                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }

                GoalProgressBar(progress: progress, tint: tint, height: 9)

                HStack(spacing: 8) {
                    GoalMetricTile(label: "Left", value: scramble.format(remaining, symbol: sym), tint: tint)
                    GoalMetricTile(label: "Target", value: scramble.format(goal.targetAmount, symbol: sym), tint: Color.roostPrimary)
                    GoalMetricTile(label: "Date", value: goal.targetDate.map(goalDateFormatter.string(from:)) ?? "-", tint: goalColour("amber"))
                }
            }
            .padding(16)
            .background(Color.roostCard.opacity(0.74), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 12) {
                MoneySectionTitle(title: "Add money")

                HStack(spacing: 8) {
                    GoalCurrencyField(
                        symbol: sym,
                        placeholder: "0.00",
                        text: $addSavingsText,
                        focused: $focusedField,
                        equals: .addSavings
                    )

                    Button {
                        addSavings(goal)
                    } label: {
                        Text("Add")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.roostCard)
                            .frame(width: 74, height: 44)
                            .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isWorking || (Decimal(string: addSavingsText) ?? 0) <= 0)
                    .opacity((Decimal(string: addSavingsText) ?? 0) > 0 ? 1 : 0.45)
                }
            }
            .padding(14)
            .background(Color.roostCard.opacity(0.66), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    MoneySectionTitle(title: "Monthly plan")
                    Spacer()
                    Text(contribution > 0 ? "\(scramble.format(contribution, symbol: sym))/mo" : "Not set")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(contribution > 0 ? tint : Color.roostMutedForeground)
                }

                if let needed = goal.monthlyNeeded {
                    Text("Needed: \(scramble.format(needed, symbol: sym))/mo")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.roostMutedForeground)
                }

                HStack(spacing: 8) {
                    GoalCurrencyField(
                        symbol: sym,
                        placeholder: "0.00",
                        text: $contributionText,
                        focused: $focusedField,
                        equals: .contribution
                    )

                    GoalDayStepper(day: $contributionDay, tint: tint)
                }

                HStack(spacing: 8) {
                    Button {
                        saveContribution(goal)
                    } label: {
                        Text("Save plan")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.roostCard)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isWorking || (Decimal(string: contributionText) ?? 0) <= 0)

                    if goal.monthlyContribution != nil {
                        Button {
                            removeContribution(goal)
                        } label: {
                            Text("Remove")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.roostDestructive)
                                .frame(width: 92, height: 40)
                                .background(Color.roostMuted.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(isWorking)
                    }
                }
            }
            .padding(14)
            .background(Color.roostCard.opacity(0.66), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.roostDestructive)
            }

            if !goal.isCompleted {
                VStack(spacing: 0) {
                    GoalActionRow(title: "Mark complete", systemImage: "checkmark.circle.fill", tint: goalColour("sage")) {
                        showCompleteConfirm = true
                    }

                    Divider()

                    GoalActionRow(title: "Delete goal", systemImage: "trash", tint: Color.roostDestructive) {
                        showDeleteConfirm = true
                    }
                }
                .background(Color.roostCard.opacity(0.56), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                        .stroke(Color.roostHairline, lineWidth: 1)
                )
            }
        }
    }

    private func hydrateContribution(_ goal: SavingsGoal) {
        contributionText = goal.monthlyContribution.map { "\($0)" } ?? ""
        contributionDay = min(28, max(1, goal.contributionDay ?? 1))
    }

    private func animate(_ goal: SavingsGoal) {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            progress = goal.progress
        }
    }

    private func addSavings(_ goal: SavingsGoal) {
        guard let amount = Decimal(string: addSavingsText), amount > 0 else { return }
        focusedField = nil
        isWorking = true
        errorMessage = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            do {
                try await goalsVM.addToGoal(id: goal.id, amount: amount)
                addSavingsText = ""
            } catch {
                errorMessage = "Couldn't add money. Try again."
            }
            isWorking = false
        }
    }

    private func saveContribution(_ goal: SavingsGoal) {
        guard let homeId = homeManager.homeId,
              let amount = Decimal(string: contributionText),
              amount > 0 else { return }
        focusedField = nil
        isWorking = true
        errorMessage = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            do {
                try await goalsVM.setGoalContribution(
                    goalId: goal.id,
                    homeId: homeId,
                    existingBudgetLineId: goal.budgetLineId,
                    name: goal.name,
                    amount: amount,
                    contributionDay: contributionDay
                )
            } catch {
                errorMessage = "Couldn't save plan. Try again."
            }
            isWorking = false
        }
    }

    private func removeContribution(_ goal: SavingsGoal) {
        isWorking = true
        errorMessage = nil
        Task {
            do {
                if let lineId = goal.budgetLineId {
                    try await goalsVM.removeGoalContribution(goalId: goal.id, budgetLineId: lineId)
                } else {
                    try await goalsVM.clearContributionFields(goalId: goal.id)
                }
                contributionText = ""
            } catch {
                errorMessage = "Couldn't remove plan. Try again."
            }
            isWorking = false
        }
    }

    private func completeGoal() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isWorking = true
        Task {
            try? await goalsVM.completeGoal(id: goalId)
            isWorking = false
            dismiss()
        }
    }

    private func deleteGoal() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        isWorking = true
        Task {
            if let goal, let lineId = goal.budgetLineId {
                try? await goalsVM.removeGoalContribution(goalId: goalId, budgetLineId: lineId)
            }
            try? await goalsVM.deleteGoal(id: goalId)
            isWorking = false
            dismiss()
        }
    }
}

// MARK: - Add Goal Page

private struct AddGoalPage: View {
    @Environment(SavingsGoalsViewModel.self) private var goalsVM
    @Environment(HomeManager.self) private var homeManager
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var name = ""
    @State private var targetAmountText = ""
    @State private var targetDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var hasTargetDate = true
    @State private var selectedColour = "terracotta"
    @State private var hasContribution = true
    @State private var contributionText = ""
    @State private var contributionDay = 1
    @State private var isSaving = false
    @State private var errorMessage: String?

    private enum Field {
        case name
        case target
        case contribution
    }

    private var sym: String { settingsVM.settings.currencySymbol }
    private var targetAmount: Decimal? { Decimal(string: targetAmountText) }
    private var contribution: Decimal? { Decimal(string: contributionText) }
    private var tint: Color { goalColour(selectedColour) }

    private var monthsToTarget: Int? {
        guard hasTargetDate else { return nil }
        let comps = Calendar.current.dateComponents([.month], from: Date(), to: targetDate)
        return comps.month.map { max(1, $0) }
    }

    private var monthlyNeeded: Decimal? {
        guard hasTargetDate,
              let months = monthsToTarget,
              let target = targetAmount,
              target > 0 else { return nil }
        return target / Decimal(months)
    }

    private var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasTarget = (targetAmount ?? 0) > 0
        let hasValidContribution = !hasContribution || ((contribution ?? 0) > 0)
        return hasName && hasTarget && hasValidContribution
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                FigmaBackHeader(title: "New goal")
                    .padding(.horizontal, goalPageInset)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        GoalTextInput(
                            label: "Name",
                            placeholder: "Holiday, emergency fund, sofa",
                            text: $name,
                            focused: $focusedField,
                            equals: .name
                        )

                        GoalCurrencyField(
                            label: "Target",
                            symbol: sym,
                            placeholder: "0.00",
                            text: $targetAmountText,
                            focused: $focusedField,
                            equals: .target
                        )
                    }
                    .padding(14)
                    .background(Color.roostCard.opacity(0.72), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                            .stroke(Color.roostHairline, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        MoneySectionTitle(title: "Target date")

                        HStack(spacing: 8) {
                            GoalChoiceButton(title: "Set date", isSelected: hasTargetDate, tint: tint) {
                                withAnimation(.easeInOut(duration: 0.18)) { hasTargetDate = true }
                            }
                            GoalChoiceButton(title: "No date", isSelected: !hasTargetDate, tint: tint) {
                                withAnimation(.easeInOut(duration: 0.18)) { hasTargetDate = false }
                            }
                        }

                        if hasTargetDate {
                            DatePicker("", selection: $targetDate, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(tint)

                            if let needed = monthlyNeeded {
                                Text("\(sym)\(needed.formatted()) per month keeps this on track.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.roostCard.opacity(0.62), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                            .stroke(Color.roostHairline, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        MoneySectionTitle(title: "Monthly plan")

                        HStack(spacing: 8) {
                            GoalChoiceButton(title: "Monthly", isSelected: hasContribution, tint: tint) {
                                withAnimation(.easeInOut(duration: 0.18)) { hasContribution = true }
                            }
                            GoalChoiceButton(title: "Later", isSelected: !hasContribution, tint: tint) {
                                withAnimation(.easeInOut(duration: 0.18)) { hasContribution = false }
                            }
                        }

                        if hasContribution {
                            HStack(spacing: 8) {
                                GoalCurrencyField(
                                    symbol: sym,
                                    placeholder: "0.00",
                                    text: $contributionText,
                                    focused: $focusedField,
                                    equals: .contribution
                                )
                                GoalDayStepper(day: $contributionDay, tint: tint)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.roostCard.opacity(0.62), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                            .stroke(Color.roostHairline, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        MoneySectionTitle(title: "Colour")
                        HStack(spacing: 10) {
                            ForEach(goalColourKeys, id: \.self) { key in
                                let colour = goalColour(key)
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedColour = key
                                } label: {
                                    Circle()
                                        .fill(colour)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColour == key ? Color.roostForeground : Color.clear, lineWidth: 2)
                                        )
                                        .overlay {
                                            if selectedColour == key {
                                                Circle()
                                                    .fill(Color.roostCard)
                                                    .frame(width: 8, height: 8)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.roostCard.opacity(0.58), in: RoundedRectangle(cornerRadius: goalCorner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: goalCorner, style: .continuous)
                            .stroke(Color.roostHairline, lineWidth: 1)
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.roostDestructive)
                    }

                    Button {
                        save()
                    } label: {
                        Text(isSaving ? "Saving..." : "Create goal")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.roostCard)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(canSave ? tint : Color.roostMutedForeground.opacity(0.35), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave || isSaving)
                    .padding(.top, 2)
                }
                .padding(.horizontal, goalPageInset)

                Spacer(minLength: DesignSystem.Spacing.screenBottom + 48)
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { focusedField = nil }
    }

    private func save() {
        guard let homeId = homeManager.homeId,
              let target = targetAmount else { return }

        focusedField = nil
        errorMessage = nil
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            var createdGoal: SavingsGoal?
            do {
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let goal = CreateSavingsGoal(
                    homeId: homeId,
                    name: trimmedName,
                    targetAmount: target,
                    savedAmount: 0,
                    colour: selectedColour,
                    icon: nil,
                    targetDate: hasTargetDate ? targetDate : nil,
                    sortOrder: nil,
                    monthlyContribution: nil,
                    contributionDay: nil
                )
                let created = try await goalsVM.addGoal(goal)
                createdGoal = created

                if hasContribution, let contribution, contribution > 0 {
                    try await goalsVM.setGoalContribution(
                        goalId: created.id,
                        homeId: homeId,
                        existingBudgetLineId: nil,
                        name: trimmedName,
                        amount: contribution,
                        contributionDay: contributionDay
                    )
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            } catch {
                if let createdGoal {
                    try? await goalsVM.deleteGoal(id: createdGoal.id)
                }
                errorMessage = "Couldn't save goal. Check the details and try again."
            }
            isSaving = false
        }
    }
}

// MARK: - Shared Pieces

private struct MoneySectionTitle: View {
    let title: String
    var count: Int?

    var body: some View {
        HStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.7)
                .foregroundStyle(Color.roostMutedForeground)
            if let count {
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.roostMuted.opacity(0.75), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }
}

private struct GoalMetricTile: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.roostMutedForeground)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.roostForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }
}

private struct GoalProgressBar: View {
    let progress: Double
    let tint: Color
    var height: CGFloat = 7

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.roostMuted.opacity(0.7))
                Capsule()
                    .fill(tint)
                    .frame(width: max(height, geo.size.width * min(1, max(0, progress))))
            }
        }
        .frame(height: height)
    }
}

private struct GoalTextInput<Field: Hashable>: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Field?>.Binding
    let equals: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color.roostMutedForeground)
            TextField(placeholder, text: $text)
                .focused(focused, equals: equals)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.roostForeground)
                .submitLabel(.done)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.roostMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.roostHairline, lineWidth: 1)
                )
        }
    }
}

private struct GoalCurrencyField<Field: Hashable>: View {
    var label: String?
    let symbol: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Field?>.Binding
    let equals: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Color.roostMutedForeground)
            }
            HStack(spacing: 8) {
                Text(symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
                TextField(placeholder, text: $text)
                    .keyboardType(.decimalPad)
                    .focused(focused, equals: equals)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.roostForeground)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Color.roostMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
        }
    }
}

private struct GoalChoiceButton: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.roostCard : Color.roostMutedForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isSelected ? tint : Color.roostMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.roostHairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct GoalDayStepper: View {
    @Binding var day: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Button {
                day = max(1, day - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.roostForeground)
                    .background(Color.roostMuted.opacity(0.7), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(spacing: 1) {
                Text("Day")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
                Text("\(day)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 42)

            Button {
                day = min(28, day + 1)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.roostForeground)
                    .background(Color.roostMuted.opacity(0.7), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
        .background(Color.roostMuted.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }
}

private struct GoalActionRow: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tint)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }
}

private let goalDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM"
    return formatter
}()
