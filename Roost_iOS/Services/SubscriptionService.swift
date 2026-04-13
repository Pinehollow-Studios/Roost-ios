import Foundation
import Observation
import Supabase

enum SubscriptionServiceError: LocalizedError {
    case missingCheckoutEndpoint
    case missingPortalEndpoint
    case missingPricesEndpoint
    case invalidEndpoint
    case invalidResponse
    case invalidSession
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingCheckoutEndpoint:
            return "Stripe checkout endpoint is not configured."
        case .missingPortalEndpoint:
            return "Stripe billing portal endpoint is not configured."
        case .missingPricesEndpoint:
            return "Stripe prices endpoint is not configured."
        case .invalidEndpoint:
            return "Stripe endpoint configuration is invalid."
        case .invalidResponse:
            return "The server returned an invalid Stripe response."
        case .invalidSession:
            return "You need to be signed in before managing a subscription."
        case .server(let message):
            return message
        }
    }
}

struct SubscriptionPrice: Equatable {
    let id: String
    let unitAmount: Int
    let currency: String
    let interval: String
    let formattedAmount: String
    let trialDays: Int
}

struct SubscriptionPriceSet: Equatable {
    let monthly: SubscriptionPrice
    let annual: SubscriptionPrice
}

@MainActor
@Observable
final class SubscriptionPricingStore {
    var prices: SubscriptionPriceSet = SubscriptionService.fallbackPrices
    var isLoading = false
    var hasLoaded = false

    @ObservationIgnored
    private let subscriptionService = SubscriptionService()

    func refresh(force: Bool = false) async {
        guard force || !hasLoaded else { return }
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            prices = try await subscriptionService.fetchAvailablePrices()
            hasLoaded = true
        } catch {
            if !hasLoaded {
                prices = SubscriptionService.fallbackPrices
                hasLoaded = true
            }
        }
    }
}

private struct SubscriptionURLResponse: Decodable {
    let url: URL
}

private struct PromoRedeemResponse: Decodable {
    let success: Bool
    let error: String?
}

private struct PricesResponse: Decodable {
    let monthly: RemoteSubscriptionPrice
    let annual: RemoteSubscriptionPrice
}

private struct RemoteSubscriptionPrice: Decodable {
    let formattedAmount: String?
    let trialDays: Int?
    let unitAmount: Int?
    let currency: String?
    let interval: String?
    let id: String?

    enum CodingKeys: String, CodingKey {
        case formattedAmount
        case trialDays
        case unitAmount
        case currency
        case interval
        case id
    }
}

struct SubscriptionService {
    static let fallbackPrices = SubscriptionPriceSet(
        monthly: SubscriptionPrice(
            id: "monthly",
            unitAmount: 499,
            currency: "GBP",
            interval: "month",
            formattedAmount: "£4.99",
            trialDays: 14
        ),
        annual: SubscriptionPrice(
            id: "annual",
            unitAmount: 3999,
            currency: "GBP",
            interval: "year",
            formattedAmount: "£39.99",
            trialDays: 14
        )
    )

    enum Plan: String {
        case monthly
        case annual
    }

    func availablePrices() -> SubscriptionPriceSet {
        SubscriptionService.fallbackPrices
    }

    func fetchAvailablePrices() async throws -> SubscriptionPriceSet {
        let endpoint = Config.stripePricesEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !endpoint.isEmpty else { throw SubscriptionServiceError.missingPricesEndpoint }
        guard let url = URL(string: endpoint) else { throw SubscriptionServiceError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !Config.supabaseAnonKey.isEmpty {
            request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionServiceError.invalidResponse
        }

        guard httpResponse.statusCode < 300 else {
            let serverMessage = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw SubscriptionServiceError.server(serverMessage?.isEmpty == false ? serverMessage! : "Stripe prices request failed.")
        }

        do {
            let remoteResponse = try JSONDecoder().decode(PricesResponse.self, from: data)
            return SubscriptionPriceSet(
                monthly: merge(remote: remoteResponse.monthly, fallback: SubscriptionService.fallbackPrices.monthly, defaultID: "monthly"),
                annual: merge(remote: remoteResponse.annual, fallback: SubscriptionService.fallbackPrices.annual, defaultID: "annual")
            )
        } catch {
            throw SubscriptionServiceError.invalidResponse
        }
    }

    func createCheckoutSession(
        plan: Plan,
        homeId: UUID,
        customerEmail: String,
        accessToken: String
    ) async throws -> URL {
        let payload = CheckoutPayload(
            plan: plan.rawValue,
            homeId: homeId.uuidString,
            customerEmail: customerEmail
        )

        return try await invokeProtectedFunction(
            name: "stripe-checkout",
            accessToken: accessToken,
            body: payload
        )
    }

    func createPortalSession(homeId: UUID, accessToken: String) async throws -> URL {
        return try await invokeProtectedFunction(
            name: "stripe-portal",
            accessToken: accessToken,
            body: PortalPayload(homeId: homeId.uuidString)
        )
    }

    func redeemPromo(code: String, homeId: UUID, accessToken: String) async throws {
        let trimmedSupabaseURL = Config.supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(trimmedSupabaseURL)/functions/v1/redeem-promo") else {
            throw SubscriptionServiceError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(
            PromoPayload(
                accessToken: accessToken,
                code: code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                homeId: homeId.uuidString
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionServiceError.invalidResponse
        }

        let result = try JSONDecoder().decode(PromoRedeemResponse.self, from: data)
        guard httpResponse.statusCode < 300, result.success else {
            throw SubscriptionServiceError.server(promoErrorCopy(for: result.error))
        }
    }

    private func performURLRequest<T: Encodable>(url: URL, accessToken: String, body: T) async throws -> URL {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if !Config.supabaseAnonKey.isEmpty {
            request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionServiceError.invalidResponse
        }

        guard httpResponse.statusCode < 300 else {
            let serverMessage = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw SubscriptionServiceError.server(serverMessage?.isEmpty == false ? serverMessage! : "Stripe request failed.")
        }

        do {
            return try JSONDecoder().decode(SubscriptionURLResponse.self, from: data).url
        } catch {
            throw SubscriptionServiceError.invalidResponse
        }
    }

    private func invokeProtectedFunction<T: Encodable>(
        name: String,
        accessToken: String,
        body: T
    ) async throws -> URL {
        let client = try SupabaseClientProvider.shared.requireClient()
        client.functions.setAuth(token: accessToken)

        do {
            let response: SubscriptionURLResponse = try await client.functions.invoke(
                name,
                options: FunctionInvokeOptions(method: .post, body: body)
            )
            return response.url
        } catch let error as FunctionsError {
            switch error {
            case .httpError(_, let data):
                let serverMessage = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                throw SubscriptionServiceError.server(serverMessage?.isEmpty == false ? serverMessage! : "Stripe request failed.")
            case .relayError:
                throw SubscriptionServiceError.server("Stripe request failed.")
            }
        } catch {
            throw error
        }
    }

    private func merge(remote: RemoteSubscriptionPrice, fallback: SubscriptionPrice, defaultID: String) -> SubscriptionPrice {
        let fallbackID = fallback.id.isEmpty ? defaultID : fallback.id
        return SubscriptionPrice(
            id: remote.id ?? fallbackID,
            unitAmount: remote.unitAmount ?? fallback.unitAmount,
            currency: remote.currency ?? fallback.currency,
            interval: remote.interval ?? fallback.interval,
            formattedAmount: remote.formattedAmount ?? fallback.formattedAmount,
            trialDays: remote.trialDays ?? fallback.trialDays
        )
    }

    private func promoErrorCopy(for code: String?) -> String {
        switch code {
        case "not_found":
            return "That code doesn’t look right. Check it and try again."
        case "already_redeemed":
            return "That code has already been used."
        case "expired":
            return "That code has expired."
        case "already_have_lifetime":
            return "This household already has lifetime Roost Pro access."
        default:
            return "Something went wrong applying that promo code."
        }
    }

    private struct CheckoutPayload: Encodable {
        let plan: String
        let homeId: String
        let customerEmail: String

        enum CodingKeys: String, CodingKey {
            case plan
            case homeId = "homeId"
            case customerEmail = "customerEmail"
        }
    }

    private struct PortalPayload: Encodable {
        let homeId: String

        enum CodingKeys: String, CodingKey {
            case homeId = "homeId"
        }
    }

    private struct PromoPayload: Encodable {
        let accessToken: String
        let code: String
        let homeId: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case code
            case homeId = "home_id"
        }
    }
}
