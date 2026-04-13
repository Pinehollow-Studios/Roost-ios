import Foundation
import Supabase

struct UserPreferencesService {
    func fetchPreferences(for userID: UUID) async throws -> UserPreferences {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("user_preferences")
            .select()
            .eq("user_id", value: userID)
            .single()
            .execute()
            .value
    }

    func upsertPreferences(_ preferences: UserPreferences) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("user_preferences")
            .upsert(preferences, onConflict: "user_id")
            .execute()
    }
}
