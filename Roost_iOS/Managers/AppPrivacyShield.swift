import UIKit

/// UIKit-level privacy cover that blocks app content from appearing in the
/// iOS app switcher.
///
/// # Architecture: dedicated UIWindow, not a UIView subview
/// A dedicated `UIWindow` at `windowLevel = .alert + 1` sits above the entire
/// app window hierarchy. Unlike adding a `UIView` to the key window, this cover
/// cannot be accidentally buried by SwiftUI re-renders, system UI insertions, or
/// any other change to the app's view hierarchy — it is completely independent.
///
/// # Cover lifecycle
/// - Added synchronously on `willResignActiveNotification` (guarantees the iOS
///   app switcher snapshot is taken with the cover already in place)
/// - Re-applied on `didEnterBackgroundNotification` as a belt-and-suspenders
/// - Also applied immediately if `isEnabled` is set while the app is not active
/// - Removed ONLY via `deactivate()`, called from SwiftUI when `scenePhase == .active`
///   — the confirmed, stable foreground state. Deliberately NOT tied to
///   `didBecomeActiveNotification`, which can fire spuriously for background apps
///   during system snapshot refreshes and scene management.
///
/// # When the shield is active
/// Only when the user is authenticated, the PIN lock screen is not showing, and the
/// initial data boot has completed. All other states handle their own privacy.
final class AppPrivacyShield {
    static let shared = AppPrivacyShield()

    /// Set to `true` when sensitive authenticated content is on screen.
    /// - Setting `true` while the app is not active immediately raises the cover.
    /// - Setting `false` immediately dismisses any active cover.
    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                if UIApplication.shared.applicationState != .active {
                    addCover()
                }
            } else {
                removeCover()
            }
        }
    }

    private var coverWindow: UIWindow?

    // Roost background colours (light: 0xEBE3D5, dark: 0x0F0D0B)
    private let coverColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 15/255,  green: 13/255,  blue: 11/255,  alpha: 1)
            : UIColor(red: 235/255, green: 227/255, blue: 213/255, alpha: 1)
    }

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        // Tear the cover down as early as possible when coming back to the
        // foreground — before `scenePhase == .active` fires — so the cover
        // can't linger over a loading / lock screen during the inactive→active
        // handoff (Face ID sheet dismiss, PIN success, etc).
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /// Called by the SwiftUI layer when `scenePhase == .active`.
    /// The only place the cover is removed.
    func deactivate() {
        removeCover()
    }

    @objc private func handleWillResignActive() {
        guard isEnabled else { return }
        addCover()
    }

    @objc private func handleDidEnterBackground() {
        guard isEnabled else { return }
        addCover()
    }

    @objc private func handleWillEnterForeground() {
        removeCover()
    }

    private func addCover() {
        guard coverWindow == nil else { return }

        // Prefer the foreground scene; fall back to any foreground-inactive scene
        // (which is what the scene is during willResignActive).
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: {
                $0.activationState == .foregroundActive ||
                $0.activationState == .foregroundInactive
            })
        else { return }

        let window = UIWindow(windowScene: scene)
        // .alert + 1 places this above system alert dialogs and keyboards —
        // the cover is truly on top of everything the app can render.
        window.windowLevel = .alert + 1
        window.isUserInteractionEnabled = false

        let vc = UIViewController()
        vc.view.backgroundColor = coverColor
        window.rootViewController = vc
        window.backgroundColor = coverColor

        // isHidden = false makes the window visible without stealing key-window
        // status (which would disrupt keyboard / input routing).
        window.isHidden = false
        coverWindow = window
    }

    private func removeCover() {
        coverWindow?.isHidden = true
        coverWindow = nil
    }
}
