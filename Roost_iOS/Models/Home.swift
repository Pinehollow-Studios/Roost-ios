import Foundation

struct Home: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var inviteCode: String
    var nextShopDate: String?
    var subscriptionStatus: String?
    var subscriptionTier: String?
    var trialEndsAt: Date?
    var currentPeriodEndsAt: Date?
    var stripeCustomerID: String?
    var stripeSubscriptionID: String?
    var stripePriceID: String?
    var hasUsedTrial: Bool?
    var createdAt: Date
    // Money settings
    var defaultExpenseSplit: Double? = nil
    var budgetCarryForward: String? = nil
    var scrambleMode: Bool? = nil
    var overspendAlertThreshold: Int? = nil
    var currencySymbol: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case nextShopDate = "next_shop_date"
        case subscriptionStatus = "subscription_status"
        case subscriptionTier = "subscription_tier"
        case trialEndsAt = "trial_ends_at"
        case currentPeriodEndsAt = "current_period_ends_at"
        case stripeCustomerID = "stripe_customer_id"
        case stripeSubscriptionID = "stripe_subscription_id"
        case stripePriceID = "stripe_price_id"
        case hasUsedTrial = "has_used_trial"
        case createdAt = "created_at"
        case defaultExpenseSplit = "default_expense_split"
        case budgetCarryForward = "budget_carry_forward"
        case scrambleMode = "scramble_mode"
        case overspendAlertThreshold = "overspend_alert_threshold"
        case currencySymbol = "currency_symbol"
    }

    /// Parsed next shop date (the DB column may be a date-only string like "2026-03-28")
    var nextShopDateParsed: Date? {
        guard let nextShopDate else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: nextShopDate)
    }

    var normalizedSubscriptionStatus: SubscriptionStatus {
        SubscriptionStatus(rawValue: (subscriptionStatus ?? "free").lowercased()) ?? .free
    }

    var normalizedSubscriptionTier: SubscriptionTier {
        SubscriptionTier(rawValue: (subscriptionTier ?? "free").lowercased()) ?? .free
    }

    var hasActiveTrial: Bool {
        normalizedSubscriptionStatus == .trialing && (trialEndsAt ?? .distantPast) > .now
    }

    var hasProAccess: Bool {
        switch normalizedSubscriptionStatus {
        case .active, .trialing, .lifetime:
            return true
        default:
            return false
        }
    }

    var effectiveStripeCustomerID: String? {
        guard let stripeCustomerID, !stripeCustomerID.isEmpty else { return nil }
        return stripeCustomerID
    }

    var effectiveStripePriceID: String? {
        guard let stripePriceID, !stripePriceID.isEmpty else { return nil }
        return stripePriceID
    }

    var hasUsedTrialValue: Bool {
        hasUsedTrial ?? false
    }
}

enum SubscriptionStatus: String {
    case free
    case trialing
    case active
    case pastDue = "past_due"
    case canceled
    case incomplete
    case lifetime
}

enum SubscriptionTier: String {
    case free
    case pro = "nest"  // DB stores "nest"; display as "Pro"
}

struct HomeMember: Codable, Identifiable, Hashable {
    let id: UUID
    var homeID: UUID
    var userID: UUID
    var displayName: String
    var avatarColor: String?
    var avatarIcon: String?
    var role: String?
    var joinedAt: Date
    // Income privacy model
    var personalIncome: Decimal? = nil
    var incomeVisibleToPartner: Bool? = nil
    var incomeSetAt: Date? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case homeID = "home_id"
        case userID = "user_id"
        case displayName = "display_name"
        case avatarColor = "avatar_color"
        case avatarIcon = "avatar_icon"
        case role
        case joinedAt = "joined_at"
        case personalIncome = "personal_income"
        case incomeVisibleToPartner = "income_visible_to_partner"
        case incomeSetAt = "income_set_at"
    }
}
