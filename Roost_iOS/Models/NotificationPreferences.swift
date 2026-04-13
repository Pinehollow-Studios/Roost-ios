import Foundation

/// Notification preferences — the Supabase table is minimal (user_id, updated_at).
/// Additional preference fields may be stored as JSON or added later.
struct NotificationPrefs: Codable, Hashable {
    var userID: UUID
    var choresEnabled: Bool?
    var expensesEnabled: Bool?
    var shoppingEnabled: Bool?
    var settlementsEnabled: Bool?
    var quietHoursEnabled: Bool?
    var quietHoursStart: String?
    var quietHoursEnd: String?
    var updatedAt: Date?

    static let `default` = NotificationPrefs(
        userID: UUID(),
        choresEnabled: true,
        expensesEnabled: true,
        shoppingEnabled: true,
        settlementsEnabled: true,
        quietHoursEnabled: false,
        quietHoursStart: nil,
        quietHoursEnd: nil,
        updatedAt: nil
    )

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case choresEnabled = "chores_enabled"
        case expensesEnabled = "expenses_enabled"
        case shoppingEnabled = "shopping_enabled"
        case settlementsEnabled = "settlements_enabled"
        case quietHoursEnabled = "quiet_hours_enabled"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
        case updatedAt = "updated_at"
    }
}

extension NotificationPrefs {
    func allowsNotification(type: String?) -> Bool {
        switch type?.lowercased() {
        case let value? where value.contains("chore"):
            return choresEnabled ?? true
        case let value? where value.contains("expense"):
            return expensesEnabled ?? true
        case let value? where value.contains("shopping"):
            return shoppingEnabled ?? true
        case let value? where value.contains("settle"):
            return settlementsEnabled ?? true
        default:
            return true
        }
    }

    func allowsLocalNotifications(at date: Date = .now) -> Bool {
        guard quietHoursEnabled == true else { return true }
        guard let quietHoursStart,
              let quietHoursEnd,
              let startComponents = Self.parseTimeComponents(from: quietHoursStart),
              let endComponents = Self.parseTimeComponents(from: quietHoursEnd)
        else {
            return true
        }

        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: date)

        guard let currentHour = currentComponents.hour,
              let currentMinute = currentComponents.minute,
              let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute
        else {
            return true
        }

        let currentTotal = currentHour * 60 + currentMinute
        let startTotal = startHour * 60 + startMinute
        let endTotal = endHour * 60 + endMinute

        if startTotal < endTotal {
            return !(startTotal...endTotal).contains(currentTotal)
        }

        return currentTotal < startTotal && currentTotal > endTotal
    }

    private static func parseTimeComponents(from value: String) -> DateComponents? {
        let parts = value.split(separator: ":").map(String.init)
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }

        return DateComponents(hour: hour, minute: minute)
    }
}
