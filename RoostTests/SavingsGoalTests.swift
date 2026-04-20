import Testing
@testable import Roost
import Foundation

/// Tests for SavingsGoal computed properties.
/// All pure calculations — no network calls required.
struct SavingsGoalTests {

    // MARK: - Helpers

    private func makeGoal(
        targetAmount: Decimal,
        savedAmount: Decimal,
        isComplete: Bool = false,
        completedAt: Date? = nil,
        targetDate: Date? = nil
    ) -> SavingsGoal {
        SavingsGoal(
            id: UUID(),
            homeId: UUID(),
            name: "Holiday Fund",
            targetAmount: targetAmount,
            savedAmount: savedAmount,
            colour: "terracotta",
            icon: nil,
            targetDate: targetDate,
            isComplete: isComplete,
            completedAt: completedAt,
            sortOrder: nil,
            monthlyContribution: nil,
            contributionDay: nil,
            budgetLineId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - progress

    @Test func progress_halfSaved() {
        let goal = makeGoal(targetAmount: 1000, savedAmount: 500)
        #expect(abs(goal.progress - 0.5) < 0.0001)
    }

    @Test func progress_quarterSaved() {
        let goal = makeGoal(targetAmount: 2000, savedAmount: 500)
        #expect(abs(goal.progress - 0.25) < 0.0001)
    }

    @Test func progress_fullySaved_returnsOne() {
        let goal = makeGoal(targetAmount: 1000, savedAmount: 1000)
        #expect(goal.progress == 1.0)
    }

    @Test func progress_overSaved_clampedAtOne() {
        // Should never exceed 1.0 even if savedAmount > targetAmount
        let goal = makeGoal(targetAmount: 1000, savedAmount: 1500)
        #expect(goal.progress == 1.0)
    }

    @Test func progress_nothingSaved_returnsZero() {
        let goal = makeGoal(targetAmount: 1000, savedAmount: 0)
        #expect(goal.progress == 0.0)
    }

    @Test func progress_zeroTarget_returnsZero() {
        // Guard against divide-by-zero
        let goal = makeGoal(targetAmount: 0, savedAmount: 0)
        #expect(goal.progress == 0.0)
    }

    // MARK: - isCompleted

    @Test func isCompleted_viaIsComplete_flag() {
        let goal = makeGoal(targetAmount: 1000, savedAmount: 500, isComplete: true)
        #expect(goal.isCompleted == true)
    }

    @Test func isCompleted_viaCompletedAt_date() {
        let goal = makeGoal(targetAmount: 1000, savedAmount: 1000, completedAt: Date())
        #expect(goal.isCompleted == true)
    }

    @Test func isCompleted_neitherSet_false() {
        let goal = makeGoal(targetAmount: 1000, savedAmount: 500)
        #expect(goal.isCompleted == false)
    }

    @Test func isCompleted_goalMetButNoFlag_false() {
        // Saving the full amount does NOT auto-set isCompleted — that's server-side
        let goal = makeGoal(targetAmount: 1000, savedAmount: 1000)
        #expect(goal.isCompleted == false)
    }

    // MARK: - monthsRemaining

    @Test func monthsRemaining_noTargetDate_isNil() {
        let goal = makeGoal(targetAmount: 1000, savedAmount: 0, targetDate: nil)
        #expect(goal.monthsRemaining == nil)
    }

    @Test func monthsRemaining_pastDate_clampedAtZero() {
        let past = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let goal = makeGoal(targetAmount: 1000, savedAmount: 0, targetDate: past)
        #expect(goal.monthsRemaining == 0)
    }

    @Test func monthsRemaining_futureDate_positive() {
        let future = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        let goal = makeGoal(targetAmount: 1000, savedAmount: 0, targetDate: future)
        // Allow 5 or 6 depending on day of month calculation
        let months = goal.monthsRemaining ?? 0
        #expect(months >= 5 && months <= 6)
    }

    @Test func monthsRemaining_neverNegative() {
        let distantPast = Calendar.current.date(byAdding: .year, value: -5, to: Date())!
        let goal = makeGoal(targetAmount: 1000, savedAmount: 0, targetDate: distantPast)
        #expect((goal.monthsRemaining ?? 0) >= 0)
    }

    // MARK: - monthlyNeeded

    @Test func monthlyNeeded_noTargetDate_isNil() {
        let goal = makeGoal(targetAmount: 1000, savedAmount: 0, targetDate: nil)
        #expect(goal.monthlyNeeded == nil)
    }

    @Test func monthlyNeeded_goalAlreadyMet_isZero() {
        let future = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        let goal = makeGoal(targetAmount: 1000, savedAmount: 1000, targetDate: future)
        #expect(goal.monthlyNeeded == 0)
    }

    @Test func monthlyNeeded_goalOverMet_isZero() {
        let future = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        let goal = makeGoal(targetAmount: 1000, savedAmount: 1200, targetDate: future)
        #expect(goal.monthlyNeeded == 0)
    }

    @Test func monthlyNeeded_pastDate_isNil() {
        // monthsRemaining == 0 → monthlyNeeded is nil (guard months > 0)
        let past = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let goal = makeGoal(targetAmount: 1000, savedAmount: 0, targetDate: past)
        #expect(goal.monthlyNeeded == nil)
    }

    @Test func monthlyNeeded_matchesFormula() {
        // remaining / months = monthly needed
        let future = Calendar.current.date(byAdding: .month, value: 4, to: Date())!
        let goal = makeGoal(targetAmount: 1000, savedAmount: 200, targetDate: future)

        guard let months = goal.monthsRemaining, months > 0,
              let needed = goal.monthlyNeeded else { return }

        let expected = Decimal(800) / Decimal(months)
        #expect(needed == expected)
    }
}
