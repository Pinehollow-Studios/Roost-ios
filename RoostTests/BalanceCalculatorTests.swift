import Testing
@testable import Roost
import Foundation

/// Tests for BalanceCalculator.calculate(expenses:myUserId:partnerUserId:)
///
/// Rule: positive = partner owes me, negative = I owe partner.
/// Settled splits and solo expenses (no splits) are excluded.
struct BalanceCalculatorTests {

    private let myId      = UUID()
    private let partnerId = UUID()
    private let homeId    = UUID()

    // MARK: - Helpers

    private func makeExpense(
        paidBy: UUID,
        amount: Decimal,
        splits: [ExpenseSplit] = []
    ) -> ExpenseWithSplits {
        ExpenseWithSplits(
            id: UUID(),
            homeID: homeId,
            title: "Test expense",
            amount: amount,
            paidBy: paidBy,
            splitType: "equal",
            category: nil,
            notes: nil,
            incurredOn: "2024-01-15",
            isRecurring: false,
            createdAt: Date(),
            expenseSplits: splits
        )
    }

    private func makeSplit(
        userId: UUID,
        amount: Decimal,
        settledAt: Date? = nil
    ) -> ExpenseSplit {
        ExpenseSplit(
            id: UUID(),
            expenseID: UUID(),
            userID: userId,
            amount: amount,
            settledAt: settledAt,
            settled: settledAt != nil
        )
    }

    // MARK: - Edge cases

    @Test func emptyExpenses_returnsZero() {
        let balance = BalanceCalculator.calculate(
            expenses: [],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == 0)
    }

    @Test func soloExpense_noSplits_ignored() {
        let expense = makeExpense(paidBy: myId, amount: 100, splits: [])
        let balance = BalanceCalculator.calculate(
            expenses: [expense],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == 0)
    }

    @Test func thirdPartySplit_notInvolvedInBalance() {
        let thirdParty = UUID()
        let split = makeSplit(userId: thirdParty, amount: 33)
        let expense = makeExpense(paidBy: myId, amount: 100, splits: [split])
        let balance = BalanceCalculator.calculate(
            expenses: [expense],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == 0)
    }

    // MARK: - Basic directions

    @Test func iPaid_partnerSplit_positiveBalance() {
        // I paid £100, partner's split is £50 → partner owes me £50
        let split = makeSplit(userId: partnerId, amount: 50)
        let expense = makeExpense(paidBy: myId, amount: 100, splits: [split])
        let balance = BalanceCalculator.calculate(
            expenses: [expense],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == 50)
    }

    @Test func partnerPaid_mySplit_negativeBalance() {
        // Partner paid £80, my split is £40 → I owe partner £40
        let split = makeSplit(userId: myId, amount: 40)
        let expense = makeExpense(paidBy: partnerId, amount: 80, splits: [split])
        let balance = BalanceCalculator.calculate(
            expenses: [expense],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == -40)
    }

    // MARK: - Settlement

    @Test func settledSplit_excluded() {
        let settled = makeSplit(userId: partnerId, amount: 50, settledAt: Date())
        let expense = makeExpense(paidBy: myId, amount: 100, splits: [settled])
        let balance = BalanceCalculator.calculate(
            expenses: [expense],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == 0)
    }

    @Test func mixedSplits_onlyUnsettledCounted() {
        // One settled (30), one unsettled (20) → only 20 counted
        let settled   = makeSplit(userId: partnerId, amount: 30, settledAt: Date())
        let unsettled = makeSplit(userId: partnerId, amount: 20)
        let expense = makeExpense(paidBy: myId, amount: 100, splits: [settled, unsettled])
        let balance = BalanceCalculator.calculate(
            expenses: [expense],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == 20)
    }

    // MARK: - Multi-expense

    @Test func multipleExpenses_netBalance() {
        // I paid £120, partner split £60 → +60
        let split1 = makeSplit(userId: partnerId, amount: 60)
        let exp1    = makeExpense(paidBy: myId, amount: 120, splits: [split1])

        // Partner paid £50, my split £25 → -25
        let split2 = makeSplit(userId: myId, amount: 25)
        let exp2   = makeExpense(paidBy: partnerId, amount: 50, splits: [split2])

        let balance = BalanceCalculator.calculate(
            expenses: [exp1, exp2],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == 35) // 60 − 25
    }

    @Test func allSettled_returnsZero() {
        let split1 = makeSplit(userId: partnerId, amount: 60, settledAt: Date())
        let exp1   = makeExpense(paidBy: myId, amount: 120, splits: [split1])

        let split2 = makeSplit(userId: myId, amount: 25, settledAt: Date())
        let exp2   = makeExpense(paidBy: partnerId, amount: 50, splits: [split2])

        let balance = BalanceCalculator.calculate(
            expenses: [exp1, exp2],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == 0)
    }

    // MARK: - Symmetry

    @Test func symmetry_oppositeViewpointsNegate() {
        // From my perspective: partner owes me 45
        // From partner's perspective: they owe me 45, so their balance should be -45
        let split   = makeSplit(userId: partnerId, amount: 45)
        let expense = makeExpense(paidBy: myId, amount: 90, splits: [split])

        let myBalance      = BalanceCalculator.calculate(expenses: [expense], myUserId: myId,       partnerUserId: partnerId)
        let partnerBalance = BalanceCalculator.calculate(expenses: [expense], myUserId: partnerId,  partnerUserId: myId)

        #expect(myBalance == -partnerBalance)
    }

    // MARK: - Precision

    @Test func decimalPrecision_noRoundingLoss() {
        // Use amounts that would lose precision if converted to Double
        let split   = makeSplit(userId: partnerId, amount: Decimal(string: "33.33")!)
        let expense = makeExpense(paidBy: myId, amount: Decimal(string: "99.99")!, splits: [split])
        let balance = BalanceCalculator.calculate(
            expenses: [expense],
            myUserId: myId,
            partnerUserId: partnerId
        )
        #expect(balance == Decimal(string: "33.33")!)
    }
}
