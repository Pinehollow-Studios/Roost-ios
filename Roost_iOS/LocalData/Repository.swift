import Foundation
import SwiftData

// MARK: - Repository protocol
//
// A Repository owns the cache-first read path for one domain. It exposes:
//   1. A stream of cached rows for a given home, kept fresh by SwiftData's own
//      change propagation.
//   2. A `refresh` method that fetches the latest from the server and upserts
//      into the cache — **preserving any locally-dirty rows** (rows that still
//      have a PendingMutation against them).
//
// Phase 1 ships this protocol; per-domain concrete implementations land with
// their respective ViewModel migrations in Phase 2 and Phase 3.

/// A repository for a single domain (expenses, budgets, …). Generic over the
/// network model type returned to the ViewModel.
@MainActor
protocol Repository {
    associatedtype Model: Identifiable where Model.ID == UUID

    /// Cache-first snapshot for the given home. Callers should render this
    /// immediately, then call `refresh` to fetch the latest from the server.
    func loadCached(homeID: UUID) throws -> [Model]

    /// Fetches the latest from the server and merges into the SwiftData cache.
    /// Preserves any rows whose `isDirty == true` (they have pending mutations).
    func refresh(homeID: UUID) async throws
}

// MARK: - DirtyRowPolicy
//
// Documents how cache upserts should interact with rows that have unreplayed
// offline mutations. Every concrete Repository should follow this policy.
enum DirtyRowPolicy {
    /// Server state for a given primary key wins **unless** the local row is
    /// dirty; a dirty local row is left untouched until its queued mutation
    /// drains.
    static let description = "Server wins on non-dirty keys; dirty keys preserved until drain."
}
