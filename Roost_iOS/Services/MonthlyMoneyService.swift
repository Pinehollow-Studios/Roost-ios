import Foundation
import Supabase

struct MonthlyMoneyService {

    func fetchMonthlySummary(homeId: UUID, month: Date) async throws -> MonthlySummary? {
        let client = try SupabaseClientProvider.shared.requireClient()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let monthString = formatter.string(from: month)

        let response = try await client
            .rpc("get_monthly_summary", params: [
                "p_home_id": homeId.uuidString,
                "p_month": monthString
            ])
            .execute()

        // The RPC may return a single JSON object or an array with one element.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let single = try? decoder.decode(MonthlySummary.self, from: response.data) {
            return single
        }
        if let array = try? decoder.decode([MonthlySummary].self, from: response.data) {
            return array.first
        }
        return nil
    }
}
