import Foundation

enum PinboardTargetScope: String, Codable, CaseIterable, Hashable {
    case `self`
    case partner
    case everyone
}

enum PinboardLinkType: String, Codable, CaseIterable, Hashable {
    case room
    case category
    case chore
    case expense
    case shopping
    case budget
    case calendar
}

struct PinboardAcknowledgement: Codable, Hashable {
    let noteID: UUID
    let userID: UUID
    let seenAt: Date

    enum CodingKeys: String, CodingKey {
        case noteID = "note_id"
        case userID = "user_id"
        case seenAt = "seen_at"
    }
}

struct PinboardNote: Codable, Identifiable, Hashable {
    let id: UUID
    let homeID: UUID
    let authorID: UUID?
    let content: String
    let linkType: PinboardLinkType?
    let linkLabel: String?
    let linkedEntityID: UUID?
    let targetScope: PinboardTargetScope
    let targetUserID: UUID?
    let notifyOnCreate: Bool
    let expiresAt: Date?
    let createdAt: Date
    let updatedAt: Date
    var acknowledgements: [PinboardAcknowledgement]

    enum CodingKeys: String, CodingKey {
        case id
        case homeID = "home_id"
        case authorID = "author_id"
        case content
        case linkType = "link_type"
        case linkLabel = "link_label"
        case linkedEntityID = "linked_entity_id"
        case targetScope = "target_scope"
        case targetUserID = "target_user_id"
        case notifyOnCreate = "notify_on_create"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case acknowledgements = "pinboard_note_acknowledgements"
    }

    var isActive: Bool {
        guard let expiresAt else { return true }
        return expiresAt > .now
    }

    var isExpiringSoon: Bool {
        guard let expiresAt else { return false }
        return expiresAt > .now && expiresAt.timeIntervalSinceNow <= 3 * 24 * 60 * 60
    }

    func isAcknowledged(by userID: UUID?) -> Bool {
        guard let userID else { return false }
        return acknowledgements.contains { $0.userID == userID }
    }

    var expiresLabel: String? {
        guard let expiresAt else { return nil }
        return Self.expiryFormatter.string(from: expiresAt)
    }

    private static let expiryFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()
}

struct CreatePinboardNote: Codable {
    let homeID: UUID
    let authorID: UUID
    let content: String
    let linkType: PinboardLinkType?
    let linkLabel: String?
    let linkedEntityID: UUID?
    let targetScope: PinboardTargetScope
    let targetUserID: UUID?
    let notifyOnCreate: Bool
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case homeID = "home_id"
        case authorID = "author_id"
        case content
        case linkType = "link_type"
        case linkLabel = "link_label"
        case linkedEntityID = "linked_entity_id"
        case targetScope = "target_scope"
        case targetUserID = "target_user_id"
        case notifyOnCreate = "notify_on_create"
        case expiresAt = "expires_at"
    }
}

struct PinboardAcknowledgementUpsert: Codable {
    let noteID: UUID
    let userID: UUID
    let seenAt: Date

    enum CodingKeys: String, CodingKey {
        case noteID = "note_id"
        case userID = "user_id"
        case seenAt = "seen_at"
    }
}
