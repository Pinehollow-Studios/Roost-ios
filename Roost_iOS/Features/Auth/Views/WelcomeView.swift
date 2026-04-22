import AuthenticationServices
import SwiftUI

struct WelcomeView: View {
    @State private var viewModel = LoginViewModel()
    @State private var isSigningInWithGoogle = false
    @State private var isSigningInWithApple = false
    @State private var appleCoordinator = AppleSignInCoordinator()
    @State private var oauthError: String?

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
            withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                orbA = true
            }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(0.8)) {
                orbB = true
            }
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true).delay(1.6)) {
                orbC = true
            }
        }
    }

    // MARK: – Background atmosphere

    private var atmosphereLayer: some View {
        ZStack {
            // Terracotta glow — top trailing
            Circle()
                .fill(Color.roostPrimary.opacity(0.38))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: orbA ? 70 : 40, y: orbA ? -160 : -130)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // Amber glow — bottom leading
            Circle()
                .fill(Color(red: 0.96, green: 0.60, blue: 0.18).opacity(0.26))
                .frame(width: 280, height: 280)
                .blur(radius: 75)
                .offset(x: orbB ? -50 : -20, y: orbB ? 120 : 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            // Secondary terracotta pulse — centre
            Circle()
                .fill(Color.roostPrimary.opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: orbC ? 30 : -30, y: orbC ? -20 : 30)
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
                Text("Roost")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Color.roostForeground)

                Text("Your home, together.")
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
                    title: "Email address",
                    text: $viewModel.email,
                    leadingSystemImage: "envelope"
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .submitLabel(.next)

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
                    title: viewModel.isSubmitting ? "Signing in…" : "Sign in",
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

            NavigationLink {
                SignupView()
            } label: {
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(Color.roostMutedForeground)
                    Text("Sign up")
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

    private var currentMessage: String? {
        // Surface a clear configuration error before the user wastes time
        // typing credentials. This guards against a build that shipped without
        // Secrets.xcconfig values baked in — otherwise the sign-in button
        // would throw a generic error with no actionable context.
        if !SupabaseClientProvider.shared.isConfigured {
            return "Sign-in is unavailable: app configuration is missing. Please reinstall or contact support."
        }
        return oauthError ?? viewModel.errorMessage
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

    @MainActor
    private func signInWithApple() async {
        isSigningInWithApple = true
        oauthError = nil
        do {
            let (idToken, nonce) = try await appleCoordinator.signIn()
            try await authService.signInWithApple(idToken: idToken, nonce: nonce)
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User dismissed the sheet — not an error
        } catch {
            oauthError = error.localizedDescription
        }
        isSigningInWithApple = false
    }
}
