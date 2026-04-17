import SwiftUI

struct HazelView: View {
    @Environment(HazelViewModel.self) private var viewModel
    @Environment(HomeManager.self) private var homeManager

    private var hasProAccess: Bool {
        homeManager.home?.hasProAccess ?? false
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Hazel", accent: .roostPrimary)

                identityCard
                featuresCard
                examplesCard
                privacyNote
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
    }

    // MARK: - Identity Card

    private var identityCard: some View {
        RoostCard(padding: DesignSystem.Spacing.cardLarge) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.row) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.roostPrimary.opacity(0.18), Color.roostSecondary.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.roostPrimary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Hazel")
                            .font(.roostSection)
                            .foregroundStyle(Color.roostForeground)

                        // Live status badge
                        HStack(spacing: 5) {
                            Circle()
                                .fill(viewModel.isActive ? Color.roostSuccess : Color.roostMutedForeground)
                                .frame(width: 7, height: 7)
                            Text(viewModel.isActive ? "Active" : "Paused")
                                .font(.roostMeta)
                                .foregroundStyle(viewModel.isActive ? Color.roostSuccess : Color.roostMutedForeground)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (viewModel.isActive ? Color.roostSuccess : Color.roostMuted).opacity(viewModel.isActive ? 0.12 : 0.6),
                            in: Capsule()
                        )
                        .animation(.roostSnappy, value: viewModel.isActive)
                    }

                    Text("Your AI household assistant — normalises inputs, auto-categorises expenses, narrates your spending month, and keeps things tidy across the app.")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)

                    if viewModel.activeCount > 0 {
                        Text("Running in \(viewModel.activeCount) area\(viewModel.activeCount == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.roostPrimary)
                            .tracking(0.3)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Features Card

    private var featuresCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    ZStack {
                        Circle()
                            .fill(Color.roostPrimary.opacity(0.10))
                            .frame(width: 32, height: 32)
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.roostPrimary)
                    }
                    Text("Where Hazel runs")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                }
                .padding(.bottom, DesignSystem.Spacing.row)

                hazelToggleRow(
                    icon: "cart.fill",
                    color: .roostShoppingTint,
                    title: "Shopping",
                    description: "Normalises item names and auto-assigns categories as you add them to a list",
                    isOn: Binding(
                        get: { viewModel.shoppingEnabled },
                        set: { viewModel.shoppingEnabled = $0 }
                    )
                )

                Divider().overlay(Color.roostHairline)

                hazelToggleRow(
                    icon: "checkmark.circle.fill",
                    color: .roostChoreTint,
                    title: "Chores",
                    description: "Cleans up chore titles and suggests room assignments when you add tasks",
                    isOn: Binding(
                        get: { viewModel.choresEnabled },
                        set: { viewModel.choresEnabled = $0 }
                    )
                )

                Divider().overlay(Color.roostHairline)

                VStack(alignment: .leading, spacing: 0) {
                    hazelToggleRow(
                        icon: "dollarsign.circle.fill",
                        color: .roostMoneyTint,
                        title: "Expenses",
                        description: "Auto-categorises expenses and merchant names as you log them",
                        isOn: Binding(
                            get: { viewModel.expensesEnabled },
                            set: { viewModel.expensesEnabled = $0 }
                        )
                    )
                    .disabled(!hasProAccess)
                    .opacity(hasProAccess ? 1 : 0.55)

                    if !hasProAccess {
                        ProBadge()
                            .padding(.horizontal, DesignSystem.Spacing.card)
                            .padding(.bottom, DesignSystem.Spacing.inline)
                    }
                }

                Divider().overlay(Color.roostHairline)

                hazelToggleRow(
                    icon: "chart.bar.fill",
                    color: .roostMoneyTint,
                    title: "Budget",
                    description: "Normalises category names and suggests limits based on your spending patterns",
                    isOn: Binding(
                        get: { viewModel.budgetEnabled },
                        set: { viewModel.budgetEnabled = $0 }
                    )
                )

                Divider().overlay(Color.roostHairline)

                VStack(alignment: .leading, spacing: 0) {
                    hazelToggleRow(
                        icon: "sparkles",
                        color: .roostPrimary,
                        title: "Budget Insights",
                        description: "Monthly spending summaries written by Hazel",
                        isOn: Binding(
                            get: { viewModel.insightsEnabled },
                            set: { viewModel.insightsEnabled = $0 }
                        )
                    )
                    .disabled(!hasProAccess)
                    .opacity(hasProAccess ? 1 : 0.55)

                    if !hasProAccess {
                        ProBadge()
                            .padding(.horizontal, DesignSystem.Spacing.card)
                            .padding(.bottom, DesignSystem.Spacing.inline)
                    }
                }
            }
        }
    }

    private func hazelToggleRow(
        icon: String,
        color: Color,
        title: String,
        description: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.row) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.10))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)
                Text(description)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(FigmaSwitchToggleStyle())
        }
        .padding(.vertical, 12)
    }

    // MARK: - Examples Card

    private var examplesCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    ZStack {
                        Circle()
                            .fill(Color.roostPrimary.opacity(0.10))
                            .frame(width: 32, height: 32)
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.roostPrimary)
                    }
                    Text("How it works")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                }

                VStack(spacing: DesignSystem.Spacing.inline) {
                    ForEach(viewModel.examples) { example in
                        exampleRow(example)
                    }
                }
            }
        }
    }

    private func exampleRow(_ example: HazelViewModel.FeatureExample) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(example.area.uppercased())
                .font(.roostMeta)
                .foregroundStyle(Color.roostPrimary)
                .tracking(1.0)

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.roostMutedForeground)
                            .frame(width: 12)
                        Text(example.before)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.roostSuccess)
                            .frame(width: 12)
                        Text(example.after)
                            .font(.roostCaption.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.roostMuted.opacity(0.45),
            in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
        )
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.inline) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.top, 1)
            Text("Hazel sends your text inputs to Claude AI on Anthropic's servers via Roost's backend. Your data is never used to train AI models and is not shared with third parties.")
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.roostMuted.opacity(0.5),
            in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
        )
    }
}
