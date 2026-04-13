import Foundation
import Supabase

struct NotificationService {
    func fetchNotifications(for userID: UUID) async throws -> [AppNotification] {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("notifications")
            .select()
            .eq("user_id", value: userID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func markAsRead(id: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("notifications")
            .update(["read": true])
            .eq("id", value: id)
            .execute()
    }

    func markAllAsRead(for userID: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("notifications")
            .update(["read": true])
            .eq("user_id", value: userID)
            .eq("read", value: false)
            .execute()
    }

    func fetchPreferences(for userID: UUID) async throws -> NotificationPrefs {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("notification_preferences")
            .select()
            .eq("user_id", value: userID)
            .single()
            .execute()
            .value
    }

    func upsertPreferences(_ preferences: NotificationPrefs) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("notification_preferences")
            .upsert(preferences, onConflict: "user_id")
            .execute()
    }
}
