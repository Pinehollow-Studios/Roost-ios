import Foundation

struct SavingsGoal: Codable, Identifiable {
    let id: UUID
    let homeId: UUID
    var name: String
    var targetAmount: Decimal
    var savedAmount: Decimal
    var colour: String          // "terracotta" | "sage" | "amber" | "blue" | "purple" | "green"
    var targetDate: Date?
    var completedAt: Date?
    var monthlyContribution: Decimal?
    var contributionDay: Int?   // day of month (1–28), default 1
    var budgetLineId: UUID?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case homeId = "home_id"
        case name
        case targetAmount = "target_amount"
        case savedAmount = "saved_amount"
        case colour
        case targetDate = "target_date"
        case completedAt = "completed_at"
        case monthlyContribution = "monthly_contribution"
        case contributionDay = "contribution_day"
        case budgetLineId = "budget_line_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: savedAmount / targetAmount).doubleValue
        return min(1.0, max(0.0, ratio))
    }

    var isCompleted: Bool { completedAt != nil }

    /// Months remaining until target date from today.
    var monthsRemaining: Int? {
        guard let target = targetDate else { return nil }
        let cal = Calendar.current
        let comps = cal.dateComponents([.month], from: Date(), to: target)
        return comps.month.map { max(0, $0) }
    }

    /// Monthly amount needed to reach target by target date.
    var monthlyNeeded: Decimal? {
        guard let months = monthsRemaining, months > 0 else { return nil }
        let remaining = targetAmount - savedAmount
        guard remaining > 0 else { return 0 }
        return remaining / Decimal(months)
    }
}

extension SavingsGoal: Equatable {
    static func == (lhs: SavingsGoal, rhs: SavingsGoal) -> Bool {
        lhs.id == rhs.id &&
        lhs.savedAmount == rhs.savedAmount &&
        lhs.targetAmount == rhs.targetAmount &&
        lhs.monthlyContribution == rhs.monthlyContribution &&
        lhs.completedAt == rhs.completedAt &&
        lhs.name == rhs.name
    }
}

struct CreateSavingsGoal: Codable {
    var homeId: UUID
    var name: String
    var targetAmount: Decimal
    var savedAmount: Decimal
    var colour: String
    var targetDate: Date?
    var monthlyContribution: Decimal?
    var contributionDay: Int?

    enum CodingKeys: String, CodingKey {
        case homeId = "home_id"
        case name
        case targetAmount = "target_amount"
        case savedAmount = "saved_amount"
        case colour
        case targetDate = "target_date"
        case monthlyContribution = "monthly_contribution"
        case contributionDay = "contribution_day"
    }
}
