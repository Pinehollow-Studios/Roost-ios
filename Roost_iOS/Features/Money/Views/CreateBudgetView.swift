import SwiftUI

// MARK: - CreateBudgetView

struct CreateBudgetView: View {

    @Environment(HomeManager.self) private var homeManager
    @Environment(BudgetTemplateViewModel.self) private var budgetVM
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(MemberNamesHelper.self) private var memberNames
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1

    // Inline add state — mirrors MoneyBudgetsView
    @State private var inlineAddSection: String? = nil
    @State private var inlineAddName = ""
    @State private var inlineAddAmount = ""
    @State private var inlineAddDay: Int = 1
    @State private var inlineAddSaving = false

    // Remove confirmation
    @State private var removeTarget: BudgetTemplateLine? = nil

    private var sym: String { settingsVM.settings.currencySymbol }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                FigmaBackHeader(title: "Create Budget", accent: .roostMoneyTint)
                    .padding(.horizontal, DesignSystem.Spacing.page)

                // Progress dots
                SetupProgressDots(currentStep: step, totalSteps: 3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                // Step content
                ZStack {
                    if step == 1 {
                        welcomeStep
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else if step == 2 {
                        fixedCostsStep
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        lifestyleStep
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .animation(.roostSmooth, value: step)
                .padding(.horizontal, DesignSystem.Spacing.page)

                Spacer(minLength: DesignSystem.Size.tabBarHeight + DesignSystem.Spacing.screenBottom + 90)
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .safeAreaInset(edge: .bottom) { bottomBar }
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

// MARK: - Step 1: Welcome

private extension CreateBudgetView {

    var welcomeStep: some View {
        VStack(spacing: 16) {
            RoostCard(prominence: .hero(accent: .roostMoneyTint)) {
                VStack(alignment: .leading, spacing: 16) {

                    RoostIconContainer(
                        systemImage: "list.bullet.rectangle.fill",
                        tint: .roostMoneyTint,
                        size: .setup
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Set up your budget")
                            .font(.roostHeading)
                            .foregroundStyle(Color.roostForeground)
                        Text("Track every pound you plan to spend — Roost carries your budget forward each month automatically.")
                            .font(.roostBody)
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    // Explanation pills
                    HStack(spacing: 8) {
                        explanationPill(
                            icon: "lock.fill",
                            title: "Fixed costs",
                            body: "Bills & subs with set monthly amounts",
                            tint: Color.roostPrimary
                        )
                        explanationPill(
                            icon: "arrow.2.circlepath",
                            title: "Lifestyle",
                            body: "Day-to-day spend with monthly rollover",
                            tint: Color.roostMoneyTint
                        )
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    func explanationPill(icon: String, title: String, body: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.roostForeground)
            }
            Text(body)
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Step 2: Fixed costs

private extension CreateBudgetView {

    var fixedCostsStep: some View {
        VStack(spacing: 14) {
            stepHeader(
                stepNum: 2,
                icon: "lock.fill",
                title: "Fixed costs",
                body: "Bills and subscriptions with set monthly amounts. Add the ones that apply — skip any that don't."
            )
            sectionGroupsView(sections: BudgetSectionDef.all.filter { $0.isFixed })
        }
    }
}

// MARK: - Step 3: Lifestyle budgets

private extension CreateBudgetView {

    var lifestyleStep: some View {
        VStack(spacing: 14) {
            stepHeader(
                stepNum: 3,
                icon: "arrow.2.circlepath",
                title: "Lifestyle budgets",
                body: "Day-to-day spending envelopes. Unspent amounts roll over to next month automatically."
            )
            sectionGroupsView(sections: BudgetSectionDef.all.filter { !$0.isFixed })
        }
    }
}

// MARK: - Shared section components

private extension CreateBudgetView {

    func stepHeader(stepNum: Int, icon: String, title: String, body: String) -> some View {
        RoostCard(prominence: .standard) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    RoostIconContainer(
                        systemImage: icon,
                        tint: .roostMoneyTint,
                        size: .row
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("STEP \(stepNum) OF 3")
                            .font(.roostMeta)
                            .tracking(1.0)
                            .foregroundStyle(Color.roostMoneyTint)
                        Text(title)
                            .font(.roostCardTitle)
                            .foregroundStyle(Color.roostForeground)
                    }
                }
                Text(body)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
            }
        }
    }

    @ViewBuilder
    func sectionGroupsView(sections: [BudgetSectionDef]) -> some View {
        ForEach(sections) { section in
            let lines = budgetVM.activeLines
                .filter { $0.sectionGroup == section.id }
                .sorted { $0.sortOrder < $1.sortOrder }

            VStack(spacing: 0) {
                wizardSectionHeader(section: section)

                ForEach(lines) { line in
                    wizardLineRow(line: line, section: section)
                }

                if inlineAddSection == section.id {
                    inlineAddRow(section: section)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    addRow(section: section)
                }
            }
            .budgetWizardPanel()
        }
    }

    func wizardSectionHeader(section: BudgetSectionDef) -> some View {
        HStack(spacing: 10) {
            RoostIconContainer(
                systemImage: section.sfSymbol,
                tint: section.allocationColour,
                size: .custom(30, iconSize: 14)
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(section.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.roostForeground)
                Text(section.isFixed ? "Fixed" : "Lifestyle")
                    .font(.roostMeta)
                    .foregroundStyle(section.allocationColour)
            }
            Spacer()
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

    func wizardLineRow(line: BudgetTemplateLine, section: BudgetSectionDef) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(line.name)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.roostForeground)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if section.isFixed {
                    if let day = line.dayOfMonth {
                        Text(ordinal(day))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.roostMutedForeground)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.roostMuted.opacity(0.6), in: Capsule())
                            .padding(.trailing, 8)
                    }
                    Text(formatAmount(line.amount))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                } else {
                    Text(formatAmount(line.amount))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)

            Rectangle()
                .fill(Color.roostHairline)
                .frame(height: 1)
                .opacity(0.72)
                .padding(.leading, 14)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { removeTarget = line } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    // MARK: Add row (mirrors MoneyBudgetsView)

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

    // MARK: Inline add form (mirrors MoneyBudgetsView)

    @ViewBuilder
    func inlineAddRow(section: BudgetSectionDef) -> some View {
        let canSave = !inlineAddName.trimmingCharacters(in: .whitespaces).isEmpty
            && !inlineAddAmount.isEmpty
            && !inlineAddSaving

        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {

                // Name field
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

                // Amount + day row
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

                // Cancel / Save
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
                                .background(
                                    canSave ? section.allocationColour : Color.roostMuted.opacity(0.45),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(section.allocationColour.opacity(0.05))

            Rectangle()
                .fill(Color.roostHairline)
                .frame(height: 1)
                .opacity(0.72)
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
}

// MARK: - Bottom bar

private extension CreateBudgetView {

    var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                if step > 1 {
                    Button {
                        withAnimation(.roostSmooth) {
                            step -= 1
                            inlineAddSection = nil
                        }
                    } label: {
                        Text("← Back")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                            .frame(width: 90)
                            .padding(.vertical, 13)
                            .background(Color.roostMuted.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if step < 3 {
                        withAnimation(.roostSmooth) {
                            step += 1
                            inlineAddSection = nil
                        }
                    } else {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    }
                } label: {
                    Text(step == 1 ? "Let's start →" : step == 3 ? "Finish" : "Next →")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.roostMoneyTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.top, 12)
            .padding(.bottom, 12 + DesignSystem.Spacing.screenBottom)
        }
        .background(Color.roostBackground.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Helpers

private extension CreateBudgetView {

    func ordinal(_ n: Int) -> String {
        switch n % 10 {
        case 1 where n != 11: return "\(n)st"
        case 2 where n != 12: return "\(n)nd"
        case 3 where n != 13: return "\(n)rd"
        default: return "\(n)th"
        }
    }

    func formatAmount(_ value: Decimal) -> String {
        "\(sym)\(value)"
    }
}

// MARK: - Panel modifier

private extension View {
    func budgetWizardPanel() -> some View {
        self
            .background(DesignSystem.Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DesignSystem.Palette.border, lineWidth: 1)
            )
    }
}
