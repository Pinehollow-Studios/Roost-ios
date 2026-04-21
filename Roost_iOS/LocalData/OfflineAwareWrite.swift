import Foundation

// MARK: - OfflineAwareWrite
//
// The single path every ViewModel mutation should go through in Phase 2+:
//
//   1. Write optimistically to SwiftData (set isDirty = true, pendingOperation = ...).
//   2. Enqueue a PendingMutation describing the intent.
//   3. Ask SyncCoordinator to drain immediately (no-op when offline).
//
// If step 3 succeeds synchronously, the mutation is already gone from the
// queue and the cache row is clean. If it fails/queues, the row stays dirty
// until SyncCoordinator drains on reconnect.
//
// The helper keeps a thin API so ViewModels don't need to know about
// MutationQueue or SyncCoordinator directly.

@MainActor
enum OfflineAwareWrite {
    /// Payload encoded into a PendingMutation. Domain handlers are responsible
    /// for decoding this shape.
    struct Intent {
        let entityType: String
        let operation: String
        let targetID: UUID
        let homeID: UUID?
        let payload: Data
        let clientTimestamp: Date

        init(
            entityType: String,
            operation: String,
            targetID: UUID,
            homeID: UUID?,
            payload: Data,
            clientTimestamp: Date = Date()
        ) {
            self.entityType = entityType
            self.operation = operation
            self.targetID = targetID
            self.homeID = homeID
            self.payload = payload
            self.clientTimestamp = clientTimestamp
        }
    }

    /// Enqueues the given intent in the persistent outbox and triggers a
    /// drain attempt. Does not throw on offline — that's the whole point.
    ///
    /// Returns the enqueued `PendingMutation.id` so the ViewModel can correlate
    /// cache rows with their outstanding mutation if needed.
    @discardableResult
    static func enqueue(_ intent: Intent) throws -> UUID {
        let queue = MutationQueue()
        let mutation = PendingMutation(
            entityType: intent.entityType,
            operation: intent.operation,
            targetID: intent.targetID,
            homeID: intent.homeID,
            payloadData: intent.payload,
            clientTimestamp: intent.clientTimestamp,
            deviceID: DeviceIdentity.current
        )
        try queue.enqueue(mutation)

        // Kick a drain attempt — SyncCoordinator is a no-op when offline.
        Task { await SyncCoordinator.shared.drainIfOnline() }
        return mutation.id
    }
}
