import Foundation
import SwiftData

@MainActor
final class LocalDataManager {
    static let shared = LocalDataManager()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            CachedShoppingItem.self,
            CachedExpense.self,
            CachedChore.self,
            CachedActivityFeedItem.self,
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
