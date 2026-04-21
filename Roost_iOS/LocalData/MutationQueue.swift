import Foundation
import SwiftData

// MARK: - PendingMutation (SwiftData row)

/// A single offline mutation waiting to be replayed against the server.
///
/// Stored in the same SwiftData container as the domain cache so it persists
/// across launches and crashes. Drained by `SyncCoordinator` in FIFO order.
@Model
final class PendingMutation {
    @Attribute(.unique) var id: UUID
    /// Logical domain this mutation targets — e.g. "expense", "budget",
    /// "shopping_item", "chore", "calendar_event". Used by SyncCoordinator to
    /// look up the correct MutationHandler.
    var entityType: String
    /// "create" | "update" | "delete" | "custom:<name>" for domain-specific
    /// intents like "custom:settlement".
    var operation: String
    /// The primary key of the affected row. For create operations this is a
    /// client-generated UUID; the server accepts it as-is (or uses it as a
    /// client_id column — see domain-specific handlers).
    var targetID: UUID
    /// Scoping identifier for multi-home reconciliation.
    var homeID: UUID?
    /// JSON-serialised payload with everything the handler needs to replay.
    /// Schema is handler-defined; SyncCoordinator does not introspect it.
    var payloadData: Data
    /// Monotonic client timestamp — used for FIFO drain and as an LWW tiebreaker.
    var clientTimestamp: Date
    /// Stable device identifier for multi-device LWW disambiguation.
    var deviceID: UUID
    /// Status string, mirrors `PendingMutation.Status`.
    var statusRaw: String
    /// Number of times we've attempted (and failed) to replay this mutation.
    var retryCount: Int
    /// Human-readable last error message for the Pending Changes UI.
    var lastError: String?
    /// Next time we should attempt replay; nil means "ASAP".
    var nextAttemptAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        entityType: String,
        operation: String,
        targetID: UUID,
        homeID: UUID?,
        payloadData: Data,
        clientTimestamp: Date = Date(),
        deviceID: UUID,
        status: Status = .pending,
        retryCount: Int = 0,
        lastError: String? = nil,
        nextAttemptAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.entityType = entityType
        self.operation = operation
        self.targetID = targetID
        self.homeID = homeID
        self.payloadData = payloadData
        self.clientTimestamp = clientTimestamp
        self.deviceID = deviceID
        self.statusRaw = status.rawValue
        self.retryCount = retryCount
        self.lastError = lastError
        self.nextAttemptAt = nextAttemptAt
        self.createdAt = createdAt
    }

    enum Status: String {
        /// Waiting to be drained.
        case pending
        /// Currently being replayed.
        case inFlight
        /// Replay failed permanently (4xx/validation). Needs user action.
        case failed
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
}

// MARK: - MutationQueue

/// Persistent outbox for offline writes. Backed by the shared SwiftData
/// container in `LocalDataManager`.
///
/// The queue itself is dumb — it only stores and retrieves rows. The decision
/// about *what* to do with a given mutation (which service to call, how to
/// encode the payload) lives in `SyncCoordinator` and its per-domain
/// `MutationHandler` registrations.
@MainActor
struct MutationQueue {
    private let container: ModelContainer

    init() {
        self.container = LocalDataManager.shared.container
    }

    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: Enqueue

    func enqueue(_ mutation: PendingMutation) throws {
        let context = container.mainContext
        context.insert(mutation)
        try context.save()
    }

    // MARK: Reads

    /// Returns pending mutations ready for replay, ordered FIFO by `createdAt`.
    /// Excludes rows whose `nextAttemptAt` is in the future (backoff).
    ///
    /// SwiftData `#Predicate` is unreliable with optional force-unwraps, so
    /// we fetch all pending rows and filter the backoff condition in Swift.
    /// The fetch is capped at `limit * 4` to avoid pathological reads when
    /// the queue is large and mostly backed-off.
    func nextBatch(limit: Int = 25) throws -> [PendingMutation] {
        let context = container.mainContext
        let pendingRaw = PendingMutation.Status.pending.rawValue
        let predicate = #Predicate<PendingMutation> { m in
            m.statusRaw == pendingRaw
        }
        var descriptor = FetchDescriptor<PendingMutation>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = max(limit * 4, limit)
        let rows = try context.fetch(descriptor)
        let now = Date()
        return rows
            .filter { $0.nextAttemptAt == nil || ($0.nextAttemptAt ?? now) <= now }
            .prefix(limit)
            .map { $0 }
    }

    func allFailed() throws -> [PendingMutation] {
        let context = container.mainContext
        let failedRaw = PendingMutation.Status.failed.rawValue
        let predicate = #Predicate<PendingMutation> { $0.statusRaw == failedRaw }
        let descriptor = FetchDescriptor<PendingMutation>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func pendingCount() throws -> Int {
        let context = container.mainContext
        let pendingRaw = PendingMutation.Status.pending.rawValue
        let predicate = #Predicate<PendingMutation> { $0.statusRaw == pendingRaw }
        let descriptor = FetchDescriptor<PendingMutation>(predicate: predicate)
        return try context.fetchCount(descriptor)
    }

    func failedCount() throws -> Int {
        let context = container.mainContext
        let failedRaw = PendingMutation.Status.failed.rawValue
        let predicate = #Predicate<PendingMutation> { $0.statusRaw == failedRaw }
        let descriptor = FetchDescriptor<PendingMutation>(predicate: predicate)
        return try context.fetchCount(descriptor)
    }

    func pendingForEntity(_ entityID: UUID) throws -> [PendingMutation] {
        let context = container.mainContext
        let predicate = #Predicate<PendingMutation> { $0.targetID == entityID }
        let descriptor = FetchDescriptor<PendingMutation>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: State transitions

    func markInFlight(_ id: UUID) throws {
        try updateStatus(id: id) { m in
            m.status = .inFlight
        }
    }

    func markSucceeded(_ id: UUID) throws {
        let context = container.mainContext
        let predicate = #Predicate<PendingMutation> { $0.id == id }
        let descriptor = FetchDescriptor<PendingMutation>(predicate: predicate)
        if let row = try context.fetch(descriptor).first {
            context.delete(row)
            try context.save()
        }
    }

    /// Records a failure, updates status/retry count and schedules next attempt
    /// via exponential backoff.
    ///
    /// - Parameters:
    ///   - terminal: if true, moves the row to `.failed` (needs user action).
    ///     Otherwise the row stays `.pending` with a `nextAttemptAt` in the
    ///     future and will be retried automatically.
    func markFailed(_ id: UUID, error: String, terminal: Bool) throws {
        try updateStatus(id: id) { m in
            m.retryCount += 1
            m.lastError = error
            if terminal {
                m.status = .failed
                m.nextAttemptAt = nil
            } else {
                m.status = .pending
                m.nextAttemptAt = Self.backoffDelay(for: m.retryCount).map { Date().addingTimeInterval($0) }
            }
        }
    }

    /// User-initiated retry of a `failed` mutation from the Pending Changes UI.
    func retry(_ id: UUID) throws {
        try updateStatus(id: id) { m in
            m.status = .pending
            m.nextAttemptAt = nil
        }
    }

    /// User-initiated discard of a `failed` mutation.
    func discard(_ id: UUID) throws {
        try markSucceeded(id) // same effect — row is deleted
    }

    func clearAll() throws {
        let context = container.mainContext
        try context.delete(model: PendingMutation.self)
        try context.save()
    }

    // MARK: Backoff policy
    //
    // Exponential with hard ceiling, matches Splitwise/Todoist behaviour:
    // 1s → 5s → 30s → 2m → 10m → 10m ...
    private static func backoffDelay(for retryCount: Int) -> TimeInterval? {
        switch retryCount {
        case 0, 1: return 1
        case 2: return 5
        case 3: return 30
        case 4: return 120
        default: return 600
        }
    }

    // MARK: Helpers

    private func updateStatus(id: UUID, mutation: (PendingMutation) -> Void) throws {
        let context = container.mainContext
        let predicate = #Predicate<PendingMutation> { $0.id == id }
        let descriptor = FetchDescriptor<PendingMutation>(predicate: predicate)
        guard let row = try context.fetch(descriptor).first else { return }
        mutation(row)
        try context.save()
    }
}
