import Foundation
import Supabase

struct RoomService {

    // MARK: - Rooms

    func fetchRooms(for homeID: UUID) async throws -> [Room] {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("home_rooms")
            .select()
            .eq("home_id", value: homeID)
            .order("name")
            .execute()
            .value
    }

    func createRoom(_ room: CreateRoom) async throws -> Room {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("home_rooms")
            .insert(room)
            .select()
            .single()
            .execute()
            .value
    }

    func updateRoom(id: UUID, name: String, icon: String?) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("home_rooms")
            .update(RoomUpdatePayload(name: name, icon: icon))
            .eq("id", value: id)
            .execute()
    }

    func deleteRoom(id: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("home_rooms")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Room Groups

    /// Fetches all custom groups for the home, including their member room IDs.
    func fetchRoomGroups(for homeID: UUID) async throws -> [RoomGroup] {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("home_room_groups")
            .select("*, room_group_members(room_id)")
            .eq("home_id", value: homeID)
            .order("name")
            .execute()
            .value
    }

    func createRoomGroup(_ group: CreateRoomGroup) async throws -> RoomGroup {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("home_room_groups")
            .insert(group)
            .select("*, room_group_members(room_id)")
            .single()
            .execute()
            .value
    }

    func updateRoomGroup(id: UUID, name: String, icon: String?) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("home_room_groups")
            .update(RoomGroupUpdatePayload(name: name, icon: icon))
            .eq("id", value: id)
            .execute()
    }

    func deleteRoomGroup(id: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("home_room_groups")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// Atomically replaces all members of a group (delete all, then insert new set).
    func setGroupMembers(groupId: UUID, roomIds: [UUID]) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()

        // Remove all current members
        try await client
            .from("room_group_members")
            .delete()
            .eq("group_id", value: groupId)
            .execute()

        // Insert new members (no-op if empty)
        guard !roomIds.isEmpty else { return }
        let inserts = roomIds.map { RoomGroupMemberInsert(groupID: groupId, roomID: $0) }
        try await client
            .from("room_group_members")
            .insert(inserts)
            .execute()
    }

    // MARK: - Private Payloads

    private struct RoomUpdatePayload: Codable {
        let name: String
        let icon: String?
    }

    private struct RoomGroupUpdatePayload: Codable {
        let name: String
        let icon: String?
    }

    private struct RoomGroupMemberInsert: Codable {
        let groupID: UUID
        let roomID: UUID

        enum CodingKeys: String, CodingKey {
            case groupID = "group_id"
            case roomID = "room_id"
        }
    }
}
