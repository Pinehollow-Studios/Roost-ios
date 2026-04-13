import Foundation
import LocalAuthentication
import CryptoKit

@MainActor
@Observable
final class AppLockManager {

    var isLocked: Bool = false

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "roost-lock-enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "roost-lock-enabled") }
    }

    var hasPIN: Bool {
        UserDefaults.standard.string(forKey: "roost-pin-hash") != nil
    }

    var useBiometrics: Bool {
        get { UserDefaults.standard.bool(forKey: "roost-use-biometrics") }
        set { UserDefaults.standard.set(newValue, forKey: "roost-use-biometrics") }
    }

    var autoLockDelay: Int {
        // Seconds. 0 = immediate. 60 = 1 minute. 300 = 5 minutes.
        get { UserDefaults.standard.integer(forKey: "roost-autolock-delay") }
        set { UserDefaults.standard.set(newValue, forKey: "roost-autolock-delay") }
    }

    // Initialised to distantPast so the very first appDidForeground (app launch)
    // treats the device as having been "away" long enough to require a lock.
    // Set to nil after each foreground check so that transient scene-phase flips
    // caused by system overlays (e.g. Face ID prompt) never re-trigger a lock.
    private var backgroundedAt: Date? = Date.distantPast
    private var failedAttempts: Int = 0
    var cooldownUntil: Date? = nil

    func lock() {
        guard isEnabled && hasPIN else { return }
        isLocked = true
    }

    func appDidBackground() {
        backgroundedAt = Date()
    }

    func appDidForeground() {
        guard isEnabled && hasPIN else { return }
        // Only act if the app actually went to the background (backgroundedAt is set).
        // When the Face ID system overlay appears/disappears the app cycles through
        // inactive→active without ever hitting background, so backgroundedAt stays nil
        // and we skip here — preventing the re-lock loop.
        guard let bg = backgroundedAt else { return }
        backgroundedAt = nil
        let elapsed = Date().timeIntervalSince(bg)
        if autoLockDelay == 0 || elapsed >= Double(autoLockDelay) {
            isLocked = true
        }
    }

    func unlock(pin: String) -> Bool {
        guard let hash = UserDefaults.standard.string(forKey: "roost-pin-hash") else { return false }
        let isCorrect = hashPIN(pin) == hash
        if isCorrect {
            isLocked = false
            failedAttempts = 0
            cooldownUntil = nil
            return true
        } else {
            failedAttempts += 1
            if failedAttempts >= 5 {
                cooldownUntil = Date().addingTimeInterval(10)
                failedAttempts = 0
            }
            return false
        }
    }

    func setupPIN(_ pin: String) {
        UserDefaults.standard.set(hashPIN(pin), forKey: "roost-pin-hash")
        isEnabled = true
    }

    func clearPIN() {
        UserDefaults.standard.removeObject(forKey: "roost-pin-hash")
        UserDefaults.standard.removeObject(forKey: "roost-lock-enabled")
        UserDefaults.standard.removeObject(forKey: "roost-use-biometrics")
        isLocked = false
    }

    func unlockWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return false }
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Roost"
            )
            if result {
                isLocked = false
                failedAttempts = 0
                cooldownUntil = nil
            }
            return result
        } catch {
            return false
        }
    }

    func biometricsAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func biometricType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }

    private func hashPIN(_ pin: String) -> String {
        let data = Data((pin + "roost-salt-v1").utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
