import SwiftUI

// MARK: - Main View

struct BudgetCategoriesSettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(HomeManager.self) private var homeManager
    @Environment(BudgetCarrySettings.self) private var budgetCarrySettings
    @Environment(BudgetViewModel.self) private var viewModel

    @State private var editingRow: BudgetLimitRowData?
    @State private var saveToast: String?
    @State private var customName = ""
    @State private var customEmoji = BudgetCategoryCatalog.customIconOptions.first?.emoji ?? "⭐"
    @State private var customColorKey = BudgetCategoryCatalog.customColorKeys.first ?? "slate"
    @FocusState private var customNameFocused: Bool

    private var settingsMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    }

    private var editableCategories: [BudgetCategoryDefinition] {
        BudgetCategoryCatalog.mergeCategories(custom: viewModel.customCategories)
    }

    private var existingNames: Set<String> {
        Set(editableCategories.map { $0.name.lowercased() })
    }

    private var availablePresets: [BudgetCategoryDefinition] {
        BudgetCategoryCatalog.optionalPresetCategories.filter { !existingNames.contains($0.name.lowercased()) }
    }

    private var currentMonthLabel: String {
        settingsMonth.formatted(.dateTime.month(.wide).year())
    }

    private var currentMonthBudgets: [Budget] {
        viewModel.budgets.filter {
            Calendar.current.isDate($0.month, equalTo: settingsMonth, toGranularity: .month)
        }
    }

    private var currentMonthBudgetLookup: [String: Budget] {
        Dictionary(uniqueKeysWithValues: currentMonthBudgets.map { ($0.category.lowercased(), $0) })
    }

    private var editableLimitRows: [BudgetLimitRowData] {
        editableCategories.map { category in
            BudgetLimitRowData(
                category: category,
                currentBudget: currentMonthBudgetLookup[category.name.lowercased()]
            )
        }
    }

    private var customNamePreview: String {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "New Category" : trimmed
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Budget Categories")

                Text("Set this month's limits, add the categories your home actually uses, and carry good habits forward without rebuilding the whole budget.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                monthlyLimitsSection
                rolloverModeSection
                presetsSection

                if !viewModel.customCategories.isEmpty {
                    customCategoriesSection
                }

                createCategorySection
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task(id: homeManager.homeId) {
            guard let homeId = homeManager.homeId,
                  viewModel.budgets.isEmpty,
                  viewModel.customCategories.isEmpty else { return }
            await viewModel.load(homeId: homeId)
        }
        .sheet(item: $editingRow) { row in
            BudgetLimitEditorSheet(
                row: row,
                onSave: { amount in
                    guard let homeId = homeManager.homeId,
                          let userId = authManager.currentUser?.id else { return false }
                    let didSave = await viewModel.saveBudget(
                        category: row.category.name,
                        amount: amount,
                        homeId: homeId,
                        userId: userId,
                        month: settingsMonth
                    )
                    if didSave { saveToast = "Budget saved" }
                    return didSave
                },
                onClear: {
                    guard let homeId = homeManager.homeId,
                          let userId = authManager.currentUser?.id,
                          let currentBudget = row.currentBudget
                            ?? currentMonthBudgetLookup[row.category.name.lowercased()]
                    else { return false }
                    let didClear = await viewModel.deleteBudget(currentBudget, homeId: homeId, userId: userId)
                    if didClear { saveToast = "Budget cleared" }
                    return didClear
                }
            )
        }
        .overlay(alignment: .bottom) {
            toastOverlay
        }
        .task(id: saveToast) {
            guard saveToast != nil else { return }
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.roostEaseOut) { saveToast = nil }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var monthlyLimitsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            Text("Monthly budget limits")
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)

            Text("These limits are for \(currentMonthLabel). Leave a category blank if you do not want a cap on it.")
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            if budgetCarrySettings.mode == .manual,
               !viewModel.hasBudgets(in: settingsMonth),
               viewModel.canCarryForwardBudgets(into: settingsMonth) {
                carryForwardBanner
            }

            VStack(spacing: DesignSystem.Spacing.inline) {
                ForEach(editableLimitRows) { row in
                    BudgetLimitDisplayRow(row: row) {
                        editingRow = row
                    }
                }
            }
        }
    }

    private var carryForwardBanner: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    RoostIconBadge(systemImage: "arrow.trianglehead.clockwise", tint: .roostPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carry last month forward")
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                        Text("Start \(currentMonthLabel) with the same limits instead of setting everything again.")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                RoostButton(title: "Use last month's limits", variant: .outline, systemImage: "clock.arrow.circlepath") {
                    guard let homeId = homeManager.homeId,
                          let userId = authManager.currentUser?.id else { return }
                    Task {
                        await viewModel.copyBudgetsFromPreviousMonth(
                            into: settingsMonth, homeId: homeId, userId: userId
                        )
                    }
                }
            }
        }
    }

    private var rolloverModeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            Text("Monthly rollover")
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)

            Text("By default, Roost carries your category limits into each new month automatically. Switch to manual if you want to set every month from scratch.")
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ForEach(BudgetCarryMode.allCases) { mode in
                    let isSelected = budgetCarrySettings.mode == mode
                    Button { budgetCarrySettings.mode = mode } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: mode.symbolName)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(mode.title)
                                    .font(.roostLabel)
                            }
                            .foregroundStyle(isSelected ? Color.roostCard : Color.roostForeground)

                            Text(mode.subtitle)
                                .font(.roostCaption)
                                .foregroundStyle(isSelected ? Color.roostCard.opacity(0.86) : Color.roostMutedForeground)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(DesignSystem.Spacing.card)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                                .fill(isSelected ? Color.roostPrimary : Color.roostSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                                .stroke(isSelected ? Color.clear : Color.roostHairline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            Text("Add more categories")
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)

            Text("These are the common extras from the Mac app. Add them once and they will appear everywhere budgets and expense categories are used.")
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            if availablePresets.isEmpty {
                RoostSectionSurface(emphasis: .subtle) {
                    Text("You've already added all of the preset categories.")
                        .font(.roostBody)
                        .foregroundStyle(Color.roostMutedForeground)
                }
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: DesignSystem.Spacing.inline
                ) {
                    ForEach(availablePresets) { category in
                        Button {
                            guard let homeId = homeManager.homeId,
                                  let userId = authManager.currentUser?.id else { return }
                            Task {
                                await viewModel.addCustomCategory(
                                    name: category.name,
                                    emoji: category.emoji,
                                    color: category.colorKey,
                                    homeId: homeId,
                                    userId: userId
                                )
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 10) {
                                    CategoryGlyph(category: category)
                                    Spacer(minLength: 0)
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(BudgetCategoryCatalog.tint(for: category.colorKey))
                                }
                                Text(category.name)
                                    .font(.roostBody.weight(.medium))
                                    .foregroundStyle(Color.roostForeground)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(DesignSystem.Spacing.card)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                                    .fill(Color.roostSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                                    .stroke(Color.roostHairline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var customCategoriesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            Text("Your added categories")
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)

            Text("Remove categories you no longer need. Any monthly limits tied to them are removed too.")
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: DesignSystem.Spacing.inline) {
                ForEach(viewModel.customCategories) { category in
                    let def = BudgetCategoryDefinition(
                        name: category.name,
                        emoji: category.emoji,
                        systemImage: BudgetCategoryCatalog.systemImage(forStoredEmoji: category.emoji),
                        colorKey: category.color ?? "slate",
                        isCustom: true
                    )
                    RoostSectionSurface(emphasis: .subtle) {
                        HStack(spacing: 12) {
                            CategoryGlyph(category: def)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(category.name)
                                    .font(.roostBody.weight(.medium))
                                    .foregroundStyle(Color.roostForeground)
                                Text("Available in budgets and expenses")
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }

                            Spacer(minLength: 0)

                            Button {
                                guard let homeId = homeManager.homeId,
                                      let userId = authManager.currentUser?.id else { return }
                                Task {
                                    await viewModel.deleteCustomCategory(category, homeId: homeId, userId: userId)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.roostDestructive)
                                    .frame(width: 44, height: 44)
                                    .background(Color.roostDestructive.opacity(0.08), in: Circle())
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var createCategorySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            Text("Create a custom category")
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)

            Text("Give it a name, pick a symbol, choose its colour, and it will appear in the budget page and expense flows.")
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            RoostSectionSurface(emphasis: .subtle) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostForeground)

                        TextField("e.g. Pets, Coffee, DIY", text: $customName)
                            .focused($customNameFocused)
                            .font(.roostBody)
                            .foregroundStyle(Color.roostForeground)
                            .tint(Color.roostPrimary)
                            .submitLabel(.done)
                            .onSubmit { customNameFocused = false }
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(
                                Color.roostInput,
                                in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                                    .stroke(
                                        customNameFocused ? Color.roostPrimary.opacity(0.5) : Color.roostHairline,
                                        lineWidth: 1
                                    )
                            )
                            .animation(.easeInOut(duration: 0.15), value: customNameFocused)
                    }

                    // Symbol picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Symbol")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostForeground)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                            spacing: 8
                        ) {
                            ForEach(BudgetCategoryCatalog.customIconOptions) { option in
                                let isSelected = customEmoji == option.emoji
                                Button { customEmoji = option.emoji } label: {
                                    Image(systemName: option.systemImage)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(
                                            isSelected
                                                ? BudgetCategoryCatalog.tint(for: customColorKey)
                                                : Color.roostForeground
                                        )
                                        .frame(width: 42, height: 42)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(
                                                    isSelected
                                                        ? BudgetCategoryCatalog.fill(for: customColorKey)
                                                        : Color.roostCard
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(
                                                    isSelected
                                                        ? BudgetCategoryCatalog.stroke(for: customColorKey)
                                                        : Color.roostHairline,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.12), value: isSelected)
                            }
                        }
                    }

                    // Colour picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Colour")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostForeground)

                        HStack(spacing: 10) {
                            ForEach(BudgetCategoryCatalog.customColorKeys, id: \.self) { key in
                                let isSelected = customColorKey == key
                                Button { customColorKey = key } label: {
                                    Circle()
                                        .fill(BudgetCategoryCatalog.tint(for: key))
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            if isSelected {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(Color.white)
                                            }
                                        }
                                        .overlay(
                                            Circle().stroke(Color.roostCard, lineWidth: isSelected ? 3 : 0)
                                        )
                                        .frame(width: 44, height: 44)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.12), value: isSelected)
                            }
                        }
                    }

                    // Preview
                    RoostSectionSurface(emphasis: .grouped, padding: 12) {
                        HStack(spacing: 12) {
                            CategoryGlyph(category: .init(
                                name: customNamePreview,
                                emoji: customEmoji,
                                systemImage: BudgetCategoryCatalog.systemImage(forStoredEmoji: customEmoji),
                                colorKey: customColorKey,
                                isCustom: true
                            ))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(customNamePreview)
                                    .font(.roostBody.weight(.medium))
                                    .foregroundStyle(Color.roostForeground)
                                Text("Preview")
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    // Add button
                    RoostButton(title: "Add category", systemImage: "plus") {
                        guard let homeId = homeManager.homeId,
                              let userId = authManager.currentUser?.id else { return }
                        let name = customName
                        let emoji = customEmoji
                        let color = customColorKey
                        customName = ""
                        customEmoji = BudgetCategoryCatalog.customIconOptions.first?.emoji ?? "⭐"
                        customColorKey = BudgetCategoryCatalog.customColorKeys.first ?? "slate"
                        customNameFocused = false
                        Task {
                            await viewModel.addCustomCategory(
                                name: name, emoji: emoji, color: color,
                                homeId: homeId, userId: userId
                            )
                        }
                    }
                    .disabled(
                        customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || homeManager.homeId == nil
                            || authManager.currentUser == nil
                    )
                }
            }
        }
    }

    // MARK: - Toast

    @ViewBuilder
    private var toastOverlay: some View {
        VStack(spacing: 8) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostCard)
                    .padding(.horizontal, DesignSystem.Spacing.card)
                    .padding(.vertical, 10)
                    .background(Color.roostDestructive, in: Capsule())
                    .onTapGesture { viewModel.errorMessage = nil }
            }
            if let saveToast {
                Text(saveToast)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostCard)
                    .padding(.horizontal, DesignSystem.Spacing.card)
                    .padding(.vertical, 10)
                    .background(Color.roostSuccess, in: Capsule())
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.page)
        .padding(.bottom, DesignSystem.Size.toastBottomOffset)
    }
}

// MARK: - Supporting Types

private struct BudgetLimitRowData: Identifiable, Hashable {
    let category: BudgetCategoryDefinition
    let currentBudget: Budget?

    var id: String { category.id }
    var currentLimit: Decimal? { currentBudget?.amount }
}

// MARK: - Category Glyph

private struct CategoryGlyph: View {
    let category: BudgetCategoryDefinition

    var body: some View {
        Image(systemName: category.systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(BudgetCategoryCatalog.tint(for: category.colorKey))
            .frame(width: 38, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BudgetCategoryCatalog.fill(for: category.colorKey))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(BudgetCategoryCatalog.stroke(for: category.colorKey), lineWidth: 1)
            )
    }
}

// MARK: - Budget Limit Display Row

private struct BudgetLimitDisplayRow: View {
    let row: BudgetLimitRowData
    let onTap: () -> Void

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "GBP"
        return f
    }()

    private func formatted(_ amount: Decimal) -> String {
        Self.currencyFormatter.string(from: amount as NSDecimalNumber)
            ?? "£\(NSDecimalNumber(decimal: amount).stringValue)"
    }

    var body: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack(spacing: 12) {
                    CategoryGlyph(category: row.category)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.category.name)
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                        Text(
                            row.currentLimit.map { "Limit: \(formatted($0)) / month" }
                                ?? "No limit set"
                        )
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                    }

                    Spacer(minLength: 0)

                    if row.category.isCustom {
                        RoostStatusPill(
                            title: "Custom",
                            tint: BudgetCategoryCatalog.tint(for: row.category.colorKey)
                        )
                    }
                }

                // Tap-to-edit button
                Button(action: onTap) {
                    HStack(spacing: 10) {
                        Text("£")
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostMutedForeground)

                        Text(row.currentLimit.map { formatted($0) } ?? "Set limit")
                            .font(.roostBody)
                            .foregroundStyle(row.currentLimit == nil ? Color.roostMutedForeground : Color.roostForeground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text("/mo")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)

                        Spacer(minLength: 0)

                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BudgetCategoryCatalog.tint(for: row.category.colorKey))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color.roostInput,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                row.currentLimit == nil
                                    ? Color.roostHairline
                                    : BudgetCategoryCatalog.stroke(for: row.category.colorKey),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Budget Limit Editor Sheet

private struct BudgetLimitEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let row: BudgetLimitRowData
    let onSave: (Decimal) async -> Bool
    let onClear: () async -> Bool

    @State private var draft: String
    @State private var isSaving = false
    @FocusState private var amountFocused: Bool

    init(
        row: BudgetLimitRowData,
        onSave: @escaping (Decimal) async -> Bool,
        onClear: @escaping () async -> Bool
    ) {
        self.row = row
        self.onSave = onSave
        self.onClear = onClear
        _draft = State(initialValue: Self.formattedDraftString(for: row.currentLimit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoostSheetHeader(
                title: row.category.name,
                subtitle: "Set a monthly limit",
                onCancel: { dismiss() }
            )

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                // Amount input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly amount")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostForeground)

                    HStack(spacing: 12) {
                        Text("£")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.roostMutedForeground)

                        TextField("0", text: $draft)
                            .focused($amountFocused)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.roostForeground)
                            .tint(Color.roostPrimary)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .onChange(of: draft) { _, newValue in
                                let filtered = Self.filteredText(from: newValue)
                                if filtered != newValue { draft = filtered }
                            }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 72)
                    .background(
                        Color.roostInput,
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                BudgetCategoryCatalog.stroke(for: row.category.colorKey),
                                lineWidth: amountFocused ? 2 : 1
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { amountFocused = true }
                    .animation(.easeInOut(duration: 0.15), value: amountFocused)
                }

                Text("Tap the amount to edit. Nothing changes until you press Save.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .padding(.top, DesignSystem.Spacing.section)

            Spacer(minLength: 0)

            // Action buttons
            HStack(spacing: 10) {
                if row.currentLimit != nil {
                    Button {
                        Task { await clearLimit() }
                    } label: {
                        Text("Remove")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostDestructive)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(Color.roostDestructive.opacity(0.08), in: Capsule())
                            .overlay(Capsule().stroke(Color.roostDestructive.opacity(0.18), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }

                Spacer(minLength: 0)

                Button {
                    Task { await saveLimit() }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.roostCard)
                                .scaleEffect(0.8)
                        }
                        Text(isSaving ? "Saving..." : "Save")
                            .font(.roostLabel)
                    }
                    .foregroundStyle(Color.roostCard)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(Color.roostPrimary, in: Capsule())
                    .opacity(canSave ? 1 : 0.5)
                }
                .buttonStyle(.plain)
                .disabled(isSaving || !canSave)
            }
        }
        .padding(DesignSystem.Spacing.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.roostBackground.ignoresSafeArea())
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.hidden)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Save") {
                    Task { await saveLimit() }
                }
                .font(.roostLabel)
                .foregroundStyle(canSave ? Color.roostPrimary : Color.roostMutedForeground)
                .disabled(!canSave || isSaving)
            }
        }
        .task {
            // Small delay lets the sheet finish its presentation animation
            try? await Task.sleep(for: .milliseconds(180))
            amountFocused = true
        }
    }

    // MARK: - Computed

    private var canSave: Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let amount = Self.decimal(from: trimmed),
              amount > 0 else { return false }
        guard let currentLimit = row.currentLimit else { return true }
        return amount != currentLimit
    }

    // MARK: - Actions

    @MainActor
    private func saveLimit() async {
        guard !isSaving else { return }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Self.decimal(from: trimmed), amount > 0 else { return }
        isSaving = true
        amountFocused = false
        let didSave = await onSave(amount)
        isSaving = false
        if didSave { dismiss() }
    }

    @MainActor
    private func clearLimit() async {
        guard !isSaving, row.currentLimit != nil else { return }
        isSaving = true
        amountFocused = false
        let didClear = await onClear()
        isSaving = false
        if didClear { dismiss() }
    }

    // MARK: - Helpers

    private static func decimal(from text: String) -> Decimal? {
        Decimal(string: text.replacingOccurrences(of: ",", with: "."))
    }

    private static func filteredText(from text: String) -> String {
        var result = ""
        var usedSeparator = false

        for character in text {
            if character.isWholeNumber {
                result.append(character)
            } else if character == "." || character == "," {
                guard !usedSeparator else { continue }
                usedSeparator = true
                result.append(".")
            }
        }

        if let separatorIndex = result.firstIndex(of: ".") {
            let fractionalStart = result.index(after: separatorIndex)
            let fractional = result[fractionalStart...]
            if fractional.count > 2 {
                result = String(result[..<fractionalStart] + fractional.prefix(2))
            }
        }

        return result
    }

    private static func formattedDraftString(for amount: Decimal?) -> String {
        guard let amount else { return "" }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.minimumIntegerDigits = 1
        formatter.numberStyle = .decimal
        return formatter.string(from: amount as NSDecimalNumber)
            ?? NSDecimalNumber(decimal: amount).stringValue
    }
}
