import SwiftUI

@MainActor
struct ShoppingListView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(ShoppingViewModel.self) private var sharedViewModel
    @Environment(HazelViewModel.self) private var hazelViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingAddSheet = false
    @State private var showingNextShopSheet = false
    @State private var collapsedCategories: Set<String> = []
    @State private var hasAppeared = false
    @State private var isClearingCompleted = false
    @State private var isSavingNextShopDate = false
    private let previewViewModel: ShoppingViewModel?
    private let homeService = HomeService()

    init(viewModel: ShoppingViewModel? = nil) {
        previewViewModel = viewModel
    }

    private var viewModel: ShoppingViewModel { previewViewModel ?? sharedViewModel }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                FigmaPageHeader(
                    title: "Shopping",
                    subtitle: "\(uncheckedCount) items to buy · Shared live"
                ) {
                    RoostAddPageButton {
                        showingAddSheet = true
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
                .shoppingEntrance(at: 0, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                    nextShopCard
                        .shoppingEntrance(at: 1, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                    if allChecked {
                        allClearCard
                            .shoppingEntrance(at: 2, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
                    }

                    if viewModel.isLoading && viewModel.items.isEmpty {
                        loadingState
                    } else if viewModel.items.isEmpty {
                        emptyState
                    } else {
                        categoriesList
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
            }
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom + 24)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddSheet) {
            AddShoppingItemSheet(
                suggestedCategories: suggestedCategories,
                suggestedQuantities: suggestedQuantities
            ) { name, quantity, category in
                guard let homeId = homeManager.homeId,
                      let userId = homeManager.currentUserId else {
                    viewModel.errorMessage = "Home not loaded yet. Try again in a moment."
                    return
                }
                await viewModel.addItem(
                    name: name,
                    quantity: quantity,
                    category: category,
                    homeId: homeId,
                    userId: userId,
                    hazelEnabled: hazelViewModel.shoppingEnabled
                )
            }
        }
        .sheet(isPresented: $showingNextShopSheet) {
            NextShopDateSheet(
                selectedDate: homeManager.home?.nextShopDateParsed ?? defaultNextShopDate,
                isSaving: isSavingNextShopDate
            ) { date in
                await saveNextShopDate(date)
            }
        }
        .conditionalRefreshable(!showingAddSheet && !showingNextShopSheet) {
            guard let homeId = homeManager.homeId else { return }
            await viewModel.loadItems(homeId: homeId)
        }
        .task {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            if !hasAppeared {
                withAnimation(.roostSmooth) {
                    hasAppeared = true
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostCard)
                    .padding(Spacing.md)
                    .background(Color.roostDestructive, in: Capsule())
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, DesignSystem.Size.toastBottomOffset)
                    .onTapGesture { viewModel.errorMessage = nil }
            }
        }
    }

    private var nextShopCard: some View {
        Button {
            showingNextShopSheet = true
        } label: {
            RoostCard {
                HStack(alignment: .center, spacing: DesignSystem.Spacing.inline) {
                    HStack(alignment: .center, spacing: DesignSystem.Spacing.inline) {
                        Image(systemName: "calendar")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.roostMutedForeground)
                            .frame(width: 28, height: 28)
                            .background(Color.roostAccent, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))

                        Text("Next shop")
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    Spacer(minLength: DesignSystem.Spacing.inline)

                    HStack(spacing: DesignSystem.Spacing.inline) {
                        Text(nextShopTitle)
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                            .lineLimit(1)

                        if let nextShopDate = homeManager.home?.nextShopDateParsed {
                            FigmaChip(title: nextShopChipTitle(for: nextShopDate), variant: nextShopChipVariant(for: nextShopDate))
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(homeManager.homeId == nil || isSavingNextShopDate)
    }

    private var allClearCard: some View {
        RoostCard {
            VStack(spacing: DesignSystem.Spacing.row) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.roostSuccess)

                    Text("All done! Ready for your shop.")
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(Color.roostSuccess)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button {
                    Task { await clearCompleted() }
                } label: {
                    Text(isClearingCompleted ? "Clearing..." : "Clear completed")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostSuccess)
                        .frame(minHeight: 44)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isClearingCompleted)
            }
        }
        .background(Color.roostSuccess.opacity(0.10), in: RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous))
    }

    private var categoriesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(groupedItems.enumerated()), id: \.element.category) { index, group in
                categorySection(group: group)
                    .shoppingEntrance(at: index + 3, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
            }
        }
    }

    private func categorySection(group: (category: String, items: [ShoppingItem])) -> some View {
        let isCollapsed = collapsedCategories.contains(group.category)
        let uncheckedInCategory = group.items.filter { !$0.checked }.count

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.roostEaseOut) {
                    toggleCategory(group.category)
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.row) {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.roostMutedForeground)

                    Text(group.category)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(Color.roostForeground)

                    Spacer(minLength: DesignSystem.Spacing.inline)

                    FigmaChip(title: "\(uncheckedInCategory) \(uncheckedInCategory == 1 ? "item" : "items")")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .background(Color.roostMuted.opacity(0.3), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(group.items) { item in
                        ShoppingItemRow(item: item, addedByName: memberName(for: item.addedBy)) {
                            guard let homeId = homeManager.homeId,
                                  let userId = homeManager.currentUserId else { return }
                            Task { await viewModel.toggleItem(item, homeId: homeId, userId: userId) }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                guard let homeId = homeManager.homeId,
                                      let userId = homeManager.currentUserId else { return }
                                Task { await viewModel.deleteItem(item, homeId: homeId, userId: userId) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(0..<4, id: \.self) { _ in
                LoadingSkeletonView()
                    .frame(height: 92)
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "cart",
            title: "Your list is empty",
            message: "Add items above and they’ll appear here.",
            eyebrow: "Shopping",
            actionTitle: "Add your first item"
        ) {
            showingAddSheet = true
        }
        .shoppingEntrance(at: 3, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
    }

    private var allChecked: Bool {
        !viewModel.items.isEmpty && uncheckedCount == 0
    }

    private var uncheckedCount: Int {
        uncheckedItems.count
    }

    private var checkedItems: [ShoppingItem] {
        viewModel.items.filter(\.checked)
    }

    private var uncheckedItems: [ShoppingItem] {
        viewModel.items.filter { !$0.checked }
    }

    private var groupedItems: [(category: String, items: [ShoppingItem])] {
        let grouped = Dictionary(grouping: viewModel.items) { item in
            (item.category?.isEmpty == false) ? item.category! : "Other"
        }
        return grouped
            .sorted { $0.key == "Other" ? true : ($1.key == "Other" ? false : $0.key < $1.key) }
            .map { category, items in
                (
                    category: category,
                    items: items.sorted { lhs, rhs in
                        if lhs.checked != rhs.checked {
                            return lhs.checked == false
                        }
                        return lhs.createdAt < rhs.createdAt
                    }
                )
            }
    }

    private static let baseCategories: [String] = [
        "Produce", "Dairy", "Bakery", "Meat & Fish",
        "Frozen", "Drinks", "Snacks", "Household", "Personal Care"
    ]

    private var suggestedCategories: [String] {
        let fromItems = Set(
            viewModel.items
                .compactMap(\.category)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
        let baseCategorySet = Set(Self.baseCategories)
        let extra = fromItems.subtracting(baseCategorySet).sorted()
        return Self.baseCategories + extra
    }

    private var suggestedQuantities: [String] {
        Array(
            Set(
                viewModel.items
                    .compactMap(\.quantity)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }

    private var nextShopTitle: String {
        guard let nextShopDate = homeManager.home?.nextShopDateParsed else {
            return "Set your next shop date"
        }
        return settingsDate(nextShopDate)
    }

    private func nextShopChipTitle(for date: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: date)).day ?? 0
        switch days {
        case ..<0:
            return "Overdue"
        case 0:
            return "Today!"
        case 1:
            return "Tomorrow"
        default:
            return "In \(days) days"
        }
    }

    private func nextShopChipVariant(for date: Date) -> FigmaChip.Variant {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: date)).day ?? 0
        switch days {
        case ..<0:
            return .destructive
        case 0...3:
            return .warning
        default:
            return .success
        }
    }

    private func settingsDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    private var defaultNextShopDate: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    }

    private func saveNextShopDate(_ date: Date) async {
        guard let homeId = homeManager.homeId, !isSavingNextShopDate else { return }

        isSavingNextShopDate = true
        defer { isSavingNextShopDate = false }

        do {
            try await homeService.updateNextShopDate(homeId: homeId, date: date)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            if homeManager.home != nil {
                homeManager.home?.nextShopDate = formatter.string(from: date)
            }

            showingNextShopSheet = false
        } catch {
            viewModel.errorMessage = "Couldn’t update the next shop date."
        }
    }

    private func clearCompleted() async {
        guard let homeId = homeManager.homeId,
              let userId = homeManager.currentUserId else {
            return
        }

        isClearingCompleted = true
        let completedItems = checkedItems
        for item in completedItems {
            await viewModel.deleteItem(item, homeId: homeId, userId: userId)
        }
        isClearingCompleted = false
    }

    private func toggleCategory(_ category: String) {
        if collapsedCategories.contains(category) {
            collapsedCategories.remove(category)
        } else {
            collapsedCategories.insert(category)
        }
    }

    private func memberName(for userId: UUID?) -> String? {
        guard let userId else { return nil }
        if userId == homeManager.currentUserId { return homeManager.currentMember?.displayName ?? "You" }
        if userId == homeManager.partner?.userID { return homeManager.partner?.displayName }
        return homeManager.members.first(where: { $0.userID == userId })?.displayName
    }

}

private struct NextShopDateSheet: View {
    let selectedDate: Date
    let isSaving: Bool
    let onPickDate: (Date) async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draftDate: Date

    init(selectedDate: Date, isSaving: Bool, onPickDate: @escaping (Date) async -> Void) {
        self.selectedDate = selectedDate
        self.isSaving = isSaving
        self.onPickDate = onPickDate
        _draftDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                RoostSheetHeader(
                    title: "Next Shop",
                    subtitle: "Pick the next shopping date for your household."
                ) {
                    dismiss()
                }

                DatePicker(
                    "Next shop date",
                    selection: $draftDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(.roostPrimary)
                .frame(maxWidth: .infinity)
                .disabled(isSaving)
                .onChange(of: draftDate) { _, newValue in
                    guard !isSaving else { return }
                    Task {
                        await onPickDate(newValue)
                    }
                }

                if isSaving {
                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.roostPrimary)

                        Text("Saving date…")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.roostBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.hidden)
    }
}

private struct ShoppingEntranceModifier: ViewModifier {
    let index: Int
    let hasAppeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: reduceMotion || hasAppeared ? 0 : CGFloat(18 + (index * 4)))
            .animation(reduceMotion ? nil : .roostSmooth.delay(Double(index) * 0.04), value: hasAppeared)
    }
}

private extension View {
    func shoppingEntrance(at index: Int, hasAppeared: Bool, reduceMotion: Bool) -> some View {
        modifier(ShoppingEntranceModifier(index: index, hasAppeared: hasAppeared, reduceMotion: reduceMotion))
    }
}

#Preview {
    ShoppingListView(viewModel: .previewShopping)
        .environment(HomeManager.previewDashboard())
        .environment(SettingsViewModel())
}

private extension ShoppingViewModel {
    static var previewShopping: ShoppingViewModel {
        let homeId = UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID()
        let userId = UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID()
        let partnerId = UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID()

        return ShoppingViewModel(items: [
            ShoppingItem(id: UUID(), homeID: homeId, name: "Milk", quantity: "2", category: "Dairy", checked: false, addedBy: userId, checkedBy: nil, createdAt: .now.addingTimeInterval(-900), updatedAt: nil),
            ShoppingItem(id: UUID(), homeID: homeId, name: "Bananas", quantity: "6", category: "Fruit", checked: false, addedBy: partnerId, checkedBy: nil, createdAt: .now.addingTimeInterval(-3600), updatedAt: nil),
            ShoppingItem(id: UUID(), homeID: homeId, name: "Pasta", quantity: "1", category: "Pantry", checked: true, addedBy: userId, checkedBy: partnerId, createdAt: .now.addingTimeInterval(-7200), updatedAt: nil),
            ShoppingItem(id: UUID(), homeID: homeId, name: "Kitchen roll", quantity: "2", category: "Household", checked: false, addedBy: partnerId, checkedBy: nil, createdAt: .now.addingTimeInterval(-18000), updatedAt: nil)
        ])
    }
}
