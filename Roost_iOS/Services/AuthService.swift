import AuthenticationServices
import CryptoKit
import Foundation
import GoogleSignIn
import Supabase

// MARK: - Types

struct AuthUser: Identifiable, Hashable {
    let id: UUID
    var email: String
    var displayName: String?
}

struct AuthSession: Hashable {
    var accessToken: String
    var refreshToken: String
}

struct AuthSignUpResult: Hashable {
    var requiresEmailConfirmation: Bool
    var user: AuthUser?
}

struct AuthSignInResult: Hashable {
    var user: AuthUser
    var session: AuthSession
}

enum AuthServiceError: LocalizedError {
    case noPresentingViewController
    case missingIdToken
    case googleClientNotConfigured

    var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            return "Unable to present sign-in screen."
        case .missingIdToken:
            return "Sign-in succeeded but no identity token was returned."
        case .googleClientNotConfigured:
            return "Google Sign-In is not configured. Add GOOGLE_CLIENT_ID to Secrets.xcconfig."
        }
    }
}

// MARK: - Protocol

protocol AuthServicing {
    func signUp(email: String, password: String, displayName: String) async throws -> AuthSignUpResult
    func signIn(email: String, password: String) async throws -> AuthSignInResult
    func signInWithGoogle() async throws
    func signInWithApple(idToken: String, nonce: String) async throws
    func signOut() async throws
    func updateEmail(_ email: String) async throws
    func sendPasswordReset(email: String) async throws
    func deleteAccount() async throws
}

// MARK: - Service

struct AuthService: AuthServicing {
    func signUp(email: String, password: String, displayName: String) async throws -> AuthSignUpResult {
        let client = try SupabaseClientProvider.shared.requireClient()
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "display_name": AnyJSON.string(displayName)
            ]
        )

        let user = AuthUser(
            id: response.user.id,
            email: response.user.email ?? email,
            displayName: response.user.userMetadata["display_name"]?.stringValue ?? displayName
        )

        return AuthSignUpResult(
            requiresEmailConfirmation: response.session == nil,
            user: user
        )
    }

    func signIn(email: String, password: String) async throws -> AuthSignInResult {
        let client = try SupabaseClientProvider.shared.requireClient()
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )

        let user = AuthUser(
            id: session.user.id,
            email: session.user.email ?? email,
            displayName: session.user.userMetadata["display_name"]?.stringValue
        )

        return AuthSignInResult(
            user: user,
            session: AuthSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
        )
    }

    @MainActor
    func signInWithGoogle() async throws {
        let googleClientID = Config.googleClientID
        guard !googleClientID.isEmpty else {
            throw AuthServiceError.googleClientNotConfigured
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: googleClientID)

        guard let presentingVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController
        else {
            throw AuthServiceError.noPresentingViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthServiceError.missingIdToken
        }

        let client = try SupabaseClientProvider.shared.requireClient()
        try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .google,
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
        )
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    func signOut() async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client.auth.signOut()
    }

    func updateEmail(_ email: String) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client.auth.update(
            user: UserAttributes(email: email)
        )
    }

    func sendPasswordReset(email: String) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: AppConstants.authCallbackURL)
        )
    }

    func deleteAccount() async throws {
        try await HomeService().deleteAccount()
        try? await signOut()
    }
}

// MARK: - Apple Sign-In Coordinator

@MainActor
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private var continuation: CheckedContinuation<(idToken: String, nonce: String), Error>?
    private var currentNonce: String?

    func signIn() async throws -> (idToken: String, nonce: String) {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let nonce = Self.randomNonceString()
            currentNonce = nonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.email, .fullName]
            request.nonce = Self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let idToken = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce
            else {
                continuation?.resume(throwing: AuthServiceError.missingIdToken)
                continuation = nil
                return
            }

            continuation?.resume(returning: (idToken: idToken, nonce: nonce))
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first ?? ASPresentationAnchor()
        }
    }

    // MARK: - Nonce helpers

    private static func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
