import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class AuthManager {
    var currentUser: AuthUser?
    var currentSession: AuthSession?
    var homeId: UUID?
    var hasHome: Bool?
    var isRestoringSession = true
    var pendingJoinCode: String?
    /// True only after a *fresh* sign-in (not session restore). Consumed by ContentView
    /// to show the one-shot AuthLoadingView; reset when the cover dismisses.
    var isNewSignIn = false

    @ObservationIgnored
    private var authStateTask: Task<Void, Never>?

    @ObservationIgnored
    private var restoreTimeoutTask: Task<Void, Never>?

    @ObservationIgnored
    private let homeService = HomeService()

    /// Upper bound on how long the UI will sit on the "Restoring session" loading
    /// screen before we give up and show the Welcome/login screen. Without this
    /// the app can hang on cold start if the Supabase auth stream stalls (seen on
    /// poor or region-restricted networks — exactly the conditions App Review hits).
    @ObservationIgnored
    private static let sessionRestoreTimeout: Duration = .seconds(6)

    var isAuthenticated: Bool {
        currentSession != nil
    }

    func startSessionListener() {
        guard authStateTask == nil else { return }

        // Safety timeout — if no auth state event arrives within
        // `sessionRestoreTimeout` we force-exit the loading screen so the user
        // can at least attempt to sign in.
        restoreTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: Self.sessionRestoreTimeout)
            guard !Task.isCancelled, let self else { return }
            if self.isRestoringSession {
                self.isRestoringSession = false
            }
        }

        authStateTask = Task { [weak self] in
            guard
                let self,
                let client = try? SupabaseClientProvider.shared.requireClient()
            else {
                self?.restoreTimeoutTask?.cancel()
                self?.clearSessionState()
                return
            }

            for await (event, session) in client.auth.authStateChanges {
                guard !Task.isCancelled else { return }
                // First event arrived — cancel the safety timeout.
                self.restoreTimeoutTask?.cancel()
                await self.applyAuthStateChange(event: event, session: session)
            }
        }
    }

    func handle(url: URL) {
        // Handle OAuth callbacks (roost-ios://auth/callback)
        if url.host == "auth" {
            Task {
                guard let client = try? SupabaseClientProvider.shared.requireClient() else { return }
                _ = try? await client.auth.session(from: url)
            }
            return
        }

        // Handle join deep links (roost-ios://join?code=<code>)
        if url.host == "join",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let raw = components.queryItems?.first(where: { $0.name == "code" })?.value {
            let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let validChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
            guard !code.isEmpty,
                  (4...32).contains(code.count),
                  code.unicodeScalars.allSatisfy({ validChars.contains($0) }) else { return }
            pendingJoinCode = code
        }
    }

    deinit {
        authStateTask?.cancel()
        restoreTimeoutTask?.cancel()
    }

    private func applyAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
            guard let session else {
                clearSessionState()
                return
            }

            currentSession = AuthSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
            currentUser = AuthUser(
                id: session.user.id,
                email: session.user.email ?? "",
                displayName: session.user.userMetadata["display_name"]?.stringValue
            )
            isRestoringSession = false
            if event == .signedIn {
                isNewSignIn = true
            }

            // Only reset hasHome (and re-check) on initial load or fresh sign-in.
            // Token refresh / user-metadata updates should not reset hasHome — doing so
            // tears down RootAuthenticatedView and shows the loading screen again for no reason.
            if event == .initialSession || event == .signedIn || hasHome == nil {
                hasHome = nil
                await refreshHomeStatus()
            }

        case .signedOut, .userDeleted:
            clearSessionState()

        case .passwordRecovery, .mfaChallengeVerified:
            isRestoringSession = false
        }
    }

    private func clearSessionState() {
        currentUser = nil
        currentSession = nil
        homeId = nil
        hasHome = nil
        isRestoringSession = false
        pendingJoinCode = nil
        try? SyncEngine().clearAllCachedData()
    }

    func refreshHomeStatus() async {
        // Race the network call against a timeout. Without this, a stalled
        // request leaves `hasHome = nil` forever and the post-login
        // "Checking your home" loader becomes a dead end.
        do {
            homeId = try await withTimeout(seconds: 8) {
                try await self.homeService.getUserHomeID()
            }
            hasHome = homeId != nil
        } catch {
            homeId = nil
            hasHome = false
        }
    }

    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    func validAccessToken() async throws -> String {
        let client = try SupabaseClientProvider.shared.requireClient()
        let session = try await client.auth.session

        currentSession = AuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )
        currentUser = AuthUser(
            id: session.user.id,
            email: session.user.email ?? currentUser?.email ?? "",
            displayName: session.user.userMetadata["display_name"]?.stringValue ?? currentUser?.displayName
        )

        return session.accessToken
    }

    func consumePendingJoinCode() -> String? {
        let code = pendingJoinCode
        pendingJoinCode = nil
        return code
    }
}
