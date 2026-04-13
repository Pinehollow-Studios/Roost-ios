import Foundation
import SwiftData

@Model
final class CachedShoppingItem {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var name: String
    var quantity: String?
    var category: String?
    var checked: Bool
    var createdAt: Date

    init(id: UUID, homeID: UUID, name: String, quantity: String?, category: String?, checked: Bool, createdAt: Date) {
        self.id = id
        self.homeID = homeID
        self.name = name
        self.quantity = quantity
        self.category = category
        self.checked = checked
        self.createdAt = createdAt
    }

    convenience init(from item: ShoppingItem) {
        self.init(
            id: item.id,
            homeID: item.homeID,
            name: item.name,
            quantity: item.quantity,
            category: item.category,
            checked: item.checked,
            createdAt: item.createdAt
        )
    }
}

@Model
final class CachedExpense {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var title: String
    var amount: Decimal
    var paidBy: UUID
    var category: String?
    var incurredOn: Date
    var createdAt: Date

    init(id: UUID, homeID: UUID, title: String, amount: Decimal, paidBy: UUID, category: String?, incurredOn: Date, createdAt: Date) {
        self.id = id
        self.homeID = homeID
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.category = category
        self.incurredOn = incurredOn
        self.createdAt = createdAt
    }

    convenience init(from expense: Expense) {
        self.init(
            id: expense.id,
            homeID: expense.homeID,
            title: expense.title,
            amount: expense.amount,
            paidBy: expense.paidBy,
            category: expense.category,
            incurredOn: expense.incurredOnDate ?? Date(),
            createdAt: expense.createdAt
        )
    }
}

@Model
final class CachedChore {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var title: String
    var choreDescription: String?
    var room: String?
    var completedBy: UUID?
    var assignedTo: UUID?
    var dueDate: Date?
    var frequency: String?
    var lastCompletedAt: Date?
    var createdAt: Date

    init(id: UUID, homeID: UUID, title: String, choreDescription: String?, room: String?, completedBy: UUID?, assignedTo: UUID?, dueDate: Date?, frequency: String?, lastCompletedAt: Date?, createdAt: Date) {
        self.id = id
        self.homeID = homeID
        self.title = title
        self.choreDescription = choreDescription
        self.room = room
        self.completedBy = completedBy
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.frequency = frequency
        self.lastCompletedAt = lastCompletedAt
        self.createdAt = createdAt
    }

    convenience init(from chore: Chore) {
        self.init(
            id: chore.id,
            homeID: chore.homeID,
            title: chore.title,
            choreDescription: chore.description,
            room: chore.room,
            completedBy: chore.completedBy,
            assignedTo: chore.assignedTo,
            dueDate: chore.dueDate,
            frequency: chore.frequency,
            lastCompletedAt: chore.lastCompletedAt,
            createdAt: chore.createdAt
        )
    }
}

@Model
final class CachedActivityFeedItem {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var userID: UUID
    var action: String
    var entityType: String?
    var entityID: UUID?
    var createdAt: Date

    init(id: UUID, homeID: UUID, userID: UUID, action: String, entityType: String?, entityID: UUID?, createdAt: Date) {
        self.id = id
        self.homeID = homeID
        self.userID = userID
        self.action = action
        self.entityType = entityType
        self.entityID = entityID
        self.createdAt = createdAt
    }

    convenience init(from item: ActivityFeedItem) {
        self.init(
            id: item.id,
            homeID: item.homeID,
            userID: item.userID,
            action: item.action,
            entityType: item.entityType,
            entityID: item.entityID,
            createdAt: item.createdAt
        )
    }
}
