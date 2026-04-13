import SwiftUI

struct NotificationsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(NotificationsViewModel.self) private var viewModel
    @Environment(NotificationRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasAnimatedIn = false

    var body: some View {
        RoostPageContainer(title: "Notifications", subtitle: nil) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    loadingCard
                        .modifier(NotificationEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                } else if viewModel.notifications.isEmpty {
                    emptyCard
                        .modifier(NotificationEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                } else {
                    actionBar
                        .modifier(NotificationEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

                    RoostSectionSurface(emphasis: .subtle) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                        SectionHeader(
                            title: "All notifications"
                        )

                        ForEach(Array(viewModel.notifications.enumerated()), id: \.element.id) { index, notification in
                            Button {
                                Task {
                                    await viewModel.markAsRead(notification)
                                    router.route(notification: notification)
                                }
                            } label: {
                                NotificationRow(notification: notification)
                            }
                            .buttonStyle(.plain)
                            .modifier(NotificationEntranceModifier(index: index + 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

                            if notification.id != viewModel.notifications.last?.id {
                                Divider()
                                    .overlay(Color.roostHairline)
                                    .padding(.leading, 48)
                            }
                        }
                    }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .task(id: authManager.currentUser?.id) {
            guard let userId = authManager.currentUser?.id else { return }
            await viewModel.load(userId: userId)
            await viewModel.startRealtime(userId: userId)
        }
        .refreshable {
            guard let userId = authManager.currentUser?.id else { return }
            await viewModel.load(userId: userId)
        }
        .task {
            guard !hasAnimatedIn else { return }
            if reduceMotion {
                hasAnimatedIn = true
            } else {
                withAnimation(.roostSmooth) {
                    hasAnimatedIn = true
                }
            }
        }
        .onDisappear {
            Task { await viewModel.stopRealtime() }
        }
        .overlay(alignment: .bottom) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostCard)
                    .padding(Spacing.md)
                    .background(Color.roostDestructive.cornerRadius(RoostTheme.controlCornerRadius))
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, DesignSystem.Size.toastBottomOffset)
                    .onTapGesture { viewModel.errorMessage = nil }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: Spacing.md) {
            Text("\(viewModel.unreadCount) unread")
                .font(.roostLabel)
                .foregroundStyle(Color.roostForeground)

            Spacer()

            if let userId = authManager.currentUser?.id, viewModel.unreadCount > 0 {
                Button {
                    Task { await viewModel.markAllAsRead(userId: userId) }
                } label: {
                    Text("Mark all read")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostPrimary)
                        .padding(.horizontal, Spacing.md)
                        .frame(minHeight: 44)
                        .background(Color.roostPrimary.opacity(0.10), in: Capsule())
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingCard: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<4, id: \.self) { _ in
                LoadingSkeletonView()
                    .frame(height: 92)
            }
        }
    }

    private var emptyCard: some View {
        EmptyStateView(
            icon: "bell",
            title: "No notifications yet",
            message: "",
            eyebrow: "Inbox"
        )
    }

}

private struct NotificationEntranceModifier: ViewModifier {
    let index: Int
    let hasAnimatedIn: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hasAnimatedIn ? 1 : 0)
            .offset(y: hasAnimatedIn || reduceMotion ? 0 : 20)
            .scaleEffect(hasAnimatedIn || reduceMotion ? 1 : 0.98)
            .animation(
                reduceMotion ? nil : .roostSmooth.delay(Double(index) * 0.04),
                value: hasAnimatedIn
            )
    }
}

private struct NotificationsPreviewContainer: View {
    let authManager: AuthManager
    let viewModel: NotificationsViewModel
    let router = NotificationRouter()

    init() {
        let authManager = AuthManager()
        let userId = UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID()
        authManager.currentUser = AuthUser(id: userId, email: "tom@roost.app", displayName: "Tom")

        self.authManager = authManager
        self.viewModel = NotificationsViewModel(
            notifications: [
                AppNotification(id: UUID(), userID: userId, homeID: UUID(), title: "Jess added bread to Shopping", type: "shopping", read: false, entityID: nil, createdAt: .now),
                AppNotification(id: UUID(), userID: userId, homeID: UUID(), title: "Electric bill was logged", type: "expense", read: false, entityID: nil, createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now),
                AppNotification(id: UUID(), userID: userId, homeID: UUID(), title: "Bathroom clean was completed", type: "chore", read: true, entityID: nil, createdAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
            ]
        )
    }

    var body: some View {
        NavigationStack {
            NotificationsView()
                .environment(authManager)
                .environment(viewModel)
                .environment(router)
        }
    }
}

#Preview("Notifications") {
    NotificationsPreviewContainer()
}
