import SwiftUI

struct SetupView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = SetupViewModel()
    @State private var showsJoinScreen = false

    // Entrance
    @State private var entered = false
    // Orb floating
    @State private var orbA = false
    @State private var orbB = false
    @State private var orbC = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.roostBackground.ignoresSafeArea()
                atmosphereLayer.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress dots
                    SetupProgressDots(currentStep: viewModel.step.rawValue, totalSteps: 3)
                        .padding(.top, geo.safeAreaInsets.top + DesignSystem.Spacing.screenTop)
                        .padding(.bottom, DesignSystem.Spacing.blockLarge)
                        .opacity(entered ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: entered)

                    // Step content
                    ZStack {
                        switch viewModel.step {
                        case .profile:
                            profileStep
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .homeChoice:
                            homeChoiceStep
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .homeName:
                            homeNameStep
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.52, dampingFraction: 0.82), value: viewModel.step)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, DesignSystem.Spacing.page)

                    // Bottom action area
                    VStack(spacing: DesignSystem.Spacing.row) {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostDestructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        RoostButton(
                            title: viewModel.buttonTitle,
                            variant: .primary,
                            isLoading: viewModel.isLoading && viewModel.step == .homeName
                        ) {
                            handlePrimaryAction()
                        }
                        .disabled(viewModel.isContinueDisabled)
                        .opacity(viewModel.isContinueDisabled ? 0.65 : 1)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .padding(.bottom, geo.safeAreaInsets.bottom + DesignSystem.Spacing.screenBottom)
                    .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
                    .frame(maxWidth: .infinity)
                    .opacity(entered ? 1 : 0)
                    .offset(y: entered ? 0 : 32)
                    .animation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.32), value: entered)
                }
                .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showsJoinScreen) {
            JoinView(
                initialInviteCode: viewModel.inviteCode,
                initialDisplayName: viewModel.displayName
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.72)) {
                entered = true
            }
            withAnimation(.easeInOut(duration: 4.4).repeatForever(autoreverses: true)) {
                orbA = true
            }
            withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true).delay(0.6)) {
                orbB = true
            }
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true).delay(1.4)) {
                orbC = true
            }

            if let name = authManager.currentUser?.displayName, !name.isEmpty {
                viewModel.displayName = name
            }

            if let code = authManager.pendingJoinCode {
                viewModel.inviteCode = code
                if viewModel.step == .profile {
                    viewModel.step = .homeChoice
                    viewModel.homeChoice = .join
                }
            }
        }
    }

    // MARK: – Background atmosphere

    private var atmosphereLayer: some View {
        ZStack {
            // Terracotta glow — top trailing
            Circle()
                .fill(Color.roostPrimary.opacity(0.32))
                .frame(width: 320, height: 320)
                .blur(radius: 85)
                .offset(x: orbA ? 60 : 30, y: orbA ? -120 : -90)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // Amber glow — bottom leading
            Circle()
                .fill(Color(red: 0.96, green: 0.60, blue: 0.18).opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: orbB ? -40 : -10, y: orbB ? 100 : 60)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            // Soft pulse — centre
            Circle()
                .fill(Color.roostPrimary.opacity(0.10))
                .frame(width: 200, height: 200)
                .blur(radius: 55)
                .offset(x: orbC ? 20 : -20, y: orbC ? -30 : 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    // MARK: – Steps

    private var profileStep: some View {
        VStack(spacing: 0) {
            stepHeader(
                icon: "person.crop.circle",
                title: "Welcome to Roost",
                subtitle: "Let's get you set up."
            )

            RoostTextField(title: "Your display name", text: $viewModel.displayName)
                .padding(.top, DesignSystem.Size.setupInputTopOffset)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.block)
    }

    private var homeChoiceStep: some View {
        VStack(spacing: 0) {
            stepHeader(
                icon: "house.fill",
                title: "Create or join a home?",
                subtitle: nil
            )

            HStack(spacing: DesignSystem.Spacing.row) {
                SetupChoiceCard(
                    title: "Create a new home",
                    subtitle: "Start fresh",
                    systemImage: "house",
                    isSelected: viewModel.homeChoice == .create
                ) {
                    viewModel.homeChoice = .create
                }

                SetupChoiceCard(
                    title: "Join existing home",
                    subtitle: "Use a code",
                    systemImage: "person.badge.plus",
                    isSelected: viewModel.homeChoice == .join
                ) {
                    viewModel.homeChoice = .join
                }
            }
            .padding(.top, DesignSystem.Spacing.block)
        }
        .padding(.top, DesignSystem.Spacing.microMedium)
    }

    private var homeNameStep: some View {
        VStack(spacing: 0) {
            stepHeader(
                icon: "sparkles",
                title: "Name your home",
                subtitle: nil
            )

            RoostTextField(title: homeNamePlaceholder, text: $viewModel.homeName)
                .padding(.top, DesignSystem.Size.setupInputTopOffset)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.block)
    }

    // MARK: – Helpers

    @ViewBuilder
    private func stepHeader(icon: String, title: String, subtitle: String?) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.roostPrimary.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color.roostPrimary)
            }
            .shadow(color: Color.roostPrimary.opacity(0.3), radius: 16, x: 0, y: 6)

            VStack(spacing: 6) {
                Text(title)
                    .font(.roostPageTitle)
                    .foregroundStyle(Color.roostForeground)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(.roostBody)
                        .foregroundStyle(Color.roostMutedForeground)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var homeNamePlaceholder: String {
        let seedName = viewModel.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return "The \(seedName.isEmpty ? "Smith" : seedName) household"
    }

    private func handlePrimaryAction() {
        guard let action = viewModel.continueAction() else {
            return
        }

        switch action {
        case .advanced:
            break
        case .openJoin:
            showsJoinScreen = true
        case .submitCreate:
            Task {
                if await viewModel.createHome() {
                    await authManager.refreshHomeStatus()
                }
            }
        }
    }
}
