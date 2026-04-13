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
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }
}
