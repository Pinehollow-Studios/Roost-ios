import SwiftUI
import SwiftData

@main
struct RoostApp: App {
    @State private var lockManager = AppLockManager()
    @State private var authManager = AuthManager()
    @State private var homeManager = HomeManager()
    @State private var networkMonitor = NetworkMonitor()
    @State private var notificationsViewModel = NotificationsViewModel()
    @State private var notificationRouter = NotificationRouter()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var dashboardViewModel = DashboardViewModel()
    @State private var shoppingViewModel = ShoppingViewModel()
    @State private var expensesViewModel = ExpensesViewModel()
    @State private var budgetViewModel = BudgetViewModel()
    @State private var choresViewModel = ChoresViewModel()
    @State private var calendarViewModel = CalendarViewModel()
    @State private var activityViewModel = ActivityViewModel()
    @State private var pinboardViewModel = PinboardViewModel()
    @State private var subscriptionPricingStore = SubscriptionPricingStore()
    @State private var appearanceSettings = AppearanceSettings()
    @State private var budgetCarrySettings = BudgetCarrySettings()
    @State private var hazelViewModel = HazelViewModel()
    // Money rebuild — Session 1A data foundation
    @State private var budgetTemplateViewModel = BudgetTemplateViewModel()
    @State private var monthlyMoneyViewModel = MonthlyMoneyViewModel()
    @State private var moneySettingsViewModel = MoneySettingsViewModel()
    @State private var memberNamesHelper = MemberNamesHelper()
    @State private var scrambleModeEnvironment = ScrambleModeEnvironment()
    @State private var appBootManager = AppBootManager()
    // Money rebuild — Session 6 savings goals
    @State private var savingsGoalsViewModel = SavingsGoalsViewModel()

    @State private var lastBackgroundedAt: Date?

    @Environment(\.scenePhase) private var scenePhase

    /// True when there is live sensitive content on screen that must be hidden
    /// from the app switcher: authenticated, app lock not showing, boot complete.
    private var privacyShieldEnabled: Bool {
        authManager.isAuthenticated && !lockManager.isLocked && appBootManager.bootedHomeId != nil
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(lockManager)
                .environment(authManager)
                .environment(homeManager)
                .environment(networkMonitor)
                .environment(notificationsViewModel)
                .environment(notificationRouter)
                .environment(settingsViewModel)
                .environment(dashboardViewModel)
                .environment(shoppingViewModel)
                .environment(expensesViewModel)
                .environment(budgetViewModel)
                .environment(choresViewModel)
                .environment(calendarViewModel)
                .environment(activityViewModel)
                .environment(pinboardViewModel)
                .environment(subscriptionPricingStore)
                .environment(appearanceSettings)
                .environment(budgetCarrySettings)
                .environment(hazelViewModel)
                .environment(budgetTemplateViewModel)
                .environment(monthlyMoneyViewModel)
                .environment(moneySettingsViewModel)
                .environment(memberNamesHelper)
                .environment(scrambleModeEnvironment)
                .environment(appBootManager)
                .environment(savingsGoalsViewModel)
                .modelContainer(LocalDataManager.shared.container)
                .onOpenURL { url in
                    authManager.handle(url: url)
                    notificationRouter.handle(url: url)
                    if url.host == "subscription" {
                        Task {
                            await homeManager.refreshCurrentHome()
                        }
                    }
                }
                .task {
                    authManager.startSessionListener()
                    LocalNotificationManager.shared.configure(router: notificationRouter)
                    await subscriptionPricingStore.refresh()
                    AppPrivacyShield.shared.isEnabled = privacyShieldEnabled
                }
                .onChange(of: scenePhase) { _, newValue in
                    switch newValue {
                    case .background:
                        lockManager.appDidBackground()
                        lastBackgroundedAt = Date()
                    case .active:
                        lockManager.appDidForeground()
                        if let bg = lastBackgroundedAt, Date().timeIntervalSince(bg) >= 180 {
                            notificationRouter.selectedTab = .home
                            notificationRouter.morePath = []
                        }
                        lastBackgroundedAt = nil
                        // Confirmed foreground — safe to remove the privacy cover.
                        // Using scenePhase rather than didBecomeActiveNotification
                        // because that notification can fire spuriously for background
                        // apps; scenePhase == .active is the stable, reliable signal.
                        AppPrivacyShield.shared.deactivate()
                    default:
                        break
                    }
                }
                // Keep UIKit shield state in sync with auth/lock/boot changes.
                .onChange(of: authManager.isAuthenticated) { _, _ in
                    AppPrivacyShield.shared.isEnabled = privacyShieldEnabled
                }
                .onChange(of: lockManager.isLocked) { _, _ in
                    // Only sync when the app is in the foreground. When the app
                    // backgrounds while a PIN is set, appDidBackground() flips
                    // isLocked → true, which would make privacyShieldEnabled false
                    // and tear down the cover that was just added on
                    // willResignActiveNotification. The cover must persist until
                    // scenePhase == .active fires deactivate().
                    guard scenePhase == .active else { return }
                    AppPrivacyShield.shared.isEnabled = privacyShieldEnabled
                }
                .onChange(of: appBootManager.bootedHomeId) { _, _ in
                    AppPrivacyShield.shared.isEnabled = privacyShieldEnabled
                }
                // SwiftUI-layer privacy overlay — belt-and-suspenders cover for scene
                // transitions that happen while the app is active (e.g. returning from
                // a background task). The UIKit AppPrivacyShield handles the timing-
                // critical app switcher snapshot; this handles the visual state inside
                // the SwiftUI hierarchy.
                //
                // Conditions mirror privacyShieldEnabled exactly — only covers when
                // there is live authenticated content, never over the lock screen
                // (which handles its own privacy) or during initial boot.
                .overlay {
                    if scenePhase != .active && privacyShieldEnabled {
                        Color.roostBackground
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                            .transaction { $0.animation = nil }
                    }
                }
        }
    }
}
