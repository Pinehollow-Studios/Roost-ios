import Foundation
import Supabase

struct ActivityService {
    func fetchActivity(for homeID: UUID) async throws -> [ActivityFeedItem] {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("activity_feed")
            .select()
            .eq("home_id", value: homeID)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
    }

    static func logActivity(
        homeId: String,
        userId: String,
        action: String,
        entityType: String,
        entityId: String? = nil
    ) {
        Task {
            do {
                let client = try SupabaseClientProvider.shared.requireClient()
                var params: [String: String] = [
                    "home_id": homeId,
                    "user_id": userId,
                    "action": action,
                    "entity_type": entityType,
                ]
                if let entityId {
                    params["entity_id"] = entityId
                }
                try await client
                    .from("activity_feed")
                    .insert(params)
                    .execute()
            } catch {
                // Fire-and-forget — never block the UI for activity logging
            }
        }
    }
}
