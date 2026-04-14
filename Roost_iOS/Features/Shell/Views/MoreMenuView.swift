import SwiftUI

struct MoreMenuView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    pageHeader
                        .padding(.top, 16)
                        .moreEntrance(at: 0, appeared: appeared, reduceMotion: reduceMotion)

                    primaryDestinations
                        .padding(.top, 24)
                        .moreEntrance(at: 1, appeared: appeared, reduceMotion: reduceMotion)

                    settingsShortcut
                        .padding(.top, 18)
                        .moreEntrance(at: 2, appeared: appeared, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, morePageInset)
                .padding(.bottom, DesignSystem.Spacing.screenBottom + DesignSystem.Spacing.tabContentBottomInset + 24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.roostPrimary.opacity(0.65), Color.roostPrimary.opacity(0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .ignoresSafeArea(edges: .top)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .settingsMessageOverlay()
        .task {
            guard !reduceMotion else {
                appeared = true
                return
            }
            withAnimation(.roostSmooth) {
                appeared = true
            }
        }
    }

    private var pageHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("More")
                    .font(.roostLargeGreeting)
                    .foregroundStyle(Color.roostForeground)

                Text("Plans and notes for the home")
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            Spacer(minLength: 0)
        }
    }

    private var primaryDestinations: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoreFeatureButton(
                title: "Calendar",
                subtitle: "Shared dates, chores, bills, and what needs attention next.",
                icon: "calendar",
                tint: Color.roostPrimary,
                destination: .calendar,
                reduceMotion: reduceMotion
            )

            MoreFeatureButton(
                title: "Pinboard",
                subtitle: "Live notes, reminders, and messages pinned for the household.",
                icon: "pin.fill",
                tint: Color.roostShoppingTint,
                destination: .pinboard,
                reduceMotion: reduceMotion
            )
        }
    }

    private var settingsShortcut: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("SETTINGS")
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .tracking(1.0)

            MoreCompactButton(
                title: "Settings",
                subtitle: "Household, app, security",
                icon: "slider.horizontal.3",
                tint: Color.roostMoneyTint,
                destination: .settings,
                reduceMotion: reduceMotion
            )
        }
    }
}

private struct MoreFeatureButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let destination: NotificationRouter.MoreDestination
    let reduceMotion: Bool

    var body: some View {
        NavigationLink(value: destination) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(tint.opacity(0.12))

                        Image(systemName: icon)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(tint)
                    }
                    .frame(width: 46, height: 46)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 32, height: 32)
                        .background(Color.roostMuted, in: Circle())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(Color.roostForeground)

                    Text(subtitle)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .background(
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                        .fill(Color.roostCard)

                    Circle()
                        .fill(tint.opacity(0.10))
                        .frame(width: 118, height: 118)
                        .blur(radius: 28)
                        .offset(x: 42, y: -56)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
        }
        .buttonStyle(MorePressStyle(reduceMotion: reduceMotion))
    }
}

private struct MoreCompactButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let destination: NotificationRouter.MoreDestination
    let reduceMotion: Bool

    var body: some View {
        NavigationLink(value: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostForeground)

                    Text(subtitle)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        }
        .buttonStyle(MorePressStyle(reduceMotion: reduceMotion))
    }
}

struct MoreSettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false
    @State private var isSigningOut = false

    private let authService = AuthService()

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    pageHeader
                        .moreEntrance(at: 0, appeared: appeared, reduceMotion: reduceMotion)

                    settingsSections
                        .padding(.top, 18)
                        .moreEntrance(at: 1, appeared: appeared, reduceMotion: reduceMotion)

                    signOutButton
                        .padding(.top, 18)
                        .moreEntrance(at: 2, appeared: appeared, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, morePageInset)
                .padding(.bottom, DesignSystem.Spacing.screenBottom + DesignSystem.Spacing.tabContentBottomInset + 32)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.roostPrimary.opacity(0.65), Color.roostPrimary.opacity(0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .ignoresSafeArea(edges: .top)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .settingsMessageOverlay()
        .task {
            guard !reduceMotion else {
                appeared = true
                return
            }
            withAnimation(.roostSmooth) {
                appeared = true
            }
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            FigmaBackHeader(title: "Settings")

            Text("Account and household controls")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.leading, 56)
        }
    }

    private var settingsSections: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingsSection(
                title: "Account",
                rows: [
                    settingsRow("Household", icon: "house", destination: .household, tint: Color.roostChoreTint),
                    settingsRow("Account", icon: "gearshape", destination: .account, tint: Color.roostMutedForeground),
                    settingsRow("Roost Pro", icon: "crown.fill", destination: .subscription, tint: Color.roostPrimary)
                ]
            )

            settingsSection(
                title: "App",
                rows: [
                    settingsRow("Appearance", icon: "circle.lefthalf.filled", destination: .appearance, tint: Color.roostPrimary),
                    settingsRow("Hazel", icon: "sparkles", destination: .hazel, tint: Color.roostChoreTint),
                    settingsRow("Notifications", icon: "bell", destination: .notificationSettings, tint: Color.roostWarning),
                    settingsRow("Security", icon: "lock.fill", destination: .security, tint: Color.roostMoneyTint)
                ]
            )

            settingsSection(
                title: "Household Setup",
                rows: [
                    settingsRow("Rooms", icon: "door.left.hand.open", destination: .rooms, tint: Color.roostChoreTint),
                    settingsRow("Money", icon: "sterlingsign.circle.fill", destination: .money, tint: Color.roostMoneyTint),
                    settingsRow("Budget Categories", icon: "tag", destination: .budgetCategories, tint: Color.roostMoneyTint),
                    settingsRow("Activity", icon: "clock.arrow.circlepath", destination: .activity, tint: Color.roostShoppingTint),
                    settingsRow("Notifications Inbox", icon: "tray", destination: .notifications, tint: Color.roostWarning)
                ]
            )

            settingsSection(
                title: "Support",
                rows: [
                    SettingsRowModel(
                        title: "App Version",
                        icon: "info.circle",
                        destination: nil,
                        tint: Color.roostMutedForeground,
                        trailingText: appVersionString,
                        hideChevron: true
                    )
                ]
            )
        }
    }

    private func settingsSection(title: String, rows: [SettingsRowModel]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased())
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .tracking(1.0)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    settingsRowView(row)

                    if index < rows.count - 1 {
                        Rectangle()
                            .fill(Color.roostHairline)
                            .frame(height: 1)
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func settingsRowView(_ row: SettingsRowModel) -> some View {
        if let destination = row.destination {
            NavigationLink(value: destination) {
                settingsRowContent(row)
            }
            .buttonStyle(MorePressStyle(reduceMotion: reduceMotion))
        } else {
            settingsRowContent(row)
        }
    }

    private func settingsRowContent(_ row: SettingsRowModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: row.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(row.tint)
                .frame(width: 34, height: 34)
                .background(row.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(row.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.roostForeground)

            Spacer(minLength: 0)

            if let trailingText = row.trailingText {
                Text(trailingText)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            if !row.hideChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private func settingsRow(
        _ title: String,
        icon: String,
        destination: NotificationRouter.MoreDestination,
        tint: Color
    ) -> SettingsRowModel {
        SettingsRowModel(
            title: title,
            icon: icon,
            destination: destination,
            tint: tint,
            trailingText: nil,
            hideChevron: false
        )
    }

    private var signOutButton: some View {
        Button {
            Task { await signOut() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))

                Text(isSigningOut ? "Signing out..." : "Sign out")
                    .font(.system(size: 14, weight: .medium))

                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.roostDestructive)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.roostDestructive.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .stroke(Color.roostDestructive.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(MorePressStyle(reduceMotion: reduceMotion))
        .disabled(isSigningOut)
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
    let tint: Color
    let trailingText: String?
    let hideChevron: Bool
}

private struct MorePressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}

private struct MoreEntranceModifier: ViewModifier {
    let index: Int
    let appeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: reduceMotion || appeared ? 0 : CGFloat(18 + index * 4))
            .animation(reduceMotion ? nil : .roostSmooth.delay(Double(index) * 0.045), value: appeared)
    }
}

private extension View {
    func moreEntrance(at index: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        modifier(MoreEntranceModifier(index: index, appeared: appeared, reduceMotion: reduceMotion))
    }
}

private let morePageInset: CGFloat = 12
