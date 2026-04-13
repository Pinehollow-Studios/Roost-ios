import Foundation
import Observation
import Realtime

@MainActor
@Observable
final class MoneySettingsViewModel {

    var settings = MoneySettings()
    var isLoading = false

    @ObservationIgnored
    private let service = MoneySettingsService()

    @ObservationIgnored
    private var homesSubscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    // MARK: - Load

    func load(homeId: UUID) async {
        isLoading = true
        if let loaded = try? await service.fetchSettings(homeId: homeId) {
            settings = loaded
        }
        isLoading = false
    }

    /// Update a single setting locally and persist the full settings row to Supabase.
    func updateSetting<T>(
        _ keyPath: WritableKeyPath<MoneySettings, T>,
        value: T,
        homeId: UUID
    ) async throws {
        settings[keyPath: keyPath] = value
        try await service.persistSettings(settings, homeId: homeId)
    }

    func toggleScrambleMode(homeId: UUID) async throws {
        settings.scrambleMode.toggle()
        try await service.persistSettings(settings, homeId: homeId)
    }

    // MARK: - Realtime

    func startRealtime(homeId: UUID) async {
        if let existing = subscribedHomeId, existing != homeId { await stopRealtime() }
        guard homesSubscriptionId == nil else { return }
        subscribedHomeId = homeId

        homesSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "homes",
            filter: .eq("id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let hid = self.subscribedHomeId else { return }
            await self.load(homeId: hid)
        }
    }

    func stopRealtime() async {
        if let id = homesSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "homes", callbackId: id)
            homesSubscriptionId = nil
        }
        subscribedHomeId = nil
    }
}
