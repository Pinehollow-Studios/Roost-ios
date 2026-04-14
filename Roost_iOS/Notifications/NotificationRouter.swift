import Foundation
import Observation

@MainActor
@Observable
final class NotificationRouter {
    enum TasksSection: Hashable {
        case shopping
        case chores
    }

    enum AppTab: Hashable {
        case home
        case money
        case shopping
        case chores
        case more
    }

    enum MoreDestination: Hashable {
        case household
        case rooms
        case pinboard
        case budgetCategories
        case appearance
        case activity
        case notifications
        case notificationSettings
        case hazel
        case subscription
        case profile
        case account
        case money
        case calendar
        case settings
        case security
    }

    var selectedTab: AppTab = .home
    var selectedTasksSection: TasksSection = .shopping
    var morePath: [MoreDestination] = []

    func handle(url: URL) {
        guard url.host == "subscription" else { return }
        selectedTab = .more
        morePath = [.subscription]
    }

    func route(notification: AppNotification) {
        route(type: notification.type, entityId: notification.entityID)
    }

    func route(type: String?, entityId: UUID?) {
        let normalizedType = type?.lowercased() ?? ""
        morePath = []

        if normalizedType.contains("shopping") || normalizedType.contains("cart") {
            selectedTasksSection = .shopping
            selectedTab = .shopping
            return
        }

        if normalizedType.contains("expense") || normalizedType.contains("settle") {
            selectedTab = .money
            return
        }

        if normalizedType.contains("chore") {
            selectedTasksSection = .chores
            selectedTab = .chores
            return
        }

        if normalizedType.contains("calendar") {
            selectedTab = .more
            morePath = [.calendar]
            return
        }

        if normalizedType.contains("pinboard") {
            selectedTab = .more
            morePath = [.pinboard]
            return
        }

        if normalizedType.contains("activity") {
            selectedTab = .more
            morePath = [.activity]
            return
        }

        if normalizedType.contains("budget") {
            selectedTab = .money
            return
        }

        if normalizedType.contains("notification") {
            selectedTab = .more
            morePath = [.notifications]
            return
        }

        if entityId != nil {
            if normalizedType.isEmpty {
                selectedTab = .more
                morePath = [.notifications]
                return
            }
        }

        selectedTab = .more
        morePath = [.notifications]
    }
}
