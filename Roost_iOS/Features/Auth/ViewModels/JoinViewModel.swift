import Foundation
import Observation

@MainActor
@Observable
final class JoinViewModel {
    var inviteCode = ""
    var displayName = ""
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private let homeService = HomeService()

    func joinHome() async -> Bool {
        let trimmedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty, !trimmedDisplayName.isEmpty else {
            errorMessage = "Please enter both your invite code and display name."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            try await homeService.joinHome(inviteCode: trimmedCode, displayName: trimmedDisplayName)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
