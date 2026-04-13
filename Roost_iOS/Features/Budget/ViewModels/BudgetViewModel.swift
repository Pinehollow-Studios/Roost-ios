import Foundation
import Observation
import Realtime

@MainActor
@Observable
final class BudgetViewModel {
    struct BudgetRowModel: Identifiable, Hashable {
        let definition: BudgetCategoryDefinition
        let budget: Budget?
        let spent: Decimal

        var id: String { definition.id }
        var category: String { definition.name }
        var limit: Decimal { budget?.amount ?? 0 }

        var progress: Double {
            guard limit > 0 else { return spent > 0 ? 1 : 0 }
            return NSDecimalNumber(decimal: spent / limit).doubleValue
        }
    }

    var budgets: [Budget] = []
    var customCategories: [CustomCategory] = []
    var expenses: [ExpenseWithSplits] = []
    var selectedMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private let budgetService = BudgetService()

    @ObservationIgnored
    private let expenseService = ExpenseService()

    @ObservationIgnored
    private var budgetSubscriptionId: UUID?

    @ObservationIgnored
    private var categorySubscriptionId: UUID?

    @ObservationIgnored
    private var expenseSubscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    init(
        budgets: [Budget] = [],
        customCategories: [CustomCategory] = [],
        expenses: [ExpenseWithSplits] = [],
        selectedMonth: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now,
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.budgets = budgets
        self.customCategories = customCategories
        self.expenses = expenses
        self.selectedMonth = selectedMonth
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    var allCategoryDefinitions: [BudgetCategoryDefinition] {
        BudgetCategoryCatalog.mergeCategories(custom: customCategories)
    }

    var rows: [BudgetRowModel] {
        rows(for: selectedMonth)
    }

    var totalBudget: Decimal {
        budgets(in: selectedMonth).reduce(0) { $0 + $1.amount }
    }

    var totalSpent: Decimal {
        rows.reduce(0) { $0 + $1.spent }
    }

    var hasBudgetsForSelectedMonth: Bool {
        !budgets(in: selectedMonth).isEmpty
    }

    func rows(for month: Date) -> [BudgetRowModel] {
        let monthBudgets = budgets(in: month)
        let monthExpenses = expenses(in: month)
        let definitions = allCategoryDefinitions
        let knownNames = Set(definitions.map(\.name))

        var orderedRows = definitions.compactMap { definition -> BudgetRowModel? in
            let budget = monthBudgets.first { $0.category.caseInsensitiveCompare(definition.name) == .orderedSame }
            let spend = spent(for: definition.name, in: monthExpenses)

            guard budget != nil || spend > 0 else { return nil }

            return BudgetRowModel(definition: definition, budget: budget, spent: spend)
        }

        let orphanedNames = Set(monthExpenses.compactMap(\.category))
            .filter { !knownNames.contains($0) }
            .sorted()

        orderedRows.append(contentsOf: orphanedNames.map { name in
            BudgetRowModel(
                definition: BudgetCategoryCatalog.definition(for: name, custom: customCategories),
                budget: monthBudgets.first { $0.category.caseInsensitiveCompare(name) == .orderedSame },
                spent: spent(for: name, in: monthExpenses)
            )
        })

        return orderedRows
    }

    func hasBudgets(in month: Date) -> Bool {
        !budgets(in: month).isEmpty
    }

    func budget(for category: String, in month: Date) -> Budget? {
        budgets(in: month).first { $0.category.caseInsensitiveCompare(category) == .orderedSame }
    }

    func limit(for category: String, in month: Date) -> Decimal? {
        budget(for: category, in: month)?.amount
    }

    func canCarryForwardBudgets(into month: Date) -> Bool {
        !copyableBudgetsFromPreviousMonth(into: month).isEmpty
    }

    func load(homeId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            async let budgetsResult = budgetService.fetchBudgets(for: homeId)
            async let categoriesResult = budgetService.fetchCustomCategories(for: homeId)
            async let expensesResult = expenseService.fetchExpenses(for: homeId)

            budgets = try await budgetsResult
            customCategories = try await categoriesResult
            expenses = try await expensesResult
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }

        isLoading = false
    }

    func changeMonth(by offset: Int) {
        if let nextMonth = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonth) {
            selectedMonth = normalizedMonth(nextMonth)
        }
    }

    func resetToCurrentMonth() {
        selectedMonth = normalizedMonth(.now)
    }

    func saveBudget(category: String, amount: Decimal, homeId: UUID, userId: UUID, month: Date? = nil) async -> Bool {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty, amount > 0 else { return false }

        let targetMonth = normalizedMonth(month ?? selectedMonth)

        let payload = UpsertBudget(
            homeID: homeId,
            category: trimmedCategory,
            amount: amount,
            month: targetMonth
        )

        do {
            let savedBudget = try await budgetService.upsertBudget(payload)
            upsertLocalBudget(savedBudget, for: targetMonth)
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: "set budget for \(trimmedCategory)",
                entityType: "budget"
            )
            return true
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
            return false
        }
    }

    func deleteBudget(_ budget: Budget, homeId: UUID, userId: UUID) async -> Bool {
        let original = budgets
        budgets.removeAll { $0.id == budget.id }

        do {
            try await budgetService.deleteBudget(id: budget.id)
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: "deleted budget for \(budget.category)",
                entityType: "budget",
                entityId: budget.id.uuidString
            )
            return true
        } catch {
            budgets = original
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
            return false
        }
    }

    func copyBudgetsFromPreviousMonth(into month: Date, homeId: UUID, userId: UUID) async {
        let copyable = copyableBudgetsFromPreviousMonth(into: month)
        guard !copyable.isEmpty else { return }

        do {
            for budget in copyable {
                try await budgetService.upsertBudget(
                    UpsertBudget(
                        homeID: homeId,
                        category: budget.category,
                        amount: budget.amount,
                        month: normalizedMonth(month)
                    )
                )
            }

            await refreshBudgets(homeId: homeId)
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: "carried forward budget limits",
                entityType: "budget"
            )
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    func ensureBudgetsCarriedForward(into month: Date, homeId: UUID, userId: UUID) async {
        let normalized = normalizedMonth(month)
        guard !hasBudgets(in: normalized) else { return }
        await copyBudgetsFromPreviousMonth(into: normalized, homeId: homeId, userId: userId)
    }

    func addCustomCategory(name: String, emoji: String, color: String, homeId: UUID, userId: UUID) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard !allCategoryDefinitions.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) else {
            errorMessage = "That category already exists."
            return
        }

        do {
            let created = try await budgetService.createCustomCategory(
                CreateCustomCategory(homeID: homeId, name: trimmedName, emoji: emoji, color: color)
            )
            customCategories.append(created)
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: "created budget category \(trimmedName)",
                entityType: "budget_category",
                entityId: created.id.uuidString
            )
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    func deleteCustomCategory(_ category: CustomCategory, homeId: UUID, userId: UUID) async {
        let originalCategories = customCategories
        let originalBudgets = budgets
        let relatedBudgets = budgets.filter { $0.category.caseInsensitiveCompare(category.name) == .orderedSame }

        customCategories.removeAll { $0.id == category.id }
        budgets.removeAll { $0.category.caseInsensitiveCompare(category.name) == .orderedSame }

        do {
            for budget in relatedBudgets {
                try await budgetService.deleteBudget(id: budget.id)
            }

            try await budgetService.deleteCustomCategory(id: category.id)
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: "deleted budget category \(category.name)",
                entityType: "budget_category",
                entityId: category.id.uuidString
            )
        } catch {
            customCategories = originalCategories
            budgets = originalBudgets
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    func startRealtime(homeId: UUID) async {
        if let subscribedHomeId, subscribedHomeId != homeId {
            await stopRealtime()
        }
        guard budgetSubscriptionId == nil,
              categorySubscriptionId == nil,
              expenseSubscriptionId == nil else { return }
        subscribedHomeId = homeId

        budgetSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "budgets",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshBudgets(homeId: homeId)
        }

        categorySubscriptionId = await RealtimeManager.shared.subscribe(
            table: "home_custom_categories",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshCategories(homeId: homeId)
        }

        expenseSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "expenses",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.refreshExpenses(homeId: homeId)
        }
    }

    func stopRealtime() async {
        if let budgetSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "budgets", callbackId: budgetSubscriptionId)
            self.budgetSubscriptionId = nil
        }

        if let categorySubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "home_custom_categories", callbackId: categorySubscriptionId)
            self.categorySubscriptionId = nil
        }

        if let expenseSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "expenses", callbackId: expenseSubscriptionId)
            self.expenseSubscriptionId = nil
        }

        subscribedHomeId = nil
    }

    private var currentMonthBudgets: [Budget] {
        budgets(in: selectedMonth)
    }

    private var currentMonthExpenses: [ExpenseWithSplits] {
        expenses(in: selectedMonth)
    }

    private func spent(for category: String) -> Decimal {
        spent(for: category, in: currentMonthExpenses)
    }

    private func spent(for category: String, in monthExpenses: [ExpenseWithSplits]) -> Decimal {
        monthExpenses
            .filter { ($0.category ?? "Other").caseInsensitiveCompare(category) == .orderedSame }
            .reduce(0) { $0 + $1.amount }
    }

    private func budgets(in month: Date) -> [Budget] {
        budgets.filter { Calendar.current.isDate($0.month, equalTo: month, toGranularity: .month) }
    }

    private func expenses(in month: Date) -> [ExpenseWithSplits] {
        expenses.filter { expense in
            guard let date = expense.incurredOnDate else { return false }
            return Calendar.current.isDate(date, equalTo: month, toGranularity: .month)
        }
    }

    private func copyableBudgetsFromPreviousMonth(into month: Date) -> [Budget] {
        guard let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: normalizedMonth(month)) else {
            return []
        }

        let existingCategories = Set(budgets(in: month).map { $0.category.lowercased() })
        return budgets(in: previousMonth).filter { !existingCategories.contains($0.category.lowercased()) }
    }

    private func refreshBudgets(homeId: UUID) async {
        do {
            budgets = try await budgetService.fetchBudgets(for: homeId)
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    private func refreshCategories(homeId: UUID) async {
        do {
            customCategories = try await budgetService.fetchCustomCategories(for: homeId)
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    private func refreshExpenses(homeId: UUID) async {
        do {
            expenses = try await expenseService.fetchExpenses(for: homeId)
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    private func upsertLocalBudget(_ budget: Budget, for month: Date) {
        let normalized = normalizedMonth(month)
        budgets.removeAll {
            $0.homeID == budget.homeID &&
            $0.category.caseInsensitiveCompare(budget.category) == .orderedSame &&
            Calendar.current.isDate($0.month, equalTo: normalized, toGranularity: .month)
        }
        budgets.append(budget)
    }

    private func normalizedMonth(_ date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
    }
}
