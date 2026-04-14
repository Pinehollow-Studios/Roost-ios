import Foundation

/// Decoded from the get_monthly_summary Postgres RPC response.
struct MonthlySummary: Codable {
    let income: Decimal
    let fixedCosts: Decimal
    let envelopesTotal: Decimal
    let totalBudgeted: Decimal
    let actualSpend: Decimal
    let surplus: Decimal
    let projectedTotal: Decimal
    let pctOfIncomeBudgeted: Decimal
    let pctSpent: Decimal

    enum CodingKeys: String, CodingKey {
        case income
        case fixedCosts = "fixed_costs"
        case envelopesTotal = "envelopes_total"
        case totalBudgeted = "total_budgeted"
        case actualSpend = "actual_spend"
        case surplus
        case projectedTotal = "projected_total"
        case pctOfIncomeBudgeted = "pct_of_income_budgeted"
        case pctSpent = "pct_spent"
    }

    var hasIncome: Bool { income > 0 }

    func replacingIncome(_ liveIncome: Decimal) -> MonthlySummary {
        let pctOfIncomeBudgeted = liveIncome > 0 ? (totalBudgeted / liveIncome) * 100 : 0
        let pctSpent = liveIncome > 0 ? (actualSpend / liveIncome) * 100 : 0

        return MonthlySummary(
            income: liveIncome,
            fixedCosts: fixedCosts,
            envelopesTotal: envelopesTotal,
            totalBudgeted: totalBudgeted,
            actualSpend: actualSpend,
            surplus: liveIncome - totalBudgeted,
            projectedTotal: projectedTotal,
            pctOfIncomeBudgeted: pctOfIncomeBudgeted,
            pctSpent: pctSpent
        )
    }

    static func empty(income: Decimal) -> MonthlySummary {
        MonthlySummary(
            income: income,
            fixedCosts: 0,
            envelopesTotal: 0,
            totalBudgeted: 0,
            actualSpend: 0,
            surplus: income,
            projectedTotal: 0,
            pctOfIncomeBudgeted: 0,
            pctSpent: 0
        )
    }
}

/// Derived from the homes table. Not Codable — constructed from a Home object.
struct MoneySettings {
    var defaultExpenseSplit: Double  // 0–100
    var budgetCarryForward: String   // "auto" or "manual"
    var scrambleMode: Bool
    var overspendAlertThreshold: Int // 50–100
    var currencySymbol: String

    init(
        defaultExpenseSplit: Double = 50.0,
        budgetCarryForward: String = "auto",
        scrambleMode: Bool = false,
        overspendAlertThreshold: Int = 80,
        currencySymbol: String = "£"
    ) {
        self.defaultExpenseSplit = defaultExpenseSplit
        self.budgetCarryForward = budgetCarryForward
        self.scrambleMode = scrambleMode
        self.overspendAlertThreshold = overspendAlertThreshold
        self.currencySymbol = currencySymbol
    }

    static func from(home: Home) -> MoneySettings {
        MoneySettings(
            defaultExpenseSplit: home.defaultExpenseSplit ?? 50.0,
            budgetCarryForward: home.budgetCarryForward ?? "auto",
            scrambleMode: home.scrambleMode ?? false,
            overspendAlertThreshold: home.overspendAlertThreshold ?? 80,
            currencySymbol: home.currencySymbol ?? "£"
        )
    }
}
