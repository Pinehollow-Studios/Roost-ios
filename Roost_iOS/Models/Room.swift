import Foundation

struct Room: Codable, Identifiable, Hashable {
    let id: UUID
    var homeID: UUID
    var name: String
    var icon: String?

    enum CodingKeys: String, CodingKey {
        case id
        case homeID = "home_id"
        case name
        case icon
    }
}

struct CreateRoom: Codable, Hashable {
    var homeID: UUID
    var name: String
    var icon: String?

    enum CodingKeys: String, CodingKey {
        case homeID = "home_id"
        case name
        case icon
    }
}

// Represents a row in room_group_members (group_id, room_id)
struct RoomGroupMember: Codable, Hashable {
    var roomID: UUID

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
    }
}

struct RoomGroup: Codable, Identifiable, Hashable {
    let id: UUID
    var homeID: UUID
    var name: String
    var icon: String?
    var roomGroupMembers: [RoomGroupMember]

    enum CodingKeys: String, CodingKey {
        case id
        case homeID = "home_id"
        case name
        case icon
        case roomGroupMembers = "room_group_members"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        homeID = try container.decode(UUID.self, forKey: .homeID)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        roomGroupMembers = (try? container.decodeIfPresent([RoomGroupMember].self, forKey: .roomGroupMembers)) ?? []
    }

    /// Room IDs that belong to this group
    var memberRoomIDs: Set<UUID> {
        Set(roomGroupMembers.map(\.roomID))
    }
}

struct CreateRoomGroup: Codable, Hashable {
    var homeID: UUID
    var name: String
    var icon: String?

    enum CodingKeys: String, CodingKey {
        case homeID = "home_id"
        case name
        case icon
    }
}
