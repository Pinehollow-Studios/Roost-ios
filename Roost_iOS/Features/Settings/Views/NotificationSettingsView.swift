import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(NotificationsViewModel.self) private var notificationsViewModel

    // Real persisted toggles
    @State private var newExpensesEnabled = true
    @State private var settlementRemindersEnabled = true
    @State private var choreRemindersEnabled = true
    @State private var shopDayRemindersEnabled = true
    @State private var quietHoursEnabled = false
    @State private var quietStartTime: Date = defaultQuietStart
    @State private var quietEndTime: Date = defaultQuietEnd

    @State private var hasLoadedPreferences = false
    @State private var systemPermissionStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Notifications", accent: .roostPrimary)

                if systemPermissionStatus == .denied {
                    systemPermissionBanner
                }

                moneySection
                planSection
                shoppingSection
                quietHoursSection
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task(id: authManager.currentUser?.id) {
            await checkSystemPermission()
            syncFromPreferences()
            hasLoadedPreferences = true
        }
        .onChange(of: notificationsViewModel.preferences) { _, _ in
            syncFromPreferences()
        }
        .onChange(of: newExpensesEnabled) { _, _ in save() }
        .onChange(of: settlementRemindersEnabled) { _, _ in save() }
        .onChange(of: choreRemindersEnabled) { _, _ in save() }
        .onChange(of: shopDayRemindersEnabled) { _, _ in save() }
        .onChange(of: quietHoursEnabled) { _, _ in save() }
        .onChange(of: quietStartTime) { _, _ in save() }
        .onChange(of: quietEndTime) { _, _ in save() }
        .overlay(alignment: .bottom) {
            if let error = notificationsViewModel.errorMessage {
                Text(error)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostCard)
                    .padding(DesignSystem.Spacing.row)
                    .background(
                        Color.roostDestructive,
                        in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                    )
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .padding(.bottom, DesignSystem.Size.toastBottomOffset)
                    .onTapGesture { notificationsViewModel.errorMessage = nil }
            }
        }
    }

    // MARK: - System Permission Banner

    private var systemPermissionBanner: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.row) {
                ZStack {
                    Circle()
                        .fill(Color.roostWarning.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.roostWarning)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Notifications are off")
                        .font(.roostBody.weight(.semibold))
                        .foregroundStyle(Color.roostForeground)
                    Text("Enable in iPhone Settings so Roost can reach you")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text("Enable")
                    .font(.roostLabel.weight(.medium))
                    .foregroundStyle(Color.roostPrimary)
            }
            .padding(DesignSystem.Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.roostWarning.opacity(0.06),
                in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .strokeBorder(Color.roostWarning.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Cards

    private var moneySection: some View {
        sectionCard(
            icon: "dollarsign.circle.fill",
            color: .roostMoneyTint,
            title: "Money",
            rows: [
                NotifRow(
                    icon: "plus.circle.fill",
                    color: .roostMoneyTint,
                    title: "New expenses",
                    description: "When your partner logs an expense",
                    isOn: $newExpensesEnabled
                ),
                NotifRow(
                    icon: "arrow.left.arrow.right.circle.fill",
                    color: .roostSecondary,
                    title: "Settlement reminders",
                    description: "Monthly reminder to settle up with your partner",
                    isOn: $settlementRemindersEnabled
                )
            ]
        )
    }

    private var planSection: some View {
        sectionCard(
            icon: "checkmark.circle.fill",
            color: .roostChoreTint,
            title: "Plan",
            rows: [
                NotifRow(
                    icon: "clock.fill",
                    color: .roostChoreTint,
                    title: "Chore reminders",
                    description: "The day before a chore is due",
                    isOn: $choreRemindersEnabled
                )
            ]
        )
    }

    private var shoppingSection: some View {
        sectionCard(
            icon: "cart.fill",
            color: .roostShoppingTint,
            title: "Shopping",
            rows: [
                NotifRow(
                    icon: "calendar.badge.clock",
                    color: .roostShoppingTint,
                    title: "Shop day reminder",
                    description: "The day before your scheduled shop",
                    isOn: $shopDayRemindersEnabled
                )
            ]
        )
    }

    private var quietHoursSection: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    ZStack {
                        Circle()
                            .fill(Color.roostSecondary.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.roostSecondary)
                    }
                    Text("Quiet Hours")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                }
                .padding(.bottom, DesignSystem.Spacing.row)

                HStack(spacing: DesignSystem.Spacing.row) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Enable quiet hours")
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                        Text("No notifications will be sent during the times below")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Toggle("", isOn: $quietHoursEnabled)
                        .labelsHidden()
                        .toggleStyle(FigmaSwitchToggleStyle())
                }
                .padding(.vertical, 12)

                if quietHoursEnabled {
                    Divider().overlay(Color.roostHairline)

                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Start")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                            DatePicker("", selection: $quietStartTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(Color.roostPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Rectangle()
                            .fill(Color.roostHairline)
                            .frame(width: 1, height: 40)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("End")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                            DatePicker("", selection: $quietEndTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(Color.roostPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.roostEaseOut, value: quietHoursEnabled)
    }

    // MARK: - Section Builder

    private struct NotifRow {
        let icon: String
        let color: Color
        let title: String
        let description: String
        let isOn: Binding<Bool>
    }

    private func sectionCard(icon: String, color: Color, title: String, rows: [NotifRow]) -> some View {
        RoostCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.10))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(color)
                    }
                    Text(title)
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                }
                .padding(.bottom, DesignSystem.Spacing.row)

                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    notifRow(row)
                    if index < rows.count - 1 {
                        Divider().overlay(Color.roostHairline)
                    }
                }
            }
        }
    }

    private func notifRow(_ row: NotifRow) -> some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.row) {
            ZStack {
                Circle()
                    .fill(row.color.opacity(0.08))
                    .frame(width: 30, height: 30)
                Image(systemName: row.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(row.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)
                Text(row.description)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: row.isOn)
                .labelsHidden()
                .toggleStyle(FigmaSwitchToggleStyle())
        }
        .padding(.vertical, 12)
    }

    // MARK: - Logic

    private func checkSystemPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        systemPermissionStatus = settings.authorizationStatus
    }

    private func syncFromPreferences() {
        let prefs = notificationsViewModel.preferences
        newExpensesEnabled = prefs.expensesEnabled ?? true
        settlementRemindersEnabled = prefs.settlementsEnabled ?? true
        choreRemindersEnabled = prefs.choresEnabled ?? true
        shopDayRemindersEnabled = prefs.shoppingEnabled ?? true
        quietHoursEnabled = prefs.quietHoursEnabled ?? false
        quietStartTime = Self.time(from: prefs.quietHoursStart) ?? Self.defaultQuietStart
        quietEndTime = Self.time(from: prefs.quietHoursEnd) ?? Self.defaultQuietEnd
    }

    private func save() {
        guard hasLoadedPreferences, let userId = authManager.currentUser?.id else { return }
        Task {
            await notificationsViewModel.savePreferences(
                for: userId,
                choresEnabled: choreRemindersEnabled,
                expensesEnabled: newExpensesEnabled,
                shoppingEnabled: shopDayRemindersEnabled,
                settlementsEnabled: settlementRemindersEnabled,
                quietHoursEnabled: quietHoursEnabled,
                quietStart: quietStartTime,
                quietEnd: quietEndTime
            )
        }
    }

    private static let defaultQuietStart: Date = {
        Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? .now
    }()

    private static let defaultQuietEnd: Date = {
        Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? .now
    }()

    private static func time(from value: String?) -> Date? {
        guard let value else { return nil }
        let parts = value.split(separator: ":").map(String.init)
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return Calendar.current.date(from: DateComponents(hour: hour, minute: minute))
    }
}
