import SwiftUI

struct CalendarView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(CalendarViewModel.self) private var sharedViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasAnimatedIn = false
    private let embeddedInParentScroll: Bool
    private let previewViewModel: CalendarViewModel?

    @MainActor
    init(viewModel: CalendarViewModel? = nil, embeddedInParentScroll: Bool = false) {
        previewViewModel = viewModel
        self.embeddedInParentScroll = embeddedInParentScroll
    }

    private var viewModel: CalendarViewModel { previewViewModel ?? sharedViewModel }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        Group {
            if embeddedInParentScroll {
                content
            } else {
                ZStack(alignment: .top) {
                    ScrollView(showsIndicators: false) {
                        content
                            .padding(.bottom, DesignSystem.Spacing.screenBottom + 24)
                    }

                    // Top accent line
                    LinearGradient(
                        colors: [Color.roostPrimary.opacity(0.72), Color.roostPrimary.opacity(0.28)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 3)
                    .ignoresSafeArea(edges: .top)
                }
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task(id: settingsViewModel.userPreferences.weekStarts) {
            viewModel.updateWeekStart(settingsViewModel.userPreferences.weekStarts)
            ensureDefaultSelection()
        }
        .onChange(of: settingsViewModel.userPreferences.weekStarts) { _, newValue in
            viewModel.updateWeekStart(newValue)
        }
        .onChange(of: viewModel.selectedMonth) { _, _ in
            ensureDefaultSelection()
        }
        .task {
            ensureDefaultSelection()
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
                    .padding(DesignSystem.Spacing.section)
                    .background(Color.roostDestructive, in: Capsule())
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .padding(.bottom, DesignSystem.Size.toastBottomOffset)
                    .onTapGesture { viewModel.errorMessage = nil }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
            if !embeddedInParentScroll {
                pageHeader
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .modifier(CalendarEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            }

            // Calendar hero card with embedded month navigator
            calendarHeroCard
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(CalendarEntranceModifier(index: embeddedInParentScroll ? 0 : 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            // Stats rail
            statsRail
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(CalendarEntranceModifier(index: embeddedInParentScroll ? 1 : 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            // Sync chip
            syncRow
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(CalendarEntranceModifier(index: embeddedInParentScroll ? 2 : 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            // Events section
            eventsSection
                .modifier(CalendarEntranceModifier(index: embeddedInParentScroll ? 3 : 4, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
        }
        .padding(.top, 0)
        .padding(.bottom, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenBottom)
        .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            FigmaBackHeader(title: "Calendar", accent: .roostPrimary)

            Text(pageSubtitle)
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.leading, 56)
        }
    }

    // MARK: - Calendar Hero Card

    private var calendarHeroCard: some View {
        VStack(spacing: 0) {
            // Month navigator embedded at top of card
            monthNavigator
                .padding(.horizontal, DesignSystem.Spacing.card)
                .padding(.top, DesignSystem.Spacing.card)
                .padding(.bottom, DesignSystem.Spacing.row)

            Divider()
                .background(Color.roostHairline)
                .padding(.horizontal, DesignSystem.Spacing.card)

            // Weekday labels + day grid
            VStack(spacing: DesignSystem.Spacing.inline) {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(String(symbol.prefix(1)))
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostMutedForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                    }
                }

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(viewModel.visibleDays.enumerated()), id: \.offset) { _, day in
                        calendarDayCell(for: day)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.card)
            .padding(.top, DesignSystem.Spacing.inline)
            .padding(.bottom, DesignSystem.Spacing.card)
        }
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                .strokeBorder(Color.roostHairline, lineWidth: 1)
        )
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack(spacing: DesignSystem.Spacing.inline) {
            Button {
                viewModel.changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(width: 36, height: 36)
                    .background(Color.roostMuted, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Text(viewModel.monthTitle)
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)

            Spacer(minLength: 0)

            Button {
                viewModel.changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(width: 36, height: 36)
                    .background(Color.roostMuted, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Day Cell

    private func calendarDayCell(for day: Date?) -> some View {
        let isSelected = if let day, let selectedDate = viewModel.selectedDate {
            Calendar.current.isDate(selectedDate, inSameDayAs: day)
        } else {
            false
        }

        let isToday = if let day {
            Calendar.current.isDateInToday(day)
        } else {
            false
        }

        let events = day.map { eventsForDay($0) } ?? []

        return Button {
            viewModel.selectDay(day)
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.roostPrimary)
                    } else if isToday {
                        Circle()
                            .strokeBorder(Color.roostPrimary, lineWidth: 1.5)
                    }

                    if let day {
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.roostBody)
                            .foregroundStyle(
                                isSelected ? Color.roostCard :
                                isToday ? Color.roostPrimary :
                                Color.roostForeground
                            )
                    }
                }
                .frame(width: 34, height: 34)

                // Event dots
                if !events.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { _, event in
                            Circle()
                                .fill(eventColor(for: event))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 4)
                } else {
                    Color.clear.frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .disabled(day == nil)
    }

    // MARK: - Stats Rail

    private var statsRail: some View {
        HStack(spacing: DesignSystem.Spacing.inline) {
            statTile(
                value: "\(upcomingChoreCount)",
                label: "Upcoming",
                icon: "checkmark.circle.fill",
                tint: Color.roostChoreTint
            )
            statTile(
                value: "\(overdueCount)",
                label: "Overdue",
                icon: "exclamationmark.circle.fill",
                tint: overdueCount > 0 ? Color.roostDestructive : Color.roostMutedForeground
            )
            statTile(
                value: "\(billCount)",
                label: "Bills",
                icon: "dollarsign.circle.fill",
                tint: Color.roostMoneyTint
            )
        }
    }

    private func statTile(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.microMedium) {
            HStack(spacing: DesignSystem.Spacing.microMedium) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tint)
                Spacer(minLength: 0)
            }
            Text(value)
                .font(.roostSectionHeading)
                .foregroundStyle(Color.roostForeground)
            Text(label)
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .lineLimit(1)
        }
        .padding(DesignSystem.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                .strokeBorder(Color.roostHairline, lineWidth: 1)
        )
    }

    // MARK: - Sync Row

    private var syncRow: some View {
        HStack(spacing: DesignSystem.Spacing.inline) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .medium))
            Text("Sync with Apple Calendar")
                .font(.roostLabel)
        }
        .foregroundStyle(Color.roostMutedForeground)
        .padding(.horizontal, DesignSystem.Spacing.section)
        .frame(height: 34)
        .background(Color.roostMuted, in: Capsule())
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            HStack {
                Text(sectionTitle.uppercased())
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
                    .tracking(1.5)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignSystem.Spacing.page)

            if displayedEvents.isEmpty {
                emptyEventsState
                    .padding(.horizontal, DesignSystem.Spacing.page)
            } else {
                VStack(spacing: DesignSystem.Spacing.inline) {
                    ForEach(Array(displayedEvents.enumerated()), id: \.element.id) { index, event in
                        eventRow(event)
                            .padding(.horizontal, DesignSystem.Spacing.page)
                            .modifier(CalendarEntranceModifier(
                                index: (embeddedInParentScroll ? 4 : 6) + index,
                                hasAnimatedIn: hasAnimatedIn,
                                reduceMotion: reduceMotion
                            ))
                    }
                }
            }
        }
    }

    private var emptyEventsState: some View {
        VStack(spacing: DesignSystem.Spacing.row) {
            Image(systemName: "calendar")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.roostMutedForeground)
            Text("Nothing scheduled")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.blockLarge)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                .strokeBorder(Color.roostHairline, lineWidth: 1)
        )
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: DesignSystem.Spacing.row) {
            // Type icon
            ZStack {
                Circle()
                    .fill(eventColor(for: event).opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: eventIcon(for: event))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(eventColor(for: event))
            }

            // Title + date
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
                    .lineLimit(1)
                Text(eventDateLabel(for: event))
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            Spacer(minLength: 0)

            // Overdue badge
            if isOverdue(event) {
                FigmaChip(title: "Overdue", variant: .destructive)
            }
        }
        .padding(.leading, DesignSystem.Spacing.card)
        .padding(.trailing, DesignSystem.Spacing.card)
        .padding(.vertical, DesignSystem.Spacing.row)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                .strokeBorder(Color.roostHairline, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(eventColor(for: event))
                .frame(width: 3)
                .padding(.vertical, DesignSystem.Spacing.row)
        }
    }

    // MARK: - Helpers

    private var pageSubtitle: String {
        let total = upcomingChoreCount + billCount
        if total == 0 { return "All clear this month" }
        return "\(total) thing\(total == 1 ? "" : "s") coming up"
    }

    private var displayedEvents: [CalendarEvent] {
        let source = viewModel.selectedDate == nil ? viewModel.upcomingEvents : viewModel.selectedDayEvents
        return Array(source.prefix(10))
    }

    private var sectionTitle: String {
        if let selectedDate = viewModel.selectedDate {
            return selectedDate.formatted(.dateTime.day().month(.wide))
        }
        return "Upcoming"
    }

    private var weekdaySymbols: [String] {
        let symbols = Calendar.current.shortStandaloneWeekdaySymbols
        if settingsViewModel.userPreferences.weekStarts == "sunday" {
            return symbols
        }
        return Array(symbols.dropFirst()) + [symbols.first].compactMap { $0 }
    }

    private var upcomingChoreCount: Int {
        viewModel.events.filter {
            $0.type == "chore" && Calendar.current.startOfDay(for: $0.date) >= Calendar.current.startOfDay(for: .now)
        }.count
    }

    private var overdueCount: Int {
        viewModel.events.filter {
            $0.type == "chore" && Calendar.current.startOfDay(for: $0.date) < Calendar.current.startOfDay(for: .now)
        }.count
    }

    private var billCount: Int {
        viewModel.events.filter {
            $0.type == "expense" && Calendar.current.isDate($0.date, equalTo: viewModel.selectedMonth, toGranularity: .month)
        }.count
    }

    private func eventsForDay(_ date: Date) -> [CalendarEvent] {
        viewModel.events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func eventColor(for event: CalendarEvent) -> Color {
        switch event.type {
        case "chore": return Color.roostChoreTint
        case "expense": return Color.roostMoneyTint
        default: return Color.roostShoppingTint
        }
    }

    private func eventIcon(for event: CalendarEvent) -> String {
        switch event.type {
        case "chore": return "checkmark.circle"
        case "expense": return "dollarsign"
        default: return "calendar"
        }
    }

    private func eventDateLabel(for event: CalendarEvent) -> String {
        if Calendar.current.isDateInToday(event.date) { return "Today" }
        if Calendar.current.isDateInTomorrow(event.date) { return "Tomorrow" }
        return event.date.formatted(.dateTime.day().month(.abbreviated))
    }

    private func ensureDefaultSelection() {
        if let selectedDate = viewModel.selectedDate,
           Calendar.current.isDate(selectedDate, equalTo: viewModel.selectedMonth, toGranularity: .month) {
            return
        }
        if Calendar.current.isDate(.now, equalTo: viewModel.selectedMonth, toGranularity: .month) {
            viewModel.selectDay(Calendar.current.startOfDay(for: .now))
        } else {
            viewModel.selectDay(nil)
        }
    }

    private func isOverdue(_ event: CalendarEvent) -> Bool {
        event.type == "chore" && Calendar.current.startOfDay(for: event.date) < Calendar.current.startOfDay(for: .now)
    }

}

// MARK: - Entrance Modifier

private struct CalendarEntranceModifier: ViewModifier {
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

// MARK: - Preview

#Preview("Calendar") {
    let homeManager = HomeManager.previewDashboard()
    let settingsViewModel: SettingsViewModel = {
        let viewModel = SettingsViewModel()
        viewModel.userPreferences.weekStarts = "monday"
        return viewModel
    }()

    let month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    let events = [
        CalendarEvent(id: UUID(), title: "Take bins out", date: .now, type: "chore", relatedEntityID: nil),
        CalendarEvent(id: UUID(), title: "Electric bill due", date: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now, type: "expense", relatedEntityID: nil),
        CalendarEvent(id: UUID(), title: "Vacuum living room", date: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now, type: "chore", relatedEntityID: nil)
    ]

    NavigationStack {
        CalendarView(
            viewModel: CalendarViewModel(
                events: events,
                selectedMonth: month,
                selectedDate: nil,
                weekStarts: "monday"
            )
        )
        .environment(homeManager)
        .environment(settingsViewModel)
    }
}
