import SwiftUI
import UIKit

struct HouseholdSettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(HomeManager.self) private var homeManager
    @Environment(SettingsViewModel.self) private var settingsViewModel

    @State private var homeName = ""
    @State private var stagedHomeName = ""
    @State private var showingRenameAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Household", accent: .roostPrimary)

                if let home = homeManager.home {
                    householdNameCard(home)
                    householdIDCard(home)
                    membersCard
                    inviteCard(home)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task(id: homeManager.home?.id) {
            homeName = homeManager.home?.name ?? ""
        }
        .alert("Household Name", isPresented: $showingRenameAlert) {
            TextField("Household name", text: $stagedHomeName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                guard let home = homeManager.home else { return }
                Task {
                    let didSave = await settingsViewModel.updateHomeName(home, newName: stagedHomeName)
                    if didSave,
                       let homeId = homeManager.homeId,
                       let userId = homeManager.currentUserId {
                        homeName = stagedHomeName
                        await homeManager.loadHome(homeId: homeId, userId: userId)
                    }
                }
            }
        } message: {
            Text("Update the name shown across your household.")
        }
        .settingsMessageOverlay()
    }

    private func householdNameCard(_ home: Home) -> some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.inline) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    cardIcon("house.fill", size: 14)

                    Text("Household Name")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)

                    Spacer(minLength: 0)

                    Button {
                        stagedHomeName = home.name
                        showingRenameAlert = true
                    } label: {
                        Text("Edit")
                            .font(.roostLabel.weight(.medium))
                            .foregroundStyle(Color.roostPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Text(homeName.isEmpty ? home.name : homeName)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
            }
        }
    }

    private func householdIDCard(_ home: Home) -> some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.inline) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    cardIcon("number", size: 14)

                    Text("Household ID")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)

                    Spacer(minLength: 0)

                    Button {
                        UIPasteboard.general.string = home.inviteCode
                        settingsViewModel.successMessage = "Household ID copied."
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14, weight: .medium))
                            Text("Copy")
                                .font(.roostLabel.weight(.medium))
                        }
                        .foregroundStyle(Color.roostPrimary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Text(home.inviteCode)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .tracking(2)
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

    private var membersCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    cardIcon("person.2.fill", size: 13)
                    Text("Members")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                }

                VStack(spacing: 12) {
                    ForEach(homeManager.members) { member in
                        HStack(spacing: DesignSystem.Spacing.row) {
                            MemberAvatar(
                                label: member.displayName,
                                color: settingsViewModel.avatarColor(for: member.avatarColor),
                                icon: LucideIcon.sfSymbolName(for: member.avatarIcon),
                                size: .md
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.displayName)
                                    .font(.roostBody.weight(.medium))
                                    .foregroundStyle(Color.roostForeground)

                                Text(memberSubtitle(member))
                                    .font(.roostLabel)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }

                            Spacer(minLength: 0)

                            FigmaChip(title: memberRole(member))
                        }
                    }
                }
            }
        }
    }

    private func inviteCard(_ home: Home) -> some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    cardIcon("paperplane.fill", size: 14)
                    Text("Invite Partner")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                }

                Text("Share this invite code with your partner to join your household")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: DesignSystem.Spacing.inline) {
                    Text(home.inviteCode)
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Color.roostForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                .fill(Color.roostAccent)
                        )

                    Button {
                        UIPasteboard.general.string = home.inviteCode
                        settingsViewModel.successMessage = "Invite code copied."
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.roostCard)
                            .frame(width: 48, height: 48)
                            .background(Color.roostPrimary, in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Text("Or send them an invite link via email or message")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)

                ShareLink(item: inviteLink(for: home.inviteCode)) {
                    Text("Share Invite Link")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Size.buttonHeight)
                        .background(
                            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                .fill(Color.roostSecondary.opacity(0.18))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                .stroke(Color.roostHairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func cardIcon(_ systemName: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.roostPrimary.opacity(0.10))
                .frame(width: 32, height: 32)
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(Color.roostPrimary)
        }
    }

    private func memberSubtitle(_ member: HomeMember) -> String {
        if member.userID == authManager.currentUser?.id {
            return authManager.currentUser?.email ?? memberRole(member)
        }
        return memberRole(member)
    }

    private func memberRole(_ member: HomeMember) -> String {
        member.role?.capitalized ?? "Member"
    }

    private func inviteLink(for code: String) -> URL {
        URL(string: "roost-ios://join?code=\(code)") ?? URL(string: "roost-ios://join")!
    }
}
