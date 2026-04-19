import SwiftUI

struct FigmaTabBar: View {
    @Binding var selectedTab: NotificationRouter.AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { item in
                Button {
                    guard selectedTab != item.tab else { return }
                    selectedTab = item.tab
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                if selectedTab == item.tab {
                                    Capsule()
                                        .fill(item.accent.opacity(0.12))
                                }

                                tabIcon(for: item)
                            }
                            .frame(width: 50, height: 28)

                            // Badge
                            if let badge = item.badge {
                                Text("\(badge)")
                                    .font(.roostTabLabel)
                                    .foregroundStyle(Color.roostCard)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .padding(.horizontal, badge > 9 ? 3 : 0)
                                    .background(item.badgeColor, in: Capsule())
                                    .offset(x: 2, y: -3)
                            }
                        }

                        Text(item.title)
                            .font(.roostTabLabel)
                            .foregroundStyle(
                                selectedTab == item.tab
                                    ? item.accent
                                    : Color.roostMutedForeground
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
        .frame(maxWidth: .infinity)
        .frame(height: DesignSystem.Size.tabBarHeight)
        .background {
            // The card's rounded top corners are drawn via UnevenRoundedRectangle.
            // The 1pt hairline sits as an overlay on the same shape so it's
            // clipped automatically to the curved corners — previously it was
            // a separate sibling `Rectangle` that bled past the curve edges.
            let shape = UnevenRoundedRectangle(
                topLeadingRadius: DesignSystem.Radius.xl,
                topTrailingRadius: DesignSystem.Radius.xl,
                style: .continuous
            )

            shape
                .fill(Color.roostCard)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.roostHairline)
                        .frame(height: 1)
                }
                .clipShape(shape)
                .shadow(
                    color: DesignSystem.Shadow.tabBarColor,
                    radius: DesignSystem.Shadow.tabBarRadius,
                    x: 0,
                    y: DesignSystem.Shadow.tabBarYOffset
                )
                .ignoresSafeArea(edges: .bottom)
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
            transaction.animation = nil
        }
    }

    @ViewBuilder
    private func tabIcon(for item: TabItem) -> some View {
        if item == .more {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(selectedTab == item.tab ? item.accent : Color.roostMutedForeground)
                        .frame(width: 3, height: 3)
                }
            }
        } else {
            Image(systemName: selectedTab == item.tab ? item.activeSymbol : item.symbol)
                .font(.system(size: 20, weight: selectedTab == item.tab ? .semibold : .regular))
                .foregroundStyle(selectedTab == item.tab ? item.accent : Color.roostMutedForeground)
        }
    }
}

private extension FigmaTabBar {
    enum TabItem: CaseIterable {
        case home
        case money
        case shopping
        case chores
        case more

        var tab: NotificationRouter.AppTab {
            switch self {
            case .home: .home
            case .money: .money
            case .shopping: .shopping
            case .chores: .chores
            case .more: .more
            }
        }

        var title: String {
            switch self {
            case .home: "Home"
            case .money: "Money"
            case .shopping: "Shop"
            case .chores: "Chores"
            case .more: "More"
            }
        }

        var symbol: String {
            switch self {
            case .home: "house"
            case .money: "dollarsign.circle"
            case .shopping: "cart"
            case .chores: "checkmark.circle"
            case .more: "ellipsis"
            }
        }

        var activeSymbol: String {
            switch self {
            case .home: "house.fill"
            case .money: "dollarsign.circle.fill"
            case .shopping: "cart.fill"
            case .chores: "checkmark.circle.fill"
            case .more: "ellipsis"
            }
        }

        var accent: Color {
            switch self {
            case .home:
                return .roostPrimary
            case .money:
                return .roostMoneyTint
            case .shopping:
                return .roostShoppingTint
            case .chores:
                return .roostChoreTint
            case .more:
                return .roostPrimary
            }
        }

        var badge: Int? {
            nil
        }

        var badgeColor: Color {
            .roostPrimary
        }
    }
}
