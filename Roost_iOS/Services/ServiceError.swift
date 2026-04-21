import Foundation

enum ServiceError: LocalizedError {
    case notImplemented
    case networkUnavailable
    case authExpired
    case permissionDenied
    case notFound
    case conflict
    case serverError
    /// Write couldn't reach the server but was persisted to the offline outbox
    /// and will be replayed automatically on reconnect. UI should treat as success.
    case queuedForLaterSync
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
        case .queuedForLaterSync:
            return "Saved offline — we'll sync it when you reconnect."
        case .unknown(let message):
            return message
        }
    }
}
