import Foundation
import Supabase

struct HazelBudgetInsight: Codable, Equatable {
    let summary: String
    let outlook: String
    let focus: [String]
}

struct HazelBudgetInsightInput: Codable, Equatable {
    struct TopCategory: Codable, Equatable {
        let name: String
        let spend: Double
        let limit: Double?
        let pct: Double
        let recurringTotal: Double
    }

    let monthLabel: String
    let totalSpent: Double
    let totalBudget: Double
    let projectedMonthEnd: Double
    let remaining: Double
    let overspend: Double
    let topCategories: [TopCategory]
}

enum BudgetInsightsServiceError: LocalizedError {
    case unavailable
    case notPro

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Hazel couldn’t read this month just now."
        case .notPro:
            return "Hazel budget insights are available with Roost Pro."
        }
    }
}

struct BudgetInsightsService {
    private let cachePrefix = "hazel-budget|"

    func cachedInsight(for key: String) -> HazelBudgetInsight? {
        guard let data = UserDefaults.standard.data(forKey: cachePrefix + key) else { return nil }
        return try? JSONDecoder().decode(HazelBudgetInsight.self, from: data)
    }

    func cache(_ insight: HazelBudgetInsight, for key: String) {
        guard let data = try? JSONEncoder().encode(insight) else { return }
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: cachePrefix + key)
        pruneCache(keeping: key, in: defaults)
    }

    func fetchInsights(homeId: UUID, input: HazelBudgetInsightInput) async throws -> HazelBudgetInsight {
        let client = try SupabaseClientProvider.shared.requireClient()
        let session = try await client.auth.session
        client.functions.setAuth(token: session.accessToken)

        do {
            let response: HazelBudgetInsightResponse = try await client.functions.invoke(
                "budget-insights",
                options: FunctionInvokeOptions(
                    method: .post,
                    body: RequestBody(homeId: homeId.uuidString, input: input)
                )
            )

            if response.success, let data = response.data {
                return data
            }

            if response.reason == "not_nest" {
                throw BudgetInsightsServiceError.notPro
            }

            throw BudgetInsightsServiceError.unavailable
        } catch let error as FunctionsError {
            switch error {
            case .httpError(_, _):
                throw BudgetInsightsServiceError.unavailable
            case .relayError:
                throw BudgetInsightsServiceError.unavailable
            }
        } catch {
            throw error
        }
    }

    private func pruneCache(keeping key: String, in defaults: UserDefaults) {
        let activeKey = cachePrefix + key
        for cachedKey in defaults.dictionaryRepresentation().keys where cachedKey.hasPrefix(cachePrefix) && cachedKey != activeKey {
            defaults.removeObject(forKey: cachedKey)
        }
    }

    private struct RequestBody: Encodable {
        let homeId: String
        let input: HazelBudgetInsightInput
    }

    private struct HazelBudgetInsightResponse: Decodable {
        let success: Bool
        let data: HazelBudgetInsight?
        let reason: String?
    }
}
