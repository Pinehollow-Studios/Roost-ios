import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                RoostSectionSurface(emphasis: .raised, padding: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("Email")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostForeground)
                        RoostTextField(title: "you@example.com", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)

                        Text("Password")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostForeground)
                        RoostSecureField(title: "Your password", text: $viewModel.password)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostDestructive)
                        }

                        RoostButton(
                            title: viewModel.isSubmitting ? "Signing in..." : "Log in",
                            variant: .primary
                        ) {
                            Task {
                                await viewModel.submit()
                            }
                        }
                        .opacity(viewModel.canSubmit ? 1 : 0.72)
                        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .navigationTitle("Log in")
        .navigationBarTitleDisplayMode(.inline)
    }
}
