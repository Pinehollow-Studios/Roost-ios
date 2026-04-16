import SwiftUI

struct ActivityFeedView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(ActivityViewModel.self) private var sharedViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasAnimatedIn = false
    private let previewViewModel: ActivityViewModel?

    init(viewModel: ActivityViewModel? = nil) {
        previewViewModel = viewModel
    }

    private var viewModel: ActivityViewModel { previewViewModel ?? sharedViewModel }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Activity", accent: .roostPrimary)

                if viewModel.isLoading && viewModel.items.isEmpty {
                    loadingCard
                        .modifier(ActivityEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                } else if viewModel.items.isEmpty {
                    emptyCard
                        .modifier(ActivityEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                } else {
                    RoostCard {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: DesignSystem.Spacing.inline) {
                                ZStack {
                                    Circle()
                                        .fill(Color.roostPrimary.opacity(0.10))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.roostPrimary)
                                }
                                Text("Latest updates")
                                    .font(.roostCardTitle)
                                    .foregroundStyle(Color.roostForeground)
                            }
                            .padding(.bottom, DesignSystem.Spacing.row)

                            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                                ActivityRow(
                                    item: item,
                                    member: member(for: item.userID),
                                    memberName: memberName(for: item.userID)
                                )
                                .modifier(ActivityEntranceModifier(index: index, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

                                if item.id != viewModel.items.last?.id {
                                    Divider()
                                        .overlay(Color.roostHairline)
                                        .padding(.leading, 44)
                                }
                            }
                        }
                    }
                    .modifier(ActivityEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
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
        .refreshable {
            guard let homeId = homeManager.homeId else { return }
            await viewModel.loadActivity(homeId: homeId)
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
        .overlay(alignment: .bottom) {
            if let error = viewModel.errorMessage {
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
                    .onTapGesture { viewModel.errorMessage = nil }
            }
        }
    }

    private var loadingCard: some View {
        VStack(spacing: DesignSystem.Spacing.inline) {
            ForEach(0..<4, id: \.self) { _ in
                LoadingSkeletonView()
                    .frame(height: 100)
            }
        }
    }

    private var emptyCard: some View {
        EmptyStateView(
            icon: "clock.arrow.circlepath",
            title: "No activity yet",
            message: "",
            eyebrow: "Activity"
        )
    }

    private func memberName(for userId: UUID) -> String {
        member(for: userId)?.displayName ?? "Roost"
    }

    private func member(for userId: UUID) -> HomeMember? {
        homeManager.members.first(where: { $0.userID == userId })
    }
}

private struct ActivityEntranceModifier: ViewModifier {
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

#Preview("Activity") {
    let homeManager = HomeManager.previewDashboard()
    let homeId = homeManager.homeId ?? UUID()
    let userId = homeManager.currentMember?.userID ?? UUID()
    let partnerId = homeManager.partner?.userID ?? UUID()

    let items = [
        ActivityFeedItem(id: UUID(), homeID: homeId, userID: userId, action: "Added milk to Shopping", entityType: "shopping", entityID: nil, metadata: nil, createdAt: .now),
        ActivityFeedItem(id: UUID(), homeID: homeId, userID: partnerId, action: "Completed Bathroom clean", entityType: "chore", entityID: nil, metadata: nil, createdAt: Calendar.current.date(byAdding: .hour, value: -4, to: .now) ?? .now),
        ActivityFeedItem(id: UUID(), homeID: homeId, userID: userId, action: "Logged Electric bill", entityType: "expense", entityID: nil, metadata: nil, createdAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
    ]

    NavigationStack {
        ActivityFeedView(viewModel: ActivityViewModel(items: items))
            .environment(homeManager)
    }
}
