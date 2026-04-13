import Foundation
import UserNotifications

@MainActor
final class LocalNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationManager()

    private let center = UNUserNotificationCenter.current()
    private weak var router: NotificationRouter?

    func configure(router: NotificationRouter) {
        self.router = router
        center.delegate = self
    }

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func schedule(notification: AppNotification) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.type?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Roost update"
        content.sound = .default
        content.userInfo = [
            "type": notification.type ?? "",
            "entity_id": notification.entityID?.uuidString ?? "",
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let type = userInfo["type"] as? String
        let entityId = (userInfo["entity_id"] as? String).flatMap(UUID.init(uuidString:))

        await MainActor.run {
            router?.route(type: type, entityId: entityId)
        }
    }
}
