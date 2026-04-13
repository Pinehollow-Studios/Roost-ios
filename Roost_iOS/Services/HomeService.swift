import Foundation
import Supabase

struct HomeService {
    func createHomeForUser(homeName: String, displayName: String) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .rpc("create_home_for_user", params: [
                "home_name": homeName,
                "display_name": displayName
            ])
            .execute()
    }

    func joinHome(inviteCode: String, displayName: String) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .rpc("join_home_by_invite_code", params: [
                "code": inviteCode.lowercased(),
                "display_name": displayName
            ])
            .execute()
    }

    func getUserHomeID() async throws -> UUID? {
        let client = try SupabaseClientProvider.shared.requireClient()
        let response = try await client
            .rpc("get_user_home_id")
            .execute()

        return try JSONDecoder().decode(UUID?.self, from: response.data)
    }

    func fetchHome(id: UUID) async throws -> Home {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("homes")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func fetchMembers(homeId: UUID) async throws -> [HomeMember] {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("home_members")
            .select()
            .eq("home_id", value: homeId)
            .execute()
            .value
    }

    func updateMemberProfile(id: UUID, displayName: String, avatarColor: String?, avatarIcon: String?) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        var payload: [String: AnyJSON] = [
            "display_name": .string(displayName)
        ]
        if let avatarColor {
            payload["avatar_color"] = .string(avatarColor)
        } else {
            payload["avatar_color"] = .null
        }
        if let avatarIcon {
            payload["avatar_icon"] = .string(avatarIcon)
        } else {
            payload["avatar_icon"] = .null
        }
        try await client
            .from("home_members")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    func updateHomeName(id: UUID, name: String) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("homes")
            .update(["name": name])
            .eq("id", value: id)
            .execute()
    }

    func updateNextShopDate(homeId: UUID, date: Date) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        try await client
            .from("homes")
            .update(["next_shop_date": formatter.string(from: date)])
            .eq("id", value: homeId)
            .execute()
    }

    func leaveHome() async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .rpc("leave_home")
            .execute()
    }

    func deleteAccount() async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .rpc("delete_account")
            .execute()
    }
}
