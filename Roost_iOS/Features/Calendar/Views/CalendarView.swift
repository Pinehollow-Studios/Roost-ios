import SwiftUI

struct CalendarView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(NotificationRouter.self) private var notificationRouter
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
                ScrollView(showsIndicators: false) {
                    content
                        .padding(.bottom, DesignSystem.Spacing.screenBottom)
                }
            }
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
                PlanSectionPicker(selected: .calendar) { section in
                    navigateTo(section)
                }
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(CalendarEntranceModifier(index: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
            }

            monthNavigator
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(CalendarEntranceModifier(index: embeddedInParentScroll ? 0 : 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            calendarCard
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(CalendarEntranceModifier(index: embeddedInParentScroll ? 1 : 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            Text(statsLine)
                .font(.roostLabel)
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(CalendarEntranceModifier(index: embeddedInParentScroll ? 2 : 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            syncRow
                .padding(.horizontal, DesignSystem.Spacing.page)
                .modifier(CalendarEntranceModifier(index: embeddedInParentScroll ? 3 : 4, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))

            eventsSection
                .modifier(CalendarEntranceModifier(index: embeddedInParentScroll ? 4 : 5, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
        }
        .padding(.top, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenTop)
        .padding(.bottom, embeddedInParentScroll ? 0 : DesignSystem.Spacing.screenBottom)
        .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                viewModel.changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
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
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var calendarCard: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(spacing: 8) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(String(symbol.prefix(1)))
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostMutedForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 20)
                    }
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(viewModel.visibleDays.enumerated()), id: \.offset) { _, day in
                        calendarDayCell(for: day)
                    }
                }
            }
        }
    }

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
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(
                            isToday && !isSelected ? Color.roostPrimary :
                                isSelected ? Color.roostAccent : .clear
                        )

                    if let day {
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.roostBody)
                            .foregroundStyle(isToday && !isSelected ? Color.roostCard : Color.roostForeground)
                    }
                }
                .frame(width: 36, height: 36)

                if !events.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { _, event in
                            Circle()
                                .fill(eventColor(for: event))
                                .frame(width: 6, height: 6)
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(.plain)
        .disabled(day == nil)
    }

    private var syncRow: some View {
        HStack {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .medium))
                Text("Sync with Apple Calendar")
                    .font(.roostLabel)
            }
            .foregroundStyle(Color.roostMutedForeground)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(Color.roostMuted, in: Capsule())
            Spacer(minLength: 0)
        }
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sectionTitle)
                .font(.roostBody.weight(.medium))
                .foregroundStyle(Color.roostForeground)
                .padding(.horizontal, DesignSystem.Spacing.page)

            if displayedEvents.isEmpty {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous)
                            .fill(Color.roostAccent)
                        Image(systemName: "calendar")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                    .frame(width: 64, height: 64)

                    Text("Nothing scheduled")
                        .font(.roostBody)
                        .foregroundStyle(Color.roostMutedForeground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(displayedEvents.enumerated()), id: \.element.id) { index, event in
                        eventRow(event)
                            .padding(.horizontal, DesignSystem.Spacing.page)
                            .modifier(CalendarEntranceModifier(index: index + 6, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
                    }
                }
            }
        }
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(eventColor(for: event))
                    .frame(width: 14, height: 14)

                Text(event.title)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Text(eventTimeLabel(for: event))
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostMutedForeground)

                if isOverdue(event) {
                    FigmaChip(title: "Overdue", variant: .destructive)
                }
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(eventColor(for: event))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        }
    }

    private var displayedEvents: [CalendarEvent] {
        let source = viewModel.selectedDate == nil ? viewModel.upcomingEvents : viewModel.selectedDayEvents
        return Array(source.prefix(10))
    }

    private var sectionTitle: String {
        if let selectedDate = viewModel.selectedDate {
            return "Events on \(selectedDate.formatted(.dateTime.day().month(.wide)))"
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

    private var statsLine: String {
        "\(upcomingChoreCount) upcoming chores · \(overdueCount) overdue · \(billCount) bills this month · Next shop: \(nextShopLabel)"
    }

    private var upcomingChoreCount: Int {
        viewModel.events.filter { $0.type == "chore" && Calendar.current.startOfDay(for: $0.date) >= Calendar.current.startOfDay(for: .now) }.count
    }

    private var overdueCount: Int {
        viewModel.events.filter { $0.type == "chore" && Calendar.current.startOfDay(for: $0.date) < Calendar.current.startOfDay(for: .now) }.count
    }

    private var billCount: Int {
        viewModel.events.filter {
            $0.type == "expense" && Calendar.current.isDate($0.date, equalTo: viewModel.selectedMonth, toGranularity: .month)
        }.count
    }

    private var nextShopLabel: String {
        if let nextShop = homeManager.home?.nextShopDateParsed {
            return nextShop.formatted(.dateTime.day().month(.abbreviated))
        }
        return "TBD"
    }

    private func eventTimeLabel(for event: CalendarEvent) -> String {
        "All day"
    }

    private func eventsForDay(_ date: Date) -> [CalendarEvent] {
        viewModel.events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func eventColor(for event: CalendarEvent) -> Color {
        switch event.type {
        case "chore":
            return .roostSecondary
        case "expense":
            return .roostPrimary
        default:
            return .roostWarning
        }
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
        .environment(NotificationRouter())
        .environment(settingsViewModel)
    }
}
