import SwiftUI

struct PinboardView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(HomeManager.self) private var homeManager
    @Environment(PinboardViewModel.self) private var sharedViewModel
    @Environment(ChoresViewModel.self) private var choresViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasAnimatedIn = false
    @State private var showingAddNotePage = false
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
                ZStack(alignment: .top) {
                    ScrollView(showsIndicators: false) {
                        content
                    }

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.roostShoppingTint.opacity(0.72), Color.roostShoppingTint.opacity(0.28)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .ignoresSafeArea(edges: .top)
                }
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .conditionalRefreshable(!showingAddNotePage) {
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
        .navigationDestination(isPresented: $showingAddNotePage) {
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
        VStack(alignment: .leading, spacing: 0) {
            pageHeader
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(PinboardEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            statusRail
                .padding(.horizontal, DesignSystem.Spacing.page)
                .padding(.top, 14)
                .modifier(PinboardEntranceModifier(index: 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            filterRow
                .padding(.horizontal, DesignSystem.Spacing.page)
                .padding(.top, 12)
                .modifier(PinboardEntranceModifier(index: 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            notesSection
                .padding(.top, 18)
                .modifier(PinboardEntranceModifier(index: 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
        }
        .padding(.top, 0)
        .padding(.bottom, embeddedInParentScroll ? 0 : 120)
        .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var pageHeader: some View {
        if embeddedInParentScroll {
            FigmaPageHeader(
                title: "Pinboard",
                subtitle: pinboardSubtitle,
                accent: .roostShoppingTint
            ) {
                RoostAddPageButton {
                    showingAddNotePage = true
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                FigmaBackHeader(title: "Pinboard") {
                    RoostAddPageButton {
                        showingAddNotePage = true
                    }
                }

                Text(pinboardSubtitle)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
                    .padding(.leading, 56)
            }
        }
    }

    private var pinboardSubtitle: String {
        "\(viewModel.liveCount) live · \(viewModel.unseenCount) unseen"
    }

    private var statusRail: some View {
        HStack(spacing: DesignSystem.Spacing.inline) {
            pinboardStat(
                value: "\(viewModel.liveCount)",
                label: "Live",
                icon: "pin.fill",
                tint: Color.roostShoppingTint
            )

            pinboardStat(
                value: "\(viewModel.unseenCount)",
                label: "Unseen",
                icon: "eye.slash.fill",
                tint: viewModel.unseenCount > 0 ? Color.roostPrimary : Color.roostMutedForeground
            )
        }
    }

    private func pinboardStat(value: String, label: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)

                Text(label)
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
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
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.notes.isEmpty {
                loadingState
                    .padding(.horizontal, DesignSystem.Spacing.page)
            } else if viewModel.filteredNotes.isEmpty {
                EmptyStateView(
                    icon: "pin",
                    title: "No live notes",
                    message: "Add a note to keep something visible for the household.",
                    actionTitle: "Add Note"
                ) {
                    showingAddNotePage = true
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
            } else {
                RoostSectionSurface(emphasis: .subtle) {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: sectionTitle)

                        ForEach(Array(viewModel.filteredNotes.enumerated()), id: \.element.id) { index, note in
                            noteRow(note)
                                .modifier(PinboardEntranceModifier(index: index + 4, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

                            if note.id != viewModel.filteredNotes.last?.id {
                                Divider()
                                    .overlay(Color.roostHairline)
                                    .padding(.leading, 42)
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
            }
        }
    }

    private var loadingState: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { _ in
                    LoadingSkeletonView()
                        .frame(height: 76)
                }
            }
        }
    }

    private var sectionTitle: String {
        switch viewModel.selectedFilter {
        case .all, .active:
            return "Pinned notes"
        case .expiring:
            return "Expiring soon"
        case .permanent:
            return "Permanent notes"
        }
    }

    private func noteRow(_ note: PinboardNote) -> some View {
        let isExpanded = viewModel.expandedNoteIDs.contains(note.id)
        let isLong = note.content.count > 150
        let displayText = isLong && !isExpanded ? String(note.content.prefix(150)) + "..." : note.content
        let author = member(for: note.authorID)
        let authorName = author?.displayName ?? "Someone"
        let hasAcknowledged = note.isAcknowledged(by: currentUserId)
        let canAcknowledge = note.authorID != currentUserId && !hasAcknowledged

        return HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(hasAcknowledged ? Color.roostHairline : Color.roostPrimary)
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(authorName)
                        .font(.roostCaption.weight(.medium))
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)

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
                    .lineSpacing(2)
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

                HStack(alignment: .center, spacing: 8) {
                    Text(createdLabel(for: note))
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)

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
                                .padding(.horizontal, 10)
                                .frame(height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
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

    private func createdLabel(for note: PinboardNote) -> String {
        if Calendar.current.isDateInToday(note.createdAt) {
            return note.createdAt.formatted(.dateTime.hour().minute())
        }
        if Calendar.current.isDateInYesterday(note.createdAt) {
            return "Yesterday"
        }
        return note.createdAt.formatted(.dateTime.day().month(.abbreviated))
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
