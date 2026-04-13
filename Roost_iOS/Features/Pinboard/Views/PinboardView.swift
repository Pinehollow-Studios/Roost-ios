import SwiftUI

struct PinboardView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(HomeManager.self) private var homeManager
    @Environment(NotificationRouter.self) private var notificationRouter
    @Environment(PinboardViewModel.self) private var sharedViewModel
    @Environment(ChoresViewModel.self) private var choresViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasAnimatedIn = false
    @State private var showingComposer = false
    private let embeddedInParentScroll: Bool

    private var viewModel: PinboardViewModel { sharedViewModel }
    private var currentUserId: UUID? { authManager.currentUser?.id }
    private var homeId: UUID? { homeManager.homeId }
    private var currentMember: HomeMember? { homeManager.currentMember }
    private var partner: HomeMember? { homeManager.partner }

    init(embeddedInParentScroll: Bool = false) {
        self.embeddedInParentScroll = embeddedInParentScroll
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
        .conditionalRefreshable(!showingComposer) {
            guard let homeId, let currentUserId else { return }
            await viewModel.load(homeId: homeId, userId: currentUserId)
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
        .sheet(isPresented: $showingComposer) {
            AddPinboardNoteSheet(
                currentMemberName: currentMember?.displayName,
                partnerName: partner?.displayName,
                rooms: choresViewModel.rooms
            ) { content, targetScope, notifyOnCreate, expiresAt, room in
                guard let homeId, let currentUserId else { return }
                let targetUserID = composerTargetUserID(for: targetScope, currentUserId: currentUserId)
                await viewModel.addNote(
                    content: content,
                    homeId: homeId,
                    userId: currentUserId,
                    targetScope: targetScope,
                    targetUserID: targetUserID,
                    notifyOnCreate: notifyOnCreate,
                    expiresAt: expiresAt,
                    linkType: room == nil ? nil : .room,
                    linkLabel: room?.name,
                    linkedEntityID: room?.id
                )
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
            if !embeddedInParentScroll {
                PlanSectionPicker(selected: .pinboard) { section in
                    navigateTo(section)
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(PinboardEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
            }

            FigmaPageHeader(
                title: "Pinboard",
                subtitle: "\(viewModel.liveCount) live · \(viewModel.unseenCount) unseen"
            ) {
                RoostAddPageButton {
                    showingComposer = true
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .modifier(PinboardEntranceModifier(index: embeddedInParentScroll ? 0 : 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            filterRow
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(PinboardEntranceModifier(index: embeddedInParentScroll ? 1 : 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            notesSection
                .modifier(PinboardEntranceModifier(index: embeddedInParentScroll ? 2 : 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
        }
        .padding(.top, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenTop)
        .padding(.bottom, embeddedInParentScroll ? 0 : 120)
        .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PinboardViewModel.Filter.allCases) { filter in
                    FigmaSelectablePill(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading && viewModel.notes.isEmpty {
                ProgressView()
                    .tint(Color.roostPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, DesignSystem.Spacing.section)
            } else if viewModel.filteredNotes.isEmpty {
                EmptyStateView(
                    icon: "pin",
                    title: "No live notes",
                    message: "Everything on the board right now is coming from your shared home in Supabase. Add a note to pin the first one here.",
                    actionTitle: "Add Note"
                ) {
                    showingComposer = true
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
            } else {
                ForEach(Array(viewModel.filteredNotes.enumerated()), id: \.element.id) { index, note in
                    noteCard(note)
                        .padding(.horizontal, DesignSystem.Spacing.page)
                        .modifier(PinboardEntranceModifier(index: index + 4, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                }
            }
        }
    }

    private func noteCard(_ note: PinboardNote) -> some View {
        let isExpanded = viewModel.expandedNoteIDs.contains(note.id)
        let isLong = note.content.count > 120
        let displayText = isLong && !isExpanded ? String(note.content.prefix(120)) + "..." : note.content
        let author = member(for: note.authorID)
        let authorName = author?.displayName ?? "Someone"
        let hasAcknowledged = note.isAcknowledged(by: currentUserId)
        let canAcknowledge = note.authorID != currentUserId && !hasAcknowledged

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .fill(hasAcknowledged ? Color.roostCard : Color.roostPrimary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                        .stroke(Color.roostBorderLight, lineWidth: 1)
                )

            if !hasAcknowledged {
                UnevenRoundedRectangle(
                    topLeadingRadius: RoostTheme.cornerRadius,
                    bottomLeadingRadius: RoostTheme.cornerRadius
                )
                .fill(Color.roostPrimary)
                .frame(width: 3)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                HStack(alignment: .center, spacing: DesignSystem.Spacing.inline) {
                    HStack(spacing: 8) {
                        MemberAvatar(
                            label: authorName,
                            color: settingsViewModel.avatarColor(for: author?.avatarColor),
                            icon: LucideIcon.sfSymbolName(for: author?.avatarIcon),
                            size: .sm
                        )

                        Text(authorName)
                            .font(.roostCaption.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 6) {
                        Image(systemName: note.targetScope == .everyone ? "person.2" : "person")
                            .font(.system(size: 11, weight: .medium))
                        Text(audienceLabel(for: note))
                            .font(.roostMeta)
                    }
                    .foregroundStyle(Color.roostMutedForeground)
                }

                Text(displayText)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if isLong {
                    Button {
                        viewModel.toggleExpanded(noteID: note.id)
                    } label: {
                        Text(isExpanded ? "See less" : "See more")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostPrimary)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    if let expires = note.expiresLabel {
                        FigmaChip(
                            title: "Expires \(expires)",
                            variant: .default,
                            systemImage: "clock"
                        )
                    }

                    if let linkedTo = note.linkLabel {
                        FigmaChip(
                            title: linkedTo,
                            variant: .secondary,
                            systemImage: "link"
                        )
                    }

                    if canAcknowledge {
                        Spacer(minLength: 0)

                        Button {
                            guard let currentUserId else { return }
                            Task { await viewModel.acknowledge(noteID: note.id, userId: currentUserId) }
                        } label: {
                            Text("Acknowledge")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostPrimary)
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(DesignSystem.Spacing.card)
        }
        .contextMenu {
            if note.authorID == currentUserId,
               let homeId = homeId,
               let currentUserId = currentUserId {
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteNote(note, homeId: homeId, userId: currentUserId)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
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

    private func member(for userID: UUID?) -> HomeMember? {
        guard let userID else { return nil }
        return homeManager.members.first { $0.userID == userID }
    }

    private func audienceLabel(for note: PinboardNote) -> String {
        switch note.targetScope {
        case .everyone:
            return "For everyone"
        case .self, .partner:
            if note.targetUserID == currentUserId {
                return "For me"
            }
            if let target = member(for: note.targetUserID) {
                return "For \(target.displayName)"
            }
            if note.targetScope == .partner {
                return "For partner"
            }
            return "For self"
        }
    }

    private func composerTargetUserID(for scope: PinboardTargetScope, currentUserId: UUID) -> UUID? {
        switch scope {
        case .everyone:
            return nil
        case .self:
            return currentUserId
        case .partner:
            return partner?.userID
        }
    }
}

private struct PinboardEntranceModifier: ViewModifier {
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

#Preview("Pinboard") {
    NavigationStack {
        PinboardView()
            .environment(AuthManager())
            .environment(HomeManager.previewDashboard())
            .environment(NotificationRouter())
            .environment(PinboardViewModel())
            .environment(ChoresViewModel())
            .environment(SettingsViewModel())
    }
}
