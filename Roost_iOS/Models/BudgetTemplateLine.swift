import Foundation

struct BudgetTemplateLine: Codable, Identifiable {
    let id: UUID
    let homeId: UUID
    var name: String
    var amount: Decimal
    var budgetType: String   // "fixed" or "envelope"
    var sectionGroup: String
    var dayOfMonth: Int?
    var isAnnual: Bool
    var annualAmount: Decimal?
    var rolloverEnabled: Bool
    var ownership: String    // "shared", "member1", "member2"
    var member1Percentage: Decimal
    var lastAmount: Decimal?
    var amountChangedAt: Date?
    var note: String?
    var sortOrder: Int
    var isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case homeId = "home_id"
        case name
        case amount
        case budgetType = "budget_type"
        case sectionGroup = "section_group"
        case dayOfMonth = "day_of_month"
        case isAnnual = "is_annual"
        case annualAmount = "annual_amount"
        case rolloverEnabled = "rollover_enabled"
        case ownership
        case member1Percentage = "member1_percentage"
        case lastAmount = "last_amount"
        case amountChangedAt = "amount_changed_at"
        case note
        case sortOrder = "sort_order"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isFixed: Bool { budgetType == "fixed" }
    var isLifestyle: Bool { budgetType == "envelope" }

    var displayAmount: Decimal {
        guard isAnnual, let annualAmount else { return amount }
        var result = annualAmount / 12
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, 2, .bankers)
        return rounded
    }
}

struct CreateBudgetLine: Codable {
    var homeId: UUID
    var name: String
    var amount: Decimal
    var budgetType: String
    var sectionGroup: String
    var dayOfMonth: Int?
    var isAnnual: Bool
    var annualAmount: Decimal?
    var rolloverEnabled: Bool
    var ownership: String
    var member1Percentage: Decimal
    var note: String?
    var sortOrder: Int
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case homeId = "home_id"
        case name
        case amount
        case budgetType = "budget_type"
        case sectionGroup = "section_group"
        case dayOfMonth = "day_of_month"
        case isAnnual = "is_annual"
        case annualAmount = "annual_amount"
        case rolloverEnabled = "rollover_enabled"
        case ownership
        case member1Percentage = "member1_percentage"
        case note
        case sortOrder = "sort_order"
        case isActive = "is_active"
    }
}

/// Partial update — only non-nil fields are sent to Supabase.
/// Swift synthesises encodeIfPresent for optional properties, so nil fields are omitted.
struct UpdateBudgetLine: Codable {
    var name: String?
    var amount: Decimal?
    var budgetType: String?
    var sectionGroup: String?
    var dayOfMonth: Int?
    var isAnnual: Bool?
    var annualAmount: Decimal?
    var rolloverEnabled: Bool?
    var ownership: String?
    var member1Percentage: Decimal?
    var note: String?
    var sortOrder: Int?
    var isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case budgetType = "budget_type"
        case sectionGroup = "section_group"
        case dayOfMonth = "day_of_month"
        case isAnnual = "is_annual"
        case annualAmount = "annual_amount"
        case rolloverEnabled = "rollover_enabled"
        case ownership
        case member1Percentage = "member1_percentage"
        case note
        case sortOrder = "sort_order"
        case isActive = "is_active"
    }
}
