import Foundation
import Supabase

// MARK: - Response Models

struct HazelNormalizeResult: Decodable {
    let text: String
    let category: String?
}

struct HazelCategorizeResult: Decodable {
    let text: String
    let category: String
}

struct HazelSuggestResult: Decodable {
    let suggestions: [String]
}

// MARK: - Service

struct HazelService {

    // MARK: - Normalize (FREE — shopping, chore, budget)

    /// Normalizes a shopping item name and assigns a category.
    func normalizeShoppingItem(text: String, homeId: UUID) async -> HazelNormalizeResult? {
        await callNormalize(type: "shopping", text: text, homeId: homeId)
    }

    /// Normalizes a chore title to clean, action-oriented title case.
    func normalizeChoreTitle(text: String, homeId: UUID) async -> HazelNormalizeResult? {
        await callNormalize(type: "chore", text: text, homeId: homeId)
    }

    /// Normalizes a budget category name.
    func normalizeBudgetCategory(text: String, homeId: UUID) async -> HazelNormalizeResult? {
        await callNormalize(type: "budget", text: text, homeId: homeId)
    }

    // MARK: - Categorize Expense (PRO ONLY)

    /// Cleans up an expense title and assigns a category. Returns nil if not Pro or on error.
    func categorizeExpense(text: String, categories: [String], homeId: UUID) async -> HazelCategorizeResult? {
        guard let client = try? SupabaseClientProvider.shared.requireClient() else { return nil }

        do {
            let session = try await client.auth.session
            client.functions.setAuth(token: session.accessToken)

            let response: HazelFunctionResponse<HazelCategorizeResult> = try await client.functions.invoke(
                "hazel-categorize-expense",
                options: FunctionInvokeOptions(
                    method: .post,
                    body: CategorizeRequestBody(text: text, categories: categories, homeId: homeId.uuidString)
                )
            )

            if response.success, let data = response.data {
                return data
            }
        } catch {
            // Silently fail — Hazel is additive, not critical
        }

        return nil
    }

    // MARK: - Suggest Chores (FREE)

    /// Returns up to 5 suggested chore titles for the current month.
    func suggestChores(existingChores: [String], month: String, homeId: UUID) async -> [String] {
        guard let client = try? SupabaseClientProvider.shared.requireClient() else { return [] }

        do {
            let session = try await client.auth.session
            client.functions.setAuth(token: session.accessToken)

            let response: HazelFunctionResponse<HazelSuggestResult> = try await client.functions.invoke(
                "hazel-suggest-chores",
                options: FunctionInvokeOptions(
                    method: .post,
                    body: SuggestRequestBody(existingChores: existingChores, month: month, homeId: homeId.uuidString)
                )
            )

            if response.success, let data = response.data {
                return data.suggestions
            }
        } catch {
            // Silently fail
        }

        return []
    }

    // MARK: - Private

    private func callNormalize(type: String, text: String, homeId: UUID) async -> HazelNormalizeResult? {
        guard let client = try? SupabaseClientProvider.shared.requireClient() else { return nil }

        do {
            let session = try await client.auth.session
            client.functions.setAuth(token: session.accessToken)

            let response: HazelFunctionResponse<HazelNormalizeResult> = try await client.functions.invoke(
                "hazel-normalize",
                options: FunctionInvokeOptions(
                    method: .post,
                    body: NormalizeRequestBody(type: type, text: text, homeId: homeId.uuidString)
                )
            )

            if response.success, let data = response.data {
                return data
            }
        } catch {
            // Silently fail — Hazel is additive
        }

        return nil
    }
}

// MARK: - Request Bodies

private struct NormalizeRequestBody: Encodable {
    let type: String
    let text: String
    let homeId: String
}

private struct CategorizeRequestBody: Encodable {
    let text: String
    let categories: [String]
    let homeId: String
}

private struct SuggestRequestBody: Encodable {
    let existingChores: [String]
    let month: String
    let homeId: String
}

// MARK: - Generic Response Wrapper

private struct HazelFunctionResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let reason: String?
}
