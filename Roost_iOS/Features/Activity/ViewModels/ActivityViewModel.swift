import Foundation
import Observation
import Realtime

@MainActor
@Observable
final class ActivityViewModel {
    var items: [ActivityFeedItem] = []
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private let activityService = ActivityService()

    @ObservationIgnored
    private var subscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    init(
        items: [ActivityFeedItem] = [],
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.items = items
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    func loadActivity(homeId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await activityService.fetchActivity(for: homeId)
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }

        isLoading = false
    }

    func startRealtime(homeId: UUID) async {
        if let subscribedHomeId, subscribedHomeId != homeId {
            await stopRealtime()
        }
        guard subscriptionId == nil else { return }
        subscribedHomeId = homeId

        subscriptionId = await RealtimeManager.shared.subscribe(
            table: "activity_feed",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId else { return }
            await self.loadActivity(homeId: homeId)
        }
    }

    func stopRealtime() async {
        guard let subscriptionId else { return }
        await RealtimeManager.shared.unsubscribe(table: "activity_feed", callbackId: subscriptionId)
        self.subscriptionId = nil
        subscribedHomeId = nil
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
    }
}
