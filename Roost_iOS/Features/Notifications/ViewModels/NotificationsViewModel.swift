import Foundation
import Observation
import Realtime
import SwiftUI

@MainActor
@Observable
final class NotificationsViewModel {
    var notifications: [AppNotification] = []
    var preferences = NotificationPrefs.default
    var isLoading = false
    var errorMessage: String?
    var unreadCount = 0
    var isAppActive = true

    @ObservationIgnored
    private let notificationService = NotificationService()

    @ObservationIgnored
    private var subscriptionId: UUID?

    @ObservationIgnored
    private var subscribedUserId: UUID?

    init(
        notifications: [AppNotification] = [],
        preferences: NotificationPrefs? = nil,
        isLoading: Bool = false,
        errorMessage: String? = nil,
        unreadCount: Int? = nil
    ) {
        self.notifications = notifications
        self.preferences = preferences ?? NotificationPrefs.default
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.unreadCount = unreadCount ?? notifications.filter { !$0.read }.count
    }

    func load(userId: UUID) async {
        isLoading = true
        errorMessage = nil

        async let notificationsResult = fetchNotifications(userId: userId)
        async let preferencesResult = fetchPreferences(userId: userId)

        notifications = await notificationsResult
        preferences = await preferencesResult
        unreadCount = notifications.filter { !$0.read }.count
        isLoading = false
    }

    func startRealtime(userId: UUID) async {
        guard subscriptionId == nil else { return }
        subscribedUserId = userId

        subscriptionId = await RealtimeManager.shared.subscribe(
            table: "notifications",
            filter: .eq("user_id", value: userId.uuidString)
        ) { [weak self] in
            guard let self, let userId = self.subscribedUserId else { return }
            await self.refreshAfterRealtime(userId: userId)
        }
    }

    func stopRealtime() async {
        guard let subscriptionId else { return }
        await RealtimeManager.shared.unsubscribe(table: "notifications", callbackId: subscriptionId)
        self.subscriptionId = nil
        subscribedUserId = nil
    }

    func markAsRead(_ notification: AppNotification) async {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }),
              notifications[index].read == false else { return }

        notifications[index].read = true
        unreadCount = notifications.filter { !$0.read }.count

        do {
            try await notificationService.markAsRead(id: notification.id)
        } catch {
            notifications[index].read = false
            unreadCount = notifications.filter { !$0.read }.count
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    func markAllAsRead(userId: UUID) async {
        let original = notifications
        notifications = notifications.map {
            var item = $0
            item.read = true
            return item
        }
        unreadCount = 0

        do {
            try await notificationService.markAllAsRead(for: userId)
        } catch {
            notifications = original
            unreadCount = notifications.filter { !$0.read }.count
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    func savePreferences(
        for userId: UUID,
        choresEnabled: Bool,
        expensesEnabled: Bool,
        shoppingEnabled: Bool,
        settlementsEnabled: Bool,
        quietHoursEnabled: Bool,
        quietStart: Date,
        quietEnd: Date
    ) async {
        var updated = preferences
        updated.userID = userId
        updated.choresEnabled = choresEnabled
        updated.expensesEnabled = expensesEnabled
        updated.shoppingEnabled = shoppingEnabled
        updated.settlementsEnabled = settlementsEnabled
        updated.quietHoursEnabled = quietHoursEnabled
        updated.quietHoursStart = Self.timeFormatter.string(from: quietStart)
        updated.quietHoursEnd = Self.timeFormatter.string(from: quietEnd)

        do {
            try await notificationService.upsertPreferences(updated)
            preferences = updated
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    private func refreshAfterRealtime(userId: UUID) async {
        let previousUnreadIds = Set(notifications.filter { !$0.read }.map(\.id))
        let refreshed = await fetchNotifications(userId: userId)
        notifications = refreshed
        unreadCount = refreshed.filter { !$0.read }.count

        let newUnread = refreshed.filter { !$0.read && !previousUnreadIds.contains($0.id) }

        if !isAppActive && preferences.allowsLocalNotifications() {
            for notification in newUnread {
                guard preferences.allowsNotification(type: notification.type) else { continue }
                await LocalNotificationManager.shared.schedule(notification: notification)
            }
        }
    }

    private func fetchNotifications(userId: UUID) async -> [AppNotification] {
        do {
            return try await notificationService.fetchNotifications(for: userId)
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
            return notifications
        }
    }

    private func fetchPreferences(userId: UUID) async -> NotificationPrefs {
        do {
            return try await notificationService.fetchPreferences(for: userId)
        } catch {
            var prefs = NotificationPrefs.default
            prefs.userID = userId
            return prefs
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
