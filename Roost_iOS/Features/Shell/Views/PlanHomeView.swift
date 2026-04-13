import SwiftUI

struct PlanHomeView: View {
    @Environment(NotificationRouter.self) private var notificationRouter

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                picker
                    .frame(maxWidth: .infinity, alignment: .center)

                Group {
                    switch notificationRouter.selectedLifeSection {
                    case .chores:
                        ChoresView(embeddedInParentScroll: true)
                    case .calendar:
                        CalendarView(embeddedInParentScroll: true)
                    case .pinboard:
                        PinboardView(embeddedInParentScroll: true)
                    }
                }
            }
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom + DesignSystem.Spacing.tabContentBottomInset)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var picker: some View {
        PlanSectionPicker(selected: selectedPickerSection) { section in
            notificationRouter.selectedLifeSection = routerSection(for: section)
        }
        .padding(.horizontal, DesignSystem.Spacing.page)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var selectedPickerSection: PlanSectionPicker.Section {
        switch notificationRouter.selectedLifeSection {
        case .chores:
            return .chores
        case .calendar:
            return .calendar
        case .pinboard:
            return .pinboard
        }
    }

    private func routerSection(for section: PlanSectionPicker.Section) -> NotificationRouter.LifeSection {
        switch section {
        case .chores:
            return .chores
        case .calendar:
            return .calendar
        case .pinboard:
            return .pinboard
        }
    }
}

#Preview {
    NavigationStack {
        PlanHomeView()
            .environment(NotificationRouter())
            .environment(HomeManager.previewDashboard())
            .environment(ChoresViewModel())
            .environment(CalendarViewModel())
            .environment(PinboardViewModel())
            .environment(SettingsViewModel())
            .environment(AuthManager())
    }
}
