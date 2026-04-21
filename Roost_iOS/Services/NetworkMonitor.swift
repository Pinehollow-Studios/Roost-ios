import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkMonitor {
    var isConnected = true
    /// True when the current path is cellular or otherwise metered. Surfaced
    /// so future logic (e.g. deferring large uploads, Hazel batching) can
    /// respect user data. Not currently consumed — reserved for Phase 4.
    var isExpensive = false

    @ObservationIgnored
    private let monitor = NWPathMonitor()

    @ObservationIgnored
    private let queue = DispatchQueue(label: "com.roostapp.ios.networkmonitor")

    @ObservationIgnored
    private var wasDisconnected = false

    /// Coalesces flappy path updates. A reconnect that lasts <250ms is ignored
    /// to avoid hammering `SyncCoordinator.drain()` during transient network
    /// blips. The previous implementation had no debounce at all.
    @ObservationIgnored
    private var debounceTask: Task<Void, Never>?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let connected = path.status == .satisfied
                let expensive = path.isExpensive

                // Debounce any transition so flapping networks don't trigger
                // a cascade of resubscribe+drain calls.
                self.debounceTask?.cancel()
                self.debounceTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard let self, !Task.isCancelled else { return }
                    await self.apply(connected: connected, expensive: expensive)
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func apply(connected: Bool, expensive: Bool) async {
        let previouslyDisconnected = wasDisconnected

        isConnected = connected
        isExpensive = expensive

        if connected && previouslyDisconnected {
            wasDisconnected = false
            // On reconnect: resubscribe realtime first (so we don't miss
            // events that land during the drain), then drain the offline
            // outbox so the server sees our queued work before realtime
            // starts overwriting cache rows.
            await RealtimeManager.shared.resubscribeAll()
            await SyncCoordinator.shared.drainIfOnline()
        } else {
            // Either we were already connected (initial state) or we just
            // went offline — update the banner regardless.
            SyncCoordinator.shared.refreshStatusCounts()
        }

        if !connected {
            wasDisconnected = true
        }
    }
}
