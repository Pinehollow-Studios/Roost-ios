import Foundation
import Observation
import Realtime
import Supabase

@MainActor
@Observable
final class RealtimeManager {
    static let shared = RealtimeManager()

    private struct ChannelEntry {
        var refCount: Int
        var channel: RealtimeChannelV2
        var listenerTask: Task<Void, Never>
        var callbacks: [UUID: @MainActor () async -> Void]
    }

    private var channels: [String: ChannelEntry] = [:]

    private init() {}

    /// Subscribe to postgres changes on a table. Returns a subscription ID for later unsubscription.
    func subscribe(
        table: String,
        filter: RealtimePostgresFilter? = nil,
        onChange: @MainActor @escaping () async -> Void
    ) async -> UUID {
        let callbackId = UUID()

        if var entry = channels[table] {
            entry.refCount += 1
            entry.callbacks[callbackId] = onChange
            channels[table] = entry
            return callbackId
        }

        guard let client = try? SupabaseClientProvider.shared.requireClient() else {
            return callbackId
        }

        let channel = client.realtimeV2.channel("realtime_\(table)")
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: table,
            filter: filter
        )

        let callbacks: [UUID: @MainActor () async -> Void] = [callbackId: onChange]
        channels[table] = ChannelEntry(
            refCount: 1,
            channel: channel,
            listenerTask: Task { /* replaced below */ },
            callbacks: callbacks
        )

        let task = Task { [weak self] in
            for await _ in changes {
                guard !Task.isCancelled else { return }
                guard let self else { return }
                if let entry = self.channels[table] {
                    for callback in entry.callbacks.values {
                        await callback()
                    }
                }
            }
        }

        channels[table]?.listenerTask = task

        do {
            try await channel.subscribeWithError()
        } catch {
            // Channel failed to subscribe — clean up
            task.cancel()
            channels.removeValue(forKey: table)
        }

        return callbackId
    }

    func unsubscribe(table: String, callbackId: UUID) async {
        guard var entry = channels[table] else { return }

        entry.callbacks.removeValue(forKey: callbackId)
        entry.refCount -= 1

        if entry.refCount <= 0 {
            entry.listenerTask.cancel()
            await entry.channel.unsubscribe()
            channels.removeValue(forKey: table)
        } else {
            channels[table] = entry
        }
    }

    func resubscribeAll() async {
        for (_, entry) in channels {
            await entry.channel.unsubscribe()
            try? await entry.channel.subscribeWithError()
        }
        // After reconnect, postgres_changes won't replay anything that happened
        // while we were offline. Fire each subscription's callback once so
        // repositories do a refresh and pick up the server's current truth.
        // Without this, lists can sit on stale cached rows until the next
        // manual pull-to-refresh.
        for (_, entry) in channels {
            for callback in entry.callbacks.values {
                await callback()
            }
        }
    }
}
