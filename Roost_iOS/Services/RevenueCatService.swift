import Foundation
import RevenueCat
import StoreKit
import UIKit

/// Wrapper around the RevenueCat SDK.
/// Call `RevenueCatService.configure(apiKey:)` once at app launch,
/// then `logIn(userId:)` / `logOut()` alongside auth state changes.
final class RevenueCatService {
    static let shared = RevenueCatService()
    private init() {}

    static let entitlementID = "pro"

    static func configure(apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
    }

    // MARK: - Auth

    func logIn(userId: String) async throws {
        _ = try await Purchases.shared.logIn(userId)
    }

    func logOut() async throws {
        _ = try await Purchases.shared.logOut()
    }

    // MARK: - Offerings

    func offerings() async throws -> Offerings {
        try await Purchases.shared.offerings()
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws -> PurchaseResultData {
        try await Purchases.shared.purchase(package: package)
    }

    func restorePurchases() async throws -> CustomerInfo {
        try await Purchases.shared.restorePurchases()
    }

    // MARK: - Customer Info

    func customerInfo() async throws -> CustomerInfo {
        try await Purchases.shared.customerInfo()
    }

    func isProActive() async -> Bool {
        guard let info = try? await Purchases.shared.customerInfo() else { return false }
        return info.entitlements[Self.entitlementID]?.isActive == true
    }

    // MARK: - Manage Subscriptions

    @MainActor
    func openManageSubscriptions() async {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        try? await AppStore.showManageSubscriptions(in: windowScene)
    }

    // MARK: - Offer Code Redemption

    func presentOfferCodeRedemption() {
        SKPaymentQueue.default().presentCodeRedemptionSheet()
    }
}
