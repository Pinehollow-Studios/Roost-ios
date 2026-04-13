import Foundation
import Observation
import Realtime

@MainActor
@Observable
final class CalendarViewModel {
    var events: [CalendarEvent] = []
    var selectedMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    var selectedDate: Date?
    var weekStarts = "monday"
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private let calendarService = CalendarService()

    @ObservationIgnored
    private let choreService = ChoreService()

    @ObservationIgnored
    private let expenseService = ExpenseService()

    @ObservationIgnored
    private var choreSubscriptionId: UUID?

    @ObservationIgnored
    private var expenseSubscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    init(
        events: [CalendarEvent] = [],
        selectedMonth: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now,
        selectedDate: Date? = nil,
        weekStarts: String = "monday",
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.events = events
        self.selectedMonth = selectedMonth
        self.selectedDate = selectedDate
        self.weekStarts = weekStarts
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    var visibleDays: [Date?] {
        let calendar = Calendar.current
        let configuredCalendar = configuredCalendar
        guard let monthInterval = configuredCalendar.dateInterval(of: .month, for: selectedMonth),
              let firstWeekday = configuredCalendar.dateComponents([.weekday], from: monthInterval.start).weekday,
              let daysRange = calendar.range(of: .day, in: .month, for: selectedMonth)
        else {
            return []
        }

        let leadingEmpty = max(firstWeekday - configuredCalendar.firstWeekday, 0)
        let normalizedLeading = leadingEmpty < 0 ? leadingEmpty + 7 : leadingEmpty
        var days = Array<Date?>(repeating: nil, count: normalizedLeading)

        for day in daysRange {
            if let date = calendar.date(from: DateComponents(
                year: calendar.component(.year, from: selectedMonth),
                month: calendar.component(.month, from: selectedMonth),
                day: day
            )) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    var upcomingEvents: [CalendarEvent] {
        let start = Calendar.current.startOfDay(for: selectedDate ?? .now)
        return events
            .filter { Calendar.current.startOfDay(for: $0.date) >= start }
            .sorted { $0.date < $1.date }
    }

    var selectedDayEvents: [CalendarEvent] {
        guard let selectedDate else { return [] }
        return eventsForDay(selectedDate)
    }

    func load(homeId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            async let choresResult = choreService.fetchChores(for: homeId)
            async let expensesResult = expenseService.fetchExpenses(for: homeId)
            let chores = try await choresResult
            let expenses = try await expensesResult
            events = calendarService.buildEvents(chores: chores, expenses: expenses)
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }

        isLoading = false
    }

    func changeMonth(by offset: Int) {
        if let nextMonth = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonth) {
            selectedMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: nextMonth)) ?? nextMonth
        }
    }

    func selectDay(_ date: Date?) {
        selectedDate = date
    }

    func updateWeekStart(_ value: String) {
        weekStarts = value
    }

    func hasEvents(on date: Date) -> Bool {
        !eventsForDay(date).isEmpty
    }

    func startRealtime(homeId: UUID) async {
        if let subscribedHomeId, subscribedHomeId != homeId {
            await stopRealtime()
        }
        guard choreSubscriptionId == nil, expenseSubscriptionId == nil else { return }
        subscribedHomeId = homeId

        choreSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "chores",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.load(homeId: homeId)
        }

        expenseSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "expenses",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.load(homeId: homeId)
        }
    }

    func stopRealtime() async {
        if let choreSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "chores", callbackId: choreSubscriptionId)
            self.choreSubscriptionId = nil
        }
        if let expenseSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "expenses", callbackId: expenseSubscriptionId)
            self.expenseSubscriptionId = nil
        }
        subscribedHomeId = nil
    }

    private func eventsForDay(_ date: Date) -> [CalendarEvent] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
    }

    private var configuredCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = weekStarts == "sunday" ? 1 : 2
        return calendar
    }
}
