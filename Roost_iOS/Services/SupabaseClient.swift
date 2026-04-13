import Foundation
@preconcurrency import KeychainAccess
import Supabase

enum SupabaseClientError: LocalizedError {
    case missingConfiguration
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase credentials are missing from Secrets.xcconfig."
        case .invalidURL:
            return "The Supabase URL in Secrets.xcconfig is invalid."
        }
    }
}

struct SupabaseConnectionStatus: Equatable {
    let message: String
    let isConnected: Bool
}

struct SupabaseClientProvider {
    static let shared = SupabaseClientProvider()

    let isConfigured: Bool
    let client: SupabaseClient?

    private init() {
        let urlString = Config.supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let anonKey = Config.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)

        isConfigured = !urlString.isEmpty && !anonKey.isEmpty

        guard
            isConfigured,
            let url = URL(string: urlString)
        else {
            client = nil
            return
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    storage: RoostAuthLocalStorage(),
                    redirectToURL: URL(string: AppConstants.authCallbackURL),
                    storageKey: "roost.auth.session",
                    flowType: .pkce
                )
            )
        )
    }

    func requireClient() throws -> SupabaseClient {
        guard isConfigured else {
            throw SupabaseClientError.missingConfiguration
        }

        guard let client else {
            throw SupabaseClientError.invalidURL
        }

        return client
    }

    func verifyConnection() async -> SupabaseConnectionStatus {
        do {
            let client = try requireClient()
            _ = try await client
                .from("homes")
                .select("id")
                .limit(1)
                .execute()

            return SupabaseConnectionStatus(
                message: "Connected to Supabase with the current app credentials.",
                isConnected: true
            )
        } catch {
            return SupabaseConnectionStatus(
                message: error.localizedDescription,
                isConnected: false
            )
        }
    }
}

private final class RoostAuthLocalStorage: AuthLocalStorage, @unchecked Sendable {
    private let keychain = Keychain(service: "com.roostapp.ios.auth")
        .accessibility(.afterFirstUnlock)

    func store(key: String, value: Data) throws {
        try keychain.set(value, key: key)
    }

    func retrieve(key: String) throws -> Data? {
        try keychain.getData(key)
    }

    func remove(key: String) throws {
        try keychain.remove(key)
    }
}
