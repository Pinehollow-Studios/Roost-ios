import Testing
import Foundation
import SwiftData
@testable import Roost

/// Covers the offline outbox contract that `SyncCoordinator` relies on:
/// enqueue, FIFO drain order, status transitions, exponential backoff, and
/// user-initiated retry/discard from the Pending Changes UI.
@MainActor
struct MutationQueueTests {

    // MARK: Helpers

    private func makeQueue() throws -> (MutationQueue, ModelContainer) {
        let schema = Schema([PendingMutation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return (MutationQueue(container: container), container)
    }

    private func mutation(
        entity: String = "expense",
        operation: String = "create",
        createdAt: Date = Date(),
        status: PendingMutation.Status = .pending
    ) -> PendingMutation {
        PendingMutation(
            entityType: entity,
            operation: operation,
            targetID: UUID(),
            homeID: UUID(),
            payloadData: Data("{}".utf8),
            clientTimestamp: createdAt,
            deviceID: UUID(),
            status: status,
            createdAt: createdAt
        )
    }

    // MARK: Tests

    @Test func enqueueAndFetchPending() throws {
        let (queue, _) = try makeQueue()
        try queue.enqueue(mutation())
        #expect(try queue.pendingCount() == 1)
        #expect(try queue.failedCount() == 0)
        #expect(try queue.nextBatch().count == 1)
    }

    @Test func nextBatchIsFIFOByCreatedAt() throws {
        let (queue, _) = try makeQueue()
        let t0 = Date().addingTimeInterval(-60)
        let t1 = Date().addingTimeInterval(-30)
        let t2 = Date()
        // Enqueue out of order — next batch should still come back FIFO.
        try queue.enqueue(mutation(entity: "b", createdAt: t1))
        try queue.enqueue(mutation(entity: "c", createdAt: t2))
        try queue.enqueue(mutation(entity: "a", createdAt: t0))

        let batch = try queue.nextBatch()
        #expect(batch.map(\.entityType) == ["a", "b", "c"])
    }

    @Test func markInFlightHidesFromNextBatch() throws {
        let (queue, _) = try makeQueue()
        let m = mutation()
        try queue.enqueue(m)
        try queue.markInFlight(m.id)
        #expect(try queue.nextBatch().isEmpty)
    }

    @Test func markSucceededDeletesRow() throws {
        let (queue, _) = try makeQueue()
        let m = mutation()
        try queue.enqueue(m)
        try queue.markSucceeded(m.id)
        #expect(try queue.pendingCount() == 0)
    }

    @Test func markFailedTerminalMovesToFailed() throws {
        let (queue, _) = try makeQueue()
        let m = mutation()
        try queue.enqueue(m)
        try queue.markFailed(m.id, error: "bad", terminal: true)
        #expect(try queue.pendingCount() == 0)
        #expect(try queue.failedCount() == 1)
        #expect(try queue.allFailed().first?.lastError == "bad")
    }

    @Test func markFailedTransientSchedulesBackoff() throws {
        let (queue, _) = try makeQueue()
        let m = mutation()
        try queue.enqueue(m)
        try queue.markFailed(m.id, error: "temp", terminal: false)

        // Stays pending with a future nextAttemptAt — so it's excluded from
        // the ready-to-run batch.
        #expect(try queue.pendingCount() == 1)
        #expect(try queue.failedCount() == 0)
        #expect(try queue.nextBatch().isEmpty)
    }

    @Test func retryResetsBackoffAndMakesRunnable() throws {
        let (queue, _) = try makeQueue()
        let m = mutation()
        try queue.enqueue(m)
        try queue.markFailed(m.id, error: "fail", terminal: true)
        try queue.retry(m.id)
        #expect(try queue.failedCount() == 0)
        #expect(try queue.nextBatch().count == 1)
    }

    @Test func discardRemovesFailedRow() throws {
        let (queue, _) = try makeQueue()
        let m = mutation()
        try queue.enqueue(m)
        try queue.markFailed(m.id, error: "fail", terminal: true)
        try queue.discard(m.id)
        #expect(try queue.failedCount() == 0)
        #expect(try queue.pendingCount() == 0)
    }

    @Test func pendingForEntityReturnsOnlyThatEntity() throws {
        let (queue, _) = try makeQueue()
        let shared = UUID()
        let other = UUID()
        let mA = PendingMutation(
            entityType: "expense", operation: "create",
            targetID: shared, homeID: UUID(),
            payloadData: Data("{}".utf8), deviceID: UUID()
        )
        let mB = PendingMutation(
            entityType: "expense", operation: "update",
            targetID: other, homeID: UUID(),
            payloadData: Data("{}".utf8), deviceID: UUID()
        )
        try queue.enqueue(mA)
        try queue.enqueue(mB)
        #expect(try queue.pendingForEntity(shared).count == 1)
        #expect(try queue.pendingForEntity(other).count == 1)
    }

    @Test func clearAllEmptiesTheQueue() throws {
        let (queue, _) = try makeQueue()
        try queue.enqueue(mutation())
        try queue.enqueue(mutation(entity: "other"))
        try queue.clearAll()
        #expect(try queue.pendingCount() == 0)
    }
}
