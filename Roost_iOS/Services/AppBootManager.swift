import Foundation
import Observation

@MainActor
@Observable
final class AppBootManager {
    var isBooting = false

    private(set) var bootedHomeId: UUID?
    private(set) var bootedUserId: UUID?

    func isBooted(homeId: UUID, userId: UUID) -> Bool {
        bootedHomeId == homeId && bootedUserId == userId
    }

    func markBooted(homeId: UUID, userId: UUID) {
        bootedHomeId = homeId
        bootedUserId = userId
        isBooting = false
    }

    func beginBoot() {
        isBooting = true
    }

    func clear() {
        isBooting = false
        bootedHomeId = nil
        bootedUserId = nil
    }
}
