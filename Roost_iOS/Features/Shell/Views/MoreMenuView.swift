import SwiftUI

struct MoreMenuView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(HomeManager.self) private var homeManager
    @Environment(SettingsViewModel.self) private var settingsViewModel

    @State private var isSigningOut = false

    private let authService = AuthService()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.blockLarge) {
                Text("More")
                    .font(.roostPageTitle)
                    .foregroundStyle(Color.roostForeground)
                    .padding(.top, DesignSystem.Spacing.screenTop)

                profileCard

                settingsSection(
                    title: "Account",
                    rows: [
                        settingsRow("Profile", icon: "person", destination: .profile, iconBackground: Color.roostPrimary.opacity(0.1), iconColor: .roostPrimary),
                        settingsRow("Household", icon: "house", destination: .household, iconBackground: Color.roostSecondary.opacity(0.1), iconColor: .roostSecondary),
                        settingsRow("Money", icon: "sterlingsign.circle.fill", destination: .money, iconBackground: Color(hex: 0xFAECE7), iconColor: Color(hex: 0xD4795E)),
                        settingsRow("Account", icon: "gearshape", destination: .account),
                        settingsRow("Roost Pro", icon: "crown.fill", destination: .subscription, iconBackground: Color.roostPrimary.opacity(0.15), iconColor: .roostPrimary)
                    ]
                )

                settingsSection(
                    title: "App",
                    rows: [
                        settingsRow("Appearance", icon: "circle.lefthalf.filled", destination: .appearance, iconBackground: Color.roostPrimary.opacity(0.1), iconColor: .roostPrimary),
                        settingsRow("Hazel", icon: "sparkles", destination: .hazel, iconBackground: Color.roostSecondary.opacity(0.1), iconColor: .roostSecondary),
                        settingsRow("Notifications", icon: "bell", destination: .notificationSettings, iconBackground: Color.roostWarning.opacity(0.1), iconColor: .roostWarning),
                        settingsRow("Security", icon: "lock.fill", destination: .security, iconBackground: Color(hex: 0xE8F0E9), iconColor: Color(hex: 0x4A7C59))
                    ]
                )

                settingsSection(
                    title: "Household Setup",
                    rows: [
                        settingsRow("Pinboard", icon: "pin", destination: .pinboard, iconBackground: Color.roostPrimary.opacity(0.1), iconColor: .roostPrimary),
                        settingsRow("Rooms", icon: "door.left.hand.open", destination: .rooms)
                    ]
                )

                settingsSection(
                    title: "Support",
                    rows: [
                        SettingsRowModel(
                            title: "App Version",
                            icon: "info.circle",
                            destination: nil,
                            iconBackground: Color.roostAccent,
                            iconColor: .roostForeground,
                            trailingText: appVersionString,
                            hideChevron: true
                        )
                    ]
                )

                Button {
                    Task { await signOut() }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.inline) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20, weight: .regular))
                        Text(isSigningOut ? "Signing out..." : "Sign out")
                            .font(.roostBody.weight(.medium))
                    }
                    .foregroundStyle(Color.roostDestructive)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(
                        RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                            .fill(Color.roostDestructive.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSigningOut)
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .settingsMessageOverlay()
    }

    private var profileCard: some View {
        NavigationLink(value: NotificationRouter.MoreDestination.profile) {
            HStack(spacing: DesignSystem.Spacing.row) {
                MemberAvatar(
                    label: homeManager.currentMember?.displayName ?? authManager.currentUser?.displayName ?? "T",
                    color: settingsViewModel.avatarColor(for: homeManager.currentMember?.avatarColor),
                    icon: LucideIcon.sfSymbolName(for: homeManager.currentMember?.avatarIcon),
                    size: .lg
                )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text(homeManager.currentMember?.displayName ?? authManager.currentUser?.displayName ?? "Tom Richardson")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                    Text(authManager.currentUser?.email ?? "tom@example.com")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .padding(DesignSystem.Spacing.cardLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .fill(Color.roostCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .stroke(Color.roostPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func settingsSection(
        title: String,
        rows: [SettingsRowModel]
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            Text(title)
                .font(.roostLabel)
                .foregroundStyle(Color.roostMutedForeground)
                .textCase(.uppercase)
                .tracking(0.6)

            RoostCard {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        settingsRowView(row)

                        if index < rows.count - 1 {
                            Divider()
                                .overlay(Color.roostHairline)
                                .padding(.leading, 48)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func settingsRowView(_ row: SettingsRowModel) -> some View {
        if let destination = row.destination {
            NavigationLink(value: destination) {
                settingsRowContent(row)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            settingsRowContent(row)
        }
    }

    private func settingsRowContent(_ row: SettingsRowModel) -> some View {
        HStack(spacing: DesignSystem.Spacing.row) {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.xs, style: .continuous)
                .fill(row.iconBackground)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: row.icon)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(row.iconColor)
                }

            Text(row.title)
                .font(.roostBody)
                .foregroundStyle(Color.roostForeground)

            Spacer()

            if let trailingText = row.trailingText {
                Text(trailingText)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            if !row.hideChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.roostMutedForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44)
        .padding(.vertical, DesignSystem.Spacing.inline)
        .contentShape(Rectangle())
    }

    private func settingsRow(
        _ title: String,
        icon: String,
        destination: NotificationRouter.MoreDestination,
        iconBackground: Color = Color.roostAccent,
        iconColor: Color = .roostForeground
    ) -> SettingsRowModel {
        SettingsRowModel(
            title: title,
            icon: icon,
            destination: destination,
            iconBackground: iconBackground,
            iconColor: iconColor,
            trailingText: nil,
            hideChevron: false
        )
    }

    private var appVersionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func signOut() async {
        isSigningOut = true
        do {
            try await authService.signOut()
        } catch {
            settingsViewModel.errorMessage = error.localizedDescription
        }
        isSigningOut = false
    }
}

private struct SettingsRowModel {
    let title: String
    let icon: String
    let destination: NotificationRouter.MoreDestination?
    let iconBackground: Color
    let iconColor: Color
    let trailingText: String?
    let hideChevron: Bool
}
