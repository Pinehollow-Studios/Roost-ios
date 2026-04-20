import Testing
@testable import Roost
import Foundation

/// Tests for MonthlyMoneyViewModel computed properties and navigation logic.
/// These tests do NOT hit the network — they inject MonthlySummary directly
/// and test the ViewModel's derived calculations.
@MainActor
struct MonthlyMoneyViewModelTests {

    // MARK: - Helpers

    private func makeSummary(
        income: Decimal,
        fixedCosts: Decimal,
        actualSpend: Decimal,
        totalBudgeted: Decimal = 0
    ) -> MonthlySummary {
        MonthlySummary(
            income: income,
            fixedCosts: fixedCosts,
            envelopesTotal: 0,
            totalBudgeted: totalBudgeted,
            actualSpend: actualSpend,
            surplus: income - totalBudgeted,
            projectedTotal: 0,
            pctOfIncomeBudgeted: 0,
            pctSpent: 0
        )
    }

    // MARK: - daysInMonth / daysElapsed

    @Test func daysInMonth_withinValidCalendarRange() {
        let vm = MonthlyMoneyViewModel()
        #expect(vm.daysInMonth >= 28 && vm.daysInMonth <= 31)
    }

    @Test func daysElapsed_neverExceedsDaysInMonth() {
        let vm = MonthlyMoneyViewModel()
        #expect(vm.daysElapsed <= vm.daysInMonth)
    }

    @Test func daysElapsed_atLeastOne() {
        // We're always at least on day 1 of the current month
        let vm = MonthlyMoneyViewModel()
        #expect(vm.daysElapsed >= 1)
    }

    @Test func daysElapsed_pastMonth_equalsAllDaysInThatMonth() {
        let vm = MonthlyMoneyViewModel()
        vm.navigateMonth(direction: -1)
        // For a past month, all days are considered elapsed
        #expect(vm.daysElapsed == vm.daysInMonth)
    }

    // MARK: - dailySpendRate

    @Test func dailySpendRate_nilWithoutSummary() {
        let vm = MonthlyMoneyViewModel()
        vm.summary = nil
        #expect(vm.dailySpendRate == nil)
    }

    @Test func dailySpendRate_calculatesSpendOverElapsedDays() {
        let vm = MonthlyMoneyViewModel()
        vm.summary = makeSummary(income: 3000, fixedCosts: 1000, actualSpend: 300)
        guard let rate = vm.dailySpendRate else { return }
        let expected = Decimal(300) / Decimal(vm.daysElapsed)
        #expect(rate == expected)
    }

    @Test func dailySpendRate_zeroSpend_isZero() {
        let vm = MonthlyMoneyViewModel()
        vm.summary = makeSummary(income: 3000, fixedCosts: 1000, actualSpend: 0)
        #expect(vm.dailySpendRate == 0)
    }

    // MARK: - projectedLifestyleSpend

    @Test func projectedLifestyleSpend_nilWithoutSummary() {
        let vm = MonthlyMoneyViewModel()
        vm.summary = nil
        #expect(vm.projectedLifestyleSpend == nil)
    }

    @Test func projectedLifestyleSpend_rateTimesDaysInMonth() {
        let vm = MonthlyMoneyViewModel()
        vm.summary = makeSummary(income: 3000, fixedCosts: 1000, actualSpend: 300)
        guard let projected = vm.projectedLifestyleSpend,
              let rate = vm.dailySpendRate else { return }
        let expected = rate * Decimal(vm.daysInMonth)
        #expect(projected == expected)
    }

    @Test func projectedLifestyleSpend_zeroSpend_isZero() {
        let vm = MonthlyMoneyViewModel()
        vm.summary = makeSummary(income: 3000, fixedCosts: 1000, actualSpend: 0)
        #expect(vm.projectedLifestyleSpend == 0)
    }

    // MARK: - projectedSurplus

    @Test func projectedSurplus_nilWithoutSummary() {
        let vm = MonthlyMoneyViewModel()
        vm.summary = nil
        #expect(vm.projectedSurplus == nil)
    }

    @Test func projectedSurplus_incomeLessFixedLessProjected() {
        // projectedSurplus = income − fixedCosts − projectedLifestyleSpend
        let vm = MonthlyMoneyViewModel()
        vm.summary = makeSummary(income: 3000, fixedCosts: 1000, actualSpend: 300)
        guard let surplus = vm.projectedSurplus,
              let projected = vm.projectedLifestyleSpend else { return }
        let expected = Decimal(3000) - Decimal(1000) - projected
        #expect(surplus == expected)
    }

    @Test func projectedSurplus_zeroSpend_equalsIncomeMinusFixed() {
        let vm = MonthlyMoneyViewModel()
        vm.summary = makeSummary(income: 3000, fixedCosts: 1000, actualSpend: 0)
        #expect(vm.projectedSurplus == 2000)
    }

    // MARK: - navigateMonth

    @Test func navigateMonth_backwardMovesToPreviousMonth() {
        let vm = MonthlyMoneyViewModel()
        let before = vm.selectedMonth
        vm.navigateMonth(direction: -1)
        #expect(vm.selectedMonth < before)
    }

    @Test func navigateMonth_forwardFromCurrentMonth_doesNothing() {
        // Cannot navigate forward past the current month
        let vm = MonthlyMoneyViewModel()
        let before = vm.selectedMonth
        vm.navigateMonth(direction: 1)
        #expect(vm.selectedMonth == before)
    }

    @Test func navigateMonth_forwardFromPastMonth_succeeds() {
        let vm = MonthlyMoneyViewModel()
        vm.navigateMonth(direction: -2)  // go back 2 months
        let twoMonthsBack = vm.selectedMonth
        vm.navigateMonth(direction: 1)   // go forward 1 — should work
        #expect(vm.selectedMonth > twoMonthsBack)
    }

    @Test func navigateMonth_clearsSummary() {
        let vm = MonthlyMoneyViewModel()
        vm.summary = makeSummary(income: 3000, fixedCosts: 1000, actualSpend: 300)
        vm.navigateMonth(direction: -1)
        #expect(vm.summary == nil)
    }

    @Test func navigateMonth_multipleBackSteps_accumulatesCorrectly() {
        let vm = MonthlyMoneyViewModel()
        vm.navigateMonth(direction: -1)
        vm.navigateMonth(direction: -1)
        vm.navigateMonth(direction: -1)
        // Should now be 3 months back — daysElapsed == daysInMonth for all past months
        #expect(vm.daysElapsed == vm.daysInMonth)
    }
}
