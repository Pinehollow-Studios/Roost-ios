import SwiftUI

struct SubscriptionView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(HomeManager.self) private var homeManager
    @Environment(SubscriptionPricingStore.self) private var subscriptionPricingStore
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = SubscriptionViewModel()
    @State private var promoExpanded = false
    @State private var faqExpanded = false
    @State private var browserSession = SubscriptionBrowserSession()

    // Animation states
    @State private var glowPulsing = false
    @State private var crownAppeared = false
    @State private var shimmerPhase: CGFloat = -1.0
    @State private var featuresVisible = false
    @State private var contentAppeared = false

    private var subscriptionSyncKey: String {
        guard let home = homeManager.home else { return "nil" }
        return [
            home.id.uuidString,
            home.subscriptionStatus ?? "",
            home.subscriptionTier ?? "",
            home.trialEndsAt?.ISO8601Format() ?? "",
            home.currentPeriodEndsAt?.ISO8601Format() ?? "",
            home.stripeCustomerID ?? "",
            home.stripePriceID ?? "",
            String(home.hasUsedTrialValue)
        ].joined(separator: "|")
    }

    private var pricingSyncKey: String {
        let prices = subscriptionPricingStore.prices
        return [
            prices.monthly.id,
            prices.monthly.formattedAmount,
            String(prices.monthly.trialDays),
            prices.annual.id,
            prices.annual.formattedAmount,
            String(prices.annual.trialDays)
        ].joined(separator: "|")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Full-bleed hero — breaks out of standard padding
                heroSection
                    .padding(.horizontal, -DesignSystem.Spacing.page)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                    socialProofStrip
                    currentPlanCard

                    if showTrialBanner {
                        trialBanner
                    }

                    featuresSection
                    comparisonSection

                    if showsPlanSelector {
                        planSelectorSection
                    }

                    ctaSection

                    promoSection
                    faqSection
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
                .padding(.top, DesignSystem.Spacing.block)
                .padding(.bottom, 108)
            }
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task {
            await subscriptionPricingStore.refresh()
        }
        .task(id: subscriptionSyncKey + "|" + pricingSyncKey) {
            viewModel.sync(with: homeManager.home, prices: subscriptionPricingStore.prices)
        }
        .settingsMessageOverlay()
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowPulsing = true
            }
            withAnimation(.interpolatingSpring(stiffness: 60, damping: 10).delay(0.1)) {
                crownAppeared = true
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false).delay(0.8)) {
                shimmerPhase = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                featuresVisible = true
            }
            withAnimation(.roostSmooth.delay(0.15)) {
                contentAppeared = true
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            // Base gradient
            LinearGradient(
                colors: [Color.roostPrimary, Color.roostSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated radial glow
            RadialGradient(
                colors: [Color.white.opacity(0.18), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 140
            )
            .scaleEffect(glowPulsing ? 1.4 : 0.8)
            .offset(y: -20)

            // Decorative circle top right
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 180, height: 180)
                .offset(x: 120, y: -60)

            // Decorative circle bottom left
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 120, height: 120)
                .offset(x: -40, y: 160)

            VStack(alignment: .leading, spacing: 0) {
                // Back button
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.18), in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, DesignSystem.Spacing.screenTop)
                .padding(.leading, DesignSystem.Spacing.page)

                Spacer()

                // Crown + wordmark
                VStack(spacing: 0) {
                    // Pulsing aura rings
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 90, height: 90)
                            .scaleEffect(glowPulsing ? 1.4 : 1.0)

                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 68, height: 68)
                            .scaleEffect(glowPulsing ? 1.25 : 1.0)

                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 52, height: 52)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(crownAppeared ? 1.0 : 0.4)
                            .opacity(crownAppeared ? 1 : 0)
                    }

                    Spacer().frame(height: 18)

                    Text("Roost Pro")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(crownAppeared ? 1.0 : 0.88)
                        .opacity(crownAppeared ? 1 : 0)

                    Spacer().frame(height: 10)

                    Text("Run your home. Together.")
                        .font(.roostBody)
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .opacity(crownAppeared ? 1 : 0)
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
        }
        .frame(height: 300)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: DesignSystem.Radius.xl,
                bottomTrailingRadius: DesignSystem.Radius.xl,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
    }

    // MARK: - Current Plan Card

    private var currentPlanCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .fill(Color.roostCard)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                        .strokeBorder(currentPlanBorderGradient, lineWidth: 1.5)
                )

            HStack(alignment: .top, spacing: 14) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(currentPlanTint.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: currentPlanIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(currentPlanTint)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Current Plan")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)

                        Spacer(minLength: 0)

                        Text(currentPlanBadgeTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(currentPlanTint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(currentPlanTint.opacity(0.12), in: Capsule())
                    }

                    Text(currentPlanDescription)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)

                    if let nextBillingLine {
                        Text(nextBillingLine)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(currentPlanTint)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardLarge)
        }
    }

    private var currentPlanBorderGradient: LinearGradient {
        switch viewModel.state {
        case .active, .lifetime:
            return LinearGradient(colors: [Color.roostSuccess.opacity(0.4), Color.roostSuccess.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .trial:
            return LinearGradient(colors: [Color.roostPrimary.opacity(0.4), Color.roostSecondary.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastDue, .incomplete:
            return LinearGradient(colors: [Color.roostWarning.opacity(0.4), Color.roostWarning.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.roostHairline, Color.roostHairline], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var currentPlanIcon: String {
        switch viewModel.state {
        case .active, .lifetime: return "crown.fill"
        case .trial: return "star.fill"
        case .pastDue, .incomplete: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        default: return "house.fill"
        }
    }

    // MARK: - Trial Banner

    private var trialBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.roostPrimary.opacity(0.2), Color.roostSecondary.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: viewModel.state == .trial ? "hourglass" : "gift.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.roostPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.state == .trial ? "Trial active" : "14-day free trial")
                    .font(.roostBody.weight(.semibold))
                    .foregroundStyle(Color.roostForeground)

                Text(trialBannerCopy)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.state == .trial {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.full, style: .continuous)
                                .fill(Color.roostMuted)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.full, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.roostPrimary, Color.roostSecondary],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * min(viewModel.trialProgress, 1.0), height: 4)
                        }
                    }
                    .frame(height: 4)
                    .animation(.roostEaseOut, value: viewModel.trialProgress)
                }
            }
        }
        .padding(DesignSystem.Spacing.cardLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .fill(Color.roostPrimary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.roostPrimary.opacity(0.35), Color.roostSecondary.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Feature Showcase

    private let showcaseFeatures: [(icon: String, title: String, body: String)] = [
        ("sparkles",             "Hazel AI",            "Auto-categorizes expenses, normalizes shopping, and tidies your budget — automatically."),
        ("calendar.badge.clock", "Full Budget History",  "Navigate every past month and see exactly where your money went."),
        ("chart.pie.fill",       "Advanced Budgeting",   "Set category limits, track recurring costs, and carry budgets forward."),
        ("bell.badge.fill",      "Smart Notifications",  "Get nudged when chores are overdue, bills are due, or budgets are tight."),
        ("square.grid.2x2.fill", "Room Groups",          "Organise chores and shopping by room — kitchen, bathroom, living room and more."),
        ("person.2.fill",        "Unlimited Members",    "Add everyone in the home — no limits, no extra cost."),
    ]

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Everything you unlock")
                .font(.roostSection)
                .foregroundStyle(Color.roostForeground)

            VStack(spacing: 10) {
                ForEach(Array(showcaseFeatures.enumerated()), id: \.offset) { index, feature in
                    featureShowcaseCard(feature: feature, index: index)
                }
            }
        }
    }

    private func featureShowcaseCard(
        feature: (icon: String, title: String, body: String),
        index: Int
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.roostPrimary.opacity(0.18), Color.roostSecondary.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.roostPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.roostBody.weight(.semibold))
                    .foregroundStyle(Color.roostForeground)

                Text(feature.body)
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.roostPrimary.opacity(0.22), Color.roostSecondary.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(featuresVisible ? 1 : 0)
        .offset(y: featuresVisible ? 0 : 14)
        .animation(.roostSmooth.delay(Double(index) * 0.06), value: featuresVisible)
    }

    // MARK: - Social Proof

    private var socialProofStrip: some View {
        HStack(spacing: 0) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.roostWarning)
                }
            }

            Text(" 4.8")
                .font(.roostLabel)
                .foregroundStyle(Color.roostForeground)

            Rectangle()
                .fill(Color.roostHairline)
                .frame(width: 1, height: 14)
                .padding(.horizontal, 10)

            Text("2,000+ households")
                .font(.roostLabel)
                .foregroundStyle(Color.roostMutedForeground)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, DesignSystem.Spacing.card)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .strokeBorder(Color.roostHairline, lineWidth: 1)
        )
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 8)
    }

    // MARK: - Comparison Table

    private struct ComparisonRow {
        let feature: String
        let freeLabel: String
        let proOnly: Bool
    }

    private let comparisonRows: [ComparisonRow] = [
        ComparisonRow(feature: "Budget & expenses",     freeLabel: "✓",        proOnly: false),
        ComparisonRow(feature: "Shopping lists",        freeLabel: "✓",        proOnly: false),
        ComparisonRow(feature: "Chores & calendar",     freeLabel: "✓",        proOnly: false),
        ComparisonRow(feature: "Budget history",        freeLabel: "1 month",  proOnly: true),
        ComparisonRow(feature: "Advanced budgeting",    freeLabel: "—",        proOnly: true),
        ComparisonRow(feature: "Hazel AI",              freeLabel: "—",        proOnly: true),
        ComparisonRow(feature: "Smart notifications",   freeLabel: "—",        proOnly: true),
        ComparisonRow(feature: "Room groups",           freeLabel: "—",        proOnly: true),
        ComparisonRow(feature: "Unlimited members",     freeLabel: "2 max",    proOnly: true),
    ]

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Free vs Pro")
                .font(.roostSection)
                .foregroundStyle(Color.roostForeground)

            RoostCard(padding: 0) {
                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("Feature")
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostMutedForeground)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Free")
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostMutedForeground)
                            .frame(width: 52, alignment: .center)

                        Text("Pro")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.roostPrimary)
                            .frame(width: 52, alignment: .center)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.card)
                    .padding(.vertical, 10)
                    .background(Color.roostMuted.opacity(0.5))

                    ForEach(Array(comparisonRows.enumerated()), id: \.offset) { index, row in
                        HStack {
                            Text(row.feature)
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostForeground)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(row.freeLabel)
                                .font(.system(size: 12, weight: row.freeLabel == "✓" ? .semibold : .regular))
                                .foregroundStyle(row.freeLabel == "✓" ? Color.roostSuccess : Color.roostMutedForeground)
                                .frame(width: 52, alignment: .center)

                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.roostPrimary)
                                .frame(width: 52, alignment: .center)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.card)
                        .padding(.vertical, 10)
                        .background(row.proOnly ? Color.roostPrimary.opacity(0.03) : Color.clear)

                        if index < comparisonRows.count - 1 {
                            Divider()
                                .background(Color.roostHairline)
                                .padding(.horizontal, DesignSystem.Spacing.card)
                        }
                    }
                }
            }
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 12)
    }

    // MARK: - Plan Selector

    private var planSelectorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose your plan")
                .font(.roostSection)
                .foregroundStyle(Color.roostForeground)

            HStack(spacing: 12) {
                upgradePlanCard(
                    plan: .monthly,
                    title: "Monthly",
                    price: monthlyPlanSubtitle,
                    footnote: "Billed monthly",
                    badge: nil
                )
                upgradePlanCard(
                    plan: .annual,
                    title: "Annual",
                    price: annualPlanSubtitle,
                    footnote: annualSavingsCopy,
                    badge: "Best Value"
                )
            }
        }
    }

    private func upgradePlanCard(
        plan: SubscriptionService.Plan,
        title: String,
        price: String,
        footnote: String,
        badge: String?
    ) -> some View {
        let isSelected = viewModel.selectedPlan == plan

        return Button {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 18)) {
                viewModel.selectedPlan = plan
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Badge row
                HStack {
                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.roostPrimary, Color.roostSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }
                    Spacer(minLength: 0)
                    // Checkmark
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.roostPrimary : Color.clear)
                            .frame(width: 20, height: 20)

                        Circle()
                            .strokeBorder(isSelected ? Color.clear : Color.roostHairline, lineWidth: 1.5)
                            .frame(width: 20, height: 20)

                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(isSelected ? 1 : 0)
                            .scaleEffect(isSelected ? 1 : 0.5)
                    }
                }
                .frame(height: 26)

                Spacer().frame(height: 12)

                Text(title)
                    .font(.roostLabel)
                    .foregroundStyle(isSelected ? Color.roostPrimary : Color.roostMutedForeground)

                Spacer().frame(height: 4)

                Text(price)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.roostForeground)

                Spacer().frame(height: 6)

                Text(footnote)
                    .font(.roostMeta)
                    .foregroundStyle(isSelected ? Color.roostPrimary : Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .fill(isSelected ? Color.roostPrimary.opacity(0.07) : Color.roostCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(colors: [Color.roostPrimary.opacity(0.6), Color.roostSecondary.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.roostHairline, Color.roostHairline], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.interpolatingSpring(stiffness: 200, damping: 18), value: isSelected)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 14) {
            if [.free, .cancelled].contains(viewModel.state) {
                gradientCTAButton
            } else {
                RoostButton(
                    title: primaryActionTitle,
                    variant: primaryActionVariant,
                    systemImage: primaryActionSymbol,
                    isLoading: viewModel.isPerformingAction
                ) {
                    Task { await openPrimaryAction() }
                }
                .disabled(primaryActionDisabled)
            }

            if let copy = supportingActionCopy {
                Text(copy)
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if let err = viewModel.errorMessage {
                Text(err)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostDestructive)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Trust badges
            HStack(spacing: 0) {
                trustBadge(icon: "xmark.circle", label: "Cancel anytime")
                Spacer(minLength: 0)
                Rectangle()
                    .fill(Color.roostHairline)
                    .frame(width: 1, height: 20)
                Spacer(minLength: 0)
                trustBadge(icon: "house", label: "Per household")
                Spacer(minLength: 0)
                Rectangle()
                    .fill(Color.roostHairline)
                    .frame(width: 1, height: 20)
                Spacer(minLength: 0)
                trustBadge(icon: "lock.fill", label: "Secure checkout")
            }
            .padding(.vertical, 12)
            .padding(.horizontal, DesignSystem.Spacing.card)
            .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                    .strokeBorder(Color.roostHairline, lineWidth: 1)
            )
        }
    }

    private var gradientCTAButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            Task { await openPrimaryAction() }
        } label: {
            ZStack {
                // Shimmer sweep
                LinearGradient(
                    colors: [.clear, .white.opacity(0.2), .clear],
                    startPoint: UnitPoint(x: shimmerPhase - 0.5, y: 0.5),
                    endPoint: UnitPoint(x: shimmerPhase + 0.5, y: 0.5)
                )

                HStack(spacing: 8) {
                    if viewModel.isPerformingAction {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(primaryActionTitle)
                        .font(.roostLabel)
                }
                .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Size.buttonHeight)
            .background(
                LinearGradient(
                    colors: [Color.roostPrimary, Color.roostSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
            .shadow(color: Color.roostPrimary.opacity(0.35), radius: 12, y: 4)
        }
        .buttonStyle(ProCTAButtonStyle())
        .disabled(viewModel.isPerformingAction)
    }

    private func trustBadge(icon: String, label: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.roostMutedForeground)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.roostMutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Promo

    private var promoSection: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: promoExpanded ? 14 : 0) {
                Button {
                    withAnimation(.roostEaseOut) { promoExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Have a promo code?")
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.roostMutedForeground)
                            .rotationEffect(.degrees(promoExpanded ? 180 : 0))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if promoExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        RoostTextField(title: "Enter code", text: $viewModel.promoCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                        RoostButton(
                            title: viewModel.isApplyingPromo ? "Applying..." : "Apply Code",
                            variant: .secondary,
                            isLoading: viewModel.isApplyingPromo
                        ) {
                            Task { await applyPromoCode() }
                        }
                        .disabled(viewModel.promoCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isApplyingPromo)

                        if viewModel.promoSuccess {
                            Text("Promo code applied. Roost Pro access will refresh automatically.")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostSuccess)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let promoError = viewModel.promoError {
                            Text(promoError)
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostDestructive)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - FAQ

    private var faqSection: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: faqExpanded ? 14 : 0) {
                Button {
                    withAnimation(.roostEaseOut) { faqExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Common questions")
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.roostMutedForeground)
                            .rotationEffect(.degrees(faqExpanded ? 180 : 0))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if faqExpanded {
                    VStack(alignment: .leading, spacing: 14) {
                        faqRow(
                            question: "Can I cancel anytime?",
                            answer: "Yes. Open Stripe billing from this page and cancel whenever you need. You keep access until the end of the billing period."
                        )
                        faqRow(
                            question: "Is Roost Pro per household or per person?",
                            answer: "Per household — one subscription covers everyone in the home."
                        )
                        faqRow(
                            question: "What happens if we downgrade?",
                            answer: "All your data stays intact. Free plan limits apply again, but nothing is ever deleted."
                        )
                        faqRow(
                            question: "Is there a free trial?",
                            answer: "Yes — 14 days of full Roost Pro access, no card required to start."
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func faqRow(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(question)
                .font(.roostCaption.weight(.semibold))
                .foregroundStyle(Color.roostForeground)
            Text(answer)
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Actions

    private func openPrimaryAction() async {
        viewModel.errorMessage = nil
        let accessToken: String
        do {
            accessToken = try await authManager.validAccessToken()
        } catch {
            viewModel.errorMessage = error.localizedDescription
            return
        }
        guard let destination = await viewModel.actionURL(
            home: homeManager.home,
            user: authManager.currentUser,
            accessToken: accessToken,
            plan: viewModel.selectedPlan
        ) else { return }

        do {
            let callbackURL = try await browserSession.start(url: destination)
            if callbackURL.host == "subscription" {
                await homeManager.refreshCurrentHome()
            }
        } catch SubscriptionBrowserError.cancelled {
            return
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func applyPromoCode() async {
        let accessToken: String
        do {
            accessToken = try await authManager.validAccessToken()
        } catch {
            viewModel.promoError = error.localizedDescription
            return
        }
        await viewModel.applyPromoCode(homeId: homeManager.home?.id, accessToken: accessToken)
        if viewModel.promoSuccess {
            await homeManager.refreshCurrentHome()
        }
    }

    // MARK: - Computed Display Properties

    private var showTrialBanner: Bool {
        switch viewModel.state {
        case .free: return !(homeManager.home?.hasUsedTrialValue ?? false)
        case .trial: return true
        default: return false
        }
    }

    private var currentPlanTint: Color {
        switch viewModel.state {
        case .free, .cancelled: return .roostMutedForeground
        case .trial: return .roostPrimary
        case .active, .lifetime: return .roostSuccess
        case .pastDue, .incomplete: return .roostWarning
        }
    }

    private var currentPlanBadgeTitle: String {
        switch viewModel.state {
        case .free: return "Free"
        case .trial: return "Trial"
        case .active: return "Pro"
        case .pastDue: return "Past Due"
        case .cancelled: return "Cancelled"
        case .incomplete: return "Incomplete"
        case .lifetime: return "Lifetime"
        }
    }

    private var currentPlanDescription: String {
        switch viewModel.state {
        case .free:
            return "You're on the free plan. Upgrade to Roost Pro for advanced budgeting, Hazel, and the full household toolkit."
        case .trial:
            return "Your household is trying Roost Pro with full access across the app."
        case .active:
            return "Roost Pro is active for this household. Billing is managed in Stripe."
        case .pastDue:
            return "A billing issue is affecting your Pro access. Open billing to update your payment details."
        case .cancelled:
            return "Your subscription has been cancelled. You can restart Roost Pro any time."
        case .incomplete:
            return "Your last checkout didn't finish. Open billing to complete the setup."
        case .lifetime:
            return "This household has lifetime Roost Pro access."
        }
    }

    private var nextBillingLine: String? {
        switch viewModel.state {
        case .trial:
            guard let trialEndDate = viewModel.trialEndDate else { return nil }
            return "Trial ends \(trialEndDate.formatted(date: .abbreviated, time: .omitted))"
        case .active, .pastDue, .incomplete:
            guard let nextBillingDate = viewModel.nextBillingDate else { return nil }
            return "Next billing: \(nextBillingDate.formatted(date: .abbreviated, time: .omitted))"
        default:
            return nil
        }
    }

    private var trialBannerCopy: String {
        if viewModel.state == .trial, let trialEndDate = viewModel.trialEndDate {
            return "You have \(viewModel.trialDaysRemaining) days left. Trial ends \(trialEndDate.formatted(date: .abbreviated, time: .omitted))."
        }
        return "Try all Roost Pro features free for 14 days before \(nestPriceLabel.lowercased()) billing begins."
    }

    private var nestPriceLabel: String {
        subscriptionPricingStore.prices.monthly.formattedAmount + "/mo"
    }

    private var monthlyPlanSubtitle: String {
        subscriptionPricingStore.prices.monthly.formattedAmount + "/mo"
    }

    private var annualPlanSubtitle: String {
        subscriptionPricingStore.prices.annual.formattedAmount + "/yr"
    }

    private var annualSavingsCopy: String {
        let monthly = subscriptionPricingStore.prices.monthly.unitAmount
        let annual = subscriptionPricingStore.prices.annual.unitAmount
        let savings = max(monthly * 12 - annual, 0)
        guard savings > 0 else { return "Billed once per year" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = subscriptionPricingStore.prices.annual.currency
        if subscriptionPricingStore.prices.annual.currency.uppercased() == "GBP" {
            formatter.currencySymbol = "£"
        }
        let amount = NSDecimalNumber(value: Double(savings) / 100)
        let savingsText = formatter.string(from: amount) ?? "less"
        return "Save \(savingsText) per year"
    }

    private var showsPlanSelector: Bool {
        switch viewModel.state {
        case .free, .cancelled: return true
        default: return false
        }
    }

    private var primaryActionTitle: String {
        switch viewModel.state {
        case .free:
            return homeManager.home?.hasUsedTrialValue == true ? "Upgrade to Roost Pro" : "Start 14-Day Free Trial"
        case .trial: return "Manage Billing"
        case .active: return "Manage Subscription"
        case .pastDue: return "Update Payment Method"
        case .cancelled: return "Restart Roost Pro"
        case .incomplete: return "Complete Subscription"
        case .lifetime: return "Lifetime Access Active"
        }
    }

    private var supportingActionCopy: String? {
        switch viewModel.state {
        case .free:
            if homeManager.home?.hasUsedTrialValue == true {
                return "Billed at \(selectedPlanPriceLabel). Managed securely in Stripe."
            }
            return "Cancel anytime. \(selectedPlanPriceLabel.capitalized) after the 14-day trial."
        case .trial: return "Open Stripe billing to manage or cancel this trial."
        case .active: return "Manage plan details, billing, and cancellation in Stripe."
        case .pastDue, .incomplete: return "Stripe will guide you through fixing the billing issue."
        case .cancelled: return "Restarting Roost Pro opens Stripe checkout for this household."
        case .lifetime: return nil
        }
    }

    private var primaryActionVariant: RoostButton.Variant {
        switch viewModel.state {
        case .pastDue, .incomplete: return .secondary
        case .lifetime: return .outline
        default: return .primary
        }
    }

    private var primaryActionSymbol: String? {
        switch viewModel.state {
        case .free, .cancelled: return "crown.fill"
        case .trial, .active: return "arrow.up.right.square"
        case .pastDue, .incomplete: return "creditcard"
        case .lifetime: return "checkmark.seal.fill"
        }
    }

    private var primaryActionDisabled: Bool {
        viewModel.isPerformingAction || viewModel.state == .lifetime
    }

    private var selectedPlanPriceLabel: String {
        switch viewModel.selectedPlan {
        case .monthly: return monthlyPlanSubtitle
        case .annual: return annualPlanSubtitle
        }
    }
}

