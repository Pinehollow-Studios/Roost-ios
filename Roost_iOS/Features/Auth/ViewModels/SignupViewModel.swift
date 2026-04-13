import Foundation
import Observation

@MainActor
@Observable
final class SignupViewModel {
    var email = ""
    var password = ""
    var displayName = ""
    var isSubmitting = false
    var errorMessage: String?
    var successMessage: String?

    private let authService: AuthServicing

    init() {
        self.authService = AuthService()
    }

    init(authService: AuthServicing) {
        self.authService = authService
    }

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func submit() async {
        guard canSubmit, !isSubmitting else { return }

        isSubmitting = true
        errorMessage = nil
        successMessage = nil

        do {
            let result = try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            if result.requiresEmailConfirmation {
                successMessage = "Check your email to confirm your account, then come back and sign in."
            } else {
                successMessage = "Your account is ready. Next we’ll wire the signed-in flow."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    func apply(displayName: String) {
        self.displayName = displayName
    }
}
