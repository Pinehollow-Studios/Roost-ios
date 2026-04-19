import Foundation
import Supabase

struct MoneySettingsService {

    func fetchSettings(homeId: UUID) async throws -> MoneySettings {
        let client = try SupabaseClientProvider.shared.requireClient()
        let home: Home = try await client
            .from("homes")
            .select()
            .eq("id", value: homeId)
            .single()
            .execute()
            .value
        return MoneySettings.from(home: home)
    }

    func persistSettings(_ settings: MoneySettings, homeId: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        let payload: [String: AnyJSON] = [
            "default_expense_split": .double(settings.defaultExpenseSplit),
            "budget_carry_forward": .string(settings.budgetCarryForward),
            "scramble_mode": .bool(settings.scrambleMode),
            "overspend_alert_threshold": .integer(settings.overspendAlertThreshold),
            "currency_symbol": .string(settings.currencySymbol),
            "settlement_mode": .string(settings.settlementMode)
        ]
        try await client
            .from("homes")
            .update(payload)
            .eq("id", value: homeId)
            .execute()
    }
}
