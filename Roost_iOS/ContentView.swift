//
//  ContentView.swift
//  Roost_iOS
//
//  Created by Tom Slater on 25/03/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(AppLockManager.self) private var lockManager
    @Environment(AppearanceSettings.self) private var appearanceSettings
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(ResumeSnapshotStore.self) private var resumeSnapshotStore
    @Environment(\.scenePhase) private var scenePhase

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
                        MainTabView()
                    } else {
                        RoostLoadingView(message: "Checking your home…")
                    }
                } else {
                    NavigationStack { WelcomeView() }
                }
            }

            OfflineBanner(isVisible: !networkMonitor.isConnected)

            if let snapshot = resumeSnapshotStore.snapshotImage,
               resumeSnapshotStore.isShowingSnapshot,
               authManager.isAuthenticated {
                Image(uiImage: snapshot)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if authManager.isAuthenticated && lockManager.isLocked {
                LockScreenView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(999)
            }
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
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .inactive, .background:
                resumeSnapshotStore.captureCurrentWindow()
            case .active:
                resumeSnapshotStore.showForResume()
            @unknown default:
                break
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                resumeSnapshotStore.clear()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
        .environment(AppearanceSettings())
        .environment(NetworkMonitor())
        .environment(ResumeSnapshotStore())
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
