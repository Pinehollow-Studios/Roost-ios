import SwiftUI

// MARK: - Colour helper

private func goalColour(_ key: String) -> Color {
    switch key {
    case "sage":       return Color(hex: 0x9DB19F)
    case "amber":      return Color(hex: 0xE6A563)
    case "blue":       return Color(hex: 0x6CA3C8)
    case "purple":     return Color(hex: 0xC97A9B)
    case "green":      return Color(hex: 0x7FA087)
    default:           return Color(hex: 0xD4815E) // terracotta
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
    @State private var selectedGoal: SavingsGoal? = nil
    @State private var showNestUpsell = false
    @State private var completedExpanded = false

    private var isNest: Bool { homeManager.home?.hasProAccess ?? false }
    private var sym: String { settingsVM.settings.currencySymbol }

    private var activeGoals: [SavingsGoal] { goalsVM.activeGoals }
    private var completedGoals: [SavingsGoal] { goalsVM.completedGoals }
    private var goalsToShow: [SavingsGoal] {
        isNest ? activeGoals : Array(activeGoals.prefix(1))
    }
    private var hiddenCount: Int { activeGoals.count - goalsToShow.count }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    FigmaBackHeader(title: "Goals")
                        .padding(.horizontal, Spacing.md)

                    if !activeGoals.isEmpty {
                        contributionSummaryCard
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.sm)
                            .padding(.bottom, Spacing.sm)
                    }

                    SectionHeader(title: "SAVING TOWARD")
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, 4)

                    if goalsVM.isLoading && goalsVM.goals.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .padding(.vertical, Spacing.xl)
                    } else if goalsVM.error != nil && goalsVM.goals.isEmpty {
                        goalsErrorState
                    } else if activeGoals.isEmpty {
                        emptyState
                    } else {
                        ForEach(goalsToShow) { goal in
                            GoalCard(goal: goal, scramble: scramble, sym: sym) {
                                selectedGoal = goal
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.sm)
                        }

                        if hiddenCount > 0 {
                            proGateFooter
                                .padding(.horizontal, Spacing.md)
                                .padding(.bottom, Spacing.sm)
                        }
                    }

                    // Add goal inline link
                    Button {
                        if !isNest && activeGoals.count >= 1 {
                            showNestUpsell = true
                        } else {
                            showAddGoal = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle")
                            Text("Add saving goal")
                        }
                        .font(.roostBody)
                        .foregroundStyle(Color.roostAccent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                    }

                    if !completedGoals.isEmpty {
                        completedGoalsSection
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.md)
                    }

                    Spacer(minLength: 100)
                }
            }

            FigmaFloatingActionButton(systemImage: "plus") {
                if !isNest && activeGoals.count >= 1 {
                    showNestUpsell = true
                } else {
                    showAddGoal = true
                }
            }
            .padding(.trailing, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet()
        }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailSheet(goalId: goal.id)
        }
        .nestUpsell(isPresented: $showNestUpsell, feature: .advancedBudgeting)
        .onChange(of: goalsVM.goals) { _, _ in
            // Keep selectedGoal fresh
            if let g = selectedGoal {
                selectedGoal = goalsVM.goals.first(where: { $0.id == g.id })
            }
        }
    }

    // MARK: - Contribution summary card

    private var contributionSummaryCard: some View {
        let total = goalsVM.totalMonthlyContribution
        let surplus: Decimal? = summaryVM.summary.map { $0.surplus > 0 ? $0.surplus : 0 }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly contributions")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(scramble.format(total, symbol: sym))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.roostForeground)
                }
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(goalColour("sage"))
            }

            if let surplus, surplus > 0 {
                Divider()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(goalColour("sage"))
                    Text("Your monthly surplus is \(scramble.format(surplus, symbol: sym))")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Pro gate footer

    private var proGateFooter: some View {
        Button { showNestUpsell = true } label: {
            HStack {
                Text("Unlock \(hiddenCount) more goal\(hiddenCount == 1 ? "" : "s") with Roost Pro →")
                    .font(.roostBody)
                Spacer()
            }
            .foregroundStyle(Color.roostAccent)
            .padding(Spacing.md)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Completed goals section

    private var completedGoalsSection: some View {
        DisclosureGroup(
            isExpanded: $completedExpanded,
            content: {
                VStack(spacing: Spacing.sm) {
                    ForEach(completedGoals) { goal in
                        GoalCard(goal: goal, scramble: scramble, sym: sym, isCompleted: true) {
                            selectedGoal = goal
                        }
                    }
                }
                .padding(.top, Spacing.sm)
            },
            label: {
                SectionHeader(title: "COMPLETED (\(completedGoals.count))")
            }
        )
    }

    // MARK: - Error state

    private var goalsErrorState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: 0xE6A563))
            Text("Couldn't load goals")
                .font(.roostBody.weight(.medium))
                .foregroundStyle(Color.roostForeground)
            Button("Try again") {
                Task {
                    guard let homeId = homeManager.homeId else { return }
                    await goalsVM.load(homeId: homeId)
                }
            }
            .font(.roostCaption)
            .foregroundStyle(Color(hex: 0xD4795E))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "star.circle")
                .font(.system(size: 44))
                .foregroundStyle(Color.roostMutedForeground)
            Text("No saving goals yet")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
            Text("Add your first goal to start tracking your savings.")
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
                .multilineTextAlignment(.center)
            Button("Add goal") { showAddGoal = true }
                .font(.roostBody)
                .foregroundStyle(Color.roostAccent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - GoalCard

private struct GoalCard: View {
    let goal: SavingsGoal
    let scramble: ScrambleModeEnvironment
    let sym: String
    var isCompleted: Bool = false
    let onTap: () -> Void

    @State private var animatedProgress: Double = 0

    private var colour: Color { goalColour(goal.colour) }
    private var progressFraction: Double { goal.progress }

    private var statusLabel: String {
        if isCompleted { return "Complete" }
        guard goal.monthlyContribution != nil else { return "Unfunded" }
        guard goal.targetDate != nil else { return "No deadline" }
        if let needed = goal.monthlyNeeded,
           let contrib = goal.monthlyContribution,
           contrib >= needed {
            return "On track"
        }
        return "Behind"
    }

    private var statusColour: Color {
        switch statusLabel {
        case "On track", "Complete": return goalColour("sage")
        case "Behind", "Unfunded":   return goalColour("terracotta")
        default:                      return Color.roostMutedForeground
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(colour.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(colour, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(progressFraction * 100))%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(colour)
                }
                .frame(width: 60, height: 60)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animatedProgress = progressFraction
                    }
                }
                .onChange(of: progressFraction) { _, newVal in
                    withAnimation(.easeOut(duration: 0.6)) {
                        animatedProgress = newVal
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(Color.roostForeground)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(scramble.format(goal.savedAmount, symbol: sym))
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostForeground)
                        Text("of \(scramble.format(goal.targetAmount, symbol: sym))")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    HStack(spacing: 6) {
                        // Status pill
                        Text(statusLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(statusColour)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(statusColour.opacity(0.12), in: Capsule())

                        if let target = goal.targetDate {
                            Text(target, style: .date)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                    }

                    if let contrib = goal.monthlyContribution, !isCompleted {
                        Text("\(scramble.format(contrib, symbol: sym))/mo")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .padding(Spacing.md)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(isCompleted ? 0.65 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - GoalDetailSheet

private struct GoalDetailSheet: View {
    let goalId: UUID

    @Environment(SavingsGoalsViewModel.self) private var goalsVM
    @Environment(HomeManager.self) private var homeManager
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(ScrambleModeEnvironment.self) private var scramble
    @Environment(\.dismiss) private var dismiss

    @State private var showAddSavings = false
    @State private var addSavingsText = ""
    @State private var showEditContribution = false
    @State private var showDeleteConfirm = false
    @State private var showCompleteConfirm = false
    @State private var isWorking = false
    @State private var animatedProgress: Double = 0

    private var goal: SavingsGoal? {
        goalsVM.goals.first(where: { $0.id == goalId })
    }
    private var sym: String { settingsVM.settings.currencySymbol }

    var body: some View {
        NavigationStack {
            Group {
                if let goal {
                    detailContent(goal: goal)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(goal?.name ?? "Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func detailContent(goal: SavingsGoal) -> some View {
        let colour = goalColour(goal.colour)
        let progress = goal.progress

        ScrollView {
            VStack(spacing: Spacing.lg) {

                // Large ring
                ZStack {
                    Circle()
                        .stroke(colour.opacity(0.15), lineWidth: 10)
                        .frame(width: 140, height: 140)
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(colour, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 140, height: 140)
                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(colour)
                        Text("saved")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) { animatedProgress = progress }
                }
                .onChange(of: progress) { _, val in
                    withAnimation(.easeOut(duration: 0.6)) { animatedProgress = val }
                }

                // Amount row
                HStack(spacing: 0) {
                    VStack {
                        Text(scramble.format(goal.savedAmount, symbol: sym))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.roostForeground)
                        Text("saved")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                    .frame(maxWidth: .infinity)
                    Divider().frame(height: 36)
                    VStack {
                        Text(scramble.format(goal.targetAmount - goal.savedAmount, symbol: sym))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.roostForeground)
                        Text("remaining")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                    .frame(maxWidth: .infinity)
                    Divider().frame(height: 36)
                    VStack {
                        Text(scramble.format(goal.targetAmount, symbol: sym))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.roostForeground)
                        Text("target")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, Spacing.sm)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, Spacing.md)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(colour.opacity(0.15)).frame(height: 8)
                        Capsule().fill(colour).frame(width: geo.size.width * animatedProgress, height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, Spacing.md)

                // Add savings section
                VStack(spacing: 0) {
                    if !showAddSavings {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) { showAddSavings = true }
                        } label: {
                            Label("Add savings", systemImage: "plus.circle.fill")
                                .font(.roostBody)
                                .foregroundStyle(colour)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Spacing.md)
                        }
                    } else {
                        VStack(spacing: Spacing.sm) {
                            HStack {
                                Text(sym)
                                    .foregroundStyle(Color.roostMutedForeground)
                                TextField("Amount", text: $addSavingsText)
                                    .keyboardType(.decimalPad)
                                    .font(.roostBody)
                            }
                            .padding(Spacing.sm)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            HStack(spacing: Spacing.sm) {
                                Button("Cancel") {
                                    withAnimation { showAddSavings = false; addSavingsText = "" }
                                }
                                .foregroundStyle(Color.roostMutedForeground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button("Confirm") {
                                    confirmAddSavings(goal: goal)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(colour)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .disabled(isWorking || Decimal(string: addSavingsText) == nil)
                            }
                        }
                        .padding(Spacing.md)
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, Spacing.md)

                // Contribution section
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Monthly contribution")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                            if let contrib = goal.monthlyContribution {
                                Text(scramble.format(contrib, symbol: sym) + "/mo")
                                    .font(.roostBody.weight(.medium))
                                    .foregroundStyle(Color.roostForeground)
                                if let day = goal.contributionDay {
                                    Text("Day \(day) of each month")
                                        .font(.roostCaption)
                                        .foregroundStyle(Color.roostMutedForeground)
                                }
                            } else {
                                Text("Not set")
                                    .font(.roostBody)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                        }
                        Spacer()
                        Button(goal.monthlyContribution == nil ? "Set up" : "Edit") {
                            showEditContribution = true
                        }
                        .font(.roostCaption)
                        .foregroundStyle(colour)
                    }
                    .padding(Spacing.md)

                    if let needed = goal.monthlyNeeded {
                        Divider().padding(.horizontal, Spacing.md)
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(Color.roostMutedForeground)
                            Text("Need \(scramble.format(needed, symbol: sym))/mo to reach target")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                        .padding(Spacing.md)
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, Spacing.md)

                // Target date
                if let target = goal.targetDate {
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(colour)
                        Text("Target date: ")
                            .foregroundStyle(Color.roostMutedForeground)
                        + Text(target, style: .date)
                            .foregroundStyle(Color.roostForeground)
                        if let months = goal.monthsRemaining {
                            Spacer()
                            Text("\(months)mo left")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                    }
                    .font(.roostCaption)
                    .padding(Spacing.md)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, Spacing.md)
                }

                // Actions
                if !goal.isCompleted {
                    VStack(spacing: 0) {
                        Button {
                            showCompleteConfirm = true
                        } label: {
                            Label("Mark as complete", systemImage: "checkmark.circle.fill")
                                .font(.roostBody)
                                .foregroundStyle(goalColour("sage"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Spacing.md)
                        }

                        Divider().padding(.horizontal, Spacing.md)

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete goal", systemImage: "trash")
                                .font(.roostBody)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Spacing.md)
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, Spacing.md)
                }

                Spacer(minLength: Spacing.xl)
            }
            .padding(.top, Spacing.md)
        }
        .sheet(isPresented: $showEditContribution) {
            EditContributionSheet(goalId: goalId)
        }
        .confirmationDialog("Mark as complete?", isPresented: $showCompleteConfirm, titleVisibility: .visible) {
            Button("Mark complete") {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                Task {
                    isWorking = true
                    try? await goalsVM.completeGoal(id: goalId)
                    isWorking = false
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will move the goal to your completed list.")
        }
        .confirmationDialog("Delete goal?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    isWorking = true
                    // Remove budget line if linked
                    if let lineId = goal.budgetLineId {
                        try? await goalsVM.removeGoalContribution(goalId: goalId, budgetLineId: lineId)
                    }
                    try? await goalsVM.deleteGoal(id: goalId)
                    isWorking = false
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private func confirmAddSavings(goal: SavingsGoal) {
        guard let amount = Decimal(string: addSavingsText), amount > 0 else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            isWorking = true
            try? await goalsVM.addToGoal(id: goalId, amount: amount)
            withAnimation { showAddSavings = false; addSavingsText = "" }
            isWorking = false
        }
    }
}

// MARK: - AddGoalSheet

private struct AddGoalSheet: View {
    @Environment(SavingsGoalsViewModel.self) private var goalsVM
    @Environment(HomeManager.self) private var homeManager
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var targetAmountText = ""
    @State private var targetDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var hasTargetDate = false
    @State private var selectedColour = "terracotta"
    @State private var hasContribution = false
    @State private var contributionText = ""
    @State private var contributionDay = 1
    @State private var isSaving = false

    private var sym: String { settingsVM.settings.currencySymbol }
    private var targetAmount: Decimal? { Decimal(string: targetAmountText) }
    private var contribution: Decimal? { Decimal(string: contributionText) }

    private var monthsToTarget: Int? {
        guard hasTargetDate else { return nil }
        let cal = Calendar.current
        let comps = cal.dateComponents([.month], from: Date(), to: targetDate)
        return comps.month.map { max(0, $0) }
    }

    private var monthlyNeeded: Decimal? {
        guard let months = monthsToTarget, months > 0,
              let target = targetAmount else { return nil }
        return target / Decimal(months)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && targetAmount != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {

                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Goal name")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                        TextField("e.g. Holiday, New car…", text: $name)
                            .font(.roostBody)
                            .padding(Spacing.sm)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Target amount
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Target amount")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                        HStack {
                            Text(sym)
                                .foregroundStyle(Color.roostMutedForeground)
                            TextField("0.00", text: $targetAmountText)
                                .keyboardType(.decimalPad)
                                .font(.roostBody)
                        }
                        .padding(Spacing.sm)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Target date
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(isOn: $hasTargetDate) {
                            Text("Target date")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                        .tint(goalColour(selectedColour))

                        if hasTargetDate {
                            DatePicker(
                                "",
                                selection: $targetDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()

                            if let months = monthsToTarget {
                                Text("\(months) month\(months == 1 ? "" : "s") to reach target")
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                            if let needed = monthlyNeeded {
                                Text("You'd need to save \(sym)\(needed.formatted()) per month")
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                        }
                    }

                    // Colour swatches
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Colour")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                        HStack(spacing: 12) {
                            ForEach(goalColourKeys, id: \.self) { key in
                                let c = goalColour(key)
                                Button {
                                    selectedColour = key
                                } label: {
                                    ZStack {
                                        Circle().fill(c).frame(width: 32, height: 32)
                                        if selectedColour == key {
                                            Circle()
                                                .stroke(.white, lineWidth: 2)
                                                .frame(width: 32, height: 32)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Monthly contribution
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $hasContribution) {
                            Text("Monthly contribution")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                        .tint(goalColour(selectedColour))

                        if hasContribution {
                            HStack {
                                Text(sym)
                                    .foregroundStyle(Color.roostMutedForeground)
                                TextField("0.00", text: $contributionText)
                                    .keyboardType(.decimalPad)
                                    .font(.roostBody)
                                Text("/ month")
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                            .padding(Spacing.sm)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            Stepper("Day \(contributionDay) of month", value: $contributionDay, in: 1...28)
                                .font(.roostBody)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .navigationTitle("New goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private func save() {
        guard let homeId = homeManager.homeId,
              let target = targetAmount else { return }

        isSaving = true
        Task {
            do {
                let contrib = hasContribution ? contribution : nil
                let day = hasContribution ? contributionDay : nil
                let goal = CreateSavingsGoal(
                    homeId: homeId,
                    name: name.trimmingCharacters(in: .whitespaces),
                    targetAmount: target,
                    savedAmount: 0,
                    colour: selectedColour,
                    targetDate: hasTargetDate ? targetDate : nil,
                    monthlyContribution: contrib,
                    contributionDay: day
                )
                try await goalsVM.addGoal(goal)

                // Wire up budget template line if contribution specified
                if hasContribution, let contrib, let day {
                    if let created = goalsVM.activeGoals.last {
                        try? await goalsVM.setGoalContribution(
                            goalId: created.id,
                            homeId: homeId,
                            existingBudgetLineId: nil,
                            name: name.trimmingCharacters(in: .whitespaces),
                            amount: contrib,
                            contributionDay: day
                        )
                    }
                }

                dismiss()
            } catch {
                // Non-fatal — dismiss anyway
                dismiss()
            }
            isSaving = false
        }
    }
}

// MARK: - EditContributionSheet

private struct EditContributionSheet: View {
    let goalId: UUID

    @Environment(SavingsGoalsViewModel.self) private var goalsVM
    @Environment(HomeManager.self) private var homeManager
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(ScrambleModeEnvironment.self) private var scramble
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var contributionDay = 1
    @State private var isSaving = false

    private var sym: String { settingsVM.settings.currencySymbol }
    private var goal: SavingsGoal? { goalsVM.goals.first(where: { $0.id == goalId }) }
    private var amount: Decimal? { Decimal(string: amountText) }
    private var canSave: Bool { amount != nil && amount! > 0 }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Monthly amount")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                    HStack {
                        Text(sym).foregroundStyle(Color.roostMutedForeground)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.roostBody)
                        Text("/ month").foregroundStyle(Color.roostMutedForeground)
                    }
                    .padding(Spacing.sm)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Stepper("Day \(contributionDay) of month", value: $contributionDay, in: 1...28)
                    .font(.roostBody)

                if let goal, let needed = goal.monthlyNeeded {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.roostMutedForeground)
                        Text("You need \(scramble.format(needed, symbol: sym))/mo to reach your target on time")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }

                if goal?.monthlyContribution != nil {
                    Button("Remove contribution", role: .destructive) {
                        removeContribution()
                    }
                    .font(.roostBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding(Spacing.md)
            .navigationTitle("Monthly contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave || isSaving)
                }
            }
            .onAppear {
                if let goal {
                    if let c = goal.monthlyContribution {
                        amountText = "\(c)"
                    }
                    contributionDay = goal.contributionDay ?? 1
                }
            }
        }
    }

    private func save() {
        guard let homeId = homeManager.homeId,
              let amount, let goal else { return }
        isSaving = true
        Task {
            try? await goalsVM.setGoalContribution(
                goalId: goalId,
                homeId: homeId,
                existingBudgetLineId: goal.budgetLineId,
                name: goal.name,
                amount: amount,
                contributionDay: contributionDay
            )
            isSaving = false
            dismiss()
        }
    }

    private func removeContribution() {
        guard let goal, let lineId = goal.budgetLineId else {
            // No linked template line — just clear fields on goal
            Task {
                try? await goalsVM.clearContributionFields(goalId: goalId)
                dismiss()
            }
            return
        }
        Task {
            isSaving = true
            try? await goalsVM.removeGoalContribution(goalId: goalId, budgetLineId: lineId)
            isSaving = false
            dismiss()
        }
    }
}
