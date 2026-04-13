import Foundation
import Supabase

struct BudgetService {
    func fetchBudgets(for homeID: UUID) async throws -> [Budget] {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("budgets")
            .select()
            .eq("home_id", value: homeID)
            .execute()
            .value
    }

    func upsertBudget(_ budget: UpsertBudget) async throws -> Budget {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("budgets")
            .upsert(budget, onConflict: "home_id,category,month")
            .select()
            .single()
            .execute()
            .value
    }

    func deleteBudget(id: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("budgets")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func fetchCustomCategories(for homeID: UUID) async throws -> [CustomCategory] {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("home_custom_categories")
            .select()
            .eq("home_id", value: homeID)
            .order("created_at")
            .execute()
            .value
    }

    func createCustomCategory(_ category: CreateCustomCategory) async throws -> CustomCategory {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("home_custom_categories")
            .insert(category)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteCustomCategory(id: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("home_custom_categories")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
