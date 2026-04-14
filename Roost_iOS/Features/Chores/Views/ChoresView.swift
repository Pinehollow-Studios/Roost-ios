import SwiftUI

struct ChoresView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(ChoresViewModel.self) private var sharedViewModel
    @Environment(HazelViewModel.self) private var hazelViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingAddChorePage = false
    @State private var showingSuggestSheet = false
    @State private var suggestedChores: [String] = []
    @State private var isFetchingSuggestions = false
    @State private var hasAppeared = false
    @State private var selectedFilter: PersonFilter = .everyone
    @State private var collapsedGroups: Set<ChoreGroup.Kind> = []
    @State private var isClearingCompleted = false

    private let embeddedInParentScroll: Bool
    private let previewViewModel: ChoresViewModel?

    private enum PersonFilter: String, CaseIterable, Identifiable {
        case everyone = "All"
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

    private var activeChores: [Chore] {
        filteredChores.filter { !$0.isCompleted }
    }

    private var completedChores: [Chore] {
        filteredChores.filter(\.isCompleted)
    }

    private var overdueChores: [Chore] {
        activeChores.filter(\.isOverdue)
    }

    private var dueTodayChores: [Chore] {
        activeChores.filter { chore in
            guard let dueDate = chore.dueDate, !chore.isOverdue else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }
    }

    private var upcomingChores: [Chore] {
        activeChores.filter { chore in
            guard let dueDate = chore.dueDate else { return false }
            return !chore.isOverdue && !Calendar.current.isDateInToday(dueDate)
        }
    }

    private var unscheduledChores: [Chore] {
        activeChores.filter { $0.dueDate == nil }
    }

    var body: some View {
        Group {
            if embeddedInParentScroll {
                content
            } else {
                ScrollView(showsIndicators: false) {
                    content
                }
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showingAddChorePage) {
            if let myUserId {
                AddChoreSheet(
                    myName: myName,
                    partnerName: partnerName,
                    myUserId: myUserId,
                    partnerUserId: partnerUserId,
                    rooms: viewModel.rooms,
                    roomGroups: viewModel.roomGroups
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
        .conditionalRefreshable(!showingAddChorePage) {
            guard let homeId = await homeManager.homeId else { return }
            await viewModel.load(homeId: homeId)
        }
        .task {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.roostSmooth) {
                hasAppeared = true
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

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader
                .padding(.top, embeddedInParentScroll ? 0 : 16)
                .choresEntrance(at: 0, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

            choreHero
                .padding(.top, 22)
                .choresEntrance(at: 1, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

            quickActionRail
                .padding(.top, 12)
                .choresEntrance(at: 2, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

            filterRow
                .padding(.top, 14)
                .choresEntrance(at: 3, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

            if viewModel.isLoading && viewModel.chores.isEmpty {
                loadingState
                    .padding(.top, 24)
                    .choresEntrance(at: 4, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
            } else if filteredChores.isEmpty {
                emptyState
                    .padding(.top, 24)
                    .choresEntrance(at: 4, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
            } else {
                choreBoard
                    .padding(.top, 24)
                    .choresEntrance(at: 4, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                if !completedChores.isEmpty {
                    completedDock
                        .padding(.top, 14)
                        .choresEntrance(at: 5 + choreGroups.count, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
                }
            }
        }
        .padding(.horizontal, choresPageInset)
        .padding(.bottom, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenBottom + DesignSystem.Spacing.tabContentBottomInset + 12)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var pageHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Chores")
                    .font(.roostLargeGreeting)
                    .foregroundStyle(Color.roostForeground)

                Text(headerSubtitle)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            Spacer(minLength: 0)
        }
    }

    private var choreHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("CHORE LIST")
                        .font(.roostMeta)
                        .foregroundStyle(choresAccent)
                        .tracking(1.0)

                    Text(choreHeroTitle)
                        .font(.roostHero)
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                }

                Spacer(minLength: 0)

                choreProgressDial
                    .frame(width: 76, height: 76)
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(nextDueTitle)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(nextDueChipTitle)
                        .font(.roostMeta)
                        .foregroundStyle(nextDueAccent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(nextDueAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.roostMuted)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(choresAccent)
                                .frame(width: geo.size.width * completionProgress)
                                .animation(DesignSystem.Motion.progressFill, value: completionProgress)
                        }
                }
                .frame(height: 7)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                    .fill(Color.roostCard)

                Circle()
                    .fill(choresAccent.opacity(0.18))
                    .frame(width: 124, height: 124)
                    .blur(radius: 32)
                    .offset(x: 40, y: -52)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 12, x: 0, y: 5)
    }

    private var choreProgressDial: some View {
        ZStack {
            Circle()
                .stroke(Color.roostMuted, lineWidth: 8)

            Circle()
                .trim(from: 0, to: completionProgress)
                .stroke(
                    choresAccent,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Motion.progressFill, value: completionProgress)

            VStack(spacing: 1) {
                Text("\(activeChores.count)")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)
                Text("left")
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
            }
        }
    }

    private var quickActionRail: some View {
        HStack(spacing: 10) {
            choreActionTile(
                title: "Add",
                detail: "New chore",
                icon: "plus",
                tint: choreAddAccent,
                isProminent: true
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.72)
                showingAddChorePage = true
            }

            choreActionTile(
                title: "Suggest",
                detail: hazelViewModel.choresEnabled ? "Hazel" : "Off",
                icon: "sparkles",
                tint: hazelViewModel.choresEnabled ? .roostPrimary : .roostMutedForeground
            ) {
                guard hazelViewModel.choresEnabled else { return }
                UISelectionFeedbackGenerator().selectionChanged()
                Task { await fetchSuggestions() }
            }
            .disabled(!hazelViewModel.choresEnabled || isFetchingSuggestions)

            choreActionTile(
                title: "Done",
                detail: "\(completedChores.count) complete",
                icon: "checkmark",
                tint: completedChores.isEmpty ? .roostMutedForeground : .roostSuccess
            ) {
                guard !completedChores.isEmpty else { return }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                Task { await clearCompleted() }
            }
            .disabled(completedChores.isEmpty || isClearingCompleted)
        }
    }

    private func choreActionTile(
        title: String,
        detail: String,
        icon: String,
        tint: Color,
        isProminent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(isProminent ? 0.16 : 0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)

                    Text(detail)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .stroke(isProminent ? tint.opacity(0.24) : Color.roostHairline, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        }
        .buttonStyle(ChoresPressStyle(reduceMotion: reduceMotion))
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PersonFilter.allCases) { filter in
                    Button {
                        guard selectedFilter != filter else { return }
                        selectedFilter = filter
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        Text(label(for: filter))
                            .font(.roostLabel)
                            .foregroundStyle(selectedFilter == filter ? Color.roostCard : Color.roostMutedForeground)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selectedFilter == filter ? choresAccent : Color.roostMuted.opacity(0.5))
                            )
                    }
                    .buttonStyle(ChoresPressStyle(reduceMotion: reduceMotion))
                }
            }
        }
    }

    private var choreBoard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if activeChores.isEmpty {
                allDoneState
            } else {
                ForEach(Array(choreGroups.enumerated()), id: \.element.id) { index, group in
                    choreGroupSection(group, index: index)
                }
            }
        }
    }

    private func choreGroupSection(_ group: ChoreGroup, index: Int) -> some View {
        let isCollapsed = collapsedGroups.contains(group.kind)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.roostEaseOut) {
                    toggleGroup(group.kind)
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(group.tint.opacity(0.14))
                        Image(systemName: group.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(group.tint)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.title)
                            .font(.roostCardTitle)
                            .foregroundStyle(Color.roostForeground)

                        Text(group.subtitle)
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        Text("\(group.chores.count)")
                            .font(.roostLabel)
                            .foregroundStyle(group.tint)
                            .frame(width: 30, height: 30)
                            .background(group.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
            }
            .buttonStyle(ChoresPressStyle(reduceMotion: reduceMotion))

            if !isCollapsed {
                VStack(spacing: 8) {
                    ForEach(group.chores) { chore in
                        choreCard(chore, tint: group.tint)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.roostCard.opacity(0.9), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
        .choresEntrance(at: index + 4, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
    }

    private func choreCard(_ chore: Chore, tint: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                toggle(chore)
            } label: {
                animatedCheckbox(for: chore, tint: tint)
            }
            .buttonStyle(ChoresPressStyle(reduceMotion: reduceMotion))

            Button {
                toggle(chore)
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(chore.title)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(chore.isCompleted ? Color.roostMutedForeground : Color.roostForeground)
                        .strikethrough(chore.isCompleted, color: Color.roostMutedForeground.opacity(0.8))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text(assignmentLabel(for: chore))
                            .font(.roostMeta)
                            .foregroundStyle(tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(choreMetaLine(for: chore))
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                            .lineLimit(1)
                    }

                    if let lastCompletedText = lastCompletedText(for: chore) {
                        Text(lastCompletedText)
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ChoresPressStyle(reduceMotion: reduceMotion))

            Button {
                delete(chore)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(width: 34, height: 34)
                    .background(Color.roostMuted.opacity(0.28), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(ChoresPressStyle(reduceMotion: reduceMotion))
        }
        .padding(12)
        .background(chore.isCompleted ? Color.roostMuted.opacity(0.22) : Color.roostSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
        .opacity(chore.isCompleted ? 0.72 : 1)
        .contextMenu {
            Button(role: .destructive) {
                delete(chore)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .animation(reduceMotion ? nil : choresCheckAnimation, value: chore.isCompleted)
    }

    private func animatedCheckbox(for chore: Chore, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(chore.isCompleted ? tint : Color.clear)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(chore.isCompleted ? tint : Color.roostHairline, lineWidth: 1.5)

            if chore.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.roostCard)
                    .transition(.scale(scale: 0.45).combined(with: .opacity))
            }
        }
        .frame(width: 32, height: 32)
        .animation(choresCheckAnimation, value: chore.isCompleted)
    }

    private var completedDock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.roostSuccess)
                    .frame(width: 30, height: 30)
                    .background(Color.roostSuccess.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(activeChores.isEmpty ? "Chores complete" : "\(completedChores.count) done")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)

                    Text(activeChores.isEmpty ? "Everything is checked off." : "Clear completed chores when the list is tidy.")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                Spacer(minLength: 0)
            }

            Button {
                Task { await clearCompleted() }
            } label: {
                Text(isClearingCompleted ? "Clearing..." : "Clear completed chores")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostSuccess)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.roostSuccess.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(ChoresPressStyle(reduceMotion: reduceMotion))
            .disabled(isClearingCompleted)
        }
        .padding(15)
        .background(Color.roostSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private var allDoneState: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("All done")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)

                Text("No active chores for this filter.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            Spacer(minLength: 0)

            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.roostSuccess)
                .frame(width: 40, height: 40)
                .background(Color.roostSuccess.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.roostSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(0..<4, id: \.self) { _ in
                LoadingSkeletonView()
                    .frame(height: 108)
            }
        }
    }

    private var emptyState: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("No chores yet")
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)

                Text("Use Add for the first household task.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "checklist")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(choreAddAccent)
                .frame(width: 40, height: 40)
                .background(choreAddAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.roostSurface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private var choreGroups: [ChoreGroup] {
        [
            ChoreGroup(kind: .overdue, chores: overdueChores),
            ChoreGroup(kind: .today, chores: dueTodayChores),
            ChoreGroup(kind: .upcoming, chores: upcomingChores),
            ChoreGroup(kind: .unscheduled, chores: unscheduledChores)
        ]
        .filter { !$0.chores.isEmpty }
    }

    private var headerSubtitle: String {
        if activeChores.isEmpty && !completedChores.isEmpty { return "All clear · \(completedChores.count) done" }
        if overdueChores.count > 0 { return "\(overdueChores.count) overdue · \(activeChores.count) active" }
        if dueTodayChores.count > 0 { return "\(dueTodayChores.count) due today · \(activeChores.count) active" }
        return "\(activeChores.count) active · \(completedChores.count) done"
    }

    private var choreHeroTitle: String {
        if filteredChores.isEmpty { return "No chores" }
        if overdueChores.count == 1 { return "1 overdue" }
        if overdueChores.count > 1 { return "\(overdueChores.count) overdue" }
        if dueTodayChores.count == 1 { return "1 due today" }
        if dueTodayChores.count > 1 { return "\(dueTodayChores.count) due today" }
        if activeChores.isEmpty { return "All done" }
        if activeChores.count == 1 { return "1 active" }
        return "\(activeChores.count) active"
    }

    private var nextDueTitle: String {
        guard let nextDueChore else { return "Nothing due" }
        return nextDueChore.title
    }

    private var nextDueChipTitle: String {
        guard let dueDate = nextDueChore?.dueDate else { return "Clear" }
        if Calendar.current.isDateInToday(dueDate) { return "Today" }
        if dueDate < Calendar.current.startOfDay(for: .now) { return "Late" }
        return settingsViewModel.formattedDate(dueDate)
    }

    private var nextDueAccent: Color {
        guard let dueDate = nextDueChore?.dueDate else { return .roostSuccess }
        if Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: .now) { return .roostDestructive }
        if Calendar.current.isDateInToday(dueDate) { return .roostWarning }
        return .roostSuccess
    }

    private var nextDueChore: Chore? {
        activeChores
            .filter { $0.dueDate != nil }
            .sorted { lhs, rhs in
                (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
            }
            .first
    }

    private var completionProgress: CGFloat {
        guard !filteredChores.isEmpty else { return 0 }
        return CGFloat(completedChores.count) / CGFloat(filteredChores.count)
    }

    private func label(for filter: PersonFilter) -> String {
        switch filter {
        case .everyone:
            return "All chores"
        case .me:
            return "Mine"
        case .partner:
            if let partnerName { return "\(partnerName)'s" }
            return "Partner's"
        }
    }

    private func toggle(_ chore: Chore) {
        guard let myUserId, let homeId = homeManager.homeId else { return }
        ShoppingHaptics.itemToggled(willCheck: !chore.isCompleted)
        Task {
            await viewModel.toggleCompletion(chore, currentUserId: myUserId, homeId: homeId)
        }
    }

    private func delete(_ chore: Chore) {
        guard let homeId = homeManager.homeId, let myUserId else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.56)
        Task { await viewModel.deleteChore(chore, homeId: homeId, userId: myUserId) }
    }

    private func toggleGroup(_ group: ChoreGroup.Kind) {
        UISelectionFeedbackGenerator().selectionChanged()
        if collapsedGroups.contains(group) {
            collapsedGroups.remove(group)
        } else {
            collapsedGroups.insert(group)
        }
    }

    private func clearCompleted() async {
        guard let homeId = homeManager.homeId,
              let userId = myUserId,
              !isClearingCompleted else {
            return
        }

        isClearingCompleted = true
        let choresToDelete = completedChores
        for chore in choresToDelete {
            await viewModel.deleteChore(chore, homeId: homeId, userId: userId)
        }
        isClearingCompleted = false
    }

    private func assignmentLabel(for chore: Chore) -> String {
        memberName(for: chore.assignedTo) ?? "Unassigned"
    }

    private func choreMetaLine(for chore: Chore) -> String {
        var pieces: [String] = []
        if let room = chore.room, !room.isEmpty {
            pieces.append(room)
        }
        if let frequency = frequencyLabel(for: chore) {
            pieces.append(frequency)
        }
        if let dueDate = chore.dueDate {
            pieces.append(dueDateLabel(for: dueDate))
        }
        return pieces.isEmpty ? "Shared chore" : pieces.joined(separator: " · ")
    }

    private func frequencyLabel(for chore: Chore) -> String? {
        guard let frequency = chore.frequency, frequency != "once" else { return nil }
        return frequency.capitalized
    }

    private func dueDateLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: .now) { return "Overdue" }
        return settingsViewModel.formattedDate(date)
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
                return "Done by \(completedName) \(lastCompletedAt.formatted(.relative(presentation: .named)))"
            }
            return "Done by \(completedName)"
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
                                    UISelectionFeedbackGenerator().selectionChanged()
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

private struct ChoreGroup: Identifiable {
    enum Kind: String, Hashable {
        case overdue
        case today
        case upcoming
        case unscheduled
    }

    let kind: Kind
    let chores: [Chore]

    var id: String { kind.rawValue }

    var title: String {
        switch kind {
        case .overdue: "Overdue"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .unscheduled: "Any time"
        }
    }

    var subtitle: String {
        switch kind {
        case .overdue: "Needs attention"
        case .today: "Due before the day ends"
        case .upcoming: "Next household tasks"
        case .unscheduled: "No due date set"
        }
    }

    var tint: Color {
        switch kind {
        case .overdue: .roostDestructive
        case .today: .roostWarning
        case .upcoming: choresAccent
        case .unscheduled: Color(hex: 0x7A9199)
        }
    }

    var icon: String {
        switch kind {
        case .overdue: "exclamationmark"
        case .today: "sun.max"
        case .upcoming: "calendar"
        case .unscheduled: "tray"
        }
    }
}

private let choresPageInset: CGFloat = 12
private let choresCheckAnimation = Animation.spring(response: 0.46, dampingFraction: 0.72)
private let choreAddAccent = Color.roostChoreTint
private let choresAccent = Color.roostChoreTint

private struct ChoresPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(reduceMotion ? nil : DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}

private struct ChoresEntranceModifier: ViewModifier {
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
    func choresEntrance(at index: Int, hasAppeared: Bool, reduceMotion: Bool) -> some View {
        modifier(ChoresEntranceModifier(index: index, hasAppeared: hasAppeared, reduceMotion: reduceMotion))
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
            .environment(HazelViewModel())
            .environment(settingsViewModel)
    }
}
