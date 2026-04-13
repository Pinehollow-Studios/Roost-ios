import Foundation
import Observation
import Realtime

@MainActor
@Observable
final class MonthlyMoneyViewModel {

    var summary: MonthlySummary?
    var selectedMonth: Date = Date().startOfMonth
    var isLoading = false
    var error: Error?

    @ObservationIgnored
    private let service = MonthlyMoneyService()

    @ObservationIgnored
    private var incomeSubscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    // MARK: - Computed

    var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
    }

    var daysElapsed: Int {
        let cal = Calendar.current
        let today = Date()
        // For past months, all days are elapsed
        guard cal.isDate(today, equalTo: selectedMonth, toGranularity: .month) else {
            return daysInMonth
        }
        return cal.component(.day, from: today)
    }

    var dailySpendRate: Decimal? {
        guard let summary, daysElapsed > 0 else { return nil }
        return summary.actualSpend / Decimal(daysElapsed)
    }

    var projectedLifestyleSpend: Decimal? {
        guard let rate = dailySpendRate else { return nil }
        return rate * Decimal(daysInMonth)
    }

    var projectedSurplus: Decimal? {
        guard let summary, let projected = projectedLifestyleSpend else { return nil }
        return summary.income - summary.fixedCosts - projected
    }

    // MARK: - Load

    func loadSummary(homeId: UUID) async {
        isLoading = true
        error = nil
        do {
            summary = try await service.fetchMonthlySummary(homeId: homeId, month: selectedMonth)
        } catch {
            if !isCancellation(error) { self.error = error }
        }
        isLoading = false
    }

    func navigateMonth(direction: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: direction, to: selectedMonth) else { return }
        // Clamp forward navigation at current month
        if direction > 0 && next > Date().startOfMonth { return }
        selectedMonth = next.startOfMonth
        summary = nil
    }

    // MARK: - Realtime

    func startRealtime(homeId: UUID) async {
        if let existing = subscribedHomeId, existing != homeId { await stopRealtime() }
        guard incomeSubscriptionId == nil else { return }
        subscribedHomeId = homeId

        incomeSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "household_income",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let hid = self.subscribedHomeId else { return }
            await self.loadSummary(homeId: hid)
        }
    }

    func stopRealtime() async {
        if let id = incomeSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "household_income", callbackId: id)
            incomeSubscriptionId = nil
        }
        subscribedHomeId = nil
    }

    // MARK: - Private

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
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
