import SwiftUI

struct WelcomeView: View {
    @State private var viewModel = LoginViewModel()
    @State private var isSigningInWithGoogle = false
    @State private var oauthError: String?

    private let authService = AuthService()

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: max(geometry.size.height * 0.1, 44))

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

                            if let message = currentMessage {
                                Text(message)
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostDestructive)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            VStack(spacing: DesignSystem.Spacing.row) {
                                RoostButton(
                                    title: viewModel.isSubmitting ? "Signing in..." : "Sign in",
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

                        NavigationLink {
                            SignupView()
                        } label: {
                            HStack(spacing: 0) {
                                Text("Don’t have an account? ")
                                    .foregroundStyle(Color.roostMutedForeground)
                                Text("Sign up")
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

    private var currentMessage: String? {
        oauthError ?? viewModel.errorMessage
    }

    @MainActor
    private func signInWithGoogle() async {
        isSigningInWithGoogle = true
        oauthError = nil

        do {
            try await authService.signInWithGoogle()
        } catch {
            oauthError = error.localizedDescription
        }

        isSigningInWithGoogle = false
    }
}
