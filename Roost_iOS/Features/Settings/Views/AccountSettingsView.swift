import SwiftUI

struct AccountSettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(HomeManager.self) private var homeManager
    @Environment(SettingsViewModel.self) private var settingsViewModel

    @State private var showingLeaveAlert = false
    @State private var showingDeleteAlert = false
    @State private var isSigningOut = false

    private let authService = AuthService()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Account Settings", accent: .roostPrimary)

                profileCard
                emailCard
                passwordCard
                dangerSection
                signOutButton
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .alert("Leave Household?", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Leave Household", role: .destructive) {
                Task {
                    _ = await settingsViewModel.leaveHome(authManager: authManager, homeManager: homeManager)
                }
            }
        } message: {
            Text("Remove yourself from this household while leaving your partner's data intact.")
        }
        .alert("Delete Account?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive) {
                Task {
                    _ = await settingsViewModel.deleteAccount(authManager: authManager, homeManager: homeManager)
                }
            }
        } message: {
            Text("This permanently deletes your Roost account and all associated access.")
        }
        .settingsMessageOverlay()
    }

    private var profileCard: some View {
        RoostCard {
            HStack(spacing: DesignSystem.Spacing.row) {
                MemberAvatar(member: currentMember, size: .md)

                VStack(alignment: .leading, spacing: 3) {
                    Text(currentMember?.displayName ?? "Your account")
                        .font(.roostBody.weight(.semibold))
                        .foregroundStyle(Color.roostForeground)
                    Text(authManager.currentUser?.email ?? "")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var currentMember: HomeMember? {
        homeManager.members.first { $0.userID == authManager.currentUser?.id }
    }

    private var emailCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    ZStack {
                        Circle()
                            .fill(Color.roostPrimary.opacity(0.10))
                            .frame(width: 32, height: 32)
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.roostPrimary)
                    }
                    Text("Email Address")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                }

                Text(authManager.currentUser?.email ?? "")
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignSystem.Spacing.card)
                    .frame(minHeight: DesignSystem.Size.inputHeight)
                    .background(
                        RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                            .fill(Color.roostMuted)
                    )

                Text("This is the email you use to sign in to Roost")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
            }
        }
    }

    private var passwordCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    ZStack {
                        Circle()
                            .fill(Color.roostPrimary.opacity(0.10))
                            .frame(width: 32, height: 32)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.roostPrimary)
                    }

                    Text("Password")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)

                    Spacer(minLength: 0)

                    Button {
                        guard let email = authManager.currentUser?.email else { return }
                        Task { _ = await settingsViewModel.sendPasswordReset(email: email) }
                    } label: {
                        Text("Change")
                            .font(.roostLabel.weight(.medium))
                            .foregroundStyle(Color.roostPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Text("••••••••")
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignSystem.Spacing.card)
                    .frame(minHeight: DesignSystem.Size.inputHeight)
                    .background(
                        RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                            .fill(Color.roostMuted)
                    )
            }
        }
    }

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            Text("Danger Zone")
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostDestructive)

            dangerCard(
                title: "Leave Household",
                body: "Remove yourself from \"\(homeManager.home?.name ?? "your household")\". Your partner will still have access to all data.",
                buttonTitle: "Leave Household",
                destructiveFill: false
            ) {
                showingLeaveAlert = true
            }

            dangerCard(
                title: "Delete Account",
                body: "Permanently delete your Roost account and all associated data. This action cannot be undone.",
                buttonTitle: "Delete Account",
                destructiveFill: true
            ) {
                showingDeleteAlert = true
            }
        }
    }

    private func dangerCard(
        title: String,
        body: String,
        buttonTitle: String,
        destructiveFill: Bool,
        action: @escaping () -> Void
    ) -> some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                Text(title)
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)

                Text(body)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: action) {
                    Text(buttonTitle)
                        .font(.roostLabel)
                        .foregroundStyle(destructiveFill ? Color.roostCard : Color.roostDestructive)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Size.buttonHeight)
                        .background(
                            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                .fill(destructiveFill ? Color.roostDestructive : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                .stroke(Color.roostDestructive.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(Color.roostDestructive.opacity(0.3), lineWidth: 1)
        )
    }

    private var signOutButton: some View {
        RoostButton(
            title: isSigningOut ? "Signing out..." : "Sign out",
            variant: .ghost,
            isLoading: isSigningOut
        ) {
            guard !isSigningOut else { return }
            isSigningOut = true
            Task {
                do {
                    try await authService.signOut()
                } catch {
                    settingsViewModel.errorMessage = error.localizedDescription
                }
                isSigningOut = false
            }
        }
        .disabled(isSigningOut)
    }
}
