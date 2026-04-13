import Foundation
import Supabase

struct BudgetTemplateService {

    func fetchTemplateLines(homeId: UUID) async throws -> [BudgetTemplateLine] {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("budget_template_lines")
            .select()
            .eq("home_id", value: homeId)
            .eq("is_active", value: true)
            .order("sort_order")
            .execute()
            .value
    }

    func addLine(_ line: CreateBudgetLine) async throws -> BudgetTemplateLine {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("budget_template_lines")
            .insert(line)
            .select()
            .single()
            .execute()
            .value
    }

    func updateLine(id: UUID, updates: UpdateBudgetLine) async throws -> BudgetTemplateLine {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("budget_template_lines")
            .update(updates)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    /// Sets is_active = false. Never hard-deletes a template line.
    func removeLine(id: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("budget_template_lines")
            .update(["is_active": false])
            .eq("id", value: id)
            .execute()
    }

    func fetchRolloverHistory(homeId: UUID, month: Date) async throws -> [BudgetRolloverHistory] {
        let client = try SupabaseClientProvider.shared.requireClient()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let monthString = formatter.string(from: month)
        return try await client
            .from("budget_rollover_history")
            .select()
            .eq("home_id", value: homeId)
            .eq("month", value: monthString)
            .execute()
            .value
    }

    func upsertRolloverHistory(_ history: CreateRolloverHistory) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("budget_rollover_history")
            .upsert(history, onConflict: "home_id,template_line_id,month")
            .execute()
    }
}
