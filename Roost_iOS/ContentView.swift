//
//  ContentView.swift
//  Roost_iOS
//
//  Created by Tom Slater on 25/03/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(AppearanceSettings.self) private var appearanceSettings
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(AppBootManager.self) private var appBootManager
    @Environment(NotificationRouter.self) private var notificationRouter

    var body: some View {
        ZStack(alignment: .top) {
            Color.roostBackground
                .ignoresSafeArea()

            Group {
                if authManager.isRestoringSession {
                    RoostLoadingView(message: "Restoring session…")
                } else if authManager.isAuthenticated {
                    if authManager.hasHome == false {
                        NavigationStack { SetupView() }
                    } else if authManager.hasHome == true {
                        RootAuthenticatedView()
                    } else {
                        RoostLoadingView(message: "Checking your home…")
                    }
                } else {
                    NavigationStack { WelcomeView() }
                }
            }

            OfflineBanner(isVisible: !networkMonitor.isConnected)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear
                .frame(height: DesignSystem.Size.statusBarInset)
                .background(
                    Color.roostBackground
                        .ignoresSafeArea(edges: .top)
                )
        }
        .preferredColorScheme(appearanceSettings.preferredColorScheme)
        .onChange(of: authManager.isAuthenticated) { wasAuthenticated, isAuthenticated in
            if !isAuthenticated {
                appBootManager.clear()
                // Clear any stale navigation so the next login starts on home
                notificationRouter.selectedTab = .home
                notificationRouter.morePath = []
            }
            // After a fresh login, always land on home regardless of previous tab
            if !wasAuthenticated && isAuthenticated {
                notificationRouter.selectedTab = .home
                notificationRouter.morePath = []
            }
        }
        .onChange(of: authManager.hasHome) { wasHasHome, isHasHome in
            // After completing onboarding (setup → home confirmed), always land on home
            if wasHasHome == false && isHasHome == true {
                notificationRouter.selectedTab = .home
                notificationRouter.morePath = []
            }
        }
    }
}

private struct RootAuthenticatedView: View {
    @Environment(AppLockManager.self) private var lockManager
    @Environment(AppBootManager.self) private var appBootManager
    @Environment(AuthManager.self) private var authManager
    @Environment(HomeManager.self) private var homeManager
    @Environment(NotificationsViewModel.self) private var notificationsViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(DashboardViewModel.self) private var dashboardViewModel
    @Environment(ShoppingViewModel.self) private var shoppingViewModel
    @Environment(ExpensesViewModel.self) private var expensesViewModel
    @Environment(BudgetViewModel.self) private var budgetViewModel
    @Environment(ChoresViewModel.self) private var choresViewModel
    @Environment(CalendarViewModel.self) private var calendarViewModel
    @Environment(ActivityViewModel.self) private var activityViewModel
    @Environment(PinboardViewModel.self) private var pinboardViewModel
    @Environment(BudgetTemplateViewModel.self) private var budgetTemplateViewModel
    @Environment(MonthlyMoneyViewModel.self) private var monthlyMoneyViewModel
    @Environment(MoneySettingsViewModel.self) private var moneySettingsViewModel
    @Environment(MemberNamesHelper.self) private var memberNamesHelper
    @Environment(ScrambleModeEnvironment.self) private var scrambleModeEnvironment
    @Environment(SavingsGoalsViewModel.self) private var savingsGoalsViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var showPINSetup = false

    var body: some View {
        ZStack(alignment: .top) {
            if lockManager.isLocked {
                LockScreenView()
            } else if needsBoot {
                SecureLoginLoadingView()
            } else {
                MainTabView()

                if lockManager.migrationNeeded {
                    PINMigrationBanner {
                        showPINSetup = true
                    } onDismiss: {
                        lockManager.consumeMigrationNotice()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, DesignSystem.Spacing.row)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.roostBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.15), value: lockManager.isLocked)
        .animation(DesignSystem.Motion.modalTransition, value: lockManager.migrationNeeded)
        .task(id: bootTaskId) {
            guard !lockManager.isLocked else { return }
            guard let homeId = authManager.homeId,
                  let userId = authManager.currentUser?.id else { return }
            guard !appBootManager.isBooted(homeId: homeId, userId: userId) else { return }
            await bootAuthenticatedApp(homeId: homeId, userId: userId)
        }
        .sheet(isPresented: $showPINSetup) {
            PINSetupView {
                showPINSetup = false
            }
            .environment(lockManager)
            .onDisappear {
                if lockManager.hasPIN {
                    lockManager.consumeMigrationNotice()
                }
            }
        }
    }

    private var needsBoot: Bool {
        guard let homeId = authManager.homeId,
              let userId = authManager.currentUser?.id else {
            return true
        }
        return !appBootManager.isBooted(homeId: homeId, userId: userId)
    }

    private var bootTaskId: String {
        "\(authManager.homeId?.uuidString ?? "no-home")-\(authManager.currentUser?.id.uuidString ?? "no-user")-\(lockManager.isLocked)"
    }

    private func bootAuthenticatedApp(homeId: UUID, userId: UUID) async {
        appBootManager.beginBoot()

        await homeManager.loadHome(homeId: homeId, userId: userId)
        await homeManager.startRealtime(homeId: homeId, userId: userId)

        async let pageWarm: Void = warmPageData(homeId: homeId, userId: userId)
        async let userWarm: Void = warmUserData(userId: userId)
        _ = await (pageWarm, userWarm)

        appBootManager.markBooted(homeId: homeId, userId: userId)
    }

    private func warmPageData(homeId: UUID, userId: UUID) async {
        async let dashboardLoad: Void = dashboardViewModel.load(homeId: homeId)
        async let shoppingLoad: Void = shoppingViewModel.loadItems(homeId: homeId)
        async let expensesLoad: Void = expensesViewModel.loadExpenses(homeId: homeId)
        async let budgetLoad: Void = budgetViewModel.load(homeId: homeId)
        async let choresLoad: Void = choresViewModel.load(homeId: homeId)
        async let calendarLoad: Void = calendarViewModel.load(homeId: homeId)
        async let activityLoad: Void = activityViewModel.loadActivity(homeId: homeId)
        async let pinboardLoad: Void = pinboardViewModel.load(homeId: homeId, userId: userId)
        async let templateLoad: Void = budgetTemplateViewModel.load(homeId: homeId)
        async let monthlyLoad: Void = monthlyMoneyViewModel.loadSummary(homeId: homeId)
        async let settingsLoad: Void = moneySettingsViewModel.load(homeId: homeId)
        async let goalsLoad: Void = savingsGoalsViewModel.load(homeId: homeId)

        _ = await (dashboardLoad, shoppingLoad, expensesLoad, budgetLoad, choresLoad, calendarLoad, activityLoad, pinboardLoad)
        _ = await (templateLoad, monthlyLoad, settingsLoad, goalsLoad)

        memberNamesHelper.load(currentUserId: userId, homeMembers: homeManager.members)
        scrambleModeEnvironment.sync(from: moneySettingsViewModel.settings)

        async let dashboardRealtime: Void = dashboardViewModel.startRealtime(homeId: homeId)
        async let shoppingRealtime: Void = shoppingViewModel.startRealtime(homeId: homeId)
        async let expensesRealtime: Void = expensesViewModel.startRealtime(homeId: homeId)
        async let budgetRealtime: Void = budgetViewModel.startRealtime(homeId: homeId)
        async let choresRealtime: Void = choresViewModel.startRealtime(homeId: homeId)
        async let calendarRealtime: Void = calendarViewModel.startRealtime(homeId: homeId)
        async let activityRealtime: Void = activityViewModel.startRealtime(homeId: homeId)
        async let pinboardRealtime: Void = pinboardViewModel.startRealtime(homeId: homeId, userId: userId)
        async let templateRealtime: Void = budgetTemplateViewModel.startRealtime(homeId: homeId)
        async let monthlyRealtime: Void = monthlyMoneyViewModel.startRealtime(homeId: homeId)
        async let settingsRealtime: Void = moneySettingsViewModel.startRealtime(homeId: homeId)
        async let goalsRealtime: Void = savingsGoalsViewModel.startRealtime(homeId: homeId)

        _ = await (dashboardRealtime, shoppingRealtime, expensesRealtime, budgetRealtime, choresRealtime, calendarRealtime, activityRealtime, pinboardRealtime)
        _ = await (templateRealtime, monthlyRealtime, settingsRealtime, goalsRealtime)
    }

    private func warmUserData(userId: UUID) async {
        notificationsViewModel.isAppActive = scenePhase == .active

        async let notificationsLoad: Void = notificationsViewModel.load(userId: userId)
        async let settingsLoad: Void = settingsViewModel.loadPreferences(for: userId)
        async let notificationAuth: Void = LocalNotificationManager.shared.requestAuthorization()

        _ = await (notificationsLoad, settingsLoad, notificationAuth)

        await notificationsViewModel.startRealtime(userId: userId)
    }
}

private struct PINMigrationBanner: View {
    let onSetup: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.roostPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text("PIN protection upgraded")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)

                Text("Set up your PIN again to use app lock.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            Spacer(minLength: 8)

            Button("Set up PIN", action: onSetup)
                .font(.roostLabel)
                .foregroundStyle(Color.roostPrimary)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 6)
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
        .environment(AppLockManager())
        .environment(AppearanceSettings())
        .environment(NetworkMonitor())
        .environment(AppBootManager())
        .environment(HomeManager())
        .environment(NotificationsViewModel())
        .environment(NotificationRouter())
        .environment(SettingsViewModel())
        .environment(DashboardViewModel())
        .environment(ShoppingViewModel())
        .environment(ExpensesViewModel())
        .environment(BudgetViewModel())
        .environment(ChoresViewModel())
        .environment(CalendarViewModel())
        .environment(ActivityViewModel())
        .environment(PinboardViewModel())
}
