import Foundation
import SwiftData

/// SyncEngine bridges Supabase network models and SwiftData cached models.
///
/// Pattern:
/// 1. On app launch: load from SwiftData for instant UI
/// 2. Fetch fresh data from Supabase in the background
/// 3. Upsert server responses into SwiftData by ID (merge)
/// 4. The ViewModel uses network data as the source of truth once fetched
///
/// Offline write queue is implemented in `MutationQueue`/`SyncCoordinator`.
/// When a Supabase call fails because the device is offline, the ViewModel
/// enqueues the mutation; the coordinator replays it on reconnect.
///
/// Cache upserts below are **dirty-row preserving**: a row whose
/// `isDirty == true` represents a not-yet-replayed offline change and is never
/// overwritten or deleted by a server refresh. This prevents the previous
/// wholesale-wipe behaviour from clobbering offline work when the network
/// comes back before the queue drains.
@MainActor
struct SyncEngine {
    private let container: ModelContainer

    init() {
        self.container = LocalDataManager.shared.container
    }

    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Shopping Items

    func loadCachedShoppingItems(homeID: UUID) throws -> [ShoppingItem] {
        let context = container.mainContext
        let predicate = #Predicate<CachedShoppingItem> { $0.homeID == homeID }
        let descriptor = FetchDescriptor<CachedShoppingItem>(predicate: predicate)
        let cached = try context.fetch(descriptor)
        return cached.map { item in
            ShoppingItem(
                id: item.id,
                homeID: item.homeID,
                name: item.name,
                quantity: item.quantity,
                category: item.category,
                checked: item.checked,
                addedBy: nil,
                checkedBy: nil,
                createdAt: item.createdAt,
                updatedAt: nil
            )
        }
    }

    func cacheShoppingItems(_ items: [ShoppingItem]) throws {
        let context = container.mainContext
        guard let homeID = items.first?.homeID else {
            try context.save()
            return
        }

        let existing = try context.fetch(
            FetchDescriptor<CachedShoppingItem>(predicate: #Predicate { $0.homeID == homeID })
        )
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let incomingIDs = Set(items.map { $0.id })
        let now = Date()

        for cached in existing where !incomingIDs.contains(cached.id) && !cached.isDirty {
            context.delete(cached)
        }

        for item in items {
            if let row = existingByID[item.id] {
                if row.isDirty { continue } // local edit wins until drained
                row.homeID = item.homeID
                row.name = item.name
                row.quantity = item.quantity
                row.category = item.category
                row.checked = item.checked
                row.createdAt = item.createdAt
                row.lastSyncedAt = now
                row.pendingOperation = nil
            } else {
                let fresh = CachedShoppingItem(from: item)
                fresh.lastSyncedAt = now
                context.insert(fresh)
            }
        }
        try context.save()
    }

    // MARK: - Expenses

    func loadCachedExpenses(homeID: UUID) throws -> [Expense] {
        let context = container.mainContext
        let predicate = #Predicate<CachedExpense> { $0.homeID == homeID }
        let descriptor = FetchDescriptor<CachedExpense>(predicate: predicate)
        let cached = try context.fetch(descriptor)
        return cached.map { item in
            Expense(
                id: item.id,
                homeID: item.homeID,
                title: item.title,
                amount: item.amount,
                paidBy: item.paidBy,
                category: item.category,
                notes: nil,
                incurredOn: {
                    let f = ISO8601DateFormatter()
                    f.formatOptions = [.withFullDate]
                    return f.string(from: item.incurredOn)
                }(),
                createdAt: item.createdAt
            )
        }
    }

    func cacheExpenses(_ expenses: [Expense]) throws {
        let context = container.mainContext
        guard let homeID = expenses.first?.homeID else {
            try context.save()
            return
        }

        let existing = try context.fetch(
            FetchDescriptor<CachedExpense>(predicate: #Predicate { $0.homeID == homeID })
        )
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let incomingIDs = Set(expenses.map { $0.id })
        let now = Date()

        for cached in existing where !incomingIDs.contains(cached.id) && !cached.isDirty {
            context.delete(cached)
        }

        for expense in expenses {
            if let row = existingByID[expense.id] {
                if row.isDirty { continue }
                row.homeID = expense.homeID
                row.title = expense.title
                row.amount = expense.amount
                row.paidBy = expense.paidBy
                row.category = expense.category
                row.incurredOn = expense.incurredOnDate ?? Date()
                row.createdAt = expense.createdAt
                row.lastSyncedAt = now
                row.pendingOperation = nil
            } else {
                let fresh = CachedExpense(from: expense)
                fresh.lastSyncedAt = now
                context.insert(fresh)
            }
        }
        try context.save()
    }

    // MARK: - Chores

    func loadCachedChores(homeID: UUID) throws -> [Chore] {
        let context = container.mainContext
        let predicate = #Predicate<CachedChore> { $0.homeID == homeID }
        let descriptor = FetchDescriptor<CachedChore>(predicate: predicate)
        let cached = try context.fetch(descriptor)
        return cached.map { item in
            Chore(
                id: item.id,
                homeID: item.homeID,
                title: item.title,
                description: item.choreDescription,
                room: item.room,
                assignedTo: item.assignedTo,
                dueDate: item.dueDate,
                completedBy: item.completedBy,
                frequency: item.frequency,
                lastCompletedAt: item.lastCompletedAt,
                createdAt: item.createdAt
            )
        }
    }

    func cacheChores(_ chores: [Chore]) throws {
        let context = container.mainContext
        guard let homeID = chores.first?.homeID else {
            try context.save()
            return
        }

        let existing = try context.fetch(
            FetchDescriptor<CachedChore>(predicate: #Predicate { $0.homeID == homeID })
        )
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let incomingIDs = Set(chores.map { $0.id })
        let now = Date()

        for cached in existing where !incomingIDs.contains(cached.id) && !cached.isDirty {
            context.delete(cached)
        }

        for chore in chores {
            if let row = existingByID[chore.id] {
                if row.isDirty { continue }
                row.homeID = chore.homeID
                row.title = chore.title
                row.choreDescription = chore.description
                row.room = chore.room
                row.assignedTo = chore.assignedTo
                row.dueDate = chore.dueDate
                row.completedBy = chore.completedBy
                row.frequency = chore.frequency
                row.lastCompletedAt = chore.lastCompletedAt
                row.createdAt = chore.createdAt
                row.lastSyncedAt = now
                row.pendingOperation = nil
            } else {
                let fresh = CachedChore(from: chore)
                fresh.lastSyncedAt = now
                context.insert(fresh)
            }
        }
        try context.save()
    }

    // MARK: - Activity Feed

    func loadCachedActivity(homeID: UUID) throws -> [ActivityFeedItem] {
        let context = container.mainContext
        let predicate = #Predicate<CachedActivityFeedItem> { $0.homeID == homeID }
        let descriptor = FetchDescriptor<CachedActivityFeedItem>(predicate: predicate)
        let cached = try context.fetch(descriptor)
        return cached.map { item in
            ActivityFeedItem(
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

    func cacheActivity(_ items: [ActivityFeedItem]) throws {
        let context = container.mainContext
        guard let homeID = items.first?.homeID else {
            try context.save()
            return
        }

        let existing = try context.fetch(
            FetchDescriptor<CachedActivityFeedItem>(predicate: #Predicate { $0.homeID == homeID })
        )
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let incomingIDs = Set(items.map { $0.id })
        let now = Date()

        // Activity feed rows never carry offline writes — always a safe wipe of
        // non-dirty stale rows. We keep the dirty guard anyway for consistency.
        for cached in existing where !incomingIDs.contains(cached.id) && !cached.isDirty {
            context.delete(cached)
        }

        for item in items {
            if let row = existingByID[item.id] {
                if row.isDirty { continue }
                row.homeID = item.homeID
                row.userID = item.userID
                row.action = item.action
                row.entityType = item.entityType
                row.entityID = item.entityID
                row.createdAt = item.createdAt
                row.lastSyncedAt = now
                row.pendingOperation = nil
            } else {
                let fresh = CachedActivityFeedItem(from: item)
                fresh.lastSyncedAt = now
                context.insert(fresh)
            }
        }
        try context.save()
    }

    // MARK: - Cache Wipe

    func clearAllCachedData() throws {
        let context = container.mainContext
        try context.delete(model: CachedShoppingItem.self)
        try context.delete(model: CachedExpense.self)
        try context.delete(model: CachedChore.self)
        try context.delete(model: CachedActivityFeedItem.self)
        try context.save()
    }
}
