import Foundation
import Supabase

struct MonthlyMoneyService {
    private let incomeService = HouseholdIncomeService()

    func fetchMonthlySummary(homeId: UUID, month: Date) async throws -> MonthlySummary? {
        let client = try SupabaseClientProvider.shared.requireClient()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let monthString = formatter.string(from: month)

        async let liveIncome = incomeService.fetchCombinedMemberIncome(homeId: homeId)
        let response = try await client
            .rpc("get_monthly_summary", params: [
                "p_home_id": homeId.uuidString,
                "p_month": monthString
            ])
            .execute()
        let income = try await liveIncome

        // The RPC may return a single JSON object or an array with one element.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let single = try? decoder.decode(MonthlySummary.self, from: response.data) {
            return single.replacingIncome(income)
        }
        if let array = try? decoder.decode([MonthlySummary].self, from: response.data) {
            return array.first?.replacingIncome(income) ?? .empty(income: income)
        }
        return .empty(income: income)
    }
}
