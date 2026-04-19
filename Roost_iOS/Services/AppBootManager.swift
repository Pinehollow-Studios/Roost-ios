import Foundation
import Observation

@MainActor
@Observable
final class AppBootManager {
    var isBooting = false

    private(set) var bootedHomeId: UUID?
    private(set) var bootedUserId: UUID?

    /// `true` once `AuthLoadingView` has finished its one-shot dawn animation
    /// AND boot has completed. Gates the privacy shield so it can never arm
    /// over `LoadingView`, `LockScreenView`, or `AuthLoadingView`.
    private(set) var authLoadingComplete = false

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
        authLoadingComplete = false
    }

    func markAuthLoadingComplete() {
        authLoadingComplete = true
    }

    func resetAuthLoading() {
        authLoadingComplete = false
    }

    func clear() {
        isBooting = false
        bootedHomeId = nil
        bootedUserId = nil
        authLoadingComplete = false
    }
}
