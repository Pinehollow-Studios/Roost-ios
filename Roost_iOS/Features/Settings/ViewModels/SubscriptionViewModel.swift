import Observation
import Foundation

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
    var planPrice: String?
    var nextBillingDate: Date?

    // Promo code
    var showingPromoInput = false
    var promoCode = ""
    var isApplyingPromo = false
    var promoSuccess = false
    var promoError: String?

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
        Feature(icon: "crown", title: "Priority support"),
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

    // MARK: - Actions

    func sync(with home: Home?, prices: SubscriptionPriceSet) {
        guard let home else {
            state = .free
            trialDaysUsed = 0
            trialEndDate = nil
            planName = nil
            planPrice = nil
            nextBillingDate = nil
            selectedPlan = .monthly
            return
        }

        trialEndDate = home.trialEndsAt
        nextBillingDate = home.currentPeriodEndsAt

        if let stripePriceID = home.effectiveStripePriceID {
            if stripePriceID == prices.monthly.id {
                planName = "Monthly"
                planPrice = prices.monthly.formattedAmount
                selectedPlan = .monthly
            } else if stripePriceID == prices.annual.id {
                planName = "Annual"
                planPrice = prices.annual.formattedAmount
                selectedPlan = .annual
            } else {
                planName = "Roost Pro"
                planPrice = nil
            }
        } else {
            planName = home.normalizedSubscriptionTier == .pro ? "Roost Pro" : nil
            planPrice = nil
        }

        if let trialEndDate {
            let totalDays = prices.monthly.trialDays
            let remaining = max(Calendar.current.dateComponents([.day], from: .now, to: trialEndDate).day ?? 0, 0)
            trialDaysTotal = totalDays
            trialDaysUsed = max(totalDays - remaining, 0)
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

    func actionURL(
        home: Home?,
        user: AuthUser?,
        accessToken: String?,
        plan: SubscriptionService.Plan
    ) async -> URL? {
        guard let accessToken, !accessToken.isEmpty else {
            errorMessage = SubscriptionServiceError.invalidSession.localizedDescription
            return nil
        }

        switch state {
        case .free, .cancelled:
            guard let home else {
                errorMessage = "No household was found."
                return nil
            }
            guard let user else {
                errorMessage = SubscriptionServiceError.invalidSession.localizedDescription
                return nil
            }

            isPerformingAction = true
            defer { isPerformingAction = false }

            do {
                return try await subscriptionService.createCheckoutSession(
                    plan: plan,
                    homeId: home.id,
                    customerEmail: user.email,
                    accessToken: accessToken
                )
            } catch {
                errorMessage = error.localizedDescription
                return nil
            }

        case .trial, .active, .pastDue, .incomplete:
            guard let home else {
                errorMessage = "No household was found."
                return nil
            }

            isPerformingAction = true
            defer { isPerformingAction = false }

            do {
                return try await subscriptionService.createPortalSession(
                    homeId: home.id,
                    accessToken: accessToken
                )
            } catch {
                errorMessage = error.localizedDescription
                return nil
            }

        case .lifetime:
            return nil
        }
    }
}
