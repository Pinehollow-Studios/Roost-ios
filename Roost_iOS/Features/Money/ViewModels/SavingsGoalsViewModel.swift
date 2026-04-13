import Foundation
import Observation
import Realtime
import SwiftUI

@MainActor
@Observable
final class SavingsGoalsViewModel {

    var goals: [SavingsGoal] = []
    var isLoading = false
    var error: Error?

    @ObservationIgnored
    private let service = SavingsGoalsService()

    @ObservationIgnored
    private var subscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    // MARK: - Computed

    var activeGoals: [SavingsGoal] {
        goals.filter { !$0.isCompleted }
    }

    var completedGoals: [SavingsGoal] {
        goals.filter(\.isCompleted)
    }

    var totalMonthlyContribution: Decimal {
        activeGoals.compactMap(\.monthlyContribution).reduce(0, +)
    }

    // MARK: - Load

    func load(homeId: UUID) async {
        isLoading = true
        error = nil
        do {
            goals = try await service.fetchGoals(homeId: homeId)
        } catch {
            if !isCancellation(error) { self.error = error }
        }
        isLoading = false
    }

    // MARK: - CRUD

    func addGoal(_ data: CreateSavingsGoal) async throws {
        let created = try await service.addGoal(data)
        goals.append(created)
    }

    func addToGoal(id: UUID, amount: Decimal) async throws {
        let updated = try await service.addToGoal(id: id, amount: amount)
        if let idx = goals.firstIndex(where: { $0.id == id }) {
            goals[idx] = updated
        }
    }

    func updateGoal(id: UUID, updates: [String: AnyJSON]) async throws {
        let updated = try await service.updateGoal(id: id, updates: updates)
        if let idx = goals.firstIndex(where: { $0.id == id }) {
            goals[idx] = updated
        }
    }

    func completeGoal(id: UUID) async throws {
        let updated = try await service.completeGoal(id: id)
        if let idx = goals.firstIndex(where: { $0.id == id }) {
            goals[idx] = updated
        }
    }

    func deleteGoal(id: UUID) async throws {
        try await service.deleteGoal(id: id)
        goals.removeAll { $0.id == id }
    }

    func setGoalContribution(
        goalId: UUID,
        homeId: UUID,
        existingBudgetLineId: UUID?,
        name: String,
        amount: Decimal,
        contributionDay: Int
    ) async throws {
        let updated = try await service.setGoalContribution(
            goalId: goalId,
            homeId: homeId,
            existingBudgetLineId: existingBudgetLineId,
            name: name,
            amount: amount,
            contributionDay: contributionDay
        )
        if let idx = goals.firstIndex(where: { $0.id == goalId }) {
            goals[idx] = updated
        }
    }

    /// Clears monthly_contribution and contribution_day on the goal without touching the budget template line.
    func clearContributionFields(goalId: UUID) async throws {
        let updated = try await service.updateGoal(id: goalId, updates: [
            "monthly_contribution": AnyJSON.null,
            "contribution_day": AnyJSON.null
        ])
        if let idx = goals.firstIndex(where: { $0.id == goalId }) {
            goals[idx] = updated
        }
    }

    func removeGoalContribution(goalId: UUID, budgetLineId: UUID) async throws {
        let updated = try await service.removeGoalContribution(goalId: goalId, budgetLineId: budgetLineId)
        if let idx = goals.firstIndex(where: { $0.id == goalId }) {
            goals[idx] = updated
        }
    }

    // MARK: - Realtime

    func startRealtime(homeId: UUID) async {
        if let existing = subscribedHomeId, existing != homeId { await stopRealtime() }
        guard subscriptionId == nil else { return }
        subscribedHomeId = homeId

        subscriptionId = await RealtimeManager.shared.subscribe(
            table: "savings_goals",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let hid = self.subscribedHomeId else { return }
            await self.refresh(homeId: hid)
        }
    }

    func stopRealtime() async {
        if let id = subscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "savings_goals", callbackId: id)
            subscriptionId = nil
        }
        subscribedHomeId = nil
    }

    // MARK: - Private

    private func refresh(homeId: UUID) async {
        guard let updated = try? await service.fetchGoals(homeId: homeId) else { return }
        goals = updated
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
    }
}
