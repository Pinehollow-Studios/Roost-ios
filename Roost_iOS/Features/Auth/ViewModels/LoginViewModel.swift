import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var isSubmitting = false
    var errorMessage: String?

    private let authService: AuthServicing

    init() {
        self.authService = AuthService()
    }

    init(authService: AuthServicing) {
        self.authService = authService
    }

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    func submit() async {
        guard canSubmit, !isSubmitting else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            _ = try await authService.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
