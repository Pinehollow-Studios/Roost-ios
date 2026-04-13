import Foundation
import Observation
import Realtime

// MARK: - Optimistic Update Pattern (Phase 2 reference)
//
// Every mutation that modifies a list should follow this pattern:
//
// 1. Immediately update the local array (optimistic)
// 2. Call the service method
// 3. On error: rollback the local change + set errorMessage
// 4. On success: call ActivityService.logActivity() (fire-and-forget)
// 5. Realtime will trigger a full re-fetch to reconcile
//
// See toggleItem() and deleteItem() below for the canonical implementations.
// All other ViewModels (Expenses, Chores, etc.) should follow this same pattern.

@MainActor
@Observable
final class ShoppingViewModel {
    var items: [ShoppingItem] = []
    var isLoading = false
    var errorMessage: String?

    init() {}

    init(items: [ShoppingItem], isLoading: Bool = false, errorMessage: String? = nil) {
        self.items = items
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    /// Items grouped by category for section display. Uncategorised items go under "Other".
    var groupedItems: [(category: String, items: [ShoppingItem])] {
        let grouped = Dictionary(grouping: items) { item in
            (item.category?.isEmpty == false) ? item.category! : "Other"
        }
        return grouped
            .sorted { $0.key == "Other" ? true : ($1.key == "Other" ? false : $0.key < $1.key) }
            .map { (category: $0.key, items: $0.value) }
    }

    @ObservationIgnored
    private let shoppingService = ShoppingService()

    @ObservationIgnored
    private let hazelService = HazelService()

    @ObservationIgnored
    private var realtimeSubscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    func loadItems(homeId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await shoppingService.fetchItems(for: homeId)
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }

        isLoading = false
    }

    func addItem(
        name: String,
        quantity: String?,
        category: String?,
        homeId: UUID,
        userId: UUID,
        hazelEnabled: Bool = false
    ) async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        // If Hazel is enabled and no category was manually provided, normalize and auto-categorize
        var resolvedName = trimmedName
        var resolvedCategory = category?.isEmpty == true ? nil : category

        if hazelEnabled, resolvedCategory == nil {
            if let result = await hazelService.normalizeShoppingItem(text: trimmedName, homeId: homeId) {
                resolvedName = result.text
                resolvedCategory = result.category
            }
        }

        let newItem = CreateShoppingItem(
            homeID: homeId,
            name: resolvedName,
            quantity: quantity?.isEmpty == true ? nil : quantity,
            category: resolvedCategory
        )

        do {
            let created = try await shoppingService.createItem(newItem)
            items.insert(created, at: 0)
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: "added \(trimmedName) to the shopping list",
                entityType: "shopping_item",
                entityId: created.id.uuidString
            )
        } catch {
            if !isCancellation(error) {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleItem(_ item: ShoppingItem, homeId: UUID, userId: UUID) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        // Optimistic update
        items[index].checked.toggle()
        let nowCompleted = items[index].checked

        do {
            try await shoppingService.updateItem(items[index])
            let action = nowCompleted
                ? "checked off \(item.name)"
                : "unchecked \(item.name)"
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: action,
                entityType: "shopping_item",
                entityId: item.id.uuidString
            )
        } catch {
            // Rollback
            items[index].checked.toggle()
            if !isCancellation(error) {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteItem(_ item: ShoppingItem, homeId: UUID, userId: UUID) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        // Optimistic update
        let removed = items.remove(at: index)

        do {
            try await shoppingService.deleteItem(id: removed.id)
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: "removed \(removed.name) from the shopping list",
                entityType: "shopping_item",
                entityId: removed.id.uuidString
            )
        } catch {
            // Rollback
            items.insert(removed, at: min(index, items.count))
            if !isCancellation(error) {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Realtime

    func startRealtime(homeId: UUID) async {
        if let subscribedHomeId, subscribedHomeId != homeId {
            await stopRealtime()
        }
        guard realtimeSubscriptionId == nil else { return }
        subscribedHomeId = homeId

        realtimeSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "shopping_items",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.loadItems(homeId: homeId)
        }
    }

    func stopRealtime() async {
        guard let subId = realtimeSubscriptionId else { return }
        await RealtimeManager.shared.unsubscribe(table: "shopping_items", callbackId: subId)
        realtimeSubscriptionId = nil
        subscribedHomeId = nil
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
    }
}
