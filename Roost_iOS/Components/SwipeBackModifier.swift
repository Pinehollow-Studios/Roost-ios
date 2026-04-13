import SwiftUI
import UIKit
import ObjectiveC.runtime

struct SwipeBackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(FullScreenPopGestureInstaller())
    }
}

extension View {
    func swipeBackEnabled() -> some View {
        modifier(SwipeBackModifier())
    }
}

private struct FullScreenPopGestureInstaller: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> FullScreenPopGestureHostController {
        FullScreenPopGestureHostController()
    }

    func updateUIViewController(_ uiViewController: FullScreenPopGestureHostController, context: Context) {
        uiViewController.installIfNeeded()
    }
}

private final class FullScreenPopGestureHostController: UIViewController, UIGestureRecognizerDelegate {
    private static var installedGestureKey = 0

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        installIfNeeded()
    }

    func installIfNeeded() {
        guard let navigationController,
              let systemGesture = navigationController.interactivePopGestureRecognizer,
              let gestureView = systemGesture.view,
              let internalTarget = systemGesture.delegate else {
            return
        }

        systemGesture.isEnabled = false

        if let existing = objc_getAssociatedObject(navigationController, &Self.installedGestureKey) as? UIPanGestureRecognizer {
            existing.delegate = self
            return
        }

        let selector = Selector(("handleNavigationTransition:"))
        let panGesture = UIPanGestureRecognizer(target: internalTarget, action: selector)
        panGesture.maximumNumberOfTouches = 1
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self

        gestureView.addGestureRecognizer(panGesture)
        objc_setAssociatedObject(
            navigationController,
            &Self.installedGestureKey,
            panGesture,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController,
              navigationController.viewControllers.count > 1,
              let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }

        let translation = panGesture.translation(in: gestureRecognizer.view)
        guard translation.x > 0, abs(translation.x) > abs(translation.y) else {
            return false
        }

        let isTransitioning = (navigationController.value(forKey: "_isTransitioning") as? Bool) ?? false
        return !isTransitioning
    }
}
