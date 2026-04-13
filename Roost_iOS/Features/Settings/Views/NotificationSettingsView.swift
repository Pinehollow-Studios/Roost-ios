import SwiftUI

struct NotificationSettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(NotificationsViewModel.self) private var notificationsViewModel

    @State private var inAppNotificationsEnabled = true
    @State private var emailNotificationsEnabled = false
    @State private var newExpensesEnabled = true
    @State private var settlementRemindersEnabled = true
    @State private var budgetAlertsEnabled = true
    @State private var choreRemindersEnabled = true
    @State private var overdueChoresEnabled = true
    @State private var calendarEventsEnabled = false
    @State private var pinboardNotesEnabled = true
    @State private var shopDayRemindersEnabled = true
    @State private var listUpdatesEnabled = false
    @State private var hasLoadedPreferences = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Notifications")

                Text("Manage how Roost keeps you informed")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostMutedForeground)

                sectionCard(title: "General", rows: [
                    ("In-app notifications", "Show notifications within the app", $inAppNotificationsEnabled),
                    ("Email notifications", "Receive updates via email", $emailNotificationsEnabled)
                ])

                sectionCard(title: "Money", rows: [
                    ("New expenses", "When your partner adds an expense", $newExpensesEnabled),
                    ("Settlement reminders", "Monthly reminders to settle up", $settlementRemindersEnabled),
                    ("Budget alerts", "When you're approaching budget limits", $budgetAlertsEnabled)
                ])

                sectionCard(title: "Plan", rows: [
                    ("Chore reminders", "Day before chores are due", $choreRemindersEnabled),
                    ("Overdue chores", "Daily reminder for overdue chores", $overdueChoresEnabled),
                    ("Calendar events", "Upcoming events and appointments", $calendarEventsEnabled),
                    ("Pinboard notes", "New notes from your partner", $pinboardNotesEnabled)
                ])

                sectionCard(title: "Shopping", rows: [
                    ("Shop day reminders", "Day before your scheduled shop", $shopDayRemindersEnabled),
                    ("List updates", "When items are added to the list", $listUpdatesEnabled)
                ])
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
            syncFromPreferences()
            hasLoadedPreferences = true
        }
        .onChange(of: notificationsViewModel.preferences) { _, _ in
            syncFromPreferences()
        }
        .onChange(of: newExpensesEnabled) { _, _ in persistSupportedPreferencesIfNeeded() }
        .onChange(of: settlementRemindersEnabled) { _, _ in persistSupportedPreferencesIfNeeded() }
        .onChange(of: choreRemindersEnabled) { _, _ in persistSupportedPreferencesIfNeeded() }
        .onChange(of: shopDayRemindersEnabled) { _, _ in persistSupportedPreferencesIfNeeded() }
        .overlay(alignment: .bottom) {
            if let error = notificationsViewModel.errorMessage {
                Text(error)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostCard)
                    .padding(Spacing.md)
                    .background(Color.roostDestructive.cornerRadius(RoostTheme.controlCornerRadius))
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, DesignSystem.Size.toastBottomOffset)
                    .onTapGesture { notificationsViewModel.errorMessage = nil }
            }
        }
    }

    private func sectionCard(title: String, rows: [(String, String, Binding<Bool>)]) -> some View {
        RoostCard {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)
                    .padding(.bottom, 8)

                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    SettingsToggleRow(
                        title: row.0,
                        description: row.1,
                        isOn: row.2
                    )

                    if index < rows.count - 1 {
                        Divider()
                            .overlay(Color.roostHairline)
                    }
                }
            }
        }
    }

    private func syncFromPreferences() {
        let prefs = notificationsViewModel.preferences
        newExpensesEnabled = prefs.expensesEnabled ?? true
        settlementRemindersEnabled = prefs.settlementsEnabled ?? true
        choreRemindersEnabled = prefs.choresEnabled ?? true
        shopDayRemindersEnabled = prefs.shoppingEnabled ?? true
    }

    private func persistSupportedPreferencesIfNeeded() {
        guard hasLoadedPreferences, let userId = authManager.currentUser?.id else { return }
        Task {
            await notificationsViewModel.savePreferences(
                for: userId,
                choresEnabled: choreRemindersEnabled,
                expensesEnabled: newExpensesEnabled,
                shoppingEnabled: shopDayRemindersEnabled,
                settlementsEnabled: settlementRemindersEnabled,
                quietHoursEnabled: notificationsViewModel.preferences.quietHoursEnabled ?? false,
                quietStart: preservedQuietStart,
                quietEnd: preservedQuietEnd
            )
        }
    }

    private var preservedQuietStart: Date {
        Self.time(from: notificationsViewModel.preferences.quietHoursStart) ?? Self.defaultQuietStart
    }

    private var preservedQuietEnd: Date {
        Self.time(from: notificationsViewModel.preferences.quietHoursEnd) ?? Self.defaultQuietEnd
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
              let minute = Int(parts[1]) else {
            return nil
        }
        return Calendar.current.date(from: DateComponents(hour: hour, minute: minute))
    }
}
