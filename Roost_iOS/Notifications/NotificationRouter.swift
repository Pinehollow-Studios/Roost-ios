import Foundation
import Observation

@MainActor
@Observable
final class NotificationRouter {
    enum LifeSection: Hashable {
        case chores
        case calendar
        case pinboard
    }

    enum AppTab: Hashable {
        case home
        case shopping
        case money
        case life
        case more
    }

    enum LifeDestination: Hashable {
        case calendar
        case pinboard
    }

    enum MoreDestination: Hashable {
        case household
        case rooms
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
        case security
    }

    var selectedTab: AppTab = .home
    var selectedLifeSection: LifeSection = .chores
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
            selectedTab = .shopping
            return
        }

        if normalizedType.contains("expense") || normalizedType.contains("settle") {
            selectedTab = .money
            return
        }

        if normalizedType.contains("chore") || normalizedType.contains("calendar") {
            selectedTab = .life
            selectedLifeSection = normalizedType.contains("calendar") ? .calendar : .chores
            return
        }

        if normalizedType.contains("pinboard") {
            selectedTab = .life
            selectedLifeSection = .pinboard
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
