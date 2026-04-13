import Foundation
import Observation
import Realtime

@MainActor
@Observable
final class DashboardViewModel {
    var shoppingItems: [ShoppingItem] = []
    var expenses: [ExpenseWithSplits] = []
    var chores: [Chore] = []
    var budgets: [Budget] = []
    var activityItems: [ActivityFeedItem] = []
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private let shoppingService = ShoppingService()

    @ObservationIgnored
    private let expenseService = ExpenseService()

    @ObservationIgnored
    private let choreService = ChoreService()

    @ObservationIgnored
    private let budgetService = BudgetService()

    @ObservationIgnored
    private let activityService = ActivityService()

    @ObservationIgnored
    private var shoppingSubscriptionId: UUID?

    @ObservationIgnored
    private var expensesSubscriptionId: UUID?

    @ObservationIgnored
    private var expenseSplitsSubscriptionId: UUID?

    @ObservationIgnored
    private var choresSubscriptionId: UUID?

    @ObservationIgnored
    private var budgetsSubscriptionId: UUID?

    @ObservationIgnored
    private var activitySubscriptionId: UUID?

    @ObservationIgnored
    private var homesSubscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    init() {}

    init(
        shoppingItems: [ShoppingItem],
        expenses: [ExpenseWithSplits],
        chores: [Chore],
        budgets: [Budget],
        activityItems: [ActivityFeedItem],
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.shoppingItems = shoppingItems
        self.expenses = expenses
        self.chores = chores
        self.budgets = budgets
        self.activityItems = activityItems
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    func load(homeId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            async let shoppingResult = shoppingService.fetchItems(for: homeId)
            async let expensesResult = expenseService.fetchExpenses(for: homeId)
            async let choresResult = choreService.fetchChores(for: homeId)
            async let budgetsResult = budgetService.fetchBudgets(for: homeId)
            async let activityResult = activityService.fetchActivity(for: homeId)

            shoppingItems = try await shoppingResult
            expenses = try await expensesResult
            chores = try await choresResult
            budgets = try await budgetsResult
            activityItems = try await activityResult
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }

        isLoading = false
    }

    var uncheckedShoppingItems: [ShoppingItem] {
        shoppingItems.filter { !$0.checked }
    }

    var latestShoppingItems: [ShoppingItem] {
        Array(shoppingItems.prefix(3))
    }

    func currentBalance(myUserId: UUID, partnerUserId: UUID) -> Decimal {
        BalanceCalculator.calculate(expenses: expenses, myUserId: myUserId, partnerUserId: partnerUserId)
    }

    var overdueChores: [Chore] {
        chores.filter {
            guard let dueDate = $0.dueDate, !$0.isCompleted else { return false }
            return Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: .now)
        }
    }

    var nextDueChore: Chore? {
        chores
            .filter { !$0.isCompleted && $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first
    }

    func budgetSummary(for month: Date) -> (spent: Decimal, limit: Decimal) {
        let monthBudgets = budgets.filter { Calendar.current.isDate($0.month, equalTo: month, toGranularity: .month) }
        let spent = expenses
            .filter {
                guard let date = $0.incurredOnDate else { return false }
                return Calendar.current.isDate(date, equalTo: month, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
        let limit = monthBudgets.reduce(0) { $0 + $1.amount }
        return (spent, limit)
    }

    var recentActivity: [ActivityFeedItem] {
        Array(activityItems.prefix(5))
    }

    func startRealtime(homeId: UUID) async {
        if let subscribedHomeId, subscribedHomeId != homeId {
            await stopRealtime()
        }
        guard shoppingSubscriptionId == nil,
              expensesSubscriptionId == nil,
              expenseSplitsSubscriptionId == nil,
              choresSubscriptionId == nil,
              budgetsSubscriptionId == nil,
              activitySubscriptionId == nil,
              homesSubscriptionId == nil else { return }
        subscribedHomeId = homeId

        shoppingSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "shopping_items",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshShopping(homeId: homeId)
        }

        expensesSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "expenses",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshExpenses(homeId: homeId)
        }

        expenseSplitsSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "expense_splits"
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshExpenses(homeId: homeId)
        }

        choresSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "chores",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshChores(homeId: homeId)
        }

        budgetsSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "budgets",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshBudgets(homeId: homeId)
        }

        activitySubscriptionId = await RealtimeManager.shared.subscribe(
            table: "activity_feed",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshActivity(homeId: homeId)
        }

        homesSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "homes",
            filter: .eq("id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshHomeDependentData(homeId: homeId)
        }
    }

    func stopRealtime() async {
        if let shoppingSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "shopping_items", callbackId: shoppingSubscriptionId)
            self.shoppingSubscriptionId = nil
        }
        if let expensesSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "expenses", callbackId: expensesSubscriptionId)
            self.expensesSubscriptionId = nil
        }
        if let expenseSplitsSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "expense_splits", callbackId: expenseSplitsSubscriptionId)
            self.expenseSplitsSubscriptionId = nil
        }
        if let choresSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "chores", callbackId: choresSubscriptionId)
            self.choresSubscriptionId = nil
        }
        if let budgetsSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "budgets", callbackId: budgetsSubscriptionId)
            self.budgetsSubscriptionId = nil
        }
        if let activitySubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "activity_feed", callbackId: activitySubscriptionId)
            self.activitySubscriptionId = nil
        }
        if let homesSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "homes", callbackId: homesSubscriptionId)
            self.homesSubscriptionId = nil
        }
        subscribedHomeId = nil
    }

    private func refreshShopping(homeId: UUID) async {
        do {
            shoppingItems = try await shoppingService.fetchItems(for: homeId)
        } catch {
            if !isCancellation(error) { errorMessage = String(describing: error) }
        }
    }

    private func refreshExpenses(homeId: UUID) async {
        do {
            expenses = try await expenseService.fetchExpenses(for: homeId)
        } catch {
            if !isCancellation(error) { errorMessage = String(describing: error) }
        }
    }

    private func refreshChores(homeId: UUID) async {
        do {
            chores = try await choreService.fetchChores(for: homeId)
        } catch {
            if !isCancellation(error) { errorMessage = String(describing: error) }
        }
    }

    private func refreshBudgets(homeId: UUID) async {
        do {
            budgets = try await budgetService.fetchBudgets(for: homeId)
        } catch {
            if !isCancellation(error) { errorMessage = String(describing: error) }
        }
    }

    private func refreshActivity(homeId: UUID) async {
        do {
            activityItems = try await activityService.fetchActivity(for: homeId)
        } catch {
            if !isCancellation(error) { errorMessage = String(describing: error) }
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
    }

    private func refreshHomeDependentData(homeId: UUID) async {
        await refreshShopping(homeId: homeId)
    }
}
