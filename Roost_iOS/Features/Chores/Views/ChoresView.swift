import SwiftUI

struct ChoresView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(NotificationRouter.self) private var notificationRouter
    @Environment(ChoresViewModel.self) private var sharedViewModel
    @Environment(HazelViewModel.self) private var hazelViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingAddSheet = false
    @State private var showingSuggestSheet = false
    @State private var suggestedChores: [String] = []
    @State private var isFetchingSuggestions = false
    @State private var hasAnimatedIn = false
    @State private var selectedFilter: PersonFilter = .everyone
    private let embeddedInParentScroll: Bool
    private let previewViewModel: ChoresViewModel?

    private enum PersonFilter: String, CaseIterable, Identifiable {
        case everyone = "All chores"
        case me = "Mine"
        case partner = "Partner"

        var id: String { rawValue }
    }

    @MainActor
    init(viewModel: ChoresViewModel? = nil, embeddedInParentScroll: Bool = false) {
        previewViewModel = viewModel
        self.embeddedInParentScroll = embeddedInParentScroll
    }

    private var viewModel: ChoresViewModel { previewViewModel ?? sharedViewModel }
    private var myUserId: UUID? { homeManager.currentUserId }
    private var partnerUserId: UUID? { homeManager.partner?.userID }
    private var myName: String { homeManager.currentMember?.displayName ?? "You" }
    private var partnerName: String? { homeManager.partner?.displayName }
    private var overdueChores: [Chore] {
        filteredChores.filter(\.isOverdue)
    }

    private var upcomingChores: [Chore] {
        filteredChores.filter { !$0.isCompleted && !$0.isOverdue }
    }

    private var completedChores: [Chore] {
        filteredChores.filter(\.isCompleted)
    }

    private var filteredChores: [Chore] {
        switch selectedFilter {
        case .everyone:
            return viewModel.sortedChores
        case .me:
            return viewModel.sortedChores.filter { $0.assignedTo == myUserId }
        case .partner:
            return viewModel.sortedChores.filter { $0.assignedTo == partnerUserId }
        }
    }

    var body: some View {
        Group {
            if embeddedInParentScroll {
                content
            } else {
                ScrollView(showsIndicators: false) {
                    content
                        .padding(.bottom, 120 + DesignSystem.Spacing.tabContentBottomInset)
                }
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddSheet) {
            if let myUserId {
                AddChoreSheet(
                    myName: myName,
                    partnerName: partnerName,
                    myUserId: myUserId,
                    partnerUserId: partnerUserId,
                    suggestedRooms: viewModel.rooms.map(\.name)
                ) { title, description, assignedTo, frequency, dueDate, room in
                    guard let homeId = homeManager.homeId else { return }
                    await viewModel.addChore(
                        title: title,
                        description: description,
                        assignedTo: assignedTo,
                        frequency: frequency,
                        dueDate: dueDate,
                        room: room,
                        homeId: homeId,
                        userId: myUserId,
                        hazelEnabled: hazelViewModel.choresEnabled
                    )
                }
            }
        }
        .sheet(isPresented: $showingSuggestSheet) {
            ChoreSuggestionsSheet(
                suggestions: suggestedChores,
                isLoading: isFetchingSuggestions
            ) { title in
                guard let myUserId, let homeId = homeManager.homeId else { return }
                await viewModel.addChore(
                    title: title,
                    description: nil,
                    assignedTo: nil,
                    frequency: "weekly",
                    dueDate: nil,
                    room: nil,
                    homeId: homeId,
                    userId: myUserId,
                    hazelEnabled: hazelViewModel.choresEnabled
                )
            }
        }
        .conditionalRefreshable(!showingAddSheet) {
            guard let homeId = homeManager.homeId else { return }
            await viewModel.load(homeId: homeId)
        }
        .task {
            guard !reduceMotion else {
                hasAnimatedIn = true
                return
            }
            withAnimation(.roostSmooth) {
                hasAnimatedIn = true
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

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
            if !embeddedInParentScroll {
                PlanSectionPicker(selected: .chores) { section in
                    navigateTo(section)
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(ChoresEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
            }

            FigmaPageHeader(
                title: "Chores",
                subtitle: "\(activeChoreCount) active · \(completedChores.count) done this week"
            ) {
                HStack(spacing: 8) {
                    if hazelViewModel.choresEnabled {
                        Button {
                            Task { await fetchSuggestions() }
                        } label: {
                            HStack(spacing: 4) {
                                if isFetchingSuggestions {
                                    ProgressView()
                                        .controlSize(.mini)
                                        .tint(Color.roostPrimary)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                Text("Suggest")
                                    .font(.roostLabel)
                            }
                            .foregroundStyle(Color.roostPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.roostPrimary.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(isFetchingSuggestions)
                    }

                    RoostAddPageButton {
                        showingAddSheet = true
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .modifier(ChoresEntranceModifier(index: 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            filterRow
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(ChoresEntranceModifier(index: 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            if viewModel.isLoading && viewModel.chores.isEmpty {
                loadingState
            } else if filteredChores.isEmpty {
                emptyStateCard
            } else {
                if !overdueChores.isEmpty {
                    overdueSection
                        .modifier(ChoresEntranceModifier(index: 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                }

                if !upcomingChores.isEmpty {
                    choresSection(title: "Upcoming", chores: upcomingChores, indexOffset: 3)
                }

                if !completedChores.isEmpty {
                    completedSection
                        .modifier(ChoresEntranceModifier(index: 6, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                }
            }
        }
        .padding(.top, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenTop)
        .padding(.bottom, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenBottom + DesignSystem.Spacing.tabContentBottomInset)
        .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PersonFilter.allCases) { filter in
                    FigmaSelectablePill(
                        title: label(for: filter),
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
        }
    }

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.roostDestructive)

                Text("OVERDUE")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostMutedForeground)
                    .tracking(0.8)

                Spacer(minLength: 0)

                FigmaChip(title: "\(overdueChores.count)", variant: .destructive)
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.vertical, 8)
            .background(Color.roostDestructive.opacity(0.08))

            VStack(spacing: 8) {
                ForEach(Array(overdueChores.enumerated()), id: \.element.id) { index, chore in
                    choreRow(chore, index: index + 2)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
        }
    }

    private func choresSection(title: String, chores: [Chore], indexOffset: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.roostLabel)
                .foregroundStyle(Color.roostMutedForeground)
                .tracking(0.8)
                .padding(.horizontal, DesignSystem.Spacing.page + 1)

            VStack(spacing: 8) {
                ForEach(Array(chores.enumerated()), id: \.element.id) { index, chore in
                    choreRow(chore, index: indexOffset + index)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("COMPLETED")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostMutedForeground)
                    .tracking(0.8)

                Spacer(minLength: 0)

                Button {
                    Task { await clearCompleted() }
                } label: {
                    Text("Clear all")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostSuccess)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.page + 1)

            VStack(spacing: 8) {
                ForEach(Array(completedChores.enumerated()), id: \.element.id) { index, chore in
                    choreRow(chore, index: index + 7)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
        }
    }

    private func choreRow(_ chore: Chore, index: Int) -> some View {
        ChoreRow(
            chore: chore,
            assignedMember: member(for: chore.assignedTo),
            assignedName: memberName(for: chore.assignedTo),
            lastCompletedText: lastCompletedText(for: chore),
            streak: viewModel.streak(for: chore)
        ) {
            guard let myUserId, let homeId = homeManager.homeId else { return }
            Task {
                await viewModel.toggleCompletion(chore, currentUserId: myUserId, homeId: homeId)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                guard let homeId = homeManager.homeId, let myUserId else { return }
                Task { await viewModel.deleteChore(chore, homeId: homeId, userId: myUserId) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .modifier(ChoresEntranceModifier(index: index, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
    }

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<4, id: \.self) { _ in
                LoadingSkeletonView()
                    .frame(height: 96)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.page)
    }

    private var emptyStateCard: some View {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "No chores yet",
            message: "Add the first recurring task so nothing household-related has to live in memory.",
            eyebrow: "Chores",
            actionTitle: "Add first chore"
        ) {
            showingAddSheet = true
        }
        .padding(.horizontal, DesignSystem.Spacing.page)
    }

    private var activeChoreCount: Int {
        filteredChores.filter { !$0.isCompleted }.count
    }

    private func label(for filter: PersonFilter) -> String {
        switch filter {
        case .everyone:
            return "All chores"
        case .me:
            return "Mine"
        case .partner:
            if let partnerName {
                return "\(partnerName)’s"
            }
            return "Partner’s"
        }
    }

    private func clearCompleted() async {
        guard let homeId = homeManager.homeId,
              let userId = myUserId else {
            return
        }

        let choresToDelete = completedChores
        for chore in choresToDelete {
            await viewModel.deleteChore(chore, homeId: homeId, userId: userId)
        }
    }

    private func memberName(for userId: UUID?) -> String? {
        guard let userId else { return nil }
        if userId == myUserId { return "You" }
        if userId == partnerUserId { return partnerName }
        return member(for: userId)?.displayName
    }

    private func member(for userId: UUID?) -> HomeMember? {
        guard let userId else { return nil }
        return homeManager.members.first(where: { $0.userID == userId })
    }

    private func lastCompletedText(for chore: Chore) -> String? {
        if let completedBy = chore.completedBy {
            let completedName = memberName(for: completedBy) ?? "Someone"
            if let lastCompletedAt = chore.lastCompletedAt {
                return "Last done by \(completedName) \(lastCompletedAt.formatted(.relative(presentation: .named)))"
            }
            return "Last done by \(completedName)"
        }

        guard let latest = viewModel.completionHistory(for: chore.id).first else {
            return nil
        }

        return "Last done \(latest.createdAt.formatted(.relative(presentation: .named)))"
    }

    private func fetchSuggestions() async {
        guard let homeId = homeManager.homeId, !isFetchingSuggestions else { return }
        isFetchingSuggestions = true
        suggestedChores = await viewModel.suggestChores(homeId: homeId)
        isFetchingSuggestions = false
        if !suggestedChores.isEmpty {
            showingSuggestSheet = true
        }
    }

    private func navigateTo(_ section: PlanSectionPicker.Section) {
        switch section {
        case .chores:
            notificationRouter.selectedLifeSection = .chores
        case .calendar:
            notificationRouter.selectedLifeSection = .calendar
        case .pinboard:
            notificationRouter.selectedLifeSection = .pinboard
        }
    }
}

// MARK: - Hazel Suggestions Sheet

private struct ChoreSuggestionsSheet: View {
    let suggestions: [String]
    let isLoading: Bool
    let onAdd: (String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var addedTitles: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    RoostSheetHeader(
                        title: "Hazel Suggests",
                        subtitle: "Tap any chore to add it to your list instantly."
                    ) {
                        dismiss()
                    }

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(Color.roostPrimary)
                            Spacer()
                        }
                        .padding(.top, Spacing.xl)
                    } else if suggestions.isEmpty {
                        Text("No suggestions available right now.")
                            .font(.roostBody)
                            .foregroundStyle(Color.roostMutedForeground)
                            .padding(.horizontal, Spacing.md)
                    } else {
                        VStack(spacing: Spacing.sm) {
                            ForEach(suggestions, id: \.self) { title in
                                let added = addedTitles.contains(title)
                                Button {
                                    guard !added else { return }
                                    addedTitles.insert(title)
                                    Task { await onAdd(title) }
                                } label: {
                                    HStack(spacing: Spacing.md) {
                                        Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundStyle(added ? Color.roostSuccess : Color.roostPrimary)

                                        Text(title)
                                            .font(.roostBody)
                                            .foregroundStyle(Color.roostForeground)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                            .fill(added ? Color.roostSuccess.opacity(0.08) : Color.roostInput)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                            .stroke(added ? Color.roostSuccess.opacity(0.3) : Color.roostHairline, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(added)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, 60)
            }
            .background(Color.roostBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

private struct ChoresEntranceModifier: ViewModifier {
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

#Preview("Chores") {
    let homeManager = HomeManager.previewDashboard()
    let myId = homeManager.currentUserId ?? UUID()
    let partnerId = homeManager.partner?.userID ?? UUID()
    let homeId = homeManager.homeId ?? UUID()
    let settingsViewModel = SettingsViewModel()

    let previewChores = [
        Chore(id: UUID(), homeID: homeId, title: "Take bins out", description: "Before collection tomorrow morning", room: "Outside", assignedTo: myId, dueDate: Calendar.current.date(byAdding: .day, value: -1, to: .now), completedBy: nil, frequency: "weekly", lastCompletedAt: nil, createdAt: .now),
        Chore(id: UUID(), homeID: homeId, title: "Wipe kitchen sides", description: nil, room: "Kitchen", assignedTo: partnerId, dueDate: .now, completedBy: nil, frequency: "daily", lastCompletedAt: nil, createdAt: .now),
        Chore(id: UUID(), homeID: homeId, title: "Vacuum living room", description: nil, room: "Living Room", assignedTo: nil, dueDate: Calendar.current.date(byAdding: .day, value: 2, to: .now), completedBy: nil, frequency: "weekly", lastCompletedAt: nil, createdAt: .now),
        Chore(id: UUID(), homeID: homeId, title: "Clean bathroom mirror", description: nil, room: "Bathroom", assignedTo: myId, dueDate: Calendar.current.date(byAdding: .day, value: 7, to: .now), completedBy: myId, frequency: "weekly", lastCompletedAt: .now, createdAt: .now)
    ]

    return NavigationStack {
        ChoresView(viewModel: ChoresViewModel(chores: previewChores))
            .environment(homeManager)
            .environment(NotificationRouter())
            .environment(settingsViewModel)
    }
}
