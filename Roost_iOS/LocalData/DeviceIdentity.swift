import Foundation

/// Stable, per-install device identifier used to tag offline mutations.
///
/// Generated once on first launch and persisted to UserDefaults. Not shared
/// across reinstalls (intentional — a reinstall is treated as a new device so
/// pending-mutation conflicts can be resolved cleanly).
enum DeviceIdentity {
    private static let storageKey = "com.roostapp.ios.deviceID"

    /// The device ID for this install. Stable across launches, rotates on reinstall.
    static var current: UUID {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let uuid = UUID(uuidString: raw) {
            return uuid
        }
        let new = UUID()
        UserDefaults.standard.set(new.uuidString, forKey: storageKey)
        return new
    }
}
