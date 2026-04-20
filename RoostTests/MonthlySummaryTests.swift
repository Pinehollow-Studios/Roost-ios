import Testing
@testable import Roost
import Foundation

/// Tests for MonthlySummary pure computations.
/// replacingIncome() and empty() have no network dependency.
struct MonthlySummaryTests {

    // MARK: - Helpers

    private func makeSummary(
        income: Decimal = 3000,
        fixedCosts: Decimal = 1000,
        envelopesTotal: Decimal = 500,
        totalBudgeted: Decimal = 1500,
        actualSpend: Decimal = 600,
        surplus: Decimal = 1500,
        projectedTotal: Decimal = 700
    ) -> MonthlySummary {
        let pct = income > 0 ? (totalBudgeted / income) * 100 : 0
        let spent = income > 0 ? (actualSpend / income) * 100 : 0
        return MonthlySummary(
            income: income,
            fixedCosts: fixedCosts,
            envelopesTotal: envelopesTotal,
            totalBudgeted: totalBudgeted,
            actualSpend: actualSpend,
            surplus: surplus,
            projectedTotal: projectedTotal,
            pctOfIncomeBudgeted: pct,
            pctSpent: spent
        )
    }

    // MARK: - hasIncome

    @Test func hasIncome_positiveIncome_true() {
        #expect(makeSummary(income: 3000).hasIncome == true)
    }

    @Test func hasIncome_zeroIncome_false() {
        #expect(makeSummary(income: 0).hasIncome == false)
    }

    // MARK: - empty()

    @Test func empty_incomeSet_allOtherFieldsZero() {
        let empty = MonthlySummary.empty(income: 2500)
        #expect(empty.income == 2500)
        #expect(empty.fixedCosts == 0)
        #expect(empty.envelopesTotal == 0)
        #expect(empty.totalBudgeted == 0)
        #expect(empty.actualSpend == 0)
        #expect(empty.projectedTotal == 0)
        #expect(empty.pctOfIncomeBudgeted == 0)
        #expect(empty.pctSpent == 0)
    }

    @Test func empty_surplus_equalsIncome() {
        // With no budgeted costs, surplus should equal the full income
        let empty = MonthlySummary.empty(income: 3000)
        #expect(empty.surplus == 3000)
    }

    @Test func empty_zeroIncome_surplusIsZero() {
        let empty = MonthlySummary.empty(income: 0)
        #expect(empty.surplus == 0)
    }

    // MARK: - replacingIncome()

    @Test func replacingIncome_updatesIncomeField() {
        let updated = makeSummary(income: 3000).replacingIncome(4000)
        #expect(updated.income == 4000)
    }

    @Test func replacingIncome_surplusIsIncomeLessTotalBudgeted() {
        // surplus = liveIncome - totalBudgeted
        let updated = makeSummary(income: 3000, totalBudgeted: 1500).replacingIncome(4000)
        #expect(updated.surplus == 2500) // 4000 − 1500
    }

    @Test func replacingIncome_pctOfIncomeBudgeted_recalculated() {
        // 1500 / 3000 * 100 = 50
        let updated = makeSummary(income: 3000, totalBudgeted: 1500).replacingIncome(3000)
        #expect(updated.pctOfIncomeBudgeted == 50)
    }

    @Test func replacingIncome_pctSpent_recalculated() {
        // 600 / 3000 * 100 = 20
        let updated = makeSummary(income: 3000, actualSpend: 600).replacingIncome(3000)
        #expect(updated.pctSpent == 20)
    }

    @Test func replacingIncome_zeroIncome_percentagesAreZero() {
        let updated = makeSummary().replacingIncome(0)
        #expect(updated.pctOfIncomeBudgeted == 0)
        #expect(updated.pctSpent == 0)
    }

    @Test func replacingIncome_zeroIncome_surplusIsNegativeTotalBudgeted() {
        // surplus = 0 − totalBudgeted
        let updated = makeSummary(totalBudgeted: 1500).replacingIncome(0)
        #expect(updated.surplus == -1500)
    }

    @Test func replacingIncome_preservesFixedCostsAndEnvelopes() {
        let updated = makeSummary(fixedCosts: 800, envelopesTotal: 400).replacingIncome(5000)
        #expect(updated.fixedCosts == 800)
        #expect(updated.envelopesTotal == 400)
    }

    @Test func replacingIncome_preservesActualSpendAndProjected() {
        let updated = makeSummary(actualSpend: 750, projectedTotal: 900).replacingIncome(5000)
        #expect(updated.actualSpend == 750)
        #expect(updated.projectedTotal == 900)
    }

    @Test func replacingIncome_fullIncomeBudgeted_pctIs100() {
        // All income is budgeted → pctOfIncomeBudgeted = 100
        let updated = makeSummary(totalBudgeted: 3000).replacingIncome(3000)
        #expect(updated.pctOfIncomeBudgeted == 100)
    }

    @Test func replacingIncome_moreBudgetedThanIncome_pctOver100() {
        // It's valid to budget more than income (e.g. irregular months)
        let updated = makeSummary(totalBudgeted: 4000).replacingIncome(3000)
        #expect(updated.pctOfIncomeBudgeted > 100)
    }
}
