import Foundation

struct ActivityFeedItem: Codable, Identifiable, Hashable {
    let id: UUID
    var homeID: UUID
    var userID: UUID
    var action: String
    var entityType: String?
    var entityID: UUID?
    var metadata: [String: String]?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case homeID = "home_id"
        case userID = "user_id"
        case action
        case entityType = "entity_type"
        case entityID = "entity_id"
        case metadata
        case createdAt = "created_at"
    }
}
