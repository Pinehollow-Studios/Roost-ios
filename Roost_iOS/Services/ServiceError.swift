import Foundation

enum ServiceError: LocalizedError {
    case notImplemented
    case networkUnavailable
    case authExpired
    case permissionDenied
    case notFound
    case conflict
    case serverError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature isn't ready yet."
        case .networkUnavailable:
            return "Looks like you're offline. Check your connection and try again."
        case .authExpired:
            return "Your session has expired. Please sign in again."
        case .permissionDenied:
            return "You don't have permission to do that."
        case .notFound:
            return "We couldn't find what you were looking for."
        case .conflict:
            return "Something changed while you were working. Pull to refresh and try again."
        case .serverError:
            return "Something went wrong on our end. Give it a moment and try again."
        case .unknown(let message):
            return message
        }
    }
}
