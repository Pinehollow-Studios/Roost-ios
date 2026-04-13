import Foundation

struct AppNotification: Codable, Identifiable, Hashable {
    let id: UUID
    var userID: UUID
    var homeID: UUID?
    var title: String
    var type: String?
    var read: Bool
    var entityID: UUID?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case homeID = "home_id"
        case title
        case type
        case read
        case entityID = "entity_id"
        case createdAt = "created_at"
    }
}
