import SwiftUI

// MARK: - Feature Context

struct ProFeatureContext {
    let icon: String
    let title: String
    let description: String

    static let budgetHistory = ProFeatureContext(
        icon: "calendar.badge.clock",
        title: "Budget History",
        description: "Navigate through past months to review your full spending history."
    )
    static let budgetInsights = ProFeatureContext(
        icon: "sparkles",
        title: "Hazel Budget Insights",
        description: "Get AI-written plain-English summaries of your monthly spending."
    )
    static let advancedBudgeting = ProFeatureContext(
        icon: "chart.pie",
        title: "Advanced Budgeting",
        description: "Unlock multiple savings goals, full month-by-month spending trends, and a month comparison view."
    )
    static let roomGroups = ProFeatureContext(
        icon: "square.grid.2x2",
        title: "Room Groups",
        description: "Organise your home by room so chores and shopping are easier to manage."
    )
    static let choreSuggestions = ProFeatureContext(
        icon: "lightbulb.fill",
        title: "AI Chore Suggestions",
        description: "Hazel suggests new chores for the month based on your household routine."
    )
    static let hazelBulkCategorize = ProFeatureContext(
        icon: "sparkles",
        title: "Smart Expense Sorting",
        description: "Let Hazel automatically categorize all your uncategorized expenses in one tap."
    )
}

// MARK: - Pro Upsell Sheet

struct ProUpsellSheet: View {
    let feature: ProFeatureContext

    @Environment(AuthManager.self) private var authManager
    @Environment(HomeManager.self) private var homeManager
    @Environment(SubscriptionPricingStore.self) private var pricingStore
    @Environment(NotificationRouter.self) private var notificationRouter
    @Environment(\.dismiss) private var dismiss

    @State private var isStartingCheckout = false
    @State private var errorMessage: String?
    @State private var browserSession = SubscriptionBrowserSession()

    // Animation states
    @State private var heroAppeared = false
    @State private var shimmerPhase: CGFloat = -1.0
    @State private var featuresVisible = false

    private var hasUsedTrial: Bool { homeManager.home?.hasUsedTrialValue ?? false }
    private var monthlyPrice: String { pricingStore.prices.monthly.formattedAmount }

    private var upgradeTitle: String {
        hasUsedTrial ? "Upgrade to Roost Pro" : "Start Your Free Trial"
    }
    private var upgradeSubtitle: String {
        hasUsedTrial
            ? "Billed at \(monthlyPrice)/mo. Cancel anytime."
            : "14 days free, then \(monthlyPrice)/mo. Cancel anytime."
    }

    private let proHighlights: [(icon: String, title: String)] = [
        ("sparkles",             "Hazel AI — categorize, narrate, and sort"),
        ("lightbulb.fill",       "AI chore suggestions each month"),
        ("calendar.badge.clock", "Full budget history, every month"),
        ("chart.pie.fill",       "Advanced budgeting with category limits"),
        ("bell.badge.fill",      "Smart chore and expense notifications"),
        ("square.grid.2x2.fill", "Room groups for organised chores"),
        ("person.2.fill",        "Unlimited household members"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                heroSection
                    .zIndex(1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        lockedFeatureCard
                        proHighlightsSection
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.roostMeta)
                                .foregroundStyle(Color.roostDestructive)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 4)
                        }
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.proBg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .colorScheme(.dark)
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 55, damping: 9).delay(0.08)) {
                heroAppeared = true
            }
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false).delay(0.6)) {
                shimmerPhase = 2.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                featuresVisible = true
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack {
            // Aurora drift background
            ProAuroraBackground()

            // Thin amber hairline at bottom
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.proAmber.opacity(0.25))
                    .frame(height: 1)
            }

            // Content
            VStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(DesignSystem.ProPalette.gradientH)
                    .scaleEffect(heroAppeared ? 1.0 : 0.3)
                    .opacity(heroAppeared ? 1 : 0)
                    .proGlow()

                VStack(spacing: 6) {
                    HStack(spacing: 0) {
                        Text("Roost ")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.proWarmWhite)
                        Text("Pro")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(DesignSystem.ProPalette.gradientH)
                    }
                    .scaleEffect(heroAppeared ? 1.0 : 0.85)
                    .opacity(heroAppeared ? 1 : 0)

                    Text("Your home, elevated.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.proBodyText)
                        .tracking(0.3)
                        .opacity(heroAppeared ? 1 : 0)
                }
            }
            .padding(.vertical, 28)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 188)
    }

    // MARK: - Locked Feature Card

    private var lockedFeatureCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.proCopper.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.proAmber)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(feature.title)
                        .font(.roostBody.weight(.semibold))
                        .foregroundStyle(Color.proWarmWhite)

                    ProBadge()
                }

                Text(feature.description)
                    .font(.roostCaption)
                    .foregroundStyle(Color.proMutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.proCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .strokeBorder(Color.proAmber.opacity(0.18), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(DesignSystem.ProPalette.gradient)
                .frame(width: 3)
                .padding(.vertical, 12)
        }
    }

    // MARK: - Pro Highlights

    private var proHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT YOU UNLOCK")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.proMutedText)
                .tracking(1.2)

            VStack(spacing: 8) {
                ForEach(Array(proHighlights.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.proCopper.opacity(0.15))
                                .frame(width: 32, height: 32)

                            Image(systemName: item.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.proAmber)
                        }

                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.proWarmWhite)

                        Spacer(minLength: 0)
                    }
                    .opacity(featuresVisible ? 1 : 0)
                    .offset(y: featuresVisible ? 0 : 18)
                    .animation(
                        .spring(response: 0.38, dampingFraction: 0.76).delay(0.28 + Double(index) * 0.065),
                        value: featuresVisible
                    )
                }
            }
        }
        .padding(16)
        .background(Color.proCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .strokeBorder(Color.proAmber.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await openCheckout() }
            } label: {
                ZStack {
                    DesignSystem.ProPalette.gradientH

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: shimmerPhase - 0.3),
                            .init(color: Color.proWarmWhite.opacity(0.35), location: shimmerPhase),
                            .init(color: .clear, location: shimmerPhase + 0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )

                    HStack(spacing: 8) {
                        if isStartingCheckout {
                            ProgressView().tint(Color.proDeepBurn).controlSize(.small)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                        }
                        Text(upgradeTitle)
                            .font(.system(size: 15, weight: .bold))
                            .tracking(-0.2)
                    }
                    .foregroundStyle(Color.proDeepBurn)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .clipShape(Capsule())
                .shadow(color: Color.proAmber.opacity(0.25), radius: 12, y: 4)
            }
            .buttonStyle(ProCTAButtonStyle())
            .disabled(isStartingCheckout)

            Text(upgradeSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color.proMutedText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button {
                dismiss()
                notificationRouter.selectedTab = .more
                notificationRouter.morePath = [.subscription]
            } label: {
                HStack(spacing: 5) {
                    Text("See all features")
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.proAmber)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.proCopper.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.proCopper.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Checkout

    private func openCheckout() async {
        errorMessage = nil
        isStartingCheckout = true
        defer { isStartingCheckout = false }

        let accessToken: String
        do {
            accessToken = try await authManager.validAccessToken()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        guard let home = homeManager.home, let user = authManager.currentUser else {
            errorMessage = "No household found."
            return
        }

        let service = SubscriptionService()
        do {
            let url = try await service.createCheckoutSession(
                plan: .monthly,
                homeId: home.id,
                customerEmail: user.email,
                accessToken: accessToken
            )
            let callbackURL = try await browserSession.start(url: url)
            if callbackURL.host == "subscription" {
                await homeManager.refreshCurrentHome()
                dismiss()
            }
        } catch SubscriptionBrowserError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Pro CTA Button Style (shared)

struct ProCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(
                configuration.isPressed
                    ? DesignSystem.Motion.buttonPress
                    : DesignSystem.Motion.buttonRelease,
                value: configuration.isPressed
            )
    }
}

// MARK: - View Modifier

private struct ProUpsellModifier: ViewModifier {
    @Binding var isPresented: Bool
    let feature: ProFeatureContext

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            ProUpsellSheet(feature: feature)
        }
    }
}

extension View {
    func proUpsell(isPresented: Binding<Bool>, feature: ProFeatureContext) -> some View {
        modifier(ProUpsellModifier(isPresented: isPresented, feature: feature))
    }

    func nestUpsell(isPresented: Binding<Bool>, feature: ProFeatureContext) -> some View {
        proUpsell(isPresented: isPresented, feature: feature)
    }
}
