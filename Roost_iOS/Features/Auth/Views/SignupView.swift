import AuthenticationServices
import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SignupViewModel()
    @State private var isSigningInWithGoogle = false
    @State private var isSigningInWithApple = false
    @State private var appleCoordinator = AppleSignInCoordinator()

    // Entrance
    @State private var entered = false
    // Orb floating
    @State private var orbA = false
    @State private var orbB = false
    @State private var orbC = false

    private let authService = AuthService()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.roostBackground.ignoresSafeArea()
                atmosphereLayer.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                            .padding(.top, geo.safeAreaInsets.top + 52)
                            .padding(.bottom, 44)

                        formCard
                            .padding(.horizontal, DesignSystem.Spacing.page)
                            .padding(.bottom, geo.safeAreaInsets.bottom + 44)
                    }
                    .frame(minHeight: geo.size.height)
                    .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .statusBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.72)) {
                entered = true
            }
            withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
                orbA = true
            }
            withAnimation(.easeInOut(duration: 4.6).repeatForever(autoreverses: true).delay(1.0)) {
                orbB = true
            }
            withAnimation(.easeInOut(duration: 5.2).repeatForever(autoreverses: true).delay(0.4)) {
                orbC = true
            }
        }
    }

    // MARK: – Background atmosphere

    private var atmosphereLayer: some View {
        ZStack {
            // Terracotta glow — top leading
            Circle()
                .fill(Color.roostPrimary.opacity(0.34))
                .frame(width: 360, height: 360)
                .blur(radius: 95)
                .offset(x: orbA ? -60 : -30, y: orbA ? -140 : -110)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Amber glow — bottom trailing
            Circle()
                .fill(Color(red: 0.96, green: 0.60, blue: 0.18).opacity(0.24))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: orbB ? 60 : 30, y: orbB ? 110 : 70)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            // Secondary terracotta pulse — centre
            Circle()
                .fill(Color.roostPrimary.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 65)
                .offset(x: orbC ? -20 : 20, y: orbC ? 40 : -10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    // MARK: – Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            RoostLogoMark(size: 80, cornerRadius: DesignSystem.Radius.lg)
                .shadow(color: Color.roostPrimary.opacity(0.55), radius: 28, x: 0, y: 10)
                .scaleEffect(entered ? 1 : 0.72)
                .opacity(entered ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.05), value: entered)

            VStack(spacing: 5) {
                Text("Create account")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.roostForeground)

                Text("Join your household.")
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .opacity(entered ? 1 : 0)
            .offset(y: entered ? 0 : 20)
            .animation(.spring(response: 0.65, dampingFraction: 0.78).delay(0.18), value: entered)
        }
    }

    // MARK: – Form card

    private var formCard: some View {
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
                    title: viewModel.isSubmitting ? "Creating account…" : "Create account",
                    variant: .primary,
                    isLoading: viewModel.isSubmitting
                ) {
                    Task { await viewModel.submit() }
                }
                .opacity(viewModel.canSubmit ? 1 : 0.65)
                .disabled(!viewModel.canSubmit || viewModel.isSubmitting)

                AuthDivider(title: "or")

                GoogleAuthButton(
                    title: "Continue with Google",
                    isLoading: isSigningInWithGoogle
                ) {
                    Task { await signInWithGoogle() }
                }

                AppleSignInButton(
                    title: "Continue with Apple",
                    isLoading: isSigningInWithApple
                ) {
                    Task { await signInWithApple() }
                }
            }

            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(Color.roostMutedForeground)
                    Text("Sign in")
                        .foregroundStyle(Color.roostPrimary)
                        .fontWeight(.medium)
                }
                .font(.roostBody)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                .fill(Color.roostCard.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 32, x: 0, y: 12)
        .opacity(entered ? 1 : 0)
        .offset(y: entered ? 0 : 52)
        .animation(.spring(response: 0.78, dampingFraction: 0.82).delay(0.28), value: entered)
    }

    // MARK: – Helpers

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

    @MainActor
    private func signInWithApple() async {
        isSigningInWithApple = true
        viewModel.errorMessage = nil
        do {
            let (idToken, nonce) = try await appleCoordinator.signIn()
            try await authService.signInWithApple(idToken: idToken, nonce: nonce)
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User dismissed the sheet — not an error
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        isSigningInWithApple = false
    }
}
