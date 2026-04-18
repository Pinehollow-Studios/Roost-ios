import Foundation
import Observation
import RevenueCat
import Supabase

// MARK: - Errors

enum SubscriptionServiceError: LocalizedError {
    case invalidSession
    case server(String)
    case invalidEmail

    var errorDescription: String? {
        switch self {
        case .invalidSession:
            return "You need to be signed in before managing a subscription."
        case .server(let message):
            return message
        case .invalidEmail:
            return "A valid email address is required to set up a subscription."
        }
    }
}

// MARK: - Display types (used by SubscriptionView and SubscriptionViewModel)

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

// MARK: - Pricing Store (loads from RevenueCat offerings)

@MainActor
@Observable
final class SubscriptionPricingStore {
    var prices: SubscriptionPriceSet = SubscriptionService.fallbackPrices
    var monthlyPackage: Package?
    var annualPackage: Package?
    var isLoading = false
    var hasLoaded = false

    func refresh(force: Bool = false) async {
        guard force || !hasLoaded else { return }
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let offerings = try await RevenueCatService.shared.offerings()
            guard let current = offerings.current else {
                if !hasLoaded { prices = SubscriptionService.fallbackPrices; hasLoaded = true }
                return
            }

            let monthly = current.availablePackages.first { $0.packageType == .monthly }
            let annual  = current.availablePackages.first { $0.packageType == .annual }

            monthlyPackage = monthly
            annualPackage  = annual

            prices = SubscriptionPriceSet(
                monthly: monthly.map { pkg in
                    SubscriptionPrice(
                        id: "monthly",
                        unitAmount: NSDecimalNumber(decimal: pkg.storeProduct.price).multiplying(by: 100).intValue,
                        currency: pkg.storeProduct.currencyCode ?? "GBP",
                        interval: "month",
                        formattedAmount: pkg.storeProduct.localizedPriceString,
                        trialDays: 14
                    )
                } ?? SubscriptionService.fallbackPrices.monthly,
                annual: annual.map { pkg in
                    SubscriptionPrice(
                        id: "annual",
                        unitAmount: NSDecimalNumber(decimal: pkg.storeProduct.price).multiplying(by: 100).intValue,
                        currency: pkg.storeProduct.currencyCode ?? "GBP",
                        interval: "year",
                        formattedAmount: pkg.storeProduct.localizedPriceString,
                        trialDays: 14
                    )
                } ?? SubscriptionService.fallbackPrices.annual
            )
            hasLoaded = true
        } catch {
            if !hasLoaded {
                prices = SubscriptionService.fallbackPrices
                hasLoaded = true
            }
        }
    }
}

// MARK: - SubscriptionService

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

    /// Redeems a backend gift code (lifetime or timed access).
    /// Distinct from Apple Offer Codes — these are admin-granted codes managed in Supabase.
    func redeemPromo(code: String, homeId: UUID, accessToken: String) async throws {
        let trimmedSupabaseURL = Config.supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(trimmedSupabaseURL)/functions/v1/redeem-promo") else {
            throw SubscriptionServiceError.server("Invalid endpoint configuration.")
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
            throw SubscriptionServiceError.server("Invalid server response.")
        }

        let result = try JSONDecoder().decode(PromoRedeemResponse.self, from: data)
        guard httpResponse.statusCode < 300, result.success else {
            throw SubscriptionServiceError.server(promoErrorCopy(for: result.error))
        }
    }

    private func promoErrorCopy(for code: String?) -> String {
        switch code {
        case "not_found":
            return "That code doesn't look right. Check it and try again."
        case "already_redeemed":
            return "That code has already been used."
        case "expired":
            return "That code has expired."
        case "already_have_lifetime":
            return "This household already has lifetime Roost Pro access."
        default:
            return "Something went wrong applying that code."
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

    private struct PromoRedeemResponse: Decodable {
        let success: Bool
        let error: String?
    }
}
