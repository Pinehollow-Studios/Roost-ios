import Foundation

struct CalendarEvent: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var type: String
    var relatedEntityID: UUID?
}
