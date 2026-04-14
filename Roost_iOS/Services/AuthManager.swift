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

    @ObservationIgnored
    private var authStateTask: Task<Void, Never>?

    @ObservationIgnored
    private let homeService = HomeService()

    var isAuthenticated: Bool {
        currentSession != nil
    }

    func startSessionListener() {
        guard authStateTask == nil else { return }

        authStateTask = Task { [weak self] in
            guard
                let self,
                let client = try? SupabaseClientProvider.shared.requireClient()
            else {
                self?.clearSessionState()
                return
            }

            for await (event, session) in client.auth.authStateChanges {
                guard !Task.isCancelled else { return }
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
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
           !code.isEmpty {
            pendingJoinCode = code.lowercased()
        }
    }

    deinit {
        authStateTask?.cancel()
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
            hasHome = nil

            await refreshHomeStatus()

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
    }

    func refreshHomeStatus() async {
        do {
            homeId = try await homeService.getUserHomeID()
            hasHome = homeId != nil
        } catch {
            homeId = nil
            hasHome = false
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
