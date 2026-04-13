import Foundation
import Supabase

/// Maps raw errors from Supabase and network layers into user-friendly messages
/// using warm, Roost-voice copy.
enum ErrorHandler {
    /// Convert any error into a friendly, displayable message.
    static func message(for error: Error) -> String {
        // Already a ServiceError with a friendly message
        if let serviceError = error as? ServiceError {
            return serviceError.localizedDescription
        }

        let nsError = error as NSError

        // Network connectivity errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return ServiceError.networkUnavailable.localizedDescription
            case NSURLErrorTimedOut:
                return "That took too long. Check your connection and try again."
            default:
                return "Having trouble connecting. Give it a moment and try again."
            }
        }

        // Supabase HTTP errors (check error description for status codes)
        let description = error.localizedDescription.lowercased()

        if description.contains("401") || description.contains("jwt expired") || description.contains("invalid jwt") {
            return ServiceError.authExpired.localizedDescription
        }

        if description.contains("403") || description.contains("rls") || description.contains("permission") {
            return ServiceError.permissionDenied.localizedDescription
        }

        if description.contains("404") || description.contains("not found") {
            return ServiceError.notFound.localizedDescription
        }

        if description.contains("409") || description.contains("conflict") || description.contains("duplicate") {
            return ServiceError.conflict.localizedDescription
        }

        if description.contains("500") || description.contains("internal server") {
            return ServiceError.serverError.localizedDescription
        }

        // Fallback
        return "Something didn't work quite right. Please try again."
    }
}
