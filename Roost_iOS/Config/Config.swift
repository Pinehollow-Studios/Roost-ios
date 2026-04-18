import Foundation

enum Config {
    private static func stringValue(for key: String, fallback: String = "") -> String {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           !value.isEmpty {
            return value
        }
        return fallback
    }

    static let supabaseURL: String = {
        if let directURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           !directURL.isEmpty {
            return directURL
        }

        let host = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_HOST") as? String ?? ""
        guard !host.isEmpty else { return "" }
        return "https://\(host)"
    }()

    static let supabaseAnonKey: String = stringValue(for: "SUPABASE_ANON_KEY")

    static let googleClientID: String = stringValue(for: "GOOGLE_CLIENT_ID")

    static let revenueCatAPIKey: String = stringValue(for: "REVENUECAT_API_KEY")
}
