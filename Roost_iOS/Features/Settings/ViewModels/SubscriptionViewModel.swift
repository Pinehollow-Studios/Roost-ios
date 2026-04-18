import Observation
import Foundation
import RevenueCat

@MainActor
@Observable
final class SubscriptionViewModel {
    enum SubscriptionState: String {
        case free
        case trial
        case active
        case pastDue
        case cancelled
        case incomplete
        case lifetime
    }

    var state: SubscriptionState = .free
    var isLoading = false
    var isPerformingAction = false
    var errorMessage: String?
    var selectedPlan: SubscriptionService.Plan = .monthly

    // Trial info
    var trialDaysUsed = 0
    var trialDaysTotal = 14
    var trialEndDate: Date?

    // Active subscription info
    var planName: String?
    var nextBillingDate: Date?

    // Gift code (backend-granted codes — lifetime or timed)
    var showingPromoInput = false
    var promoCode = ""
    var isApplyingPromo = false
    var promoSuccess = false
    var promoError: String?

    // Duplicate subscriber notice (Option A: user has active Apple sub but home already has an owner)
    private(set) var isDuplicateSubscriber = false

    var trialProgress: Double {
        guard trialDaysTotal > 0 else { return 0 }
        return Double(trialDaysUsed) / Double(trialDaysTotal)
    }

    var trialDaysRemaining: Int {
        max(0, trialDaysTotal - trialDaysUsed)
    }

    let proFeatures: [Feature] = [
        Feature(icon: "sparkles", title: "Hazel AI assistant"),
        Feature(icon: "chart.pie", title: "Advanced budgeting"),
        Feature(icon: "bell.badge", title: "Smart notifications"),
        Feature(icon: "person.2", title: "Unlimited members"),
        Feature(icon: "square.grid.2x2", title: "Room groups"),
        Feature(icon: "sparkles", title: "Hazel AI intelligence"),
    ]

    let freeFeatures: [Feature] = [
        Feature(icon: "cart", title: "Shared shopping list"),
        Feature(icon: "sterlingsign.circle", title: "Expense tracking"),
        Feature(icon: "checkmark.circle", title: "Chore management"),
        Feature(icon: "calendar", title: "Household calendar"),
    ]

    struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
    }

    @ObservationIgnored
    private let subscriptionService = SubscriptionService()

    // MARK: - Sync with Home

    func sync(with home: Home?, prices: SubscriptionPriceSet) {
        guard let home else {
            state = .free
            trialDaysUsed = 0
            trialEndDate = nil
            planName = nil
            nextBillingDate = nil
            selectedPlan = .monthly
            return
        }

        trialEndDate = home.trialEndsAt
        nextBillingDate = home.currentPeriodEndsAt
        planName = home.normalizedSubscriptionTier == .pro ? "Roost Pro" : nil

        if let trialEndDate {
            let remaining = max(Calendar.current.dateComponents([.day], from: .now, to: trialEndDate).day ?? 0, 0)
            trialDaysTotal = prices.monthly.trialDays
            trialDaysUsed = max(prices.monthly.trialDays - remaining, 0)
        } else {
            trialDaysTotal = prices.monthly.trialDays
            trialDaysUsed = home.hasUsedTrialValue ? prices.monthly.trialDays : 0
        }

        switch home.normalizedSubscriptionStatus {
        case .free:
            state = .free
        case .trialing:
            state = home.hasActiveTrial ? .trial : .free
        case .active:
            state = .active
        case .pastDue:
            state = .pastDue
        case .canceled:
            state = .cancelled
        case .incomplete:
            state = .incomplete
        case .lifetime:
            state = .lifetime
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async {
        isPerformingAction = true
        errorMessage = nil
        defer { isPerformingAction = false }

        do {
            let result = try await RevenueCatService.shared.purchase(package: package)
            if result.userCancelled { return }
            // Home state updates via RevenueCat webhook → Supabase Realtime
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isPerformingAction = true
        errorMessage = nil
        defer { isPerformingAction = false }

        do {
            _ = try await RevenueCatService.shared.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Manage Subscriptions

    func openManageSubscriptions() async {
        await RevenueCatService.shared.openManageSubscriptions()
    }

    // MARK: - Gift Code (backend-granted access)

    func applyPromoCode(homeId: UUID?, accessToken: String?) async {
        let trimmed = promoCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return }
        guard let homeId else {
            promoError = "No household was found."
            return
        }
        guard let accessToken, !accessToken.isEmpty else {
            promoError = SubscriptionServiceError.invalidSession.localizedDescription
            return
        }

        isApplyingPromo = true
        promoError = nil
        promoSuccess = false

        do {
            try await subscriptionService.redeemPromo(code: trimmed, homeId: homeId, accessToken: accessToken)
            promoSuccess = true
            promoCode = ""
        } catch {
            promoError = error.localizedDescription
        }

        isApplyingPromo = false
    }

    // MARK: - Duplicate Subscriber Detection

    /// Checks whether the current user has an active Apple subscription but the home already
    /// has a different subscription owner. Called on view appear and subscription sync.
    func checkDuplicateSubscriber(home: Home?, currentUserId: UUID?) async {
        guard
            let home,
            let ownerId = home.subscriptionOwnerUserId,
            let currentUserId,
            ownerId != currentUserId
        else {
            isDuplicateSubscriber = false
            return
        }
        // Current user is not the owner — check if they also have an active Apple subscription
        isDuplicateSubscriber = await RevenueCatService.shared.isProActive()
    }
}
