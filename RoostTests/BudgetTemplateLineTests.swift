import Testing
@testable import Roost
import Foundation

/// Tests for BudgetTemplateLine computed properties.
/// These are pure calculations with no network dependency.
struct BudgetTemplateLineTests {

    // MARK: - Helpers

    private func makeLine(
        budgetType: String = "fixed",
        amount: Decimal = 100,
        isAnnual: Bool = false,
        annualAmount: Decimal? = nil
    ) -> BudgetTemplateLine {
        BudgetTemplateLine(
            id: UUID(),
            homeId: UUID(),
            name: "Test line",
            amount: amount,
            budgetType: budgetType,
            sectionGroup: "housing",
            dayOfMonth: nil,
            isAnnual: isAnnual,
            annualAmount: annualAmount,
            rolloverEnabled: false,
            ownership: "shared",
            member1Percentage: 50,
            lastAmount: nil,
            amountChangedAt: nil,
            note: nil,
            sortOrder: 0,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - isFixed / isLifestyle

    @Test func isFixed_trueForFixedType() {
        let line = makeLine(budgetType: "fixed")
        #expect(line.isFixed == true)
        #expect(line.isLifestyle == false)
    }

    @Test func isLifestyle_trueForEnvelopeType() {
        let line = makeLine(budgetType: "envelope")
        #expect(line.isFixed == false)
        #expect(line.isLifestyle == true)
    }

    @Test func unknownType_bothFalse() {
        let line = makeLine(budgetType: "other")
        #expect(line.isFixed == false)
        #expect(line.isLifestyle == false)
    }

    // MARK: - displayAmount (non-annual)

    @Test func displayAmount_nonAnnual_returnsAmountDirectly() {
        let line = makeLine(amount: 250, isAnnual: false)
        #expect(line.displayAmount == 250)
    }

    @Test func displayAmount_nonAnnual_ignoresAnnualAmountIfPresent() {
        // isAnnual is false, so annualAmount should not be used
        let line = makeLine(amount: 150, isAnnual: false, annualAmount: 9999)
        #expect(line.displayAmount == 150)
    }

    // MARK: - displayAmount (annual)

    @Test func displayAmount_annual_dividesByTwelve() {
        let line = makeLine(amount: 0, isAnnual: true, annualAmount: 1200)
        #expect(line.displayAmount == 100)
    }

    @Test func displayAmount_annual_bankersRounding() {
        // 1000 / 12 = 83.3333… → banker's rounding to 2dp = 83.33
        let line = makeLine(amount: 0, isAnnual: true, annualAmount: 1000)
        #expect(line.displayAmount == Decimal(string: "83.33")!)
    }

    @Test func displayAmount_annual_exactlyDivisible_noRemainder() {
        // 600 / 12 = 50.00
        let line = makeLine(amount: 0, isAnnual: true, annualAmount: 600)
        #expect(line.displayAmount == 50)
    }

    @Test func displayAmount_annual_largeAmount() {
        // 24000 / 12 = 2000
        let line = makeLine(amount: 0, isAnnual: true, annualAmount: 24000)
        #expect(line.displayAmount == 2000)
    }

    @Test func displayAmount_annual_nilAnnualAmount_fallsBackToAmount() {
        // isAnnual true but no annualAmount → guard exits early, returns base amount
        let line = makeLine(amount: 500, isAnnual: true, annualAmount: nil)
        #expect(line.displayAmount == 500)
    }

    @Test func displayAmount_annual_roundHalfEven() {
        // 100 / 12 = 8.3333… → 8.33 (digit after 2nd dp is 3, rounds down)
        let line = makeLine(amount: 0, isAnnual: true, annualAmount: 100)
        #expect(line.displayAmount == Decimal(string: "8.33")!)
    }
}
