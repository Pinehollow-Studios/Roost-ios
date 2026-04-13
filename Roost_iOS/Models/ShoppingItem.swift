import Foundation

struct ShoppingItem: Codable, Identifiable, Hashable {
    let id: UUID
    var homeID: UUID
    var name: String
    var quantity: String?
    var category: String?
    var checked: Bool
    var addedBy: UUID?
    var checkedBy: UUID?
    var createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case homeID = "home_id"
        case name
        case quantity
        case category
        case checked
        case addedBy = "added_by"
        case checkedBy = "checked_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateShoppingItem: Codable, Hashable {
    var homeID: UUID
    var name: String
    var quantity: String?
    var category: String?

    enum CodingKeys: String, CodingKey {
        case homeID = "home_id"
        case name
        case quantity
        case category
    }
}
