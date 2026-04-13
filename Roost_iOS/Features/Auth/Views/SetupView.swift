import SwiftUI

struct SetupView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = SetupViewModel()
    @State private var showsJoinScreen = false

    var body: some View {
        VStack(spacing: 0) {
            SetupProgressDots(currentStep: viewModel.step.rawValue, totalSteps: 3)
                .padding(.top, DesignSystem.Spacing.screenTop)
                .padding(.bottom, DesignSystem.Spacing.blockLarge)

            VStack(spacing: 0) {
                Group {
                    switch viewModel.step {
                    case .profile:
                        profileStep
                    case .homeChoice:
                        homeChoiceStep
                    case .homeName:
                        homeNameStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

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
                    .opacity(viewModel.isContinueDisabled ? 0.72 : 1)
                }
                .padding(.bottom, DesignSystem.Spacing.screenBottom)
            }
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, DesignSystem.Spacing.page)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showsJoinScreen) {
            JoinView(
                initialInviteCode: viewModel.inviteCode,
                initialDisplayName: viewModel.displayName
            )
        }
        .onAppear {
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

    private var profileStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: DesignSystem.Spacing.microMedium) {
                Text("Welcome to Roost")
                    .font(.roostPageTitle)
                    .foregroundStyle(Color.roostForeground)

                Text("Let's get you set up.")
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .multilineTextAlignment(.center)

            RoostTextField(title: "Your display name", text: $viewModel.displayName)
                .padding(.top, DesignSystem.Size.setupInputTopOffset)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.block)
    }

    private var homeChoiceStep: some View {
        VStack(spacing: 0) {
            Text("Create or join a home?")
                .font(.roostPageTitle)
                .foregroundStyle(Color.roostForeground)
                .multilineTextAlignment(.center)

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
            Text("Name your home")
                .font(.roostPageTitle)
                .foregroundStyle(Color.roostForeground)
                .multilineTextAlignment(.center)

            RoostTextField(title: homeNamePlaceholder, text: $viewModel.homeName)
                .padding(.top, DesignSystem.Size.setupInputTopOffset)
        }
        .padding(.top, DesignSystem.Spacing.block)
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
