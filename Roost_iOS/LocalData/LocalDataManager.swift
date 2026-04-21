import Foundation
import SwiftData

@MainActor
final class LocalDataManager {
    static let shared = LocalDataManager()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            // Pre-offline models (Phase 0 — extended in-place with offline metadata).
            CachedShoppingItem.self,
            CachedExpense.self,
            CachedChore.self,
            CachedActivityFeedItem.self,
            // Phase 1 offline foundation — additional domain caches.
            CachedExpenseSplit.self,
            CachedBudget.self,
            CachedCustomCategory.self,
            CachedSavingsGoal.self,
            CachedCalendarEvent.self,
            CachedPinboardNote.self,
            CachedRoom.self,
            CachedHome.self,
            CachedHomeMember.self,
            CachedHouseholdIncome.self,
            // Phase 1 offline foundation — mutation outbox.
            PendingMutation.self,
        ])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            // Schema migration failure — wipe the store and start fresh rather than crashing.
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            try? FileManager.default.removeItem(at: config.url)
            do {
                container = try ModelContainer(for: schema)
            } catch {
                // Fall back to in-memory store so the app remains usable.
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                container = try! ModelContainer(for: schema, configurations: memoryConfig)
            }
        }
    }
}
