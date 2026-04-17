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
/// Offline write queue: not yet implemented. When offline, writes should be
/// queued locally and replayed when connectivity returns. For now, writes
/// fail with an error if the network is unavailable.
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
        if let homeID = items.first?.homeID {
            let predicate = #Predicate<CachedShoppingItem> { $0.homeID == homeID }
            try context.delete(model: CachedShoppingItem.self, where: predicate)
        }
        for item in items {
            context.insert(CachedShoppingItem(from: item))
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
        if let homeID = expenses.first?.homeID {
            let predicate = #Predicate<CachedExpense> { $0.homeID == homeID }
            try context.delete(model: CachedExpense.self, where: predicate)
        }
        for expense in expenses {
            context.insert(CachedExpense(from: expense))
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
        if let homeID = chores.first?.homeID {
            let predicate = #Predicate<CachedChore> { $0.homeID == homeID }
            try context.delete(model: CachedChore.self, where: predicate)
        }
        for chore in chores {
            context.insert(CachedChore(from: chore))
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
        if let homeID = items.first?.homeID {
            let predicate = #Predicate<CachedActivityFeedItem> { $0.homeID == homeID }
            try context.delete(model: CachedActivityFeedItem.self, where: predicate)
        }
        for item in items {
            context.insert(CachedActivityFeedItem(from: item))
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
