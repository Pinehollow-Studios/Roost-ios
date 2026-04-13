import Foundation
import Observation
import Realtime
import SwiftUI

// MARK: - Supporting types

struct BudgetCategory: Identifiable {
    let id: UUID
    let name: String
    let colour: Color
}

struct BillClash: Identifiable {
    let id: UUID = UUID()
    let lines: [BudgetTemplateLine]
    let totalAmount: Decimal
    let earliestDay: Int
    let latestDay: Int
}

// MARK: - ViewModel

@MainActor
@Observable
final class BudgetTemplateViewModel {

    var templateLines: [BudgetTemplateLine] = []
    var rolloverHistory: [BudgetRolloverHistory] = []
    var isLoading = false
    var error: Error?

    @ObservationIgnored
    private let service = BudgetTemplateService()

    @ObservationIgnored
    private var templateLinesSubscriptionId: UUID?

    @ObservationIgnored
    private var rolloverSubscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    // MARK: - Computed properties

    var activeLines: [BudgetTemplateLine] {
        templateLines.filter(\.isActive).sorted { $0.sortOrder < $1.sortOrder }
    }

    var fixedLines: [BudgetTemplateLine] {
        activeLines.filter(\.isFixed)
    }

    var lifestyleLines: [BudgetTemplateLine] {
        activeLines.filter(\.isLifestyle)
    }

    /// The source of truth for expense categorisation. Derived from lifestyle lines only.
    var categories: [BudgetCategory] {
        lifestyleLines.map { line in
            BudgetCategory(id: line.id, name: line.name, colour: categoryColour(for: line.name))
        }
    }

    var linesBySection: [String: [BudgetTemplateLine]] {
        Dictionary(grouping: activeLines, by: \.sectionGroup)
    }

    var totalFixed: Decimal {
        fixedLines.reduce(0) { $0 + $1.displayAmount }
    }

    var totalLifestyle: Decimal {
        lifestyleLines.reduce(0) { $0 + $1.displayAmount }
    }

    var totalBudgeted: Decimal {
        totalFixed + totalLifestyle
    }

    // MARK: - Rollover-aware helpers

    /// Effective budget for a lifestyle line this month (base + any rollover).
    func getEffectiveAmount(lineId: UUID, month: Date) -> Decimal {
        guard let line = templateLines.first(where: { $0.id == lineId }) else { return 0 }
        let base = line.displayAmount
        guard line.rolloverEnabled, let rollover = getRolloverAmount(lineId: lineId) else {
            return base
        }
        return base + rollover
    }

    /// Rollover from previous month for the given line (from cached rolloverHistory).
    func getRolloverAmount(lineId: UUID) -> Decimal? {
        rolloverHistory.first(where: { $0.templateLineId == lineId })?.rolloverAmount
    }

    /// Total spent against a lifestyle line's category in a given month.
    func getSpent(category: String, month: Date, expenses: [Expense]) -> Decimal {
        let cal = Calendar.current
        return expenses
            .filter { expense in
                guard let cat = expense.category,
                      cat.caseInsensitiveCompare(category) == .orderedSame,
                      let date = expense.incurredOnDate else { return false }
                return cal.isDate(date, equalTo: month, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }

    /// Remaining budget in a lifestyle line for the given month.
    func getRemaining(lineId: UUID, month: Date, expenses: [Expense]) -> Decimal {
        guard let line = templateLines.first(where: { $0.id == lineId }) else { return 0 }
        let effective = getEffectiveAmount(lineId: lineId, month: month)
        let spent = getSpent(category: line.name, month: month, expenses: expenses)
        return effective - spent
    }

    // MARK: - Health score

    /// Budget health score 0–100.
    func calculateHealthScore(income: Decimal, hasGoals: Bool) -> Int {
        guard income > 0 else { return 50 }

        var score = 100

        // Penalise for fixed costs above 50% of income
        let fixedRatio = NSDecimalNumber(decimal: totalFixed / income).doubleValue
        if fixedRatio > 0.7 { score -= 30 }
        else if fixedRatio > 0.5 { score -= 15 }

        // Penalise for total budgeted above 90% of income
        let totalRatio = NSDecimalNumber(decimal: totalBudgeted / income).doubleValue
        if totalRatio > 0.9 { score -= 20 }
        else if totalRatio > 0.8 { score -= 10 }

        // Reward for having savings goals
        if hasGoals { score += 10 }

        // Reward for having any lifestyle envelopes
        if !lifestyleLines.isEmpty { score += 5 }

        return max(0, min(100, score))
    }

    // MARK: - Bill clash detection

    /// Detects fixed lines whose payment days cluster close together.
    func detectBillClashes() -> [BillClash] {
        let billsWithDay = fixedLines.compactMap { line -> (BudgetTemplateLine, Int)? in
            guard let day = line.dayOfMonth else { return nil }
            return (line, day)
        }
        guard !billsWithDay.isEmpty else { return [] }

        // Group into 5-day windows
        var clashes: [BillClash] = []
        var processed: Set<UUID> = []

        for (line, day) in billsWithDay {
            guard !processed.contains(line.id) else { continue }
            let window = billsWithDay.filter { abs($0.1 - day) <= 2 }
            guard window.count > 1 else { continue }
            let clashLines = window.map(\.0)
            let total = clashLines.reduce(Decimal(0)) { $0 + $1.displayAmount }
            let days = window.map(\.1)
            let clash = BillClash(
                lines: clashLines,
                totalAmount: total,
                earliestDay: days.min() ?? day,
                latestDay: days.max() ?? day
            )
            clashes.append(clash)
            clashLines.forEach { processed.insert($0.id) }
        }
        return clashes
    }

    // MARK: - Load & CRUD

    func load(homeId: UUID) async {
        isLoading = true
        error = nil
        let currentMonth = Date().startOfMonth
        do {
            async let linesTask = service.fetchTemplateLines(homeId: homeId)
            async let rolloverTask = service.fetchRolloverHistory(homeId: homeId, month: currentMonth)
            templateLines = try await linesTask
            rolloverHistory = try await rolloverTask
        } catch {
            if !isCancellation(error) { self.error = error }
        }
        isLoading = false
    }

    func addLine(_ data: CreateBudgetLine) async throws {
        let created = try await service.addLine(data)
        templateLines.append(created)
    }

    func updateLine(id: UUID, updates: UpdateBudgetLine) async throws {
        let updated = try await service.updateLine(id: id, updates: updates)
        if let idx = templateLines.firstIndex(where: { $0.id == id }) {
            templateLines[idx] = updated
        }
    }

    func removeLine(id: UUID) async throws {
        try await service.removeLine(id: id)
        if let idx = templateLines.firstIndex(where: { $0.id == id }) {
            templateLines[idx].isActive = false
        }
    }

    // MARK: - Month-end rollover

    /// Idempotent — safe to call on every load.
    /// For each lifestyle line with rolloverEnabled, checks if a rollover history
    /// entry already exists for the current month. If not, calculates the underspent
    /// amount from the previous month and records it.
    func processMonthRollover(homeId: UUID, month: Date, expenses: [Expense]) async {
        let cal = Calendar.current
        guard let previousMonth = cal.date(byAdding: .month, value: -1, to: month) else { return }

        let rolloverLines = lifestyleLines.filter(\.rolloverEnabled)
        guard !rolloverLines.isEmpty else { return }

        // Load previous month rollover history to get carry-in amounts
        let previousRollover = (try? await service.fetchRolloverHistory(homeId: homeId, month: previousMonth)) ?? []

        for line in rolloverLines {
            // Skip if already recorded for this month
            let alreadyExists = rolloverHistory.contains {
                $0.templateLineId == line.id &&
                cal.isDate($0.month, equalTo: month, toGranularity: .month)
            }
            guard !alreadyExists else { continue }

            let baseAmount = line.displayAmount
            let prevCarryIn = previousRollover.first(where: { $0.templateLineId == line.id })?.rolloverAmount ?? 0
            let prevEffective = baseAmount + prevCarryIn
            let prevSpent = getSpent(category: line.name, month: previousMonth, expenses: expenses)
            let rolloverAmount = max(0, prevEffective - prevSpent)
            let effectiveAmount = baseAmount + rolloverAmount

            let history = CreateRolloverHistory(
                homeId: homeId,
                templateLineId: line.id,
                month: month,
                baseAmount: baseAmount,
                rolloverAmount: rolloverAmount,
                effectiveAmount: effectiveAmount
            )

            do {
                try await service.upsertRolloverHistory(history)
            } catch {
                // Non-fatal — continue processing other lines
            }
        }

        // Refresh cached rollover history
        if let refreshed = try? await service.fetchRolloverHistory(homeId: homeId, month: month) {
            rolloverHistory = refreshed
        }
    }

    // MARK: - Realtime

    func startRealtime(homeId: UUID) async {
        if let existing = subscribedHomeId, existing != homeId { await stopRealtime() }
        guard templateLinesSubscriptionId == nil else { return }
        subscribedHomeId = homeId

        templateLinesSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "budget_template_lines",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let hid = self.subscribedHomeId else { return }
            await self.refreshTemplateLines(homeId: hid)
        }

        rolloverSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "budget_rollover_history",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let hid = self.subscribedHomeId else { return }
            await self.refreshRolloverHistory(homeId: hid)
        }
    }

    func stopRealtime() async {
        if let id = templateLinesSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "budget_template_lines", callbackId: id)
            templateLinesSubscriptionId = nil
        }
        if let id = rolloverSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "budget_rollover_history", callbackId: id)
            rolloverSubscriptionId = nil
        }
        subscribedHomeId = nil
    }

    // MARK: - Private helpers

    private func refreshTemplateLines(homeId: UUID) async {
        guard let lines = try? await service.fetchTemplateLines(homeId: homeId) else { return }
        templateLines = lines
    }

    private func refreshRolloverHistory(homeId: UUID) async {
        let month = Date().startOfMonth
        guard let history = try? await service.fetchRolloverHistory(homeId: homeId, month: month) else { return }
        rolloverHistory = history
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
    }

    /// Stable colour derived from a category name using a hash.
    private func categoryColour(for name: String) -> Color {
        let palette: [Color] = [
            Color(hex: 0xD4815E), // terracotta
            Color(hex: 0x8EA882), // sage
            Color(hex: 0xC99952), // amber
            Color(hex: 0x7CB7A3), // teal
            Color(hex: 0x7A8FA1), // slate-blue
            Color(hex: 0xD98695), // rose
            Color(hex: 0xA08AB8), // violet
            Color(hex: 0x8F6BAE), // purple
        ]
        let hash = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }
}

// MARK: - Date helpers

private extension Date {
    var startOfMonth: Date {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: self)
        ) ?? self
    }
}
