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
    @State private var resumeSnapshotStore = ResumeSnapshotStore()
    @State private var hazelViewModel = HazelViewModel()
    // Money rebuild — Session 1A data foundation
    @State private var budgetTemplateViewModel = BudgetTemplateViewModel()
    @State private var monthlyMoneyViewModel = MonthlyMoneyViewModel()
    @State private var moneySettingsViewModel = MoneySettingsViewModel()
    @State private var memberNamesHelper = MemberNamesHelper()
    @State private var scrambleModeEnvironment = ScrambleModeEnvironment()
    // Money rebuild — Session 6 savings goals
    @State private var savingsGoalsViewModel = SavingsGoalsViewModel()

    @Environment(\.scenePhase) private var scenePhase

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
                .environment(resumeSnapshotStore)
                .environment(hazelViewModel)
                .environment(budgetTemplateViewModel)
                .environment(monthlyMoneyViewModel)
                .environment(moneySettingsViewModel)
                .environment(memberNamesHelper)
                .environment(scrambleModeEnvironment)
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
                }
                .onChange(of: scenePhase) { _, newValue in
                    switch newValue {
                    case .background:
                        lockManager.appDidBackground()
                    case .active:
                        lockManager.appDidForeground()
                    default:
                        break
                    }
                }
        }
    }
}
