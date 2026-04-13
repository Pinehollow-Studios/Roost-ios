import Foundation
import Observation

@MainActor
@Observable
final class SetupViewModel {
    enum Step: Int {
        case profile = 1
        case homeChoice = 2
        case homeName = 3
    }

    enum HomeChoice {
        case create
        case join
    }

    enum ProgressAction {
        case advanced
        case openJoin
        case submitCreate
    }

    var step: Step = .profile
    var displayName = ""
    var homeChoice: HomeChoice?
    var homeName = ""
    var inviteCode = ""
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private let homeService = HomeService()

    var buttonTitle: String {
        switch step {
        case .homeName:
            return isLoading ? "Finishing..." : "Finish"
        case .profile, .homeChoice:
            return "Continue"
        }
    }

    var isContinueDisabled: Bool {
        switch step {
        case .profile:
            return displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .homeChoice:
            return homeChoice == nil
        case .homeName:
            return homeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
        }
    }

    func continueAction() -> ProgressAction? {
        errorMessage = nil

        switch step {
        case .profile:
            guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            step = .homeChoice
            return .advanced

        case .homeChoice:
            guard let homeChoice else {
                return nil
            }

            switch homeChoice {
            case .create:
                step = .homeName
                return .advanced
            case .join:
                return .openJoin
            }

        case .homeName:
            guard !homeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return .submitCreate
        }
    }

    func createHome() async -> Bool {
        let trimmedName = homeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDisplay = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedDisplay.isEmpty else {
            errorMessage = "Please fill in both fields."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            try await homeService.createHomeForUser(
                homeName: trimmedName,
                displayName: trimmedDisplay
            )
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func joinHome() async -> Bool {
        let trimmedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDisplay = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty, !trimmedDisplay.isEmpty else {
            errorMessage = "Please fill in both fields."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            try await homeService.joinHome(
                inviteCode: trimmedCode,
                displayName: trimmedDisplay
            )
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
