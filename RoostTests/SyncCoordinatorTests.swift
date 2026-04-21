import Testing
import Foundation
@testable import Roost

/// Smoke tests for the offline sync state surface. Heavier end-to-end drain
/// tests are parked until Phase 2 introduces real `MutationHandler`
/// implementations — at that point `SyncCoordinator` will be refactored to
/// accept an injectable `MutationQueue` for deterministic testing.
@MainActor
struct SyncCoordinatorTests {

    // MARK: SyncStatusStore

    @Test func statusStoreStartsIdle() {
        let store = SyncStatusStore()
        #expect(store.state == .idle)
        #expect(store.pendingCount == 0)
        #expect(store.failedCount == 0)
    }

    @Test func statusStoreEqualityForSyncingState() {
        // Important because the offline banner uses `.state == .idle` etc.
        // to decide whether to render — any regression in Equatable semantics
        // silently breaks the banner.
        #expect(SyncStatusStore.State.idle == .idle)
        #expect(SyncStatusStore.State.offline == .offline)
        #expect(SyncStatusStore.State.syncing(pending: 2) == .syncing(pending: 2))
        #expect(SyncStatusStore.State.syncing(pending: 2) != .syncing(pending: 3))
        #expect(SyncStatusStore.State.error(failed: 1) == .error(failed: 1))
        #expect(SyncStatusStore.State.error(failed: 1) != .error(failed: 2))
    }

    @Test func reconciliationCounterIsMonotonic() {
        let store = SyncStatusStore()
        store.reconciliationCount += 1
        store.reconciliationCount += 1
        #expect(store.reconciliationCount == 2)
        // The UI uses `lastAcknowledgedReconciliation` to dismiss the toast
        // without clearing the running count, so verify both track
        // independently.
        store.lastAcknowledgedReconciliation = 2
        store.reconciliationCount += 1
        #expect(store.reconciliationCount == 3)
        #expect(store.lastAcknowledgedReconciliation == 2)
    }

    // MARK: MutationHandlerError classification

    @Test func handlerErrorCasesAreDistinct() {
        // Smoke check that the enum shape expected by SyncCoordinator's
        // classification switch hasn't been reordered or renamed.
        let cases: [MutationHandlerError] = [
            .transient("a"),
            .permanent("b"),
            .reconciledByServer("c"),
            .authExpired,
        ]
        #expect(cases.count == 4)
        if case .transient(let msg) = cases[0] { #expect(msg == "a") } else { Issue.record("wrong case") }
        if case .permanent(let msg) = cases[1] { #expect(msg == "b") } else { Issue.record("wrong case") }
        if case .reconciledByServer(let msg) = cases[2] { #expect(msg == "c") } else { Issue.record("wrong case") }
        if case .authExpired = cases[3] { } else { Issue.record("wrong case") }
    }

    // MARK: PendingMutation status round-trip

    @Test func pendingMutationStatusRawValueRoundTrips() {
        let m = PendingMutation(
            entityType: "expense",
            operation: "create",
            targetID: UUID(),
            homeID: UUID(),
            payloadData: Data("{}".utf8),
            deviceID: UUID(),
            status: .inFlight
        )
        #expect(m.status == .inFlight)
        m.status = .failed
        #expect(m.statusRaw == "failed")
        m.statusRaw = "pending"
        #expect(m.status == .pending)
    }
}
