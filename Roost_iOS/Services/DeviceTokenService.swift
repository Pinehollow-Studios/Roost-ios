import Foundation
import Supabase

/// Sends the APNs device token to the backend so the server can deliver
/// push notifications when the app is closed or in the background.
@MainActor
final class DeviceTokenService {
    static let shared = DeviceTokenService()

    private var lastRegisteredToken: String?

    /// Registers (or refreshes) the device token for the currently authenticated user.
    /// Safe to call on every launch — the backend upserts so duplicates are a no-op.
    func register(token: String) async {
        // Skip if the token hasn't changed since we last sent it
        guard token != lastRegisteredToken else { return }

        guard
            let client = try? SupabaseClientProvider.shared.requireClient(),
            let _ = try? await client.auth.session   // ensure authenticated
        else { return }

        let trimmedURL = Config.supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(trimmedURL)/functions/v1/register-device-token") else { return }

        do {
            let session = try await client.auth.session
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.httpBody = try JSONEncoder().encode(["token": token, "platform": "ios"])

            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode < 300 {
                lastRegisteredToken = token
            }
        } catch {
            print("[DeviceTokenService] Failed to register token: \(error.localizedDescription)")
        }
    }
}
