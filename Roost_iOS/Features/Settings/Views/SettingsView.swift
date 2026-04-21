import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(SyncStatusStore.self) private var syncStatusStore

    @State private var isSigningOut = false

    private let authService = AuthService()

    var body: some View {
        RoostPageContainer(title: "Settings", subtitle: nil) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                sectionCard(
                    title: "Personal",
                    rows: [
                        .init(title: "Profile", icon: "person.crop.circle", destination: AnyView(ProfileSettingsView())),
                        .init(title: "Preferences", icon: "slider.horizontal.3", destination: AnyView(PreferencesSettingsView()))
                    ]
                )

                sectionCard(
                    title: "Household",
                    rows: [
                        .init(title: "Household", icon: "house", destination: AnyView(HouseholdSettingsView())),
                        .init(title: "Money", icon: "sterlingsign.circle", destination: AnyView(MoneySettingsView())),
                        .init(title: "Notifications", icon: "bell", destination: AnyView(NotificationSettingsView()))
                    ]
                )

                sectionCard(
                    title: "Account",
                    rows: accountRows
                )

                signOutCard
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: authManager.currentUser?.id) {
            if let userId = authManager.currentUser?.id {
                await settingsViewModel.loadPreferences(for: userId)
            }
        }
        .settingsMessageOverlay()
    }

    /// Account section rows. Adds "Pending changes" only when the offline
    /// outbox has items the user should know about — keeps Settings clean for
    /// the 99% of sessions where everything is synced.
    private var accountRows: [SettingsRowItem] {
        var rows: [SettingsRowItem] = [
            .init(title: "Account", icon: "person.badge.key", destination: AnyView(AccountSettingsView()))
        ]
        if syncStatusStore.pendingCount + syncStatusStore.failedCount > 0 {
            rows.append(
                .init(
                    title: "Pending changes",
                    icon: "arrow.triangle.2.circlepath",
                    destination: AnyView(PendingChangesView())
                )
            )
        }
        return rows
    }

    private func sectionCard(title: String, rows: [SettingsRowItem]) -> some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title)
                    .font(.roostSection)
                    .foregroundStyle(Color.roostForeground)

                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        NavigationLink {
                            row.destination
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: row.icon)
                                    .foregroundStyle(Color.roostPrimary)
                                    .frame(width: 34, height: 34)
                                    .background(Color.roostAccent, in: Circle())

                                Text(row.title)
                                    .font(.roostBody)
                                    .foregroundStyle(Color.roostForeground)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if row.id != rows.last?.id {
                            Divider()
                                .overlay(Color.roostHairline)
                                .padding(.leading, 50)
                        }
                    }
                }
            }
        }
    }

    private var signOutCard: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Session")
                    .font(.roostSection)
                    .foregroundStyle(Color.roostForeground)

                Button(role: .destructive) {
                    Task { await signOut() }
                } label: {
                    HStack {
                        Text(isSigningOut ? "Signing out..." : "Sign Out")
                            .font(.roostLabel)
                        Spacer()
                        if isSigningOut {
                            ProgressView()
                        }
                    }
                    .foregroundStyle(Color.roostDestructive)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.roostDestructive.opacity(0.08), in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                }
                .disabled(isSigningOut)
                .buttonStyle(.plain)
            }
        }
    }

    private func signOut() async {
        isSigningOut = true
        do {
            try await authService.signOut()
        } catch {
            // Auth state listener still owns session state transitions.
        }
        isSigningOut = false
    }
}

private struct SettingsRowItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let destination: AnyView
}

private struct SettingsMessageOverlay: ViewModifier {
    @Environment(SettingsViewModel.self) private var settingsViewModel

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message = settingsViewModel.errorMessage ?? settingsViewModel.successMessage {
                Text(message)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostCard)
                    .padding(Spacing.md)
                    .background((settingsViewModel.errorMessage != nil ? Color.roostDestructive : Color.roostSuccess).cornerRadius(RoostTheme.controlCornerRadius))
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, DesignSystem.Size.toastBottomOffset)
                    .onTapGesture {
                        settingsViewModel.errorMessage = nil
                        settingsViewModel.successMessage = nil
                    }
            }
        }
    }
}

extension View {
    func settingsMessageOverlay() -> some View {
        modifier(SettingsMessageOverlay())
    }
}
