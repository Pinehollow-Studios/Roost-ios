import Foundation
import SwiftData

// MARK: - Offline metadata (shared conventions)
//
// Every `Cached*` model carries four nullable metadata fields used by the
// offline subsystem. They are all optional with nil defaults so SwiftData can
// do a lightweight migration from the pre-offline schema without touching a
// real user's cache.
//
//   - isDirty: true when the row has an un-replayed offline mutation against it
//   - lastSyncedAt: timestamp of the last successful server reconciliation
//   - pendingOperation: "create" | "update" | "delete" | "settlement" | "needsCategorisation"
//   - serverUpdatedAt: the server's `updated_at` at the time we last fetched
//     this row. Used as an LWW tiebreaker during reconciliation.

// MARK: - Shopping Items

@Model
final class CachedShoppingItem {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var name: String
    var quantity: String?
    var category: String?
    var checked: Bool
    var createdAt: Date

    // Offline metadata
    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

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

// MARK: - Expenses

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

    // Offline metadata
    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

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

// MARK: - Expense Splits

@Model
final class CachedExpenseSplit {
    @Attribute(.unique) var id: UUID
    var expenseID: UUID
    var userID: UUID
    var amount: Decimal
    var settledAt: Date?
    var settled: Bool

    // Offline metadata
    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(id: UUID, expenseID: UUID, userID: UUID, amount: Decimal, settledAt: Date?, settled: Bool) {
        self.id = id
        self.expenseID = expenseID
        self.userID = userID
        self.amount = amount
        self.settledAt = settledAt
        self.settled = settled
    }
}

// MARK: - Chores

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

    // Offline metadata
    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

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

// MARK: - Activity Feed

@Model
final class CachedActivityFeedItem {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var userID: UUID
    var action: String
    var entityType: String?
    var entityID: UUID?
    var createdAt: Date

    // Offline metadata — activity rows are append-only, so these are mostly
    // informational (locally-appended rows carry isDirty=true until the server
    // produces the authoritative row).
    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

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

// MARK: - Budgets

@Model
final class CachedBudget {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var category: String
    var amount: Decimal
    var month: Date

    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(id: UUID, homeID: UUID, category: String, amount: Decimal, month: Date) {
        self.id = id
        self.homeID = homeID
        self.category = category
        self.amount = amount
        self.month = month
    }

    convenience init(from budget: Budget) {
        self.init(id: budget.id, homeID: budget.homeID, category: budget.category, amount: budget.amount, month: budget.month)
    }
}

// MARK: - Custom Budget Categories

@Model
final class CachedCustomCategory {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var name: String
    var emoji: String
    var colour: String?
    var createdAt: Date

    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(id: UUID, homeID: UUID, name: String, emoji: String, colour: String?, createdAt: Date) {
        self.id = id
        self.homeID = homeID
        self.name = name
        self.emoji = emoji
        self.colour = colour
        self.createdAt = createdAt
    }

    convenience init(from category: CustomCategory) {
        self.init(
            id: category.id,
            homeID: category.homeID,
            name: category.name,
            emoji: category.emoji,
            colour: category.color,
            createdAt: category.createdAt
        )
    }
}

// MARK: - Savings Goals

@Model
final class CachedSavingsGoal {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var name: String
    var targetAmount: Decimal
    var savedAmount: Decimal
    var colour: String
    var icon: String?
    var targetDate: Date?
    var isComplete: Bool
    var completedAt: Date?
    var sortOrder: Int?
    var monthlyContribution: Decimal?
    var contributionDay: Int?
    var budgetLineID: UUID?
    var createdAt: Date
    var updatedAt: Date

    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(
        id: UUID,
        homeID: UUID,
        name: String,
        targetAmount: Decimal,
        savedAmount: Decimal,
        colour: String,
        icon: String?,
        targetDate: Date?,
        isComplete: Bool,
        completedAt: Date?,
        sortOrder: Int?,
        monthlyContribution: Decimal?,
        contributionDay: Int?,
        budgetLineID: UUID?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.homeID = homeID
        self.name = name
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
        self.colour = colour
        self.icon = icon
        self.targetDate = targetDate
        self.isComplete = isComplete
        self.completedAt = completedAt
        self.sortOrder = sortOrder
        self.monthlyContribution = monthlyContribution
        self.contributionDay = contributionDay
        self.budgetLineID = budgetLineID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(from goal: SavingsGoal) {
        self.init(
            id: goal.id,
            homeID: goal.homeId,
            name: goal.name,
            targetAmount: goal.targetAmount,
            savedAmount: goal.savedAmount,
            colour: goal.colour,
            icon: goal.icon,
            targetDate: goal.targetDate,
            isComplete: goal.isComplete,
            completedAt: goal.completedAt,
            sortOrder: goal.sortOrder,
            monthlyContribution: goal.monthlyContribution,
            contributionDay: goal.contributionDay,
            budgetLineID: goal.budgetLineId,
            createdAt: goal.createdAt,
            updatedAt: goal.updatedAt
        )
    }
}

// MARK: - Calendar Events

@Model
final class CachedCalendarEvent {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var title: String
    var eventDate: Date
    var eventType: String
    var relatedEntityID: UUID?

    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(id: UUID, homeID: UUID, title: String, eventDate: Date, eventType: String, relatedEntityID: UUID?) {
        self.id = id
        self.homeID = homeID
        self.title = title
        self.eventDate = eventDate
        self.eventType = eventType
        self.relatedEntityID = relatedEntityID
    }
}

// MARK: - Pinboard Notes

@Model
final class CachedPinboardNote {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var authorID: UUID?
    var content: String
    var linkType: String?
    var linkLabel: String?
    var linkedEntityID: UUID?
    var targetScope: String
    var targetUserID: UUID?
    var notifyOnCreate: Bool
    var expiresAt: Date?
    var createdAt: Date
    var updatedAt: Date
    /// JSON-encoded acknowledgements array. Serialised to Data to avoid
    /// adding a SwiftData relationship, which complicates migrations.
    var acknowledgementsData: Data?

    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(
        id: UUID,
        homeID: UUID,
        authorID: UUID?,
        content: String,
        linkType: String?,
        linkLabel: String?,
        linkedEntityID: UUID?,
        targetScope: String,
        targetUserID: UUID?,
        notifyOnCreate: Bool,
        expiresAt: Date?,
        createdAt: Date,
        updatedAt: Date,
        acknowledgementsData: Data?
    ) {
        self.id = id
        self.homeID = homeID
        self.authorID = authorID
        self.content = content
        self.linkType = linkType
        self.linkLabel = linkLabel
        self.linkedEntityID = linkedEntityID
        self.targetScope = targetScope
        self.targetUserID = targetUserID
        self.notifyOnCreate = notifyOnCreate
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.acknowledgementsData = acknowledgementsData
    }
}

// MARK: - Rooms

@Model
final class CachedRoom {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var name: String
    var icon: String?

    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(id: UUID, homeID: UUID, name: String, icon: String?) {
        self.id = id
        self.homeID = homeID
        self.name = name
        self.icon = icon
    }

    convenience init(from room: Room) {
        self.init(id: room.id, homeID: room.homeID, name: room.name, icon: room.icon)
    }
}

// MARK: - Home

@Model
final class CachedHome {
    @Attribute(.unique) var id: UUID
    var name: String
    var inviteCode: String
    var nextShopDate: String?
    var subscriptionStatus: String?
    var subscriptionTier: String?
    var trialEndsAt: Date?
    var currentPeriodEndsAt: Date?
    var hasUsedTrial: Bool?
    var defaultExpenseSplit: Double?
    var budgetCarryForward: String?
    var scrambleMode: Bool?
    var overspendAlertThreshold: Int?
    var currencySymbol: String?
    var settlementMode: String?
    var createdAt: Date

    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(
        id: UUID,
        name: String,
        inviteCode: String,
        nextShopDate: String?,
        subscriptionStatus: String?,
        subscriptionTier: String?,
        trialEndsAt: Date?,
        currentPeriodEndsAt: Date?,
        hasUsedTrial: Bool?,
        defaultExpenseSplit: Double?,
        budgetCarryForward: String?,
        scrambleMode: Bool?,
        overspendAlertThreshold: Int?,
        currencySymbol: String?,
        settlementMode: String?,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.nextShopDate = nextShopDate
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionTier = subscriptionTier
        self.trialEndsAt = trialEndsAt
        self.currentPeriodEndsAt = currentPeriodEndsAt
        self.hasUsedTrial = hasUsedTrial
        self.defaultExpenseSplit = defaultExpenseSplit
        self.budgetCarryForward = budgetCarryForward
        self.scrambleMode = scrambleMode
        self.overspendAlertThreshold = overspendAlertThreshold
        self.currencySymbol = currencySymbol
        self.settlementMode = settlementMode
        self.createdAt = createdAt
    }

    convenience init(from home: Home) {
        self.init(
            id: home.id,
            name: home.name,
            inviteCode: home.inviteCode,
            nextShopDate: home.nextShopDate,
            subscriptionStatus: home.subscriptionStatus,
            subscriptionTier: home.subscriptionTier,
            trialEndsAt: home.trialEndsAt,
            currentPeriodEndsAt: home.currentPeriodEndsAt,
            hasUsedTrial: home.hasUsedTrial,
            defaultExpenseSplit: home.defaultExpenseSplit,
            budgetCarryForward: home.budgetCarryForward,
            scrambleMode: home.scrambleMode,
            overspendAlertThreshold: home.overspendAlertThreshold,
            currencySymbol: home.currencySymbol,
            settlementMode: home.settlementMode,
            createdAt: home.createdAt
        )
    }
}

// MARK: - Home Members

@Model
final class CachedHomeMember {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var userID: UUID
    var displayName: String
    var avatarColor: String?
    var avatarIcon: String?
    var role: String?
    var joinedAt: Date
    var personalIncome: Decimal?
    var incomeVisibleToPartner: Bool?
    var incomeSetAt: Date?
    var paypalUsername: String?
    var monzoUsername: String?

    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(
        id: UUID,
        homeID: UUID,
        userID: UUID,
        displayName: String,
        avatarColor: String?,
        avatarIcon: String?,
        role: String?,
        joinedAt: Date,
        personalIncome: Decimal?,
        incomeVisibleToPartner: Bool?,
        incomeSetAt: Date?,
        paypalUsername: String?,
        monzoUsername: String?
    ) {
        self.id = id
        self.homeID = homeID
        self.userID = userID
        self.displayName = displayName
        self.avatarColor = avatarColor
        self.avatarIcon = avatarIcon
        self.role = role
        self.joinedAt = joinedAt
        self.personalIncome = personalIncome
        self.incomeVisibleToPartner = incomeVisibleToPartner
        self.incomeSetAt = incomeSetAt
        self.paypalUsername = paypalUsername
        self.monzoUsername = monzoUsername
    }

    convenience init(from member: HomeMember) {
        self.init(
            id: member.id,
            homeID: member.homeID,
            userID: member.userID,
            displayName: member.displayName,
            avatarColor: member.avatarColor,
            avatarIcon: member.avatarIcon,
            role: member.role,
            joinedAt: member.joinedAt,
            personalIncome: member.personalIncome,
            incomeVisibleToPartner: member.incomeVisibleToPartner,
            incomeSetAt: member.incomeSetAt,
            paypalUsername: member.paypalUsername,
            monzoUsername: member.monzoUsername
        )
    }
}

// MARK: - Household Income

@Model
final class CachedHouseholdIncome {
    @Attribute(.unique) var id: UUID
    var homeID: UUID
    var month: Date
    var combinedAmount: Decimal
    var member1Amount: Decimal?
    var member2Amount: Decimal?
    var createdAt: Date
    var updatedAt: Date

    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var pendingOperation: String?
    var serverUpdatedAt: Date?

    init(
        id: UUID,
        homeID: UUID,
        month: Date,
        combinedAmount: Decimal,
        member1Amount: Decimal?,
        member2Amount: Decimal?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.homeID = homeID
        self.month = month
        self.combinedAmount = combinedAmount
        self.member1Amount = member1Amount
        self.member2Amount = member2Amount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(from income: HouseholdIncome) {
        self.init(
            id: income.id,
            homeID: income.homeId,
            month: income.month,
            combinedAmount: income.combinedAmount,
            member1Amount: income.tomAmount,
            member2Amount: income.partnerAmount,
            createdAt: income.createdAt,
            updatedAt: income.updatedAt
        )
    }
}
