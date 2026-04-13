import Foundation

struct CalendarService {
    func buildEvents(
        chores: [Chore],
        expenses: [ExpenseWithSplits]
    ) -> [CalendarEvent] {
        var events: [CalendarEvent] = []

        for chore in chores {
            guard let dueDate = chore.dueDate else { continue }
            events.append(
                CalendarEvent(
                    id: chore.id,
                    title: chore.title,
                    date: dueDate,
                    type: "chore",
                    relatedEntityID: chore.id
                )
            )
        }

        for expense in expenses {
            guard let date = expense.incurredOnDate else { continue }

            events.append(
                CalendarEvent(
                    id: expense.id,
                    title: expense.title,
                    date: date,
                    type: "expense",
                    relatedEntityID: expense.id
                )
            )

            if expense.isRecurring == true {
                events.append(contentsOf: recurringExpenseEvents(for: expense, startingAt: date))
            }
        }

        return events.sorted { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date < rhs.date }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private func recurringExpenseEvents(for expense: ExpenseWithSplits, startingAt date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return (1...5).compactMap { offset in
            guard let nextDate = calendar.date(byAdding: .month, value: offset, to: date) else { return nil }
            return CalendarEvent(
                id: UUID(),
                title: expense.title,
                date: nextDate,
                type: "expense",
                relatedEntityID: expense.id
            )
        }
    }
}
