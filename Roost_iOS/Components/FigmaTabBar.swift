import SwiftUI

struct FigmaTabBar: View {
    @Binding var selectedTab: NotificationRouter.AppTab
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { item in
                Button {
                    guard selectedTab != item.tab else { return }
                    withAnimation(DesignSystem.Motion.tabSwitch) {
                        selectedTab = item.tab
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            // Pill + icon layer
                            ZStack {
                                if selectedTab == item.tab {
                                    Capsule()
                                        .fill(Color.roostPrimary.opacity(0.11))
                                        .matchedGeometryEffect(id: "tabSelectionPill", in: tabNamespace)
                                }

                                tabIcon(for: item)
                            }
                            .frame(width: 50, height: 30)

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
                                    ? Color.roostPrimary
                                    : Color.roostMutedForeground
                            )
                            .animation(DesignSystem.Motion.tabSwitch, value: selectedTab == item.tab)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .frame(maxHeight: .infinity, alignment: .top)
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
            Color.roostCard
                .shadow(
                    color: DesignSystem.Shadow.tabBarColor,
                    radius: DesignSystem.Shadow.tabBarRadius,
                    x: 0,
                    y: DesignSystem.Shadow.tabBarYOffset
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.roostHairline)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    private func tabIcon(for item: TabItem) -> some View {
        if item == .more {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(selectedTab == item.tab ? Color.roostPrimary : Color.roostMutedForeground)
                        .frame(width: 4, height: 4)
                }
            }
            .animation(DesignSystem.Motion.tabSwitch, value: selectedTab == item.tab)
        } else {
            Image(systemName: selectedTab == item.tab ? item.activeSymbol : item.symbol)
                .font(.system(size: 20, weight: selectedTab == item.tab ? .semibold : .regular))
                .foregroundStyle(selectedTab == item.tab ? Color.roostPrimary : Color.roostMutedForeground)
                .animation(DesignSystem.Motion.tabSwitch, value: selectedTab == item.tab)
        }
    }
}

private extension FigmaTabBar {
    enum TabItem: CaseIterable {
        case home
        case shopping
        case money
        case plan
        case more

        var tab: NotificationRouter.AppTab {
            switch self {
            case .home: .home
            case .shopping: .shopping
            case .money: .money
            case .plan: .life
            case .more: .more
            }
        }

        var title: String {
            switch self {
            case .home: "Home"
            case .shopping: "Shopping"
            case .money: "Money"
            case .plan: "Plan"
            case .more: "More"
            }
        }

        var symbol: String {
            switch self {
            case .home: "house"
            case .shopping: "cart"
            case .money: "creditcard"
            case .plan: "checkmark.circle"
            case .more: "ellipsis"
            }
        }

        var activeSymbol: String {
            switch self {
            case .home: "house.fill"
            case .shopping: "cart.fill"
            case .money: "creditcard.fill"
            case .plan: "checkmark.circle.fill"
            case .more: "ellipsis"
            }
        }

        var badge: Int? {
            switch self {
            case .shopping: 3
            case .plan: 2
            default: nil
            }
        }

        var badgeColor: Color {
            .roostPrimary
        }
    }
}
