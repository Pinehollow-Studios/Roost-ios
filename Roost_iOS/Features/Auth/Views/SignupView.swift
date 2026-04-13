import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SignupViewModel()
    @State private var isSigningInWithGoogle = false

    private let authService = AuthService()

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: max(geometry.size.height * 0.08, 36))

                    VStack(spacing: DesignSystem.Spacing.block) {
                        VStack(spacing: DesignSystem.Spacing.section) {
                            RoostLogoMark(size: 92, cornerRadius: DesignSystem.Radius.lg)

                            Text("Roost")
                                .font(.roostLargeGreeting)
                                .foregroundStyle(Color.roostForeground)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: DesignSystem.Spacing.section) {
                            VStack(spacing: DesignSystem.Spacing.row) {
                                RoostTextField(
                                    title: "Display name",
                                    text: $viewModel.displayName,
                                    leadingSystemImage: "person"
                                )

                                RoostTextField(
                                    title: "Email address",
                                    text: $viewModel.email,
                                    leadingSystemImage: "envelope"
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)

                                RoostSecureField(
                                    title: "Password",
                                    text: $viewModel.password,
                                    leadingSystemImage: "lock"
                                )
                            }

                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostDestructive)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if let successMessage = viewModel.successMessage {
                                Text(successMessage)
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostSuccess)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            VStack(spacing: DesignSystem.Spacing.row) {
                                RoostButton(
                                    title: viewModel.isSubmitting ? "Creating account..." : "Create account",
                                    variant: .primary,
                                    isLoading: viewModel.isSubmitting
                                ) {
                                    Task { await viewModel.submit() }
                                }
                                .opacity(viewModel.canSubmit ? 1 : 0.72)
                                .disabled(!viewModel.canSubmit || viewModel.isSubmitting)

                                AuthDivider(title: "or")

                                GoogleAuthButton(
                                    title: "Continue with Google",
                                    isLoading: isSigningInWithGoogle
                                ) {
                                    Task { await signInWithGoogle() }
                                }

                                AppleAuthComingSoonButton()
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.micro)

                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 0) {
                                Text("Already have an account? ")
                                    .foregroundStyle(Color.roostMutedForeground)
                                Text("Sign in")
                                    .foregroundStyle(Color.roostPrimary)
                            }
                            .font(.roostBody)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: DesignSystem.Spacing.blockLarge)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(
            Color.roostBackground
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [
                            Color.roostPrimary.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 180)
                }
                .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
    }

    @MainActor
    private func signInWithGoogle() async {
        isSigningInWithGoogle = true
        viewModel.errorMessage = nil

        do {
            try await authService.signInWithGoogle()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }

        isSigningInWithGoogle = false
    }
}
