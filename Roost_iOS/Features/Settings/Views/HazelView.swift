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
                FigmaBackHeader(title: "Hazel Settings")

                identityCard
                aboutCard
                examplesCard
                featuresCard
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

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            HStack(spacing: DesignSystem.Spacing.row) {
                Circle()
                    .fill(Color.roostPrimary.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(Color.roostPrimary)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Hazel")
                            .font(.roostCardTitle)
                            .foregroundStyle(Color.roostForeground)

                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.roostPrimary)
                    }

                    Text(viewModel.statusLabel)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(DesignSystem.Spacing.cardLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.roostPrimary.opacity(0.1),
                            Color.roostSecondary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostBorderLight, lineWidth: 1)
        )
    }

    private var aboutCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.inline) {
                Text("What Hazel does")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)

                Text("Hazel is your AI household assistant. She normalizes your shopping items, cleans up chore titles, auto-categorizes expenses, and keeps your budget tidy — all powered by Claude AI running securely on our servers.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var examplesCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                Text("Examples")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)

                exampleRow(
                    title: "Smart shopping lists",
                    subtitle: "\"bread\" → Bakery: Bread, auto-categorized"
                )

                exampleRow(
                    title: "Chore title clean-up",
                    subtitle: "\"clean the bathroom\" → Clean Bathroom"
                )

                exampleRow(
                    title: "Expense auto-categorize",
                    subtitle: "\"Tesco\" → Groceries · Pro only"
                )

                exampleRow(
                    title: "Budget category tidy",
                    subtitle: "Normalizes category names across all entries"
                )
            }
        }
    }

    private func exampleRow(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.row) {
            Circle()
                .fill(Color.roostSuccess.opacity(0.2))
                .frame(width: 24, height: 24)
                .overlay {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostSuccess)
                }
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.roostCaption.weight(.medium))
                    .foregroundStyle(Color.roostForeground)

                Text(subtitle)
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var featuresCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Hazel Features")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)
                    .padding(.bottom, DesignSystem.Spacing.row)

                // Shopping normalization — FREE
                SettingsToggleRow(
                    title: "Smart shopping lists",
                    description: "Normalize and auto-categorize items as you add them",
                    isOn: Binding(
                        get: { viewModel.shoppingEnabled },
                        set: { viewModel.shoppingEnabled = $0 }
                    )
                )

                Divider()
                    .overlay(Color.roostBorderLight)

                // Chore suggestions — FREE
                SettingsToggleRow(
                    title: "Chore title clean-up",
                    description: "Clean up chore titles and suggest new chores",
                    isOn: Binding(
                        get: { viewModel.choresEnabled },
                        set: { viewModel.choresEnabled = $0 }
                    )
                )

                Divider()
                    .overlay(Color.roostBorderLight)

                // Expense categorization — NEST ONLY
                VStack(alignment: .leading, spacing: 0) {
                    SettingsToggleRow(
                        title: "Auto-categorize expenses",
                        description: "Let Hazel tag expenses automatically as you log them",
                        isOn: Binding(
                            get: { viewModel.expensesEnabled },
                            set: { viewModel.expensesEnabled = $0 }
                        )
                    )
                    .disabled(!hasProAccess)
                    .opacity(hasProAccess ? 1 : 0.5)

                    if !hasProAccess {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .medium))
                            Text("Roost Pro only")
                                .font(.roostMeta)
                        }
                        .foregroundStyle(Color.roostMutedForeground)
                        .padding(.horizontal, DesignSystem.Spacing.cardLarge)
                        .padding(.bottom, DesignSystem.Spacing.row)
                    }
                }

                Divider()
                    .overlay(Color.roostBorderLight)

                // Budget category normalization — FREE
                SettingsToggleRow(
                    title: "Budget category tidy",
                    description: "Normalize category names in your budget",
                    isOn: Binding(
                        get: { viewModel.budgetEnabled },
                        set: { viewModel.budgetEnabled = $0 }
                    )
                )
            }
        }
    }

    private var privacyNote: some View {
        Text("Hazel sends your text inputs to Claude AI, running securely on Anthropic's servers via Roost's backend. Your data is never used to train AI models and is not shared with third parties.")
            .font(.roostMeta)
            .foregroundStyle(Color.roostMutedForeground)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DesignSystem.Spacing.card)
            .padding(.vertical, DesignSystem.Spacing.row)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                    .fill(Color.roostMuted.opacity(0.5))
            )
    }
}
