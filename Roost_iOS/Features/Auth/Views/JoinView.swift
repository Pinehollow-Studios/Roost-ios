import SwiftUI

struct JoinView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = JoinViewModel()

    let initialInviteCode: String?
    let initialDisplayName: String?

    init(initialInviteCode: String? = nil, initialDisplayName: String? = nil) {
        self.initialInviteCode = initialInviteCode
        self.initialDisplayName = initialDisplayName
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignSystem.Spacing.section) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: DesignSystem.Size.navigationIcon, weight: .regular))
                        .foregroundStyle(Color.roostForeground)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text("Join a home")
                    .font(.roostPageTitle)
                    .foregroundStyle(Color.roostForeground)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.block)

            VStack(spacing: 0) {
                Text("Enter the invite code from your partner to join their home")
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, DesignSystem.Spacing.blockLarge)

                RoostTextField(
                    title: "XXXXXX",
                    text: $viewModel.inviteCode,
                    textAlignment: .center,
                    font: .roostSectionHeading,
                    textTracking: 2
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.bottom, DesignSystem.Spacing.block)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostDestructive)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, DesignSystem.Spacing.row)
                }

                RoostButton(
                    title: viewModel.isLoading ? "Joining..." : "Join",
                    variant: .primary,
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        if await viewModel.joinHome() {
                            await authManager.refreshHomeStatus()
                        }
                    }
                }
                .disabled(viewModel.isLoading || trimmedInviteCode.isEmpty)
                .opacity(trimmedInviteCode.isEmpty ? 0.72 : 1)

                AuthDivider(title: "Or", textFont: .roostLabel)
                    .padding(.vertical, DesignSystem.Spacing.blockLarge)

                RoostButton(title: "Create your own home", variant: .ghost) {
                    dismiss()
                }
            }
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, DesignSystem.Spacing.page)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if let initialDisplayName, !initialDisplayName.isEmpty {
                viewModel.displayName = initialDisplayName
            } else if let name = authManager.currentUser?.displayName, !name.isEmpty {
                viewModel.displayName = name
            }

            if let initialInviteCode, !initialInviteCode.isEmpty {
                viewModel.inviteCode = initialInviteCode
            } else if let pendingCode = authManager.consumePendingJoinCode() {
                viewModel.inviteCode = pendingCode
            }
        }
    }

    private var trimmedInviteCode: String {
        viewModel.inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
