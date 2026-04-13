import Foundation

struct UserPreferences: Codable, Hashable {
    var userID: UUID
    var weekStarts: String
    var timeFormat: String
    var currency: String
    var dateFormat: String
    var updatedAt: Date?

    static let defaults = UserPreferences(
        userID: UUID(),
        weekStarts: "monday",
        timeFormat: "12h",
        currency: "GBP",
        dateFormat: "dd/MM/yyyy",
        updatedAt: nil
    )

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case weekStarts = "week_starts"
        case timeFormat = "time_format"
        case currency
        case dateFormat = "date_format"
        case updatedAt = "updated_at"
    }
}
