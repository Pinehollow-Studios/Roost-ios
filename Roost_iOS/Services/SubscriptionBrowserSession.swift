import AuthenticationServices
import Foundation
import UIKit

enum SubscriptionBrowserError: LocalizedError {
    case cancelled
    case noPresentationAnchor
    case invalidCallback

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Subscription flow was cancelled."
        case .noPresentationAnchor:
            return "Couldn’t present the billing browser."
        case .invalidCallback:
            return "Stripe returned an invalid callback."
        }
    }
}

@MainActor
final class SubscriptionBrowserSession: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func start(url: URL) async throws -> URL {
        guard presentationAnchor() != nil else {
            throw SubscriptionBrowserError.noPresentationAnchor
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "roost") { callbackURL, error in
                defer { self.session = nil }

                if let sessionError = error as? ASWebAuthenticationSessionError,
                   sessionError.code == .canceledLogin {
                    continuation.resume(throwing: SubscriptionBrowserError.cancelled)
                    return
                }

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: SubscriptionBrowserError.invalidCallback)
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            session.start()
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor() ?? ASPresentationAnchor()
    }

    private func presentationAnchor() -> ASPresentationAnchor? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}
