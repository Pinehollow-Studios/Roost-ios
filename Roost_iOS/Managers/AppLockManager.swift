import CommonCrypto
import Foundation
import LocalAuthentication
import Security
import SwiftUI

@MainActor
@Observable
final class AppLockManager {
    var isLocked = false
    var isAuthenticating = false
    var failedAttempts = 0
    var lockoutUntil: Date?
    var lockoutLevel = 0
    var migrationNeeded = UserDefaults.standard.bool(forKey: "roost-pin-migration-needed")
    var biometricPromptToken = 0

    private var backgroundedAt: Date?

    var isEnabled: Bool {
        get {
            (try? KeychainHelper.read(service: KeychainKeys.service, account: KeychainKeys.lockEnabled))
                .flatMap { String(data: $0, encoding: .utf8) }
                .map { $0 == "true" } ?? false
        }
        set {
            let data = Data((newValue ? "true" : "false").utf8)
            try? KeychainHelper.save(data, service: KeychainKeys.service, account: KeychainKeys.lockEnabled)
        }
    }

    var useBiometrics: Bool {
        get {
            (try? KeychainHelper.read(service: KeychainKeys.service, account: KeychainKeys.useBiometrics))
                .flatMap { String(data: $0, encoding: .utf8) }
                .map { $0 == "true" } ?? false
        }
        set {
            let data = Data((newValue ? "true" : "false").utf8)
            try? KeychainHelper.save(data, service: KeychainKeys.service, account: KeychainKeys.useBiometrics)
        }
    }

    var hasPIN: Bool {
        (try? KeychainHelper.read(service: KeychainKeys.service, account: KeychainKeys.pinHash)) != nil
    }

    var isInCooldown: Bool {
        guard let lockoutUntil else { return false }
        return Date() < lockoutUntil
    }

    var cooldownSeconds: Int {
        guard let lockoutUntil else { return 0 }
        return max(0, Int(ceil(lockoutUntil.timeIntervalSinceNow)))
    }

    var requiresReauth: Bool {
        lockoutLevel >= 4
    }

    init() {
        migrateFromUserDefaults()
        if isEnabled && hasPIN {
            isLocked = true
        }
    }

    func lock() {
        guard isEnabled && hasPIN else { return }
        isLocked = true
    }

    func appDidBackground() {
        backgroundedAt = Date()
        lock()
    }

    func appDidForeground() {
        guard isEnabled && hasPIN else { return }
        guard backgroundedAt != nil else { return }
        isLocked = true
        biometricPromptToken += 1
        backgroundedAt = nil
    }

    func attemptUnlock(pin: String) -> UnlockResult {
        if isInCooldown {
            return .cooldown(seconds: cooldownSeconds)
        }

        if requiresReauth {
            return .requiresReauth
        }

        guard
            let storedHash = try? KeychainHelper.read(service: KeychainKeys.service, account: KeychainKeys.pinHash),
            let storedSalt = try? KeychainHelper.read(service: KeychainKeys.service, account: KeychainKeys.pinSalt)
        else {
            return .error
        }

        let enteredHash = hashPIN(pin, salt: storedSalt)

        if constantTimeEqual(enteredHash, storedHash) {
            isLocked = false
            failedAttempts = 0
            lockoutLevel = 0
            lockoutUntil = nil
            return .success
        }

        return handleFailedAttempt()
    }

    func attemptBiometricUnlock() async -> BiometricResult {
        guard useBiometrics && isEnabled && !isInCooldown && !requiresReauth else {
            return .notAvailable
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .notAvailable
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Roost to access your financial data"
            )

            if success {
                isLocked = false
                failedAttempts = 0
                lockoutLevel = 0
                lockoutUntil = nil
                return .success
            }

            return .failed
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .systemCancel, .appCancel:
                return .cancelled
            case .biometryNotAvailable, .biometryNotEnrolled:
                return .notAvailable
            case .userFallback:
                return .fallbackToPIN
            default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    func setupPIN(_ pin: String) throws {
        let salt = generateSalt()
        let hash = hashPIN(pin, salt: salt)

        try KeychainHelper.save(hash, service: KeychainKeys.service, account: KeychainKeys.pinHash)
        try KeychainHelper.save(salt, service: KeychainKeys.service, account: KeychainKeys.pinSalt)

        isEnabled = true
        failedAttempts = 0
        lockoutLevel = 0
        lockoutUntil = nil
        isLocked = false
    }

    func clearPIN() {
        KeychainHelper.delete(service: KeychainKeys.service, account: KeychainKeys.pinHash)
        KeychainHelper.delete(service: KeychainKeys.service, account: KeychainKeys.pinSalt)
        KeychainHelper.delete(service: KeychainKeys.service, account: KeychainKeys.useBiometrics)
        isEnabled = false
        isLocked = false
        failedAttempts = 0
        lockoutLevel = 0
        lockoutUntil = nil
    }

    func resetLockoutForReauth() {
        failedAttempts = 0
        lockoutLevel = 0
        lockoutUntil = nil
    }

    func consumeMigrationNotice() {
        UserDefaults.standard.removeObject(forKey: "roost-pin-migration-needed")
        migrationNeeded = false
    }

    func hashPIN(_ pin: String, salt: Data) -> Data {
        var derivedKey = Data(repeating: 0, count: 32)
        let pinData = Data(pin.utf8)

        _ = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            pinData.withUnsafeBytes { pinBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pinBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        pinData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        100_000,
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }

        return derivedKey
    }

    func generateSalt() -> Data {
        var salt = Data(repeating: 0, count: 32)
        let status = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }

        precondition(status == errSecSuccess, "Unable to generate PIN salt")
        return salt
    }

    private func handleFailedAttempt() -> UnlockResult {
        failedAttempts += 1

        if failedAttempts % 3 == 0 {
            lockoutLevel += 1

            let lockoutDuration: TimeInterval
            switch lockoutLevel {
            case 1:
                lockoutDuration = 30
            case 2:
                lockoutDuration = 120
            case 3:
                lockoutDuration = 600
            default:
                lockoutUntil = nil
                return .requiresReauth
            }

            lockoutUntil = Date().addingTimeInterval(lockoutDuration)
            return .lockedOut(duration: Int(lockoutDuration), level: lockoutLevel)
        }

        let attemptsUntilLockout = 3 - (failedAttempts % 3)
        return .wrongPIN(attemptsRemaining: attemptsUntilLockout)
    }

    private func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }

        var difference: UInt8 = 0
        for index in lhs.indices {
            difference |= lhs[index] ^ rhs[index]
        }

        return difference == 0
    }

    private func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: "roost-pin-hash") != nil else { return }

        defaults.removeObject(forKey: "roost-pin-hash")
        defaults.removeObject(forKey: "roost-lock-enabled")
        defaults.removeObject(forKey: "roost-use-biometrics")
        defaults.removeObject(forKey: "roost-autolock-delay")
        defaults.set(true, forKey: "roost-pin-migration-needed")
        migrationNeeded = true
    }
}

private enum KeychainKeys {
    static let service = "com.emberstudio.roost"
    static let pinHash = "pin-hash"
    static let pinSalt = "pin-salt"
    static let lockEnabled = "lock-enabled"
    static let useBiometrics = "use-biometrics"
}

enum UnlockResult {
    case success
    case wrongPIN(attemptsRemaining: Int)
    case lockedOut(duration: Int, level: Int)
    case cooldown(seconds: Int)
    case requiresReauth
    case error
}

enum BiometricResult {
    case success
    case failed
    case cancelled
    case fallbackToPIN
    case notAvailable
}

enum BiometricType {
    case faceID
    case touchID
    case none
}
