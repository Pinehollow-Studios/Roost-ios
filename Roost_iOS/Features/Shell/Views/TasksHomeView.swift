import SwiftUI

struct TasksHomeView: View {
    @Environment(NotificationRouter.self) private var notificationRouter

    var body: some View {
        VStack(spacing: 0) {
            TasksSectionPicker(
                selected: notificationRouter.selectedTasksSection
            ) { section in
                notificationRouter.selectedTasksSection = section
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, 4)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity)

            Group {
                switch notificationRouter.selectedTasksSection {
                case .shopping:
                    ShoppingListView()
                case .chores:
                    ChoresView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct TasksSectionPicker: View {
    let selected: NotificationRouter.TasksSection
    let onSelect: (NotificationRouter.TasksSection) -> Void

    var body: some View {
        HStack(spacing: 6) {
            pickerButton(title: "Shopping", icon: "cart", section: .shopping)
            pickerButton(title: "Chores", icon: "checkmark.circle", section: .chores)
        }
        .padding(4)
        .background(Color.roostMuted, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
    }

    private func pickerButton(
        title: String,
        icon: String,
        section: NotificationRouter.TasksSection
    ) -> some View {
        Button {
            guard selected != section else { return }
            onSelect(section)
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))

                Text(title)
                    .font(.roostLabel)
            }
            .foregroundStyle(selected == section ? Color.roostCard : Color.roostMutedForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                    .fill(selected == section ? accent(for: section) : .clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func accent(for section: NotificationRouter.TasksSection) -> Color {
        switch section {
        case .shopping:
            return .roostShoppingTint
        case .chores:
            return .roostChoreTint
        }
    }
}

#Preview {
    NavigationStack {
        TasksHomeView()
            .environment(NotificationRouter())
            .environment(HomeManager.previewDashboard())
            .environment(ShoppingViewModel())
            .environment(ChoresViewModel())
            .environment(HazelViewModel())
            .environment(AuthManager())
    }
}
